-- ============================================================
-- CarryService_FINAL — OPTIMIZED
-- Perubahan:
--   • Hapus semua print() debug
--   • FIX memory leak: bindCleanup connections disimpan di tabel
--     per-pair dan di-Disconnect saat detachPair
--   • syncAnimations: koneksi CharacterRemoving/Died disimpan
--     dan di-cleanup saat stopSyncing
--   • task.wait() di acquireLock dibatasi max 300 iter (sudah ada)
-- ============================================================
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService    = game:GetService("PhysicsService")

local CarryRemote = ReplicatedStorage:FindFirstChild("CarryRemote")
	or (function()
		local r = Instance.new("RemoteEvent")
		r.Name = "CarryRemote"; r.Parent = ReplicatedStorage; return r
	end)()

local SyncingFolder = ReplicatedStorage:FindFirstChild("Syncing")
	or (function()
		local f = Instance.new("Folder")
		f.Name = "Syncing"; f.Parent = ReplicatedStorage; return f
	end)()
local SyncEvent = SyncingFolder:FindFirstChild("Sync")
	or (function()
		local r = Instance.new("RemoteEvent")
		r.Name = "Sync"; r.Parent = SyncingFolder; return r
	end)()
local UnSyncEvent = SyncingFolder:FindFirstChild("UnSync")
	or (function()
		local r = Instance.new("RemoteEvent")
		r.Name = "UnSync"; r.Parent = SyncingFolder; return r
	end)()

local GROUP_PLAYERS = "Players"
local GROUP_CARRIED = "Carried"
for _, name in ipairs({GROUP_PLAYERS, GROUP_CARRIED}) do
	pcall(function()
		if not PhysicsService:IsCollisionGroupRegistered(name) then
			PhysicsService:RegisterCollisionGroup(name)
		end
	end)
end
pcall(function()
	PhysicsService:CollisionGroupSetCollidable(GROUP_PLAYERS, GROUP_PLAYERS, false)
	PhysicsService:CollisionGroupSetCollidable(GROUP_CARRIED, GROUP_PLAYERS, false)
	PhysicsService:CollisionGroupSetCollidable(GROUP_CARRIED, GROUP_CARRIED, false)
	PhysicsService:CollisionGroupSetCollidable(GROUP_CARRIED, "Default",    false)
end)

local function setGroupRecursive(char, groupName)
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") then
			pcall(function() d.CollisionGroup = groupName end)
		end
	end
end

local PENDING_TIMEOUT = 8
local MAX_DISTANCE    = 20
local MAX_CARRY       = 5
local BASE_Z   = 1.6
local Y_OFFSET = 0.9

local function slotOffset(_i)
	local rx = math.random(-5, 5) * 0.02
	local rz = math.random(-5, 5) * 0.02
	return CFrame.new(rx, Y_OFFSET, BASE_Z + rz)
end

local pending            = {}
local carryingByCarrier  = {}
local carriedByTarget    = {}
local slotByCarrier      = {}
local lockMap            = {}
local detachGuard        = {}
local savedProps         = {}
local savedHum           = {}
local descAddedConns     = {}
local syncingPlayers     = {}
local syncedAnimations   = {}
-- FIX memory leak: simpan cleanup connections per carry-pair
local pairCleanupConns   = {}  -- key = carrierId.."_"..targetId

local IGNORED_EMOTES = {
	"running","swimming","platformstanding","seated","fallingdown",
	"gettingup","jumping","climbing","walking","idle","land","fall"
}

local function getCharHRP(p)
	local char = p.Character; if not char then return end
	local hrp  = char:FindFirstChild("HumanoidRootPart")
	local hum  = char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) then return end
	return char, hrp, hum
end

local function acquireLock(uid)
	local t = 0
	while lockMap[uid] do task.wait(); t += 1; if t > 300 then break end end
	lockMap[uid] = true
end
local function releaseLock(uid) lockMap[uid] = false end
local function acquireLocks(a, b)
	if a == b then acquireLock(a); return end
	if a < b then acquireLock(a); acquireLock(b) else acquireLock(b); acquireLock(a) end
end
local function releaseLocks(a, b)
	releaseLock(a); if b ~= a then releaseLock(b) end
end
local function getCarryMap(carrier)
	local m = carryingByCarrier[carrier.UserId]
	if not m then m = {}; carryingByCarrier[carrier.UserId] = m end
	return m
end
local function getSlotMap(carrier)
	local m = slotByCarrier[carrier.UserId]
	if not m then m = {}; slotByCarrier[carrier.UserId] = m end
	return m
end
local function countCarried(p)
	local m = carryingByCarrier[p.UserId]; if not m then return 0 end
	local n = 0; for _ in pairs(m) do n += 1 end; return n
end
local function isBeingCarried(p) return carriedByTarget[p.UserId] ~= nil end
local function canCarrierRequest(p) return not isBeingCarried(p) end
local function targetAvailable(p) return not isBeingCarried(p) end

local function saveHumState(uid, hum)
	savedHum[uid] = {
		ws          = hum.WalkSpeed,
		useJP       = hum.UseJumpPower,
		jp          = hum.JumpPower,
		jh          = hum.JumpHeight,
		autoRotate  = hum.AutoRotate,
		jumpEnabled = hum:GetStateEnabled(Enum.HumanoidStateType.Jumping),
	}
end
local function restoreHumState(uid, hum)
	local st = savedHum[uid]
	hum.PlatformStand = false
	if st then
		hum.WalkSpeed  = math.max(st.ws, 16)
		hum.AutoRotate = st.autoRotate
		if st.useJP then hum.JumpPower = st.jp else hum.JumpHeight = st.jh end
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, st.jumpEnabled)
		savedHum[uid] = nil
	else
		hum.WalkSpeed = 16; hum.AutoRotate = true
		if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end
	task.spawn(function()
		for i = 1, 4 do
			task.wait(0.1 * i)
			if not hum or not hum.Parent then break end
			hum.Sit = false; hum.PlatformStand = false
			hum.WalkSpeed = math.max(hum.WalkSpeed, 16)
			hum:ChangeState(Enum.HumanoidStateType.Running)
		end
	end)
end

local function makeCarriedLight(char, userId)
	local map = {}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") and not d:FindFirstAncestorOfClass("Tool") then
			map[d] = {cc = d.CanCollide, ml = d.Massless}
			d.CanCollide = false; d.Massless = true
		end
	end
	savedProps[userId] = map
	if descAddedConns[userId] then descAddedConns[userId]:Disconnect() end
	descAddedConns[userId] = char.DescendantAdded:Connect(function(d)
		if not carriedByTarget[userId] then return end
		if d:IsA("BasePart") and not d:FindFirstAncestorOfClass("Tool") then
			if not map[d] then map[d] = {cc = d.CanCollide, ml = d.Massless} end
			d.CanCollide = false; d.Massless = true
		end
	end)
end
local function restoreCarriedLight(userId)
	if descAddedConns[userId] then
		descAddedConns[userId]:Disconnect()
		descAddedConns[userId] = nil
	end
	local map = savedProps[userId]; if not map then return end
	savedProps[userId] = nil
	local p = Players:GetPlayerByUserId(userId)
	if not (p and p.Character) then return end
	for _, d in ipairs(p.Character:GetDescendants()) do
		if d:IsA("BasePart") and not d:FindFirstAncestorOfClass("Tool") then
			d.CanCollide = false; d.Massless = false
			pcall(function() d.CollisionGroup = GROUP_PLAYERS end)
		end
	end
end

local function giveSelfOwnership(p)
	local _, hrp = getCharHRP(p); if not hrp then return end
	pcall(function() hrp:SetNetworkOwner(p) end)
end
local function giveCarrierOwnership(target, carrier)
	local _, hrp = getCharHRP(target); if not hrp then return end
	pcall(function() hrp:SetNetworkOwner(carrier) end)
end

local function clearCarryWeldsForChar(char)
	local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
	for _, w in ipairs(hrp:GetChildren()) do
		if w:IsA("WeldConstraint") and w.Name == "CarryWeld" then w:Destroy() end
	end
end
local function findCarryWeld(tHRP, cHRP)
	for _, w in ipairs(tHRP:GetChildren()) do
		if w:IsA("WeldConstraint") and w.Name == "CarryWeld"
			and w.Part0 == cHRP and w.Part1 == tHRP then return w end
	end
end
local function ensureCarryWeld(cHRP, tHRP)
	local w = findCarryWeld(tHRP, cHRP)
	if not w then
		w = Instance.new("WeldConstraint"); w.Name = "CarryWeld"
		w.Part0 = cHRP; w.Part1 = tHRP; w.Parent = tHRP
	end
	return w
end
local function removeCarryWeld(cHRP, tHRP)
	local w = findCarryWeld(tHRP, cHRP); if w then w:Destroy() end
end

local function buildCarriedList(carrier)
	local list = {}
	local cmap = carryingByCarrier[carrier.UserId]
	if cmap then
		for tid, t in pairs(cmap) do
			table.insert(list, {id = tid, name = t.DisplayName})
		end
		table.sort(list, function(a, b) return a.name < b.name end)
	end
	return list
end
local function sendCarrierList(carrier)
	CarryRemote:FireClient(carrier, "CarrierList", {list = buildCarriedList(carrier)})
end
local function sendStart(carrier, target)
	CarryRemote:FireClient(carrier, "Start", {
		carrierId = carrier.UserId, carrierName = carrier.DisplayName,
		targetId  = target.UserId,  targetName  = target.DisplayName,
		youAreCarrier = true, carrierActiveCount = countCarried(carrier),
	})
	CarryRemote:FireClient(target, "Start", {
		carrierId = carrier.UserId, carrierName = carrier.DisplayName,
		targetId  = target.UserId,  targetName  = target.DisplayName,
		youAreCarrier = false,
	})
end
local function sendEndForCarrierOnly(carrier, removed, reason)
	CarryRemote:FireClient(carrier, "End", {
		reason = reason or "end", youAreCarrier = true,
		carrierActiveCount = countCarried(carrier),
		removedId = removed.UserId, removedName = removed.DisplayName,
	})
end
local function sendEndPair(carrier, target, reason)
	CarryRemote:FireClient(carrier, "End", {
		reason = reason or "end", youAreCarrier = true,
		carrierActiveCount = countCarried(carrier),
		removedId = target.UserId, removedName = target.DisplayName,
	})
	CarryRemote:FireClient(target, "End", {
		reason = reason or "end", youAreCarrier = false,
	})
end

-- FIX: cleanup pair connections
local function cleanupPairConns(cUID, tUID)
	local key = tostring(cUID).."_"..tostring(tUID)
	local conns = pairCleanupConns[key]
	if conns then
		for _, c in ipairs(conns) do
			if c and c.Connected then c:Disconnect() end
		end
		pairCleanupConns[key] = nil
	end
end

local function reindexSlots(carrier)
	acquireLock(carrier.UserId)
	pcall(function()
		local _, cHRP = getCharHRP(carrier); if not cHRP then return end
		local smap = slotByCarrier[carrier.UserId]; if not smap then return end
		local temp = {}
		for tid, s in pairs(smap) do
			local t = Players:GetPlayerByUserId(tid)
			if t then table.insert(temp, {p = t, s = s}) end
		end
		table.sort(temp, function(a, b) return a.s < b.s end)
		for i, e in ipairs(temp) do
			local _, tHRP = getCharHRP(e.p); if not tHRP then continue end
			slotByCarrier[carrier.UserId][e.p.UserId] = i
			if e.s ~= i then
				removeCarryWeld(cHRP, tHRP)
				tHRP.CFrame = cHRP.CFrame * slotOffset(i)
				ensureCarryWeld(cHRP, tHRP)
			end
		end
	end)
	releaseLock(carrier.UserId)
end

local function detachPair(carrier, target, reason)
	local cUID, tUID = carrier.UserId, target.UserId
	-- FIX: cleanup bindCleanup connections
	cleanupPairConns(cUID, tUID)
	acquireLock(cUID)
	local _,    cHRP        = getCharHRP(carrier)
	local tChar, tHRP, tHum = getCharHRP(target)
	if cHRP and tHRP then removeCarryWeld(cHRP, tHRP) end
	if tChar then setGroupRecursive(tChar, GROUP_PLAYERS) end
	if tHRP then
		pcall(function()
			tHRP.AssemblyLinearVelocity  = Vector3.zero
			tHRP.AssemblyAngularVelocity = Vector3.zero
		end)
	end
	if tHum then
		tHum.PlatformStand = false; tHum.Sit = false; tHum.Jump = false
		restoreHumState(tUID, tHum)
	end
	local cmap = carryingByCarrier[cUID]
	if cmap then
		cmap[tUID] = nil
		if not next(cmap) then carryingByCarrier[cUID] = nil end
	end
	if slotByCarrier[cUID] then slotByCarrier[cUID][tUID] = nil end
	carriedByTarget[tUID] = nil
	releaseLock(cUID)
	giveSelfOwnership(target)
	restoreCarriedLight(tUID)
	sendEndPair(carrier, target, reason)
	task.defer(function()
		if carryingByCarrier[cUID] then reindexSlots(carrier) end
		sendCarrierList(carrier)
	end)
end
local function detachAllForCarrier(carrier, reason)
	local cmap = carryingByCarrier[carrier.UserId]; if not cmap then return end
	local list = {}; for _, t in pairs(cmap) do table.insert(list, t) end
	for _, t in ipairs(list) do detachPair(carrier, t, reason) end
end
local function detachIfAny(p, reason)
	if carriedByTarget[p.UserId] then
		detachPair(carriedByTarget[p.UserId], p, reason)
	elseif carryingByCarrier[p.UserId] then
		detachAllForCarrier(p, reason)
	end
end
local function safeDetachIfAny(p, reason)
	if detachGuard[p.UserId] then return end
	detachGuard[p.UserId] = true
	task.defer(function() detachIfAny(p, reason); detachGuard[p.UserId] = nil end)
end

local function transferPassengersToAtomic(newCarrier, oldCarrier)
	local oldMap = carryingByCarrier[oldCarrier.UserId]; if not oldMap then return end
	local smapOld = slotByCarrier[oldCarrier.UserId] or {}
	local arr = {}
	for tid, t in pairs(oldMap) do table.insert(arr, {t = t, s = smapOld[tid] or 999}) end
	table.sort(arr, function(a, b) return a.s < b.s end)
	local _, newHRP = getCharHRP(newCarrier)
	local _, oldHRP = getCharHRP(oldCarrier)
	if not newHRP or not oldHRP then return end
	acquireLocks(newCarrier.UserId, oldCarrier.UserId)
	for _, entry in ipairs(arr) do
		local t = entry.t
		local tChar, tHRP, tHum = getCharHRP(t)
		if tChar and tHRP and tHum then
			local used, smNew = {}, getSlotMap(newCarrier)
			for _, idx in pairs(smNew) do used[idx] = true end
			local slotIdx
			for i = 1, MAX_CARRY do if not used[i] then slotIdx = i; break end end
			if not slotIdx then continue end
			cleanupPairConns(oldCarrier.UserId, t.UserId)
			removeCarryWeld(oldHRP, tHRP)
			tHRP.CFrame = newHRP.CFrame * slotOffset(slotIdx)
			ensureCarryWeld(newHRP, tHRP)
			tHum.AutoRotate = false; tHum.WalkSpeed = 0
			if tHum.UseJumpPower then tHum.JumpPower = 0 else tHum.JumpHeight = 0 end
			tHum.Sit = true
			tHum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			tHum.Jump = false
			setGroupRecursive(tChar, GROUP_CARRIED)
			giveCarrierOwnership(t, newCarrier)
			local om = carryingByCarrier[oldCarrier.UserId]
			if om then om[t.UserId] = nil; if not next(om) then carryingByCarrier[oldCarrier.UserId] = nil end end
			if slotByCarrier[oldCarrier.UserId] then slotByCarrier[oldCarrier.UserId][t.UserId] = nil end
			getCarryMap(newCarrier)[t.UserId] = t
			getSlotMap(newCarrier)[t.UserId]  = slotIdx
			carriedByTarget[t.UserId]         = newCarrier
			sendEndForCarrierOnly(oldCarrier, t, "transfer")
			sendStart(newCarrier, t)
		end
	end
	releaseLocks(newCarrier.UserId, oldCarrier.UserId)
	if carryingByCarrier[oldCarrier.UserId] then reindexSlots(oldCarrier) end
	sendCarrierList(newCarrier); sendCarrierList(oldCarrier)
end

task.spawn(function()
	while true do
		task.wait(2)
		local now = os.clock()
		for targetId, info in pairs(pending) do
			if now - info.time > PENDING_TIMEOUT then
				local target = Players:GetPlayerByUserId(targetId)
				if info.requester and info.requester.Parent == Players then
					CarryRemote:FireClient(info.requester, "RequestExpired", {targetId = targetId})
					if target then CarryRemote:FireClient(target, "PromptExpire", {}) end
				end
				pending[targetId] = nil
			end
		end
	end
end)

local function hasPendingIncoming(p) return pending[p.UserId] ~= nil end
local function hasPendingOutgoing(p)
	for _, info in pairs(pending) do if info.requester == p then return true end end
	return false
end

local function startCarry(carrier, target)
	local cChar, cHRP       = getCharHRP(carrier)
	local tChar, tHRP, tHum = getCharHRP(target)
	if not (cChar and cHRP and tChar and tHRP and tHum) then
		return false, "character missing"
	end
	acquireLock(carrier.UserId)
	local ok, err = pcall(function()
		if (cHRP.Position - tHRP.Position).Magnitude > MAX_DISTANCE then error("too far") end
		if not canCarrierRequest(carrier) then error("busy") end
		if not targetAvailable(target) then error("busy") end
		local extra = countCarried(target)
		if (countCarried(carrier) + 1 + extra) > MAX_CARRY then error("limit_transfer") end
		local used, sm = {}, getSlotMap(carrier)
		for _, idx in pairs(sm) do used[idx] = true end
		local slotIdx
		for i = 1, MAX_CARRY do if not used[i] then slotIdx = i; break end end
		if not slotIdx then error("limit") end
		tHRP.CFrame = cHRP.CFrame * slotOffset(slotIdx)
		ensureCarryWeld(cHRP, tHRP)
		saveHumState(target.UserId, tHum)
		tHum.AutoRotate = false; tHum.WalkSpeed = 0
		if tHum.UseJumpPower then tHum.JumpPower = 0 else tHum.JumpHeight = 0 end
		tHum.Sit = true
		tHum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		tHum.Jump = false
		makeCarriedLight(tChar, target.UserId)
		setGroupRecursive(tChar, GROUP_CARRIED)
		giveCarrierOwnership(target, carrier)
		getCarryMap(carrier)[target.UserId] = target
		getSlotMap(carrier)[target.UserId]  = slotIdx
		carriedByTarget[target.UserId]      = carrier

		-- FIX memory leak: simpan connections agar bisa di-cleanup
		local pairKey = tostring(carrier.UserId).."_"..tostring(target.UserId)
		pairCleanupConns[pairKey] = {}
		local function bindCleanup(char, p, connList)
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				table.insert(connList, hum.Died:Connect(function()
					safeDetachIfAny(p, "death")
				end))
			end
			table.insert(connList, char.AncestryChanged:Connect(function(_, parent)
				if not parent then safeDetachIfAny(p, "character removed") end
			end))
		end
		bindCleanup(cChar, carrier, pairCleanupConns[pairKey])
		bindCleanup(tChar, target,  pairCleanupConns[pairKey])

		sendStart(carrier, target)
	end)
	releaseLock(carrier.UserId)
	if not ok then return false, tostring(err) end
	if countCarried(target) > 0 then transferPassengersToAtomic(carrier, target) end
	sendCarrierList(carrier)
	return true
end

CarryRemote.OnServerEvent:Connect(function(player, action, data)
	if action == "Request" then
		local targetId = data and data.targetId
		if type(targetId) ~= "number" then return end
		local target = Players:GetPlayerByUserId(targetId)
		if not target or target == player then return end
		local _, cHRP = getCharHRP(player); local _, tHRP = getCharHRP(target)
		if not (cHRP and tHRP) then return end
		if (cHRP.Position - tHRP.Position).Magnitude > MAX_DISTANCE then
			CarryRemote:FireClient(player, "TooFar", {targetId = targetId}); return
		end
		local extra = countCarried(target)
		if (countCarried(player) + 1 + extra) > MAX_CARRY then
			CarryRemote:FireClient(player, "Limit", {max = MAX_CARRY, reason = "transfer"}); return
		end
		if not canCarrierRequest(player) or not targetAvailable(target) then
			CarryRemote:FireClient(player, "Busy", {}); return
		end
		if hasPendingIncoming(player) or hasPendingOutgoing(player) or pending[target.UserId] then
			CarryRemote:FireClient(player, "Busy", {}); return
		end
		pending[target.UserId] = {requester = player, time = os.clock()}
		CarryRemote:FireClient(target, "Prompt", {fromId = player.UserId, fromName = player.DisplayName})
	elseif action == "Response" then
		local accept      = data and data.accept == true
		local requesterId = data and data.requesterId
		if type(requesterId) ~= "number" then return end
		local requester = Players:GetPlayerByUserId(requesterId); if not requester then return end
		local pend = pending[player.UserId]
		if not pend or pend.requester ~= requester then return end
		pending[player.UserId] = nil
		if not accept then
			CarryRemote:FireClient(requester, "Declined", {targetId = player.UserId})
			CarryRemote:FireClient(player, "PromptClose", {}); return
		end
		local ok2, err2 = startCarry(requester, player)
		if not ok2 then
			if tostring(err2) == "limit_transfer" then
				CarryRemote:FireClient(requester, "Limit",  {max = MAX_CARRY, reason = "transfer"})
				CarryRemote:FireClient(player,    "Failed", {reason = "limit_transfer"})
			else
				CarryRemote:FireClient(requester, "Failed", {reason = err2})
				CarryRemote:FireClient(player,    "Failed", {reason = err2})
			end
		end
	elseif action == "Stop" then
		local targetId = data and data.targetId
		if type(targetId) == "number" then
			local t = Players:GetPlayerByUserId(targetId)
			if t and carryingByCarrier[player.UserId]
				and carryingByCarrier[player.UserId][targetId] then
				detachPair(player, t, "stop"); return
			end
		end
		detachIfAny(player, "stop")
	end
end)

-- FIX: syncAnimations — simpan koneksi agar bisa cleanup
local syncConns = {}  -- [userId] = {conn1, conn2, ...}

local function stopSyncing(p)
	syncingPlayers[p.UserId]   = nil
	syncedAnimations[p.UserId] = nil
	-- FIX: disconnect semua koneksi sync
	if syncConns[p.UserId] then
		for _, c in ipairs(syncConns[p.UserId]) do
			if c and c.Connected then c:Disconnect() end
		end
		syncConns[p.UserId] = nil
	end
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		local animator = hum:FindFirstChildOfClass("Animator")
		if animator then
			for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
				if not track.Animation then continue end
				local name = track.Animation.Name:lower()
				if not table.find(IGNORED_EMOTES, name)
					and track.Priority ~= Enum.AnimationPriority.Core then
					pcall(function() track:Stop(); track:Destroy() end)
				end
			end
		end
	end
end

local function syncAnimations(p, targetPlayer)
	if not (p.Character and targetPlayer.Character) then return end
	local hum1  = p.Character:FindFirstChildOfClass("Humanoid")
	local hum2  = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
	if not (hum1 and hum2) then return end
	local anim1 = hum1:FindFirstChildOfClass("Animator")
	local anim2 = hum2:FindFirstChildOfClass("Animator")
	if not (anim1 and anim2) then return end
	if syncingPlayers[p.UserId] then stopSyncing(p) end
	syncingPlayers[p.UserId]   = true
	syncedAnimations[p.UserId] = {}
	syncConns[p.UserId] = {}

	task.spawn(function()
		while syncingPlayers[p.UserId] do
			if not (p.Character and targetPlayer.Character) then
				stopSyncing(p); break
			end
			local newList = {}
			for _, t in ipairs(anim2:GetPlayingAnimationTracks()) do
				if not t.Animation then continue end
				local name = t.Animation.Name:lower()
				if not table.find(IGNORED_EMOTES, name)
					and t.Priority ~= Enum.AnimationPriority.Core then
					local playing = syncedAnimations[p.UserId][t.Animation.AnimationId]
					if playing then
						pcall(function()
							playing.TimePosition = t.TimePosition
							playing:AdjustSpeed(t.Speed)
						end)
						newList[t.Animation.AnimationId] = playing
					else
						local nt
						pcall(function()
							nt = anim1:LoadAnimation(t.Animation)
							nt.Priority = Enum.AnimationPriority.Action
							nt:Play()
							nt.TimePosition = t.TimePosition
							nt:AdjustSpeed(t.Speed)
						end)
						if nt then newList[t.Animation.AnimationId] = nt end
					end
				end
			end
			for id, tr in pairs(syncedAnimations[p.UserId]) do
				if not newList[id] then pcall(function() tr:Stop() end) end
			end
			syncedAnimations[p.UserId] = newList
			task.wait(0.05)
		end
	end)

	-- FIX: simpan koneksi biar bisa cleanup
	table.insert(syncConns[p.UserId], hum2.Died:Connect(function() stopSyncing(p) end))
	table.insert(syncConns[p.UserId], targetPlayer.CharacterRemoving:Connect(function() stopSyncing(p) end))
	table.insert(syncConns[p.UserId], p.CharacterRemoving:Connect(function() stopSyncing(p) end))
end

SyncEvent.OnServerEvent:Connect(function(p, targetPlayer)
	if targetPlayer and targetPlayer:IsA("Player") then
		syncAnimations(p, targetPlayer)
	end
end)
UnSyncEvent.OnServerEvent:Connect(function(p) stopSyncing(p) end)

-- [PATCH A3] guard AvatarChanger dihapus (sistem sudah tidak ada)
local function isAvatarChangingCarry(_) return false end

local function onCharacterAdded(p, char)
	-- FIX: skip saat ganti avatar
	if p:GetAttribute("IsChangingAvatar") == true then return end
	if isAvatarChangingCarry(p.UserId) then return end
	task.defer(function()
		if isAvatarChangingCarry(p.UserId) then return end
		clearCarryWeldsForChar(char)
		setGroupRecursive(char, GROUP_PLAYERS)
		char.DescendantAdded:Connect(function(d)
			if d:IsA("BasePart") then
				task.defer(function()
					if not carriedByTarget[p.UserId] then
						pcall(function() d.CollisionGroup = GROUP_PLAYERS end)
					end
				end)
			end
		end)
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Sit = false; hum.AutoRotate = true
			hum.WalkSpeed = 16; hum.PlatformStand = false; hum.Jump = false
			if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
			hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		end
		savedProps[p.UserId] = nil
		savedHum[p.UserId]   = nil
		stopSyncing(p)
		safeDetachIfAny(p, "respawn")
		giveSelfOwnership(p)
	end)
end

Players.PlayerAdded:Connect(function(p)
	if p.Character then onCharacterAdded(p, p.Character) end
	p.CharacterAdded:Connect(function(char) onCharacterAdded(p, char) end)
end)
for _, p in ipairs(Players:GetPlayers()) do
	if p.Character then onCharacterAdded(p, p.Character) end
	p.CharacterAdded:Connect(function(char) onCharacterAdded(p, char) end)
end

Players.PlayerRemoving:Connect(function(p)
	pending[p.UserId] = nil
	stopSyncing(p)
	-- FIX: cleanup semua pairCleanupConns untuk player ini
	local uidStr = tostring(p.UserId)
	for key in pairs(pairCleanupConns) do
		if key:find(uidStr) then
			for _, c in ipairs(pairCleanupConns[key] or {}) do
				if c and c.Connected then c:Disconnect() end
			end
			pairCleanupConns[key] = nil
		end
	end
	detachIfAny(p, "left")
end)

-- FIX: expose carriedByTarget agar AvatarChangerNewServer bisa cek carrier
task.defer(function()
	local bf2 = game:GetService("ServerStorage"):WaitForChild("GetCarrierOf", 10)
	if not bf2 then return end
	bf2.OnInvoke = function(targetUserId)
		local carrier = carriedByTarget[targetUserId]
		return carrier
	end
end)