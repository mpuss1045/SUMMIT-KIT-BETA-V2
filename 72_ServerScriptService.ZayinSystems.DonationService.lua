-- ============================================
-- ZayinDonationService (FIXED + OPTIMIZED)
-- Fix:
--   • config nil di loadStatue() → pakai STATUE_CONFIG lokal
--   • Hapus dummy testing data (backdoor potensial)
--   • Hapus memory leak: thumbnailCache & nameCache dibersihkan saat PlayerRemoving
--   • Guard statueVersion agar task.spawn lama tidak override model baru
--   • pcall tambahan di seluruh network call
--   • Donation tidak ditampilkan di leaderstats (parent ke player langsung)
-- ============================================
local DataStoreService   = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")

local ZC     = ReplicatedStorage:WaitForChild("ZayinConfig", 10)
local SDC = require(ZC:WaitForChild("ShopDonationConfig", 10))
local Config = SDC.Donation
local ok_gc, GameConfig = pcall(require, game:GetService("ReplicatedStorage"):WaitForChild("ZayinConfig", 10):WaitForChild("GameConfig", 10))
if not ok_gc then GameConfig = nil end

local suffix        = RunService:IsStudio() and "_Studio" or ""
local DonationStore = DataStoreService:GetOrderedDataStore(Config.DataStoreName .. suffix)
local NamesStore    = DataStoreService:GetDataStore(Config.NamesStoreName .. suffix)

-- ── Remote setup ────────────────────────────────────────
local DonationFolder = ReplicatedStorage:FindFirstChild("DonationSystem")
if not DonationFolder then
	DonationFolder        = Instance.new("Folder")
	DonationFolder.Name   = "DonationSystem"
	DonationFolder.Parent = ReplicatedStorage
end

local function getOrMakeRE(name)
	local r = DonationFolder:FindFirstChild(name)
	if not r then
		r        = Instance.new("RemoteEvent")
		r.Name   = name
		r.Parent = DonationFolder
	end
	return r
end

-- [P52] gift: remote & state
local GiftIntentRE = getOrMakeRE("GiftIntent")
local GiftNotifRE  = getOrMakeRE("GiftNotif")
local pendingGift  = {} -- [userId pembeli] = {targetId, kunci}

local PromptEvent   = getOrMakeRE("DonationPrompt")
local NotifyEvent   = getOrMakeRE("DonationNotify")

-- [OPSI A] satu donasi = satu notif (pesan digabung ke kartu donasi)
local donasiSeq = 0
local function kirimNotifDonasi(info, pesan)
	NotifyEvent:FireAllClients({
		donor   = info.donor,
		userId  = info.userId,
		amount  = info.amount,
		total   = info.total,
		message = pesan,
		type    = "donation",
	})
end
local MsgEvent      = getOrMakeRE("DonationMessage")
local OpenUIEvent   = getOrMakeRE("DonationOpenUI")
local UpdateUIEvent = getOrMakeRE("DonationUpdateUI")

-- ── Workspace refs ───────────────────────────────────────
local zw           = workspace:WaitForChild("ZayinWorkspace", 15)
local donFolder    = zw:WaitForChild("Donation", 10)
local patungFolder = donFolder:WaitForChild("PatungTopDonation", 10)
local lbModel      = donFolder:WaitForChild("TopDonationLeaderboard", 10)

local topStatues = {
	patungFolder:WaitForChild("TopDonate1", 10),
	patungFolder:WaitForChild("TopDonate2", 10),
	patungFolder:WaitForChild("TopDonate3", 10),
}

local STATUE_CONFIG = {
	SCALE    = 1.0,
	ANGLE    = 270,
	Y_OFFSET = 1,
}

-- ── Cache & state ─────────────────────────────────────────
local cachedTopList   = {}
local nameCache       = {}
local thumbnailCache  = {}
local managedStatues  = {}
local statueVersion   = 0
local pendingMessages = {}
local pendingDonasi   = {} -- [P48] donasi menunggu pesan
local msgCooldownTime = {}

-- ── Warna UI ─────────────────────────────────────────────
local C = {
	bg        = Color3.fromRGB(6,   10,  20),
	bg3       = Color3.fromRGB(15,  22,  42),
	cyan      = Color3.fromRGB(0,  210, 255),
	gold      = Color3.fromRGB(255, 215,   0),
	silver    = Color3.fromRGB(200, 215, 230),
	bronze    = Color3.fromRGB(205, 127,  50),
	white     = Color3.new(1, 1, 1),
	rowbg     = Color3.fromRGB(8,   13,  26),
	black     = Color3.new(0, 0, 0),
	donGold   = Color3.fromRGB(255, 200,  40),
	donAccent = Color3.fromRGB(255, 165,   0),
}
local MEDAL  = {C.gold, C.silver, C.bronze}
local MEDALS = {"🥇", "🥈", "🥉"}

-- ── Helper UI ────────────────────────────────────────────
local function make(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props) do obj[k] = v end
	if parent then obj.Parent = parent end
	return obj
end
local function addCorner(r, p)    make("UICorner",  {CornerRadius = UDim.new(0, r)}, p) end
local function addStroke(c, t, p) make("UIStroke",  {Color = c, Thickness = t}, p) end
local function addTextStroke(p)   make("UIStroke",  {Color = Color3.new(0,0,0), Thickness = 1.5, Transparency = 0.2}, p) end
local function addGradient(colors, rotation, parent)
	local kps = {}
	for i, col in ipairs(colors) do kps[i] = ColorSequenceKeypoint.new((i-1)/(#colors-1), col) end
	make("UIGradient", {Color = ColorSequence.new(kps), Rotation = rotation or 0}, parent)
end

-- ── Thumbnail (dengan cache) ──────────────────────────────
local function getThumbnail(userId)
	if not userId then return "" end
	if thumbnailCache[userId] then return thumbnailCache[userId] end
	local ok, url = pcall(function()
		return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)
	local result = (ok and url) or ""
	if result ~= "" then thumbnailCache[userId] = result end
	return result
end

-- ── Fetch top list dari DataStore ────────────────────────
local function fetchTopList()
	local topList = {}
	local ok, pages = pcall(function()
		return DonationStore:GetSortedAsync(false, Config.LeaderboardSize)
	end)
	if not ok then return cachedTopList end
	for _, entry in ipairs(pages:GetCurrentPage()) do
		local uid = entry.key
		local dn  = nameCache[uid]
		if not dn then
			pcall(function() dn = NamesStore:GetAsync(uid) end)
			nameCache[uid] = dn or ("Player_" .. uid)
			dn = nameCache[uid]
		end
		local un = dn
		pcall(function() un = Players:GetNameFromUserIdAsync(tonumber(uid)) end)
		table.insert(topList, {userId = uid, displayName = dn, username = un, amount = entry.value})
	end
	if #topList > 0 then cachedTopList = topList end
	return cachedTopList
end

-- ── Update leaderboard SurfaceGui ────────────────────────
local function updateLeaderboard(topList)
	local sg = lbModel:FindFirstChildWhichIsA("SurfaceGui", true)
	if not sg then return end
	local items = sg:FindFirstChild("Items", true)
	if not items then return end

	local listSF = sg:FindFirstChild("List", true)
	if listSF then
		listSF.AnchorPoint = Vector2.new(0, 0)
		listSF.Position    = UDim2.new(0, 0, 0, 65)
		listSF.Size        = UDim2.new(1, 0, 1, -65)
	end
	local listContent = sg:FindFirstChild("ListContent", true)
	if listContent then
		listContent.AnchorPoint = Vector2.new(0, 0)
		listContent.Position    = UDim2.new(0, 0, 0, 0)
		listContent.Size        = UDim2.new(1, 0, 1, 0)
	end
	items.Size = UDim2.new(1, 0, 1, 0)

	for _, child in pairs(items:GetChildren()) do
		if child.Name:match("^E%d+$") then child:Destroy() end
	end

	local nothing = items:FindFirstChild("Nothing")
	if nothing then nothing.Visible = #topList == 0 end

	local ul = items:FindFirstChildOfClass("UIListLayout")
	if not ul then
		ul = make("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 3)
		}, items)
	end

	for rank, entry in ipairs(topList) do
		local strokeColor = MEDAL[rank] or C.cyan
		local ROW_H = rank <= 3 and 54 or 46
		local thumb = getThumbnail(tonumber(entry.userId))

		local row = make("Frame", {
			Name = "E"..rank, LayoutOrder = rank,
			Size = UDim2.new(1, -30, 0, ROW_H),
			Position = UDim2.new(0, 15, 0, 0),
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0
		}, items)
		addCorner(8, row)
		addStroke(strokeColor, rank <= 3 and 1.5 or 1, row)

		local rankBox = make("Frame", {
			Size = UDim2.fromOffset(36, 36),
			Position = UDim2.new(0, 3, 0.5, -18),
			BackgroundColor3 = Color3.fromRGB(12,20,38),
			BorderSizePixel = 0, ZIndex = 2
		}, row)
		addCorner(8, rankBox)
		addStroke(strokeColor, 1.5, rankBox)
		local noLbl = make("TextLabel", {
			Size = UDim2.new(1,0,1,0),
			BackgroundTransparency = 1,
			Text = MEDALS[rank] or "#"..rank,
			TextColor3 = strokeColor,
			Font = Enum.Font.GothamBold,
			TextSize = rank <= 3 and 20 or 16,
			ZIndex = 3
		}, rankBox)
		addTextStroke(noLbl)

		local av = make("ImageLabel", {
			Size = UDim2.fromOffset(36, 36),
			Position = UDim2.new(0, 48, 0.5, -18),
			BackgroundColor3 = C.bg3,
			BorderSizePixel = 0,
			Image = thumb, ZIndex = 2
		}, row)
		addCorner(100, av)
		addStroke(strokeColor, 1.5, av)

		local ng = make("Frame", {
			Size = UDim2.new(1, -150, 1, -6),
			Position = UDim2.new(0, 90, 0, 3),
			BackgroundTransparency = 1, ZIndex = 2
		}, row)
		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 1)
		}, ng)
		local dn = make("TextLabel", {
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			Text = entry.displayName,
			TextColor3 = C.white,
			Font = Enum.Font.GothamBold, TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3
		}, ng)
		addTextStroke(dn)
		local un = make("TextLabel", {
			Size = UDim2.new(1, 0, 0, 11),
			BackgroundTransparency = 1,
			Text = "@"..entry.username,
			TextColor3 = C.silver,
			Font = Enum.Font.Gotham, TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3
		}, ng)
		addTextStroke(un)

		local vBox = make("Frame", {
			Size = UDim2.fromOffset(72, 40),
			Position = UDim2.new(1, -4, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = C.bg3,
			BorderSizePixel = 0, ZIndex = 2
		}, row)
		addCorner(8, vBox)
		addStroke(C.donGold, 1, vBox)
		make("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment   = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 1),
			SortOrder = Enum.SortOrder.LayoutOrder
		}, vBox)
		local vn = make("TextLabel", {
			Size = UDim2.new(1,0,0,15),
			BackgroundTransparency = 1,
			Text = string.char(240,159,146,142).." "..tostring(entry.amount).." R$",
			TextColor3 = C.white,
			Font = Enum.Font.GothamBold, TextSize = 13,
			LayoutOrder = 1, ZIndex = 3
		}, vBox)
		addTextStroke(vn)
		local vLabel = make("TextLabel", {
			Size = UDim2.new(1,0,0,10),
			BackgroundTransparency = 1,
			Text = "DONASI",
			TextColor3 = C.donGold,
			Font = Enum.Font.GothamBold, TextSize = 10,
			LayoutOrder = 2, ZIndex = 3
		}, vBox)
		addTextStroke(vLabel)
	end
end

-- ── loadStatue ───────────────────────────────────────────
local function loadStatue(part, userId, rank, displayName, username, amount)
	if not part or not userId or userId == 0 then return end

	for _, v in pairs(workspace:GetChildren()) do
		if v:GetAttribute("ZayinDonationStatue") == rank then v:Destroy() end
	end

	local desc = nil
	for attempt = 1, 4 do
		local ok, result = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(userId)
		end)
		if ok and result then desc = result; break end
		if attempt < 4 then task.wait(3) end
	end
	if not desc then return end

	local ok2, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok2 or not model then return end

	model.Name = "DonationStatue_"..rank
	model:SetAttribute("ZayinDonationStatue", rank)
	model:SetAttribute("ZayinPatung", true)

	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.HealthDisplayType   = Enum.HumanoidHealthDisplayType.AlwaysOff
		hum.WalkSpeed  = 0
		hum.JumpHeight = 0
		hum.AutoRotate = false
	end

	for _, v in pairs(model:GetDescendants()) do
		if v:IsA("Script") or v:IsA("LocalScript") then v:Destroy()
		elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") then v:Destroy()
		elseif v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then v:Destroy()
		end
	end

	local boxSize = math.min(part.Size.X, part.Size.Z)
	local scale   = math.clamp(boxSize / 3 * STATUE_CONFIG.SCALE, 1.0, 6)
	model:ScaleTo(scale)

	for _, v in pairs(model:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.Anchored   = v.Name == "HumanoidRootPart"
		end
	end

	model.Parent = workspace

	if model.PrimaryPart then
		local yOff = model:GetExtentsSize().Y / 2
		local targetPos = part.Position + Vector3.new(
			0,
			part.Size.Y / 2 + yOff + STATUE_CONFIG.Y_OFFSET,
			0
		)
		model:SetPrimaryPartCFrame(
			CFrame.new(targetPos) * CFrame.Angles(0, math.rad(STATUE_CONFIG.ANGLE), 0)
		)
	end

	local head = model:FindFirstChild("Head")
	if head then
		local RANK_LABELS = {"👑 1st", "⚡ 2nd", "🔥 3rd"}
		local bb = make("BillboardGui", {
			Name = "DonorTitle", AlwaysOnTop = true,
			Size = UDim2.new(0, 260, 0, 120),
			StudsOffset = Vector3.new(0, 10, 0),
			MaxDistance = 60, LightInfluence = 0
		}, head)
		local c = make("Frame", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1}, bb)
		make("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment   = Enum.VerticalAlignment.Center,
			Padding             = UDim.new(0, 2)
		}, c)
		make("TextLabel", {
			Size=UDim2.new(1,0,0,28), BackgroundTransparency=1,
			Text=RANK_LABELS[rank] or "#"..rank,
			TextColor3=MEDAL[rank] or C.cyan,
			Font=Enum.Font.GothamBold, TextSize=22,
			TextStrokeTransparency=0.2, TextStrokeColor3=Color3.new(0,0,0)
		}, c)
		make("TextLabel", {
			Size=UDim2.new(1,0,0,16), BackgroundTransparency=1,
			Text="Top Donation",
			TextColor3=C.donGold,
			Font=Enum.Font.GothamBold, TextSize=13,
			TextStrokeTransparency=0.2, TextStrokeColor3=Color3.new(0,0,0)
		}, c)
		make("TextLabel", {
			Size=UDim2.new(1,0,0,20), BackgroundTransparency=1,
			Text=displayName, TextColor3=C.white,
			Font=Enum.Font.GothamBold, TextSize=16,
			TextStrokeTransparency=0.2, TextStrokeColor3=Color3.new(0,0,0),
			TextTruncate=Enum.TextTruncate.AtEnd
		}, c)
		make("TextLabel", {
			Size=UDim2.new(1,0,0,16), BackgroundTransparency=1,
			Text=string.char(240,159,146,142).." "..tostring(amount).." R$",
			TextColor3=Color3.new(1,1,1),
			Font=Enum.Font.GothamBold, TextSize=13,
			TextStrokeTransparency=0, TextStrokeColor3=Color3.new(0,0,0)
		}, c)
	end

	table.insert(managedStatues, model)
end

-- ── Update patung top 3 ───────────────────────────────────
local function updateStatues(topList)
	statueVersion += 1
	local myVersion = statueVersion

	for _, v in pairs(managedStatues) do
		if v and v.Parent then v:Destroy() end
	end
	managedStatues = {}

	for i = 1, 3 do
		local entry  = topList[i]
		local anchor = topStatues[i]
		if not entry or not anchor then continue end
		local uid = tonumber(entry.userId)
		if not uid or uid <= 0 then continue end

		task.spawn(function()
			task.wait((i-1) * 2)
			if statueVersion ~= myVersion then return end
			loadStatue(anchor, uid, i, entry.displayName, entry.username, entry.amount)
		end)
	end
end

-- ── Refresh semua ────────────────────────────────────────
local function refreshAll()
	local topList = fetchTopList()
	updateLeaderboard(topList)
	updateStatues(topList)
	UpdateUIEvent:FireAllClients(topList)
end

-- ── Countdown label ───────────────────────────────────────
local countdownLabel = nil
pcall(function()
	local timerPart = lbModel:FindFirstChild("DonationTimerCuntdown")
	local mf = timerPart
		and timerPart:FindFirstChild("CountdownGui")
		and timerPart.CountdownGui:FindFirstChild("MainFrame")
	countdownLabel = mf and mf:FindFirstChild("Countdown")
end)

-- ── Main loop ─────────────────────────────────────────────
task.spawn(function()
	task.wait(5)

	local papan = donFolder:FindFirstChild("PapanDonation")
	if papan then
		local old = papan:FindFirstChild("DonationPrompt")
		if old then old:Destroy() end
		local pp = Instance.new("ProximityPrompt")
		pp.Name                  = "DonationPrompt"
		pp.ActionText            = "Donasi"
		pp.ObjectText            = "💎 Papan Donasi"
		pp.KeyboardKeyCode       = Enum.KeyCode.E
		pp.MaxActivationDistance = 15
		pp.HoldDuration          = 0
		pp.Parent                = papan
	end

	while true do
		for t = (GameConfig and GameConfig.LeaderboardRefresh or Config.UpdateInterval), 0, -1 do
			if countdownLabel then
				countdownLabel.Text = string.format("%02d:%02d", math.floor(t/60), t%60)
			end
			task.wait(1)
		end
		pcall(refreshAll)
	end
end)

-- ── ProcessReceipt ────────────────────────────────────────
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local productId = receiptInfo.ProductId
	local userId    = receiptInfo.PlayerId
	-- [P52] gift: cek apakah ini produk gift
	local giftKunci = SDC.GiftMap and SDC.GiftMap[productId]
	if giftKunci then
		local pembeli = Players:GetPlayerByUserId(userId)
		local niat = pendingGift[userId]
		pendingGift[userId] = nil
		if not (pembeli and niat and niat.kunci == giftKunci) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		local target = Players:GetPlayerByUserId(niat.targetId)
		if not target then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		local g = SDC.GiftProducts[giftKunci]
		-- berikan tool ke target
		local SS = game:GetService("ServerStorage")
		local VT = SS:FindFirstChild("VIPTools")
		local daftar = type(g.tool) == "table" and g.tool or {g.tool}
		for _, namaTool in ipairs(daftar) do
			local tpl = VT and VT:FindFirstChild(namaTool)
			local bp = target:FindFirstChildOfClass("Backpack")
			if tpl and bp and not bp:FindFirstChild(namaTool) then
				tpl:Clone().Parent = bp
			end
		end
		if g.vip then target:SetAttribute("IsVIP", true) end

		-- [P58] catat gift permanen ke DataStore
		do
			local catatBE = game:GetService("ServerStorage"):FindFirstChild("CatatGift")
			if catatBE then
				pcall(function() catatBE:Fire(target.UserId, daftar, g.vip) end)
			end
		end

		-- [P54] gift masuk donasi: robux gift dihitung ke total donasi PEMBELI
		local robuxGift = g.robux or 0
		if robuxGift > 0 then
			local uidStr2 = tostring(userId)
			local totalBaru = 0
			pcall(function()
				DonationStore:UpdateAsync(uidStr2, function(old)
					totalBaru = (old or 0) + robuxGift
					return totalBaru
				end)
			end)
			pcall(function() NamesStore:SetAsync(uidStr2, pembeli.DisplayName) end)
			nameCache[uidStr2] = pembeli.DisplayName
			local dv2 = pembeli:FindFirstChild("Donation")
			if dv2 then dv2.Value = totalBaru end
			task.delay(2, function() pcall(refreshAll) end)
		end
		-- siarkan notif gift
		GiftNotifRE:FireAllClients({
			pengirim   = pembeli.DisplayName,
			pengirimId = pembeli.UserId,
			penerima   = target.DisplayName,
			penerimaId = target.UserId,
			item       = g.name,
		})
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local robux     = Config.ProductMap[productId]
	if not robux then return Enum.ProductPurchaseDecision.NotProcessedYet end

	local uidStr   = tostring(userId)
	local newTotal = 0
	local ok = pcall(function()
		DonationStore:UpdateAsync(uidStr, function(old)
			newTotal = (old or 0) + robux
			return newTotal
		end)
	end)
	if not ok then return Enum.ProductPurchaseDecision.NotProcessedYet end

	local player = Players:GetPlayerByUserId(userId)
	if player then
		pcall(function() NamesStore:SetAsync(uidStr, player.DisplayName) end)
		nameCache[uidStr] = player.DisplayName
		-- [OPSI A] donasi kecil tampil langsung; donasi besar ditahan dulu
		if robux < Config.MinMessageRobux then
		NotifyEvent:FireAllClients({
			donor  = player.DisplayName,
			userId = player.UserId,
			amount = robux,
			total  = newTotal,
			type   = "donation"
		})
		end
		if robux >= Config.MinMessageRobux then
			donasiSeq = donasiSeq + 1
			local idD = donasiSeq
			pendingDonasi[userId] = { id = idD, amount = robux, total = newTotal, donor = player.DisplayName, userId = player.UserId }
			task.delay(25, function()
				local p = pendingDonasi[userId]
				if p and p.id == idD then
					pendingDonasi[userId] = nil
					kirimNotifDonasi(p, nil)
				end
			end)
			MsgEvent:FireClient(player, "OpenMessageInput", newTotal)
		end
		-- Update donVal di player (bukan leaderstats)
		local donVal = player:FindFirstChild("Donation")
		if donVal then donVal.Value = newTotal end
	end

	task.delay(2, function() pcall(refreshAll) end)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- ── Remote handlers ───────────────────────────────────────
GiftIntentRE.OnServerEvent:Connect(function(player, targetUserId, kunci)
	local g = SDC.GiftProducts and SDC.GiftProducts[kunci]
	if not g then return end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or target == player then return end
	pendingGift[player.UserId] = { targetId = targetUserId, kunci = kunci }
	MarketplaceService:PromptProductPurchase(player, g.productId)
end)

PromptEvent.OnServerEvent:Connect(function(player, productId)
	if not Config.ProductMap[productId] then return end
	MarketplaceService:PromptProductPurchase(player, productId)
end)

MsgEvent.OnServerEvent:Connect(function(player, action, message)
	-- [FIX] notif donasi sudah tampil saat purchase; handler ini HANYA untuk pesan opsional.
	local uid = player.UserId
	local pend = pendingDonasi[uid]
	pendingDonasi[uid] = nil

	if not pend then return end

	local pesan = nil
	if action == "Send" and type(message) == "string" and #message > 0 then
		if not (msgCooldownTime[uid] and (tick() - msgCooldownTime[uid]) < 30) then
			msgCooldownTime[uid] = tick()
			pesan = message:sub(1, 150)
		end
	end

	kirimNotifDonasi(pend, pesan)
end)

-- ── Player join ───────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		-- Donation disimpan di player langsung, tidak di leaderstats
		-- agar tidak muncul di tab Players Roblox
		local donVal = Instance.new("IntValue")
		donVal.Name   = "Donation"
		donVal.Value  = 0
		donVal.Parent = player

		-- Cek cache dulu
		for _, entry in ipairs(cachedTopList) do
			if tostring(entry.userId) == tostring(player.UserId) then
				donVal.Value = entry.amount
				return
			end
		end

		-- Fallback ke DataStore
		task.wait(5)
		if player.Parent then
			pcall(function()
				local val = DonationStore:GetAsync(tostring(player.UserId))
				if val then donVal.Value = val end
			end)
		end
	end)
end)

-- ── FIX memory leak: bersihkan cache saat player keluar ──
Players.PlayerRemoving:Connect(function(player)
	pendingMessages[player.UserId]     = nil
	pendingDonasi[player.UserId]       = nil
	msgCooldownTime[player.UserId]     = nil
	nameCache[tostring(player.UserId)] = nil
	thumbnailCache[player.UserId]      = nil
end)

-- ── Init pertama ──────────────────────────────────────────
task.delay(3, function() pcall(refreshAll) end)

print("[ZayinDonationService] Ready!")