-- CheckpointClient FIXED
-- Fix: loops table direset setiap setupProximityLoops (tidak accumulate)
-- Fix: clearLoops juga clear table setelah disconnect

local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ZR        = RS:WaitForChild("ZayinRemotes")
local CPRemotes = ZR:WaitForChild("Checkpoint")
local ReachedRE = CPRemotes:WaitForChild("Reached")
local ResetBCRE = CPRemotes:WaitForChild("ResetToBC")

local cpDitolakRE = ZR:WaitForChild("CPDitolak", 10)
if cpDitolakRE then
	cpDitolakRE.OnClientEvent:Connect(function()
		local old = playerGui:FindFirstChild("ZayinCPDitolak")
		if old then old:Destroy() end
		pcall(function()
			local g = Instance.new("ScreenGui")
			g.Name = "ZayinCPDitolak"; g.ResetOnSpawn = false; g.DisplayOrder = 20; g.Parent = playerGui
			local f = Instance.new("Frame", g)
			f.Size = UDim2.new(0.28, 0, 0, 40); f.AnchorPoint = Vector2.new(0.5, 0)
			f.Position = UDim2.new(0.5, 0, -0.1, 0)
			f.BackgroundColor3 = Color3.fromRGB(20, 0, 0); f.BackgroundTransparency = 0.2; f.BorderSizePixel = 0
			Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
			local stroke = Instance.new("UIStroke", f); stroke.Color = Color3.fromRGB(255, 50, 50); stroke.Thickness = 2
			local lbl = Instance.new("TextLabel", f)
			lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
			lbl.Text = "Lewati checkpoint berurutan!"; lbl.TextColor3 = Color3.fromRGB(255, 80, 80)
			lbl.TextScaled = true; lbl.Font = Enum.Font.GothamBold
			TweenService:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{Position = UDim2.new(0.5, 0, 0.12, 0)}):Play()
			task.wait(3)
			local tw = TweenService:Create(f, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
				{Position = UDim2.new(0.5, 0, -0.1, 0)})
			tw:Play(); tw.Completed:Connect(function() g:Destroy() end)
		end)
	end)
end

local touchedCPs   = {}
-- FIX: loops table bisa diassign ulang sepenuhnya (tidak pakai insert ke tabel lama)
local activeLoop   = nil
local isRespawning = false
_G.ZayinTouchedCPs = touchedCPs

local function buildCPOrder()
	local order = {"Basecamp"}
	local zw = workspace:FindFirstChild("ZayinWorkspace")
	local cpFolder = zw and zw:FindFirstChild("Checkpoint")
	if cpFolder then
		local cpNums = {}
		for _, part in pairs(cpFolder:GetChildren()) do
			if part.Name:match("^CP%d+$") then
				table.insert(cpNums, tonumber(part.Name:match("%d+")))
			end
		end
		table.sort(cpNums)
		for _, num in ipairs(cpNums) do table.insert(order, "CP" .. num) end
	end
	table.insert(order, "SummitEasy")
	table.insert(order, "SummitHard")
	return order
end

local function showCPNotif(cpName)
	task.spawn(function()
		local old = playerGui:FindFirstChild("ZayinCPNotif")
		if old then old:Destroy() end
		pcall(function()
			local g = Instance.new("ScreenGui")
			g.Name = "ZayinCPNotif"; g.ResetOnSpawn = false; g.DisplayOrder = 15; g.Parent = playerGui
			local f = Instance.new("Frame", g)
			f.Size = UDim2.new(0.3, 0, 0, 42); f.Position = UDim2.new(0.5, 0, -0.1, 0)
			f.AnchorPoint = Vector2.new(0.5, 0)
			f.BackgroundColor3 = Color3.fromRGB(0, 0, 0); f.BackgroundTransparency = 0.5; f.BorderSizePixel = 0
			Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
			local stroke = Instance.new("UIStroke", f)
			stroke.Color = Color3.fromRGB(0, 230, 200); stroke.Thickness = 1.8
			local pad = Instance.new("UIPadding", f)
			pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12)
			pad.PaddingTop = UDim.new(0, 6);   pad.PaddingBottom = UDim.new(0, 6)
			local lbl = Instance.new("TextLabel", f)
			lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
			lbl.Text = cpName:lower():gsub("cp", "CHECKPOINT ")
			lbl.TextColor3 = Color3.fromRGB(0, 230, 200); lbl.TextScaled = true; lbl.Font = Enum.Font.GothamBold
			TweenService:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{Position = UDim2.new(0.5, 0, 0.08, 0)}):Play()
			task.wait(2)
			local tw = TweenService:Create(f, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
				{Position = UDim2.new(0.5, 0, -0.1, 0)})
			tw:Play(); tw.Completed:Connect(function() g:Destroy() end)
		end)
	end)
end

-- FIX: clearLoop disconnect dan nil-kan activeLoop
local function clearLoop()
	if activeLoop and activeLoop.Connected then
		activeLoop:Disconnect()
	end
	activeLoop = nil
end

local function resetTouchedCPs()
	touchedCPs = {}
	_G.ZayinTouchedCPs = touchedCPs
end

-- [PATCH] checkSpawnNearSummit dihapus (anti-farm summit)

local function setupProximityLoops()
	clearLoop()  -- FIX: clear loop lama sebelum buat baru
	resetTouchedCPs()
	isRespawning = true

	local zw = workspace:WaitForChild("ZayinWorkspace", 10)
	if not zw then warn("[CPClient] ZayinWorkspace tidak ditemukan!"); return end

	local cpParts  = {}
	local kkbParts = {}
	local tpParts  = {}

	local cpFolder = zw:FindFirstChild("Checkpoint")
	if cpFolder then
		for _, part in pairs(cpFolder:GetChildren()) do
			if part:IsA("BasePart") then cpParts[part.Name] = part end
		end
	end
	local kkbFolder = zw:FindFirstChild("KembaliKeBasecamp")
	if kkbFolder then
		for _, part in pairs(kkbFolder:GetChildren()) do
			if part:IsA("BasePart") then table.insert(kkbParts, part) end
		end
	end
	local tpFolder = zw:FindFirstChild("Teleport")
	if tpFolder then
		for _, part in pairs(tpFolder:GetDescendants()) do
			if part:IsA("BasePart") then table.insert(tpParts, part) end
		end
	end

	task.spawn(function()
		task.wait(0.2)
		local GetCPRF = CPRemotes:FindFirstChild("GetCheckpoint")
		local lastCP = "Basecamp"
		if GetCPRF then
			local ok, result = pcall(function() return GetCPRF:InvokeServer() end)
			if ok and result then lastCP = result end
		end
		local cpOrder = buildCPOrder()
		local cpIndex = 0
		for i, cp in ipairs(cpOrder) do
			if cp == lastCP then cpIndex = i; break end
		end
		for i = 1, cpIndex do touchedCPs[cpOrder[i]] = true end
		_G.ZayinTouchedCPs = touchedCPs
		task.wait(0.3)
		isRespawning = false
	end)

	local kkbDeb = false
	local tpDeb  = false

	-- FIX: simpan ke activeLoop (bukan table insert)
	activeLoop = RunService.Heartbeat:Connect(function()
		if isRespawning then return end
		local char = player.Character; if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
		local pos = hrp.Position

		for cpName, part in pairs(cpParts) do
			if cpName == "Basecamp" or cpName:find("Summit") then continue end
			if not touchedCPs[cpName] then
				local rel = pos - part.Position
				if math.abs(rel.X) <= part.Size.X/2 and math.abs(rel.Y) <= part.Size.Y/2
					and math.abs(rel.Z) <= part.Size.Z/2 then
					touchedCPs[cpName] = true
					_G.ZayinTouchedCPs = touchedCPs
					ReachedRE:FireServer(cpName)
					-- [P17] notif dipindah ke server (sah/tidak sah diputuskan di sana)
				end
			end
		end

		if not kkbDeb then
			for _, part in pairs(kkbParts) do
				local rel = pos - part.Position
				if math.abs(rel.X) <= part.Size.X/2 and math.abs(rel.Z) <= part.Size.Z/2 then
					kkbDeb = true
					task.spawn(function()
						ResetBCRE:FireServer()
						resetTouchedCPs()
						task.wait(2); kkbDeb = false
					end)
					break
				end
			end
		end

		if not tpDeb then
			for _, part in pairs(tpParts) do
				local rel = pos - part.Position
				if math.abs(rel.X) <= part.Size.X/2 and math.abs(rel.Z) <= part.Size.Z/2 then
					tpDeb = true
					task.spawn(function()
						ReachedRE:FireServer("__teleport__")
					-- Notify SpeedRunService untuk reset proximity
					local _tpRE = game:GetService("ReplicatedStorage"):FindFirstChild("ZayinRemotes")
					local _tpEv = _tpRE and _tpRE:FindFirstChild("TeleportOccurred")
					if _tpEv then _tpEv:FireServer() end
						task.wait(1); tpDeb = false
					end)
					break
				end
			end
		end
	end)
end

player.CharacterAdded:Connect(function()
	task.wait(1)
	setupProximityLoops()
end)

if player.Character then
	task.wait(1)
	setupProximityLoops()
end

print("[CheckpointClient FIXED] Ready!")

-- [P18] TOUCHED CP — pemicu instan begitu menyentuh part checkpoint
task.spawn(function()
	local Players = game:GetService("Players")
	local RS      = game:GetService("ReplicatedStorage")
	local plr     = Players.LocalPlayer
	local ZR5     = RS:WaitForChild("ZayinRemotes", 30)
	local CP5     = ZR5:WaitForChild("Checkpoint", 30)
	local RE5     = CP5:WaitForChild("Reached", 30)
	local zw5     = workspace:WaitForChild("ZayinWorkspace", 30)
	local cf5     = zw5:WaitForChild("Checkpoint", 30)

	local cd = {}
	local function pasang(obj)
		local nama = obj.Name
		if not (nama == "Basecamp" or nama:match("^CP%d+$")) then return end
		local parts = {}
		if obj:IsA("BasePart") then
			table.insert(parts, obj)
		else
			for _, d in ipairs(obj:GetDescendants()) do
				if d:IsA("BasePart") then table.insert(parts, d) end
			end
		end
		for _, p in ipairs(parts) do
			p.CanTouch = true
			p.Touched:Connect(function(hit)
				local ch = hit and hit.Parent
				if not ch or Players:GetPlayerFromCharacter(ch) ~= plr then return end
				local now = os.clock()
				if cd[nama] and now - cd[nama] < 1.5 then return end
				cd[nama] = now
				RE5:FireServer(nama)
			end)
		end
	end

	for _, obj in ipairs(cf5:GetChildren()) do pasang(obj) end
	cf5.ChildAdded:Connect(pasang)
end)