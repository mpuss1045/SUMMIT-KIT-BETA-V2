-- ============================================
-- ZayinCheckpointService (FIXED + AUTO-DETECT CP)
-- ============================================
local Players = game:GetService("Players")
local DS      = game:GetService("DataStoreService")
local RS      = game:GetService("ReplicatedStorage")

local ZR        = RS:WaitForChild("ZayinRemotes")
local CPRemotes = ZR:WaitForChild("Checkpoint")
local ReachedRE = CPRemotes:WaitForChild("Reached")
local ResetBCRE = CPRemotes:WaitForChild("ResetToBC")

local ZC         = RS:WaitForChild("ZayinConfig")
local GameConfig = require(ZC:WaitForChild("GameConfig"))

assert(GameConfig.DataVersion,      "[CP] GameConfig.DataVersion nil!")
assert(GameConfig.PlaytimeInterval, "[CP] GameConfig.PlaytimeInterval nil!")
assert(GameConfig.PlaytimeReward,   "[CP] GameConfig.PlaytimeReward nil!")

local cpDS              = DS:GetDataStore("ZayinCP_" .. GameConfig.DataVersion)
local playerData        = {}
local playerConnections = {}

-- ── Auto-detect checkpoints dari Workspace ─────────────────
local function buildCheckpoints()
	local zw = workspace:WaitForChild("ZayinWorkspace", 10)
	local cpFolder = zw and zw:FindFirstChild("Checkpoint")
	if not cpFolder then
		warn("[CP] Folder Checkpoint tidak ditemukan!")
		return {"Basecamp", "SummitEasy", "SummitHard"}
	end
	local cps = {"Basecamp"}
	local cpNums = {}
	for _, part in pairs(cpFolder:GetChildren()) do
		if part.Name:match("^CP%d+$") then
			table.insert(cpNums, tonumber(part.Name:match("%d+")))
		end
	end
	table.sort(cpNums)
	for _, num in ipairs(cpNums) do
		table.insert(cps, "CP" .. num)
	end
	table.insert(cps, "SummitEasy")
	table.insert(cps, "SummitHard")

	return cps
end

task.spawn(function()
	task.wait(1)
	GameConfig.Checkpoints = buildCheckpoints()
end)

-- ── Load data ──────────────────────────────────────────────
local function loadData(player)
	local ok, data = pcall(function()
		return cpDS:GetAsync("cp_" .. player.UserId)
	end)
	if not ok then warn("[CP] Gagal load " .. player.Name .. ": " .. tostring(data)) end
	playerData[player.UserId] = (ok and type(data) == "table" and data) or {
		checkpoint = "Basecamp",
		summit     = 0,
		playtime   = 0,
		bestTime   = "-",
	}
	return playerData[player.UserId]
end

-- ── Save data ──────────────────────────────────────────────
local function saveData(player)
	local data = playerData[player.UserId]
	if not data then return end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local summit = ls:FindFirstChild("Summit")
		if summit then data.summit = summit.Value end
		local bestTime = ls:FindFirstChild("BestTime")
		if bestTime then data.bestTime = bestTime.Value end
	end
	local ok, err = pcall(function()
		cpDS:SetAsync("cp_" .. player.UserId, data)
	end)
	if not ok then
		warn("[CP] Gagal save " .. player.Name .. ": " .. tostring(err))
	else

	end
end

-- ── Setup leaderstats ──────────────────────────────────────
local function setupLeaderstats(player)
	-- [P10] leaderstats diisi setelah load: loadData() memanggil DataStore
	-- (bisa 1-3 detik), jadi nilai harus di-set ulang setelah datanya tiba.
	local ls = Instance.new("Folder")
	ls.Name   = "leaderstats"
	ls.Parent = player
	local data = loadData(player)

	local summit = Instance.new("IntValue", ls)
	summit.Name  = "Summit"
	summit.Value = data.summit or 0

	local posisi = Instance.new("StringValue", ls)
	posisi.Name  = "Posisi"
	posisi.Value = data.checkpoint or "Basecamp"

	local bestTime = Instance.new("StringValue", ls)
	bestTime.Name  = "BestTime"
	bestTime.Value = data.bestTime or "-"

	-- [P10] penjaga: isi ulang sampai data benar-benar tersedia
	task.spawn(function()
		for _ = 1, 40 do
			task.wait(0.25)
			local d = playerData[player.UserId]
			if d then
				if summit and (d.summit or 0) > 0 then summit.Value = d.summit end
				if posisi and d.checkpoint then posisi.Value = d.checkpoint end
				if bestTime and d.bestTime and d.bestTime ~= "-" then bestTime.Value = d.bestTime end
				if (d.summit or 0) > 0 then return end
			end
		end
	end)
end

-- [P9] isi ulang leaderstats setelah data DataStore benar-benar tiba
local function refreshLeaderstats(player)
	task.spawn(function()
		for _ = 1, 30 do
			local data = playerData[player.UserId]
			local ls   = player:FindFirstChild("leaderstats")
			if data and ls then
				local sv = ls:FindFirstChild("Summit")
				local pv = ls:FindFirstChild("Posisi")
				local bv = ls:FindFirstChild("BestTime")
				if sv then sv.Value = data.summit or 0 end
				if pv then pv.Value = data.checkpoint or "Basecamp" end
				if bv and (bv.Value == "" or bv.Value == nil) then bv.Value = data.bestTime or "-" end
				return
			end
			task.wait(0.2)
		end
	end)
end

-- ── Update Posisi di leaderstats ───────────────────────────
local function updateCheckpointLeaderstat(player, cpName)
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local posisi = ls:FindFirstChild("Posisi")
		if posisi then
			posisi.Value = cpName

		end
	end
end

-- ── Update ZayinSpawnLocation ke posisi CP ────────────────
local function updateSpawnLocation(cpName)
	local zw = workspace:FindFirstChild("ZayinWorkspace")
	local cpFolder = zw and zw:FindFirstChild("Checkpoint")
	local cpPart = cpFolder and cpFolder:FindFirstChild(cpName)
	local spawnLoc = workspace:FindFirstChild("ZayinSpawnLocation")
	if spawnLoc and cpPart then
		local topY = cpPart.Size.Y / 2 + 3
		spawnLoc.Position = cpPart.Position + Vector3.new(0, topY, 0)

	end
end

-- ── Spawn di checkpoint ────────────────────────────────────
local function spawnAtCheckpoint(player, cpName)
	local char = player.Character
	if not char then return end
	local hrp = char:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end
	local zw = workspace:FindFirstChild("ZayinWorkspace")
	if not zw then return end
	local cpFolder = zw:FindFirstChild("Checkpoint")
	if not cpFolder then return end
	local cpModel = cpFolder:FindFirstChild(cpName)
		or cpFolder:FindFirstChild("Basecamp")
	if not cpModel then
		warn("[CP] Checkpoint tidak ditemukan: " .. tostring(cpName))
		return
	end
	local spawnPart
	if cpModel:IsA("BasePart") then
		spawnPart = cpModel
	else
		spawnPart = cpModel:FindFirstChildWhichIsA("BasePart")
	end
	if not spawnPart then
		warn("[CP] Tidak ada BasePart: " .. tostring(cpName))
		return
	end
	local topY = spawnPart.Size.Y / 2 + 3
	hrp.CFrame = spawnPart.CFrame + Vector3.new(0, topY, 0)

end

-- ── Clear connections ──────────────────────────────────────
local function clearConnections(userId)
	local conns = playerConnections[userId]
	if not conns then return end
	for _, c in pairs(conns) do
		if c and c.Connected then c:Disconnect() end
	end
	playerConnections[userId] = {}
end

-- ── Fix CanTouch ──────────────────────────────────────────
local function setupCanTouch()
	local zw = workspace:WaitForChild("ZayinWorkspace", 10)
	if not zw then return end
	local folders = {"Checkpoint", "Teleport", "KembaliKeBasecamp", "SpeedRun", "SavePoint"}
	for _, folderName in pairs(folders) do
		local folder = zw:FindFirstChild(folderName)
		if folder then
			for _, part in pairs(folder:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanTouch = true
				end
			end
		end
	end

end

-- ── Player join ────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	playerConnections[player.UserId] = {}
	setupLeaderstats(player)
	refreshLeaderstats(player) -- [P9]

	-- Update SpawnLocation ke CP terakhir sebelum karakter spawn
	task.spawn(function()
		task.wait(0.1)
		local data = playerData[player.UserId]
		local cpName = data and data.checkpoint or "Basecamp"
		updateSpawnLocation(cpName)
	end)

	player.CharacterAdded:Connect(function(char)
		clearConnections(player.UserId)
		char:WaitForChild("HumanoidRootPart", 5)
		local attempts = 0
		while not playerData[player.UserId] and attempts < 10 do
			task.wait(0.1)
			attempts += 1
		end
		local data = playerData[player.UserId]
		local cpName = data and data.checkpoint or "Basecamp"

		updateSpawnLocation(cpName)
		spawnAtCheckpoint(player, cpName)
	end)

	-- Jika karakter sudah ada saat PlayerAdded terpicu
	if player.Character then
		task.spawn(function()
			local attempts = 0
			while not playerData[player.UserId] and attempts < 20 do
				task.wait(0.1)
				attempts += 1
			end
			local data = playerData[player.UserId]
			local cpName = data and data.checkpoint or "Basecamp"

			updateSpawnLocation(cpName)
			spawnAtCheckpoint(player, cpName)
		end)
	end
end)

-- Handle player yang sudah ada saat script jalan
for _, player in pairs(Players:GetPlayers()) do
	playerConnections[player.UserId] = playerConnections[player.UserId] or {}
	if not player:FindFirstChild("leaderstats") then
		setupLeaderstats(player)
	end
	-- Update SpawnLocation
	task.spawn(function()
		-- Tunggu playerData tersedia
		local attempts = 0
		while not playerData[player.UserId] and attempts < 20 do
			task.wait(0.1)
			attempts += 1
		end
		local data = playerData[player.UserId]
		local cpName = data and data.checkpoint or "Basecamp"

		updateSpawnLocation(cpName)
		if player.Character then
			spawnAtCheckpoint(player, cpName)
		else
			player.CharacterAdded:Wait()
			spawnAtCheckpoint(player, cpName)
		end
	end)
end

-- ── Player leave ───────────────────────────────────────────
Players.PlayerRemoving:Connect(function(player)
	clearConnections(player.UserId)
	saveData(player)
	playerData[player.UserId]        = nil
	playerConnections[player.UserId] = nil
end)

-- [PATCH B3] validasi jarak: client tidak bisa klaim CP dari jauh
local CP_RADIUS = 40

local function isNearCP(player, cpName)
	-- [P18] batas kotak CP: part checkpoint bisa besar/tipis
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local zw = workspace:FindFirstChild("ZayinWorkspace")
	local cpFolder = zw and zw:FindFirstChild("Checkpoint")
	local cpObj = cpFolder and cpFolder:FindFirstChild(cpName)
	if not cpObj then return true end
	local part = cpObj:IsA("BasePart") and cpObj or cpObj:FindFirstChildWhichIsA("BasePart")
	if not part then return true end
	local rel = part.CFrame:PointToObjectSpace(hrp.Position)
	local h, m = part.Size / 2, 20
	return math.abs(rel.X) <= h.X + m
		and math.abs(rel.Y) <= h.Y + m
		and math.abs(rel.Z) <= h.Z + m
end

-- [P16] notifCP berjenis + anti-spam (Touched bisa memicu berkali-kali)
local _notifCD = {}
local function notifCP(player, pesan, jenis)
	local kunci = tostring(player.UserId) .. "|" .. tostring(pesan)
	local now = os.clock()
	if _notifCD[kunci] and now - _notifCD[kunci] < 2 then return end
	_notifCD[kunci] = now

	local notifFolder = RS.ZayinRemotes:FindFirstChild("Notif")
	local showRE = notifFolder and notifFolder:FindFirstChild("Show")
	if showRE then
		showRE:FireClient(player, { type = jenis or "warning", message = pesan })
	end
end

-- ── Checkpoint Reached ─────────────────────────────────────
ReachedRE.OnServerEvent:Connect(function(player, cpName)
	if type(cpName) ~= "string" then return end

	if cpName == "__teleport__" then
		local data = playerData[player.UserId]
		if data then
			task.spawn(spawnAtCheckpoint, player, data.checkpoint)
		end
		local teleportRE = RS.ZayinRemotes:FindFirstChild("TeleportOccurred")
		if teleportRE then teleportRE:FireClient(player) end
		return
	end

	local data = playerData[player.UserId]
	if not data then return end

	local checkpoints = GameConfig.Checkpoints
	if not checkpoints then
		task.wait(2)
		checkpoints = GameConfig.Checkpoints
	end
	if not checkpoints then return end

	local currentIdx, newIdx = 0, 0
	for i, cp in ipairs(checkpoints) do
		if cp == data.checkpoint then currentIdx = i end
		if cp == cpName          then newIdx = i end
	end

	if newIdx == 0 then return end

	-- Cek skip checkpoint dari GameConfig
	local roleId  = player:GetAttribute("RoleId")
	local canSkip = roleId and GameConfig.SkipCheckpoint and GameConfig.SkipCheckpoint[roleId] == true

	-- [P16] satu jalur notif: semua pesan lewat Notif.Show saja (tidak dobel)
	-- [P19] mundur boleh: hanya lompat MAJU yang dilarang
	if newIdx <= currentIdx then
		-- pemain kembali ke CP lama / menyentuh CP yang sama: sah, tidak perlu notif
		if newIdx < currentIdx and not (data.checkpoint or ""):find("Summit") then
			return
		end
		-- setelah summit, turun ke CP mana pun = mulai pendakian baru
		if not isNearCP(player, cpName) then return end
		if data.checkpoint ~= cpName then
			data.checkpoint = cpName
			updateCheckpointLeaderstat(player, cpName)
			updateSpawnLocation(cpName)
			saveData(player)
			notifCP(player, "CHECKPOINT " .. (cpName:match("%d+") or cpName), "success")
		end
		return
	end

	if newIdx == currentIdx + 1 or (canSkip and newIdx > currentIdx) then
		if not isNearCP(player, cpName) then return end
		if data.checkpoint ~= cpName then
			data.checkpoint = cpName
			updateCheckpointLeaderstat(player, cpName)
			updateSpawnLocation(cpName)
			saveData(player)
			notifCP(player, "CHECKPOINT " .. (cpName:match("%d+") or cpName), "success")
		end
	else
		local perlu = checkpoints[currentIdx + 1]
		notifCP(player, "TIDAK SAH|" .. (perlu and ("Lewati " .. perlu .. " dulu") or "Harus berurutan"), "warning")
	end
end)

-- ── Reset ke Basecamp ──────────────────────────────────────
ResetBCRE.OnServerEvent:Connect(function(player)
	local data = playerData[player.UserId]
	if data then
		data.checkpoint = "Basecamp"
		saveData(player)
	end
	updateCheckpointLeaderstat(player, "Basecamp")
	updateSpawnLocation("Basecamp")
	local SS = game:GetService("ServerScriptService")
	local resetSummitTracker = SS:FindFirstChild("ResetSummitTracker", true)
	if resetSummitTracker then resetSummitTracker:Fire(player) end
	local char = player.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local zw = workspace:FindFirstChild("ZayinWorkspace")
		local cpFolder = zw and zw:FindFirstChild("Checkpoint")
		local basecamp = cpFolder and cpFolder:FindFirstChild("Basecamp")
		if hrp and basecamp then
			local topY = basecamp.Size.Y / 2 + 3
			hrp.CFrame = basecamp.CFrame + Vector3.new(0, topY, 0)

		end
	end
end)

-- ── Auto save setiap 5 menit ───────────────────────────────
task.spawn(function()
	while true do
		task.wait(300)
		for _, p in ipairs(Players:GetPlayers()) do
			saveData(p)
		end

	end
end)

-- ── Playtime tracker (real-time) ───────────────────────────
local playerJoinTime = {}

Players.PlayerAdded:Connect(function(player)
	playerJoinTime[player.UserId] = tick()
	player:SetAttribute("SessionStart", tick())
end)

task.spawn(function()
	while true do
		task.wait(30) -- update setiap 30 detik
		local ptODS = game:GetService("DataStoreService"):GetOrderedDataStore("ZayinGlobalPlaytime_v1")
		for _, player in ipairs(Players:GetPlayers()) do
			local data = playerData[player.UserId]
			if data and playerJoinTime[player.UserId] then
				local sessionTime = tick() - playerJoinTime[player.UserId]
				local totalPlaytime = (data.playtime or 0) + sessionTime
				-- Save ke ODS (integer)
				pcall(function()
					ptODS:SetAsync(tostring(player.UserId), math.floor(totalPlaytime))
				end)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local data = playerData[player.UserId]
	if data and playerJoinTime[player.UserId] then
		local sessionTime = tick() - playerJoinTime[player.UserId]
		data.playtime = (data.playtime or 0) + sessionTime
		playerJoinTime[player.UserId] = nil
	end
end)

-- ── Setup CanTouch ─────────────────────────────────────────
task.spawn(setupCanTouch)

-- ── GetCheckpoint untuk client ─────────────────────────────
local GetCheckpointRF = CPRemotes:FindFirstChild("GetCheckpoint")
if not GetCheckpointRF then
	GetCheckpointRF = Instance.new("RemoteFunction")
	GetCheckpointRF.Name   = "GetCheckpoint"
	GetCheckpointRF.Parent = CPRemotes
end
GetCheckpointRF.OnServerInvoke = function(player)
	local data = playerData[player.UserId]
	return data and data.checkpoint or "Basecamp"
end


-- ── GetCPData untuk SummitService ─────────────────────────
local getCPData = Instance.new("BindableFunction")
getCPData.Name     = "GetCPData"
getCPData.Parent   = game:GetService("ServerScriptService")
getCPData.OnInvoke = function(player)
	local data = playerData[player.UserId]
	return data and data.checkpoint or "Basecamp"
end

-- ── SetSummitCP dari SummitService ────────────────────────
local setSummitCP = Instance.new("BindableEvent")
setSummitCP.Name   = "SetSummitCP"
setSummitCP.Parent = game:GetService("ServerScriptService")
setSummitCP.Event:Connect(function(player, cpName)
	local data = playerData[player.UserId]
	if not data then return end
	data.checkpoint = cpName
	updateCheckpointLeaderstat(player, cpName)
	updateSpawnLocation(cpName)
	saveData(player)

end)

-- ── UpdateSummitData dari SummitService ───────────────────
local updateSummit = Instance.new("BindableEvent")
updateSummit.Name   = "UpdateSummitData"
updateSummit.Parent = game:GetService("ServerScriptService")
updateSummit.Event:Connect(function(player)
	saveData(player)
end)