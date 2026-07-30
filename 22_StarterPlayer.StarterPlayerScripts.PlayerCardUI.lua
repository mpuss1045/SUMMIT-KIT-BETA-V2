-- ============================================================
-- PlayerCardUI (LocalScript)
-- Lokasi: StarterGui > PlayerCardUI (ScreenGui baru)
-- Fungsi: Tampilkan card player di sudut bawah kiri
--         Isi: Avatar, Nama, Summit, Posisi/CP, BestTime, Health bar
-- ============================================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================
-- WARNA & STYLE
-- ============================================================
local C = {
	bg          = Color3.fromRGB(10,  12,  20),   -- background utama (gelap)
	bg2         = Color3.fromRGB(18,  22,  38),   -- background stats
	border      = Color3.fromRGB(60,  80, 140),   -- border biru gelap
	accent      = Color3.fromRGB(80, 140, 255),   -- aksen biru
	white       = Color3.new(1, 1, 1),
	gray        = Color3.fromRGB(160, 170, 190),
	gold        = Color3.fromRGB(255, 200,  50),
	green       = Color3.fromRGB( 80, 220, 120),
	healthFull  = Color3.fromRGB( 80, 200, 100),
	healthLow   = Color3.fromRGB(220,  60,  60),
	healthBg    = Color3.fromRGB( 20,  25,  40),
}

-- ============================================================
-- BUILD UI
-- ============================================================
local function buildUI()
	-- Hapus yang lama
	local old = playerGui:FindFirstChild("PlayerCardUI")
	if old then old:Destroy() end

	local sg = Instance.new("ScreenGui")
	sg.Name            = "PlayerCardUI"
	sg.ResetOnSpawn    = false
	sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
	sg.Parent          = playerGui

	-- Main Frame — sudut bawah kiri
	local main = Instance.new("Frame")
	main.Name               = "MainCard"
	main.Size               = UDim2.new(0, 240, 0, 110)
	main.Position           = UDim2.new(0, 12, 1, -122)
	main.BackgroundColor3   = C.bg
	main.BorderSizePixel    = 0
	main.Parent             = sg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = main

	local stroke = Instance.new("UIStroke")
	stroke.Color     = C.border
	stroke.Thickness = 1.5
	stroke.Parent    = main

	-- Avatar thumbnail (kiri)
	local avatar = Instance.new("ImageLabel")
	avatar.Name               = "Avatar"
	avatar.Size               = UDim2.new(0, 72, 0, 72)
	avatar.Position           = UDim2.new(0, 10, 0, 10)
	avatar.BackgroundColor3   = C.bg2
	avatar.BorderSizePixel    = 0
	avatar.Image              = ""
	avatar.Parent             = main

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(0, 8)
	avatarCorner.Parent = avatar

	local avatarStroke = Instance.new("UIStroke")
	avatarStroke.Color     = C.accent
	avatarStroke.Thickness = 1.5
	avatarStroke.Parent    = avatar

	-- Load avatar thumbnail async
	task.spawn(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(
				player.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size420x420
			)
		end)
		if ok then avatar.Image = img end
	end)

	-- Nama player
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name              = "NameLabel"
	nameLabel.Size              = UDim2.new(0, 148, 0, 22)
	nameLabel.Position          = UDim2.new(0, 88, 0, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text              = player.DisplayName
	nameLabel.TextColor3        = C.white
	nameLabel.TextSize          = 14
	nameLabel.Font              = Enum.Font.GothamBold
	nameLabel.TextXAlignment    = Enum.TextXAlignment.Left
	nameLabel.TextTruncate      = Enum.TextTruncate.AtEnd
	nameLabel.Parent            = main

	-- Stats container (kanan atas)
	local statsFrame = Instance.new("Frame")
	statsFrame.Name               = "Stats"
	statsFrame.Size               = UDim2.new(0, 148, 0, 62)
	statsFrame.Position           = UDim2.new(0, 88, 0, 32)
	statsFrame.BackgroundColor3   = C.bg2
	statsFrame.BorderSizePixel    = 0
	statsFrame.Parent             = main

	local statsCorner = Instance.new("UICorner")
	statsCorner.CornerRadius = UDim.new(0, 6)
	statsCorner.Parent = statsFrame

	local statsLayout = Instance.new("UIListLayout")
	statsLayout.FillDirection  = Enum.FillDirection.Vertical
	statsLayout.Padding        = UDim.new(0, 2)
	statsLayout.Parent         = statsFrame

	local statsPad = Instance.new("UIPadding")
	statsPad.PaddingLeft   = UDim.new(0, 8)
	statsPad.PaddingTop    = UDim.new(0, 4)
	statsPad.PaddingRight  = UDim.new(0, 8)
	statsPad.PaddingBottom = UDim.new(0, 4)
	statsPad.Parent        = statsFrame

	-- Helper buat stat row
	local statLabels = {}
	local function makeStatRow(icon, key, defaultVal)
		local row = Instance.new("Frame")
		row.Size                 = UDim2.new(1, 0, 0, 17)
		row.BackgroundTransparency = 1
		row.Parent               = statsFrame

		local iconL = Instance.new("TextLabel")
		iconL.Size               = UDim2.new(0, 16, 1, 0)
		iconL.BackgroundTransparency = 1
		iconL.Text               = icon
		iconL.TextSize           = 11
		iconL.Font               = Enum.Font.Gotham
		iconL.TextColor3         = C.accent
		iconL.TextXAlignment     = Enum.TextXAlignment.Left
		iconL.Parent             = row

		local keyL = Instance.new("TextLabel")
		keyL.Size                = UDim2.new(0, 70, 1, 0)
		keyL.Position            = UDim2.new(0, 18, 0, 0)
		keyL.BackgroundTransparency = 1
		keyL.Text                = key .. " :"
		keyL.TextSize            = 11
		keyL.Font                = Enum.Font.Gotham
		keyL.TextColor3          = C.gray
		keyL.TextXAlignment      = Enum.TextXAlignment.Left
		keyL.Parent              = row

		local valL = Instance.new("TextLabel")
		valL.Name                = key .. "Val"
		valL.Size                = UDim2.new(1, -90, 1, 0)
		valL.Position            = UDim2.new(0, 90, 0, 0)
		valL.BackgroundTransparency = 1
		valL.Text                = tostring(defaultVal)
		valL.TextSize            = 11
		valL.Font                = Enum.Font.GothamBold
		valL.TextColor3          = C.white
		valL.TextXAlignment      = Enum.TextXAlignment.Right
		valL.Parent              = row

		statLabels[key] = valL
		return row
	end

	makeStatRow("🏔", "Summit",   "0")
	makeStatRow("🚩", "Posisi",   "Basecamp")
	makeStatRow("⏱", "BestTime", "00:00.000")

	-- Health bar container (bawah)
	local hpContainer = Instance.new("Frame")
	hpContainer.Name               = "HPContainer"
	hpContainer.Size               = UDim2.new(1, -20, 0, 14)
	hpContainer.Position           = UDim2.new(0, 10, 1, -20)
	hpContainer.BackgroundColor3   = C.healthBg
	hpContainer.BorderSizePixel    = 0
	hpContainer.Parent             = main

	local hpCorner = Instance.new("UICorner")
	hpCorner.CornerRadius = UDim.new(0, 4)
	hpCorner.Parent = hpContainer

	local hpBar = Instance.new("Frame")
	hpBar.Name               = "HPBar"
	hpBar.Size               = UDim2.new(1, 0, 1, 0)
	hpBar.BackgroundColor3   = C.healthFull
	hpBar.BorderSizePixel    = 0
	hpBar.Parent             = hpContainer

	local hpBarCorner = Instance.new("UICorner")
	hpBarCorner.CornerRadius = UDim.new(0, 4)
	hpBarCorner.Parent = hpBar

	local hpLabel = Instance.new("TextLabel")
	hpLabel.Name               = "HPLabel"
	hpLabel.Size               = UDim2.new(1, 0, 1, 0)
	hpLabel.BackgroundTransparency = 1
	hpLabel.Text               = "100 / 100"
	hpLabel.TextSize            = 9
	hpLabel.Font               = Enum.Font.GothamBold
	hpLabel.TextColor3         = C.white
	hpLabel.ZIndex             = 2
	hpLabel.Parent             = hpContainer

	-- ============================================================
	-- UPDATE LOGIC
	-- ============================================================
	local ls = player:WaitForChild("leaderstats", 15)

	-- Update stats dari leaderstats
	local function updateStats()
		if not ls then return end
		for key, label in pairs(statLabels) do
			local val = ls:FindFirstChild(key)
			if val then
				label.Text = tostring(val.Value)
			end
		end
	end

	-- Connect leaderstats changes
	if ls then
		for _, v in ipairs(ls:GetChildren()) do
			v.Changed:Connect(updateStats)
		end
		updateStats()
	end

	-- Update health bar
	local _hpConn = nil
	local function updateHP(char)
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		if _hpConn then _hpConn:Disconnect(); _hpConn = nil end
		_hpConn = hum.HealthChanged:Connect(function()
			local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
			TweenService:Create(hpBar, TweenInfo.new(0.2), {Size = UDim2.new(ratio, 0, 1, 0)}):Play()
			hpBar.BackgroundColor3 = ratio > 0.4 and C.healthFull or C.healthLow
			hpLabel.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
		end)
		hpLabel.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
	end


	-- Init dengan karakter sekarang
	if player.Character then
		updateHP(player.Character)
	end
	player.CharacterAdded:Connect(function(char)
		task.wait(0.5)
		updateHP(char)
	end)

	return sg
end

-- Build saat pertama kali
buildUI()

-- Rebuild saat respawn
player.CharacterAdded:Connect(function()
	task.wait(1)
	-- Cukup update HP, UI tidak perlu rebuild
end)

print("[PlayerCardUI] Ready!")
-- [P15] sinkron kartu: leaderstats sering terisi SETELAH kartu dibangun
task.spawn(function()
	local Players = game:GetService("Players")
	local plr = Players.LocalPlayer
	local stats = plr:WaitForChild("leaderstats", 30)
	if not stats then return end

	local gui = plr:WaitForChild("PlayerGui")
	local card = gui:WaitForChild("PlayerCardUI", 30) or gui:FindFirstChild("PlayerCard")
	if not card then
		for _, g in ipairs(gui:GetChildren()) do
			if g:IsA("ScreenGui") and g.Name:lower():find("card") then card = g break end
		end
	end
	if not card then warn("[P15] ScreenGui kartu tidak ditemukan") return end

	local kunci = {
		{cari = "summit",  stat = "Summit"},
		{cari = "posisi",  stat = "Posisi"},
		{cari = "best",    stat = "BestTime"},
	}

	local function tulis()
		for _, k in ipairs(kunci) do
			local v = stats:FindFirstChild(k.stat)
			if v then
				for _, d in ipairs(card:GetDescendants()) do
					if d:IsA("TextLabel") and d.Name:lower():find(k.cari) then
						d.Text = tostring(v.Value)
					end
				end
			end
		end
	end

	for _, k in ipairs(kunci) do
		local v = stats:FindFirstChild(k.stat)
		if v then v.Changed:Connect(function() task.wait(0.1); pcall(tulis) end) end
	end
	for _ = 1, 12 do task.wait(1); pcall(tulis) end
end)

-- [P18] kartu val — isi SummitVal/PosisiVal/BestTimeVal dari leaderstats
task.spawn(function()
	local plr   = game:GetService("Players").LocalPlayer
	local stats = plr:WaitForChild("leaderstats", 30)
	local gui   = plr:WaitForChild("PlayerGui")
	if not stats then return end

	local peta = { SummitVal = "Summit", PosisiVal = "Posisi", BestTimeVal = "BestTime" }

	local function tulis()
		for _, d in ipairs(gui:GetDescendants()) do
			if d:IsA("TextLabel") and peta[d.Name] then
				local v = stats:FindFirstChild(peta[d.Name])
				if v then d.Text = tostring(v.Value) end
			end
		end
	end

	for _, nama in pairs(peta) do
		local v = stats:FindFirstChild(nama)
		if v then v.Changed:Connect(function() task.wait(0.05); pcall(tulis) end) end
	end
	for _, nama in pairs({"Summit","Posisi","BestTime"}) do
		local v = stats:FindFirstChild(nama)
		if v then v.Changed:Connect(function() task.wait(0.05); pcall(tulis) end) end
	end
	for _ = 1, 15 do task.wait(0.7); pcall(tulis) end
end)

-- [P86] kartu pojok: perkecil & sudutkan ke kiri bawah
task.spawn(function()
	local UIS = game:GetService("UserInputService")
	local M2 = UIS.TouchEnabled and not UIS.KeyboardEnabled
	local plr2 = game:GetService("Players").LocalPlayer
	local gui2 = plr2:WaitForChild("PlayerGui")

	local function atur()
		local card = gui2:FindFirstChild("PlayerCardUI")
		if not card then return end
		for _, f in ipairs(card:GetChildren()) do
			if f:IsA("Frame") then
				local skala = M2 and 0.72 or 0.82
				local us = f:FindFirstChildOfClass("UIScale")
				if not us then
					us = Instance.new("UIScale")
					us.Parent = f
				end
				us.Scale = skala
				f.AnchorPoint = Vector2.new(0, 1)
				f.Position = UDim2.new(0, 4, 1, -4)
			end
		end
	end

	for _ = 1, 12 do task.wait(0.7); pcall(atur) end
end)