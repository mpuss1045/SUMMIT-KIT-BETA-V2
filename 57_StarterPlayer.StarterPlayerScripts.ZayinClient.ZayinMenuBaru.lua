-- ZayinMenuBaru v3.4
-- Fix v3.3: Heartbeat viewport → GetPropertyChangedSignal
-- Fix v3.3: SpeedRunClient double position assignment
-- New v3.4: Top Right Buttons — [Reset BC] [Leaderstat] [Hide UI] (lingkaran)

-- Sembunyikan default backpack Roblox
pcall(function() game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local M = UIS.TouchEnabled and not UIS.KeyboardEnabled

local C = {
	BG     = Color3.fromRGB(10, 10, 12),
	BG2    = Color3.fromRGB(16, 18, 22),
	BG3    = Color3.fromRGB(22, 26, 32),
	CYAN   = Color3.fromRGB(0,  210, 200),
	CYND   = Color3.fromRGB(0,  150, 145),
	BORDER = Color3.fromRGB(40, 40, 48),
	BORDC  = Color3.fromRGB(0,  180, 175),
	TEXT   = Color3.fromRGB(220,230, 235),
	TEXTS  = Color3.fromRGB(120,140, 150),
	RED    = Color3.fromRGB(255, 75,  75),
	REDBG  = Color3.fromRGB(32,  10,  10),
	WHITE  = Color3.fromRGB(255,255, 255),
	GREEN  = Color3.fromRGB(40, 215, 115),
	GREENBG= Color3.fromRGB(0,  32,  14),
}

local function make(cls, props, parent)
	local i = Instance.new(cls)
	for k,v in pairs(props or {}) do i[k]=v end
	if parent then i.Parent=parent end
	return i
end
local function corner(obj, r) make("UICorner", {CornerRadius=UDim.new(0, r or 8)}, obj) end
local function stroke(obj, col, t)
	local s = make("UIStroke", {Color=col or C.BORDER, Thickness=t or 1}, obj)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; return s
end
local function tw(o, t, props) TweenService:Create(o, TweenInfo.new(t), props):Play() end

local function L()
	local vp = workspace.CurrentCamera.ViewportSize
	local sw, sh = vp.X, vp.Y
	if M then
		if sh > sw then
			return {pw=math.min(sw-12, 8*40+7*4+18), ph=120, cw=40, ch=52, cp=4,
				by=8, bw=110, bh=32, sw=math.min(sw-16,270), sh2=math.min(sh*0.62,360), sy=48}
		else
			return {pw=math.min(sw-14, 8*46+7*5+20), ph=132, cw=46, ch=58, cp=5,
				by=6, bw=100, bh=28, sw=math.min(sw*0.4,250), sh2=math.min(sh-50,300), sy=42}
		end
	end
	return {pw=8*74+7*8+28, ph=168, cw=74, ch=80, cp=8,
		by=14, bw=128, bh=34, sw=285, sh2=340, sy=56}
end

local layout = L()

local sg = make("ScreenGui", {
	Name="ZayinMenuBaru", ResetOnSpawn=false,
	DisplayOrder=10, IgnoreGuiInset=true
}, playerGui)

local menuBtn = make("TextButton", {
	Size=UDim2.new(0,layout.bw,0,layout.bh),
	AnchorPoint=Vector2.new(0.5,0),
	Position=UDim2.new(0.5,0,0,layout.by),
	BackgroundColor3=C.BG2, BackgroundTransparency=0.35,
	BorderSizePixel=0, Text="MAIN MENU",
	TextSize=M and 10 or 12, Font=Enum.Font.GothamBold,
	TextColor3=C.CYAN, AutoButtonColor=false,
}, sg)
corner(menuBtn, 20); stroke(menuBtn, C.BORDER, 1)

local panel = make("Frame", {
	Name="MenuPanel",
	Size=UDim2.new(0,layout.pw,0,layout.ph),
	AnchorPoint=Vector2.new(0.5,0),
	Position=UDim2.new(0.5,0,0,layout.by+layout.bh+6),
	BackgroundColor3=C.BG, BackgroundTransparency=0.5,
	BorderSizePixel=0, Visible=false,
}, sg)
corner(panel, 14); stroke(panel, C.BORDC, 1.5)

local hdrH = M and 36 or 42
local hdr = make("Frame", {Size=UDim2.new(1,0,0,hdrH), BackgroundColor3=C.BG2, BackgroundTransparency=0.35, BorderSizePixel=0}, panel)
corner(hdr, 14)

make("TextLabel", {
	Size=UDim2.new(1,-70,1,0), Position=UDim2.new(0,14,0,0),
	BackgroundTransparency=1, Text="MAIN MENU",
	TextSize=M and 10 or 12, Font=Enum.Font.GothamBold,
	TextColor3=C.CYAN, TextXAlignment=Enum.TextXAlignment.Left
}, hdr)

local closeBtn = make("TextButton", {
	Size=UDim2.new(0,M and 50 or 58,0,M and 22 or 26),
	Position=UDim2.new(1,-(M and 58 or 66),0.5,-(M and 11 or 13)),
	BackgroundColor3=C.REDBG, BorderSizePixel=0,
	Text="Tutup", TextSize=M and 9 or 11,
	Font=Enum.Font.GothamBold, TextColor3=C.RED, AutoButtonColor=false
}, hdr)
corner(closeBtn, 12); stroke(closeBtn, C.RED, 1)

make("Frame", {
	Size=UDim2.new(1,-20,0,1), Position=UDim2.new(0,10,0,hdrH),
	BackgroundColor3=C.CYND, BorderSizePixel=0
}, panel)

local grid = make("Frame", {
	Size=UDim2.new(1,-14,1,-(hdrH+8)),
	Position=UDim2.new(0,7,0,hdrH+4),
	BackgroundTransparency=1, BorderSizePixel=0, ClipsDescendants=true
}, panel)

local gl = make("UIGridLayout", {
	CellSize=UDim2.new(0,layout.cw,0,layout.ch),
	CellPadding=UDim2.new(0,layout.cp,0,layout.cp),
	HorizontalAlignment=Enum.HorizontalAlignment.Center,
	SortOrder=Enum.SortOrder.LayoutOrder
}, grid)
make("UIPadding", {PaddingTop=UDim.new(0,8), PaddingBottom=UDim.new(0,16)}, grid)

local ITEMS = {
	{icon="🎵", label="Musik",    color=Color3.fromRGB(0,200,190),   bg=Color3.fromRGB(0,30,28)},
	{icon="💃", label="Emote",    color=Color3.fromRGB(190,70,210),  bg=Color3.fromRGB(32,0,38)},
	{icon="👤", label="Avatar",   color=Color3.fromRGB(60,145,250),  bg=Color3.fromRGB(0,14,40)},
	{icon="⚙️", label="Setting",  color=Color3.fromRGB(150,155,165), bg=Color3.fromRGB(20,20,24)},
	{icon="📷", label="Kamera",   color=Color3.fromRGB(245,175,40),  bg=Color3.fromRGB(38,26,0)},
	{icon="👁️", label="Spectate", color=Color3.fromRGB(40,215,115),  bg=Color3.fromRGB(0,32,14)},
	{icon="💎", label="Donasi",   color=Color3.fromRGB(110,180,250), bg=Color3.fromRGB(0,14,40)},
	{icon="🛒", label="Shop",     color=Color3.fromRGB(250,130,50),  bg=Color3.fromRGB(38,14,0)},
}

local activeCell = nil
local debounce   = {}
local panelOpen  = false
local btnDeb     = false
local accentRefs = {}
local PANEL_MAP  = {}
-- [P44] slot panel: kanan & kiri bergantian
local SLOT = { kanan = nil, kiri = nil }
local SLOT_URUT = {}  -- urutan buka, untuk tahu mana yang paling lama

local _specGC do local o, g = pcall(function() return require(game:GetService("ReplicatedStorage"):WaitForChild("ZayinConfig",10):WaitForChild("GameConfig",10)) end) if o then _specGC = g end end
	local refreshSpec = function() end

-- [P46] closeMenuAll dideklarasikan di bawah closeMenu
local function closeAllSub()
	for _, p in pairs(PANEL_MAP) do p.Visible = false end
	if SLOT then SLOT.kanan = nil; SLOT.kiri = nil; SLOT_URUT = {} end
end

for i, item in ipairs(ITEMS) do
	local cell = make("TextButton", {
		Name=item.label.."Btn", BackgroundColor3=C.BG3,
		BackgroundTransparency=0, BorderSizePixel=0,
		Text="", AutoButtonColor=false, LayoutOrder=i
	}, grid)
	corner(cell, 12)
	local cs = stroke(cell, C.BORDER, 1)

	-- [P43] ikon bulat
	local ikonSz = M and 28 or 42
	local ikonBg = make("Frame", {
		Size = UDim2.fromOffset(ikonSz, ikonSz),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, M and 5 or 6),
		BackgroundColor3 = item.bg,
		BorderSizePixel = 0,
	}, cell)
	corner(ikonBg, 100)
	stroke(ikonBg, item.color, 1.5)
	make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = item.icon,
		TextSize = M and 15 or 22,
		Font = Enum.Font.Gotham,
		TextColor3 = C.WHITE,
	}, ikonBg)

	make("TextLabel", {
		Size=UDim2.new(1,0,0,M and 12 or 14), Position=UDim2.new(0,0,1,M and -16 or -18),
		BackgroundTransparency=1, Text=item.label,
		TextSize=M and 7 or 10, Font=Enum.Font.GothamBold,
		TextColor3=item.color, TextXAlignment=Enum.TextXAlignment.Center
	}, cell)

	local accent = make("Frame", {
		Name="Accent", Size=UDim2.new(0.4,0,0,2),
		Position=UDim2.new(0.3,0,1,-3),
		BackgroundColor3=item.color, BackgroundTransparency=0.8, BorderSizePixel=0
	}, cell)
	corner(accent, 1)
	accentRefs[item.label] = accent

	if not M then
		cell.MouseEnter:Connect(function()
			if activeCell ~= cell then tw(cell, 0.12, {BackgroundColor3=C.BG2}) end
		end)
		cell.MouseLeave:Connect(function()
			if activeCell ~= cell then tw(cell, 0.12, {BackgroundColor3=C.BG3}) end
		end)
	end

	cell.MouseButton1Click:Connect(function()
		if debounce[item.label] then return end
		debounce[item.label] = true

		if activeCell and activeCell ~= cell then
			tw(activeCell, 0.15, {BackgroundColor3=C.BG3})
			local ocs = activeCell:FindFirstChildOfClass("UIStroke")
			if ocs then ocs.Color=C.BORDER; ocs.Thickness=1 end
			local oln = activeCell.Name:gsub("Btn","")
			local oac = accentRefs[oln]
			if oac then tw(oac, 0.15, {BackgroundTransparency=0.8, Size=UDim2.new(0.4,0,0,2), Position=UDim2.new(0.3,0,1,-3)}) end
		end

		activeCell = cell
		tw(cell, 0.15, {BackgroundColor3=item.bg})
		cs.Color=item.color; cs.Thickness=1.5
		tw(accent, 0.15, {BackgroundTransparency=0, Size=UDim2.new(0.7,0,0,2), Position=UDim2.new(0.15,0,1,-3)})

		local target = PANEL_MAP[item.label]
		if target then
			if target.Visible then
				TweenService:Create(target, TweenInfo.new(0.15,Enum.EasingStyle.Quint,Enum.EasingDirection.In),
					{BackgroundTransparency=1, Position=UDim2.new(0,target.Position.X.Offset,0,target.Position.Y.Offset-12)}):Play()
				task.delay(0.15, function() target.Visible=false; target.BackgroundTransparency=0 end)
				-- [P44] kosongkan slot
				if SLOT.kanan == target then SLOT.kanan = nil end
				if SLOT.kiri  == target then SLOT.kiri  = nil end
			else
				if item.label == "Spectate" then task.spawn(refreshSpec) end
				local vp = workspace.CurrentCamera.ViewportSize
				local pw = target.Size.X.Offset
				local ph = target.Size.Y.Offset
				local cx = math.floor(vp.X/2)
				local hw = math.floor(layout.pw/2)
				-- [P44] pilih slot: kanan dulu, lalu kiri, lalu gantikan yang terlama
				local posKanan = math.min(cx+hw+8, vp.X-pw-8)
				local posKiri  = math.max(8, cx-hw-pw-8)

				local slotDipakai
				if SLOT.kanan == target then slotDipakai = "kanan"
				elseif SLOT.kiri == target then slotDipakai = "kiri"
				elseif not SLOT.kanan then slotDipakai = "kanan"
				elseif not SLOT.kiri then slotDipakai = "kiri"
				else
					-- dua-duanya penuh: gantikan yang paling lama dibuka
					local terlama = table.remove(SLOT_URUT, 1)
					slotDipakai = terlama or "kanan"
					local lamaPanel = SLOT[slotDipakai]
					if lamaPanel and lamaPanel.Visible then
						local arah = (slotDipakai == "kanan") and 30 or -30
						TweenService:Create(lamaPanel, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
							{BackgroundTransparency = 1,
							 Position = UDim2.new(0, lamaPanel.Position.X.Offset + arah, 0, lamaPanel.Position.Y.Offset)}):Play()
						local lp = lamaPanel
						task.delay(0.19, function()
							if lp then lp.Visible = false; lp.BackgroundTransparency = 0 end
						end)
					end
				end

				SLOT[slotDipakai] = target
				-- catat urutan (buang duplikat dulu)
				for idx = #SLOT_URUT, 1, -1 do
					if SLOT_URUT[idx] == slotDipakai then table.remove(SLOT_URUT, idx) end
				end
				table.insert(SLOT_URUT, slotDipakai)

				local sx = (slotDipakai == "kanan") and posKanan or posKiri
				-- masuk dari sisi luar supaya animasinya terasa mengalir
				local sxAwal = (slotDipakai == "kanan") and (sx + 28) or (sx - 28)
				local sy = math.min(layout.sy, vp.Y-ph-8)
				target.BackgroundTransparency = 1
				target.Position = UDim2.new(0, sxAwal or sx, 0, sy)
				target.Visible = true
				TweenService:Create(target, TweenInfo.new(0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
					{BackgroundTransparency=0, Position=UDim2.new(0,sx,0,sy)}):Play()
			end
		end
		task.delay(0.3, function() debounce[item.label]=false end)
	end)
end

local function makeSubPanel(title, w, h)
	w = w or layout.sw; h = h or layout.sh2
	local vp = workspace.CurrentCamera.ViewportSize
	local p = make("Frame", {
		Size=UDim2.new(0,w,0,h),
		Position=UDim2.new(0,math.floor(vp.X/2-w/2),0,layout.sy),
		BackgroundColor3=C.BG, BackgroundTransparency=0.5, BorderSizePixel=0, Visible=false
	}, sg)
	corner(p, 12); stroke(p, C.BORDC, 1.5)

	local phH = M and 36 or 40
	local ph2 = make("Frame", {Size=UDim2.new(1,0,0,phH), BackgroundColor3=C.BG2, BackgroundTransparency=0.35, BorderSizePixel=0}, p)
	corner(ph2, 12)

	make("TextLabel", {
		Size=UDim2.new(1,-50,1,0), Position=UDim2.new(0,12,0,0),
		BackgroundTransparency=1, Text=title,
		TextSize=M and 10 or 12, Font=Enum.Font.GothamBold,
		TextColor3=C.CYAN, TextXAlignment=Enum.TextXAlignment.Left
	}, ph2)

	local cls = make("TextButton", {
		Size=UDim2.new(0,M and 48 or 54,0,M and 22 or 25),
		Position=UDim2.new(1,-(M and 56 or 62),0.5,-(M and 11 or 12)),
		BackgroundColor3=C.REDBG, BorderSizePixel=0,
		Text="Tutup", TextSize=M and 9 or 11,
		Font=Enum.Font.GothamBold, TextColor3=C.RED, AutoButtonColor=false
	}, ph2)
	corner(cls, 10); stroke(cls, C.RED, 1)
	cls.MouseButton1Click:Connect(function()
		TweenService:Create(p, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{BackgroundTransparency = 1}):Play()
		task.delay(0.17, function()
			p.Visible = false; p.BackgroundTransparency = 0
			if SLOT then
				if SLOT.kanan == p then SLOT.kanan = nil end
				if SLOT.kiri  == p then SLOT.kiri  = nil end
			end
		end)
	end)

	make("Frame", {
		Size=UDim2.new(1,-16,0,1), Position=UDim2.new(0,8,0,phH),
		BackgroundColor3=C.CYND, BorderSizePixel=0
	}, p)

	local cont = make("ScrollingFrame", {
		Name="Content",
		Size=UDim2.new(1,-10,1,-(phH+6)), Position=UDim2.new(0,5,0,phH+4),
		BackgroundTransparency=1, BorderSizePixel=0,
		ScrollBarThickness=3, ScrollBarImageColor3=C.CYAN,
		CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y
	}, p)
	make("UIPadding", {PaddingTop=UDim.new(0,5), PaddingLeft=UDim.new(0,4), PaddingRight=UDim.new(0,4)}, cont)
	make("UIListLayout", {Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder}, cont)

	return p, cont
end

local musikP,  musikC   = makeSubPanel("🎵  Musik")
local emoteP,  emoteC   = makeSubPanel("💃  Emote")
local avatarP, avatarC  = makeSubPanel("👤  Avatar", math.min(layout.sw+80,420), math.min(layout.sh2+120,520))
local settingP,settingC = makeSubPanel("⚙️  Setting")
local camP,    camC     = makeSubPanel("📷  Kamera", math.min(layout.sw,280), math.min(layout.sh2,200))
local specP,   specC    = makeSubPanel("👁️  Spectate", math.min(layout.sw,300), math.min(layout.sh2,360))
local donP,    donC     = makeSubPanel("💎  Donasi", math.min(layout.sw+20,320), math.min(layout.sh2,400))
local shopP,   shopC    = makeSubPanel("🛒  Shop", math.min(layout.sw,280), math.min(layout.sh2,200))

musikP.Name="MusikPanel"; emoteP.Name="EmotePanel"
settingP.Name="SettingPanel"; avatarP.Name="AvatarPanel"
camP.Name="KameraPanel"; specP.Name="SpectatePanel"
donP.Name="DonasiPanel"; shopP.Name="ShopPanel"

PANEL_MAP = {
	Musik=musikP, Emote=emoteP, Avatar=avatarP, Setting=settingP,
	Kamera=camP,  Spectate=specP, Donasi=donP,  Shop=shopP,
}

-- ── KAMERA ──
local freecamActive = false
local freecamToggleBE = nil

task.spawn(function()
	local RS = game:GetService("ReplicatedStorage")
	local t0 = tick()
	while not freecamToggleBE and (tick()-t0) < 10 do
		freecamToggleBE = RS:FindFirstChild("FreecamToggle")
		if not freecamToggleBE then task.wait(0.2) end
	end
end)

local freecamBtn = make("TextButton", {
	Size=UDim2.new(1,0,0,M and 38 or 44),
	BackgroundColor3=C.BG3, BorderSizePixel=0,
	Text="📷  Freecam: OFF", TextSize=M and 10 or 12,
	Font=Enum.Font.GothamBold, TextColor3=Color3.fromRGB(245,175,40),
	AutoButtonColor=false, LayoutOrder=1
}, camC)
corner(freecamBtn, 8)
local freecamStroke = stroke(freecamBtn, Color3.fromRGB(245,175,40), 1)

local function updateFreecamBtn()
	if freecamActive then
		freecamBtn.Text = "📷  Freecam: ON"; freecamBtn.TextColor3 = C.GREEN
		freecamStroke.Color = C.GREEN; tw(freecamBtn, 0.15, {BackgroundColor3=C.GREENBG})
	else
		freecamBtn.Text = "📷  Freecam: OFF"; freecamBtn.TextColor3 = Color3.fromRGB(245,175,40)
		freecamStroke.Color = Color3.fromRGB(245,175,40); tw(freecamBtn, 0.15, {BackgroundColor3=C.BG3})
	end
end

freecamBtn.MouseButton1Click:Connect(function()
	if not freecamToggleBE then
		freecamToggleBE = game:GetService("ReplicatedStorage"):FindFirstChild("FreecamToggle")
	end
	if freecamToggleBE then
		freecamToggleBE:Fire()
	else
		local oldText = freecamBtn.Text
		freecamBtn.Text = "⚠️  Freecam belum siap"
		task.delay(2, function() if freecamBtn and freecamBtn.Parent then freecamBtn.Text = oldText end end)
	end
end)

-- [PATCH] sinkron state freecam dari FreecamController
task.spawn(function()
	while true do
		task.wait(0.3)
		local fc = _G.ZayinFreecamActive == true
		if fc ~= freecamActive then freecamActive = fc; updateFreecamBtn() end
	end
end)

local speedLevels = {40, 80, 160, 320}
local speedIdx = 2
local speedBtn = make("TextButton", {
	Size=UDim2.new(1,0,0,M and 38 or 44),
	BackgroundColor3=C.BG3, BorderSizePixel=0,
	Text="⚡  Speed: " .. speedLevels[speedIdx],
	TextSize=M and 10 or 12, Font=Enum.Font.GothamBold,
	TextColor3=Color3.fromRGB(110,180,250), AutoButtonColor=false, LayoutOrder=2
}, camC)
corner(speedBtn, 8); stroke(speedBtn, Color3.fromRGB(110,180,250), 1)
speedBtn.MouseButton1Click:Connect(function()
	speedIdx = (speedIdx % #speedLevels) + 1
	speedBtn.Text = "⚡  Speed: " .. speedLevels[speedIdx]
	_G.ZayinFreecamSpeed = speedLevels[speedIdx]
end)

make("TextLabel", {
	Size=UDim2.new(1,0,0,M and 48 or 56), BackgroundTransparency=1,
	Text="💡  PC: Klik kanan + WASD gerak\nQ/E = naik turun  |  Shift = 2.5x cepat\nMobile: Joystick kiri + drag kanan",
	TextSize=M and 8 or 10, Font=Enum.Font.Gotham, TextColor3=C.TEXTS,
	TextXAlignment=Enum.TextXAlignment.Center, TextYAlignment=Enum.TextYAlignment.Center,
	TextWrapped=true, LayoutOrder=3
}, camC)

-- ── SPECTATE ──
local specCurrentIdx   = 1
local specPlayers      = {}
local specActivePlayer = nil

local specIndicator = make("TextLabel", {
	Size=UDim2.new(0,200,0,M and 20 or 24),
	AnchorPoint=Vector2.new(0.5,0),
	Position=UDim2.new(0.5,0,0,layout.by+layout.bh+6+layout.ph+10),
	BackgroundColor3=Color3.fromRGB(0,30,18), BackgroundTransparency=0.2,
	BorderSizePixel=0, Text="", TextSize=M and 9 or 11,
	Font=Enum.Font.GothamBold, TextColor3=C.GREEN,
	TextXAlignment=Enum.TextXAlignment.Center, Visible=false, ZIndex=12,
}, sg)
corner(specIndicator, 12); stroke(specIndicator, C.GREEN, 1)

local function stopSpectate()
	specActivePlayer = nil; specIndicator.Visible = false
	local cam = workspace.CurrentCamera
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then cam.CameraSubject = hum end
		cam.CameraType = Enum.CameraType.Custom
	end
end

local function doSpectate(p)
	if not p or not p.Parent then return end
	specActivePlayer = p
	local cam = workspace.CurrentCamera
	local char = p.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		cam.CameraSubject = hum or char.PrimaryPart
		cam.CameraType = Enum.CameraType.Follow
	end
	specIndicator.Text = "👁️  Spectating: " .. p.DisplayName
	specIndicator.Visible = true
end

refreshSpec = function()
	if not specC then return end
	for _, c in pairs(specC:GetChildren()) do
		if not (c:IsA("UIListLayout") or c:IsA("UIPadding")) then c:Destroy() end
	end
	specPlayers = {}
		for _, p in pairs(Players:GetPlayers()) do
		if p ~= player then
			local rid = p:GetAttribute("RoleId")
			local RS2 = game:GetService("ReplicatedStorage")
			local ok2, GC2 = pcall(function() return _specGC end)
			local canSpec = true
			if ok2 and GC2 and GC2.Spectate then
				canSpec = GC2.Spectate[rid or "Player"] ~= false
			end
			if canSpec then table.insert(specPlayers, p) end
		end
	end

	local hdrH2 = M and 38 or 44
	local hdrFrame = make("Frame", {
		Size=UDim2.new(1,0,0,hdrH2), BackgroundColor3=C.BG2, BackgroundTransparency=0.35,
		BorderSizePixel=0, LayoutOrder=0
	}, specC)
	corner(hdrFrame, 8)

	local prevBtn = make("TextButton", {
		Size=UDim2.fromOffset(M and 34 or 40, M and 28 or 32),
		Position=UDim2.new(0,4,0.5,-(M and 14 or 16)),
		BackgroundColor3=C.BG3, BorderSizePixel=0,
		Text="◀", TextColor3=C.CYAN, Font=Enum.Font.GothamBold,
		TextSize=M and 12 or 14, AutoButtonColor=false
	}, hdrFrame)
	corner(prevBtn, 6); stroke(prevBtn, C.CYND, 1)

	local stopBtn = make("TextButton", {
		Size=UDim2.new(1,-(M and 88 or 100),1,-8), Position=UDim2.new(0,M and 42 or 48,0,4),
		BackgroundColor3=Color3.fromRGB(80,10,10), BorderSizePixel=0,
		Text="⏹  Stop Spectate", TextColor3=Color3.fromRGB(255,100,100),
		Font=Enum.Font.GothamBold, TextSize=M and 9 or 11, AutoButtonColor=false
	}, hdrFrame)
	corner(stopBtn, 6); stroke(stopBtn, Color3.fromRGB(200,40,40), 1)

	local nextBtn = make("TextButton", {
		Size=UDim2.fromOffset(M and 34 or 40, M and 28 or 32),
		Position=UDim2.new(1,-(M and 38 or 44),0.5,-(M and 14 or 16)),
		BackgroundColor3=C.BG3, BorderSizePixel=0,
		Text="▶", TextColor3=C.CYAN, Font=Enum.Font.GothamBold,
		TextSize=M and 12 or 14, AutoButtonColor=false
	}, hdrFrame)
	corner(nextBtn, 6); stroke(nextBtn, C.CYND, 1)

	make("TextLabel", {
		Size=UDim2.new(1,0,0,M and 18 or 22), BackgroundTransparency=1,
		Text="👥  " .. #specPlayers .. " player di server",
		TextSize=M and 8 or 10, Font=Enum.Font.Gotham, TextColor3=C.TEXTS,
		TextXAlignment=Enum.TextXAlignment.Center, LayoutOrder=1
	}, specC)

	if #specPlayers == 0 then
		make("TextLabel", {
			Size=UDim2.new(1,0,0,60), BackgroundTransparency=1,
			Text="😴  Tidak ada player lain\ndi server ini",
			TextSize=M and 10 or 12, Font=Enum.Font.Gotham, TextColor3=C.TEXTS,
			TextXAlignment=Enum.TextXAlignment.Center, TextYAlignment=Enum.TextYAlignment.Center, LayoutOrder=2
		}, specC)
		stopSpectate(); return
	end

	stopBtn.MouseButton1Click:Connect(stopSpectate)
	prevBtn.MouseButton1Click:Connect(function()
		if #specPlayers == 0 then return end
		specCurrentIdx = specCurrentIdx - 1
		if specCurrentIdx < 1 then specCurrentIdx = #specPlayers end
		doSpectate(specPlayers[specCurrentIdx])
	end)
	nextBtn.MouseButton1Click:Connect(function()
		if #specPlayers == 0 then return end
		specCurrentIdx = specCurrentIdx + 1
		if specCurrentIdx > #specPlayers then specCurrentIdx = 1 end
		doSpectate(specPlayers[specCurrentIdx])
	end)

	local COLS = M and 2 or 3
	local CELL = math.floor(((M and 230 or 260) / COLS) - 8)
	local gridFrame = make("Frame", {
		Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1, BorderSizePixel=0, LayoutOrder=3
	}, specC)
	make("UIGridLayout", {
		CellSize=UDim2.fromOffset(CELL, CELL+28), CellPadding=UDim2.fromOffset(6,6),
		HorizontalAlignment=Enum.HorizontalAlignment.Center, SortOrder=Enum.SortOrder.LayoutOrder
	}, gridFrame)
	make("UIPadding", {PaddingTop=UDim.new(0,4)}, gridFrame)

	for idx, p in ipairs(specPlayers) do
		local cell = make("Frame", {
			Name="Cell_"..p.Name, BackgroundColor3=C.BG3,
			BorderSizePixel=0, LayoutOrder=idx
		}, gridFrame)
		corner(cell, 12); stroke(cell, C.CYND, 1)

		local av = make("ImageLabel", {
			Size=UDim2.fromOffset(CELL-14, CELL-14),
			Position=UDim2.new(0.5,0,0,4), AnchorPoint=Vector2.new(0.5,0),
			BackgroundColor3=C.BG2, BorderSizePixel=0
		}, cell)
		corner(av, 100); stroke(av, C.CYND, 1.5)
		task.spawn(function()
			local ok, url = pcall(function()
				return Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
			end)
			if ok and av.Parent then av.Image = url end
		end)

		make("TextLabel", {
			Size=UDim2.new(1,-4,0,14), Position=UDim2.new(0,2,1,-28),
			BackgroundTransparency=1, Text=p.DisplayName,
			TextSize=M and 9 or 10, Font=Enum.Font.GothamBold, TextColor3=C.CYAN,
			TextTruncate=Enum.TextTruncate.AtEnd, TextXAlignment=Enum.TextXAlignment.Center
		}, cell)

		local ls = p:FindFirstChild("leaderstats")
		local summit = ls and ls:FindFirstChild("Summit")
		local posisi = ls and ls:FindFirstChild("Posisi")
		make("TextLabel", {
			Size=UDim2.new(1,-4,0,12), Position=UDim2.new(0,2,1,-14),
			BackgroundTransparency=1,
			Text=(summit and tostring(summit.Value).."⛰" or "0⛰").." "..(posisi and tostring(posisi.Value) or ""),
			TextSize=M and 8 or 9, Font=Enum.Font.Gotham, TextColor3=C.TEXTS,
			TextTruncate=Enum.TextTruncate.AtEnd, TextXAlignment=Enum.TextXAlignment.Center
		}, cell)

		local btn = make("TextButton", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=5}, cell)
		local pidx = idx
		btn.MouseButton1Click:Connect(function() specCurrentIdx = pidx; doSpectate(p) end)
	end
end

Players.PlayerAdded:Connect(function()
	if specP and specP.Visible then task.spawn(refreshSpec) end
end)
Players.PlayerRemoving:Connect(function(p)
	if specActivePlayer == p then stopSpectate() end
	if specP and specP.Visible then task.spawn(refreshSpec) end
end)

-- ── DONASI ──
task.spawn(function()
	task.wait(0.5)
	local ok, Cfg = pcall(function()
		local SDC2 = require(game:GetService("ReplicatedStorage"):WaitForChild("ZayinConfig", 10):WaitForChild("ShopDonationConfig", 10))
		return SDC2.Donation
	end)
	if not (ok and Cfg and Cfg.Products) then return end
	for i, p in ipairs(Cfg.Products) do
		local btn = make("TextButton", {
			Size=UDim2.new(1,0,0,M and 36 or 40),
			BackgroundColor3=Color3.fromRGB(22,24,32), BorderSizePixel=0,
			Text="💎 "..p.Label.."  —  R$ "..p.Robux,
			TextColor3=Color3.fromRGB(220,230,240), Font=Enum.Font.GothamBold,
			TextSize=M and 10 or 11, AutoButtonColor=false, LayoutOrder=i
		}, donC)
		corner(btn, 8)
		btn.MouseEnter:Connect(function() btn.BackgroundColor3=Color3.fromRGB(28,30,40) end)
		btn.MouseLeave:Connect(function() btn.BackgroundColor3=Color3.fromRGB(22,24,32) end)
		btn.MouseButton1Click:Connect(function()
			pcall(function()
				game:GetService("MarketplaceService"):PromptProductPurchase(Players.LocalPlayer, p.ProductId)
			end)
		end)
	end
end)

-- ── SHOP ──
make("TextLabel", {
	Size=UDim2.new(1,0,0,120), BackgroundTransparency=1,
	Text="🛒\n\nComing Soon!", TextSize=M and 14 or 16,
	Font=Enum.Font.GothamBold, TextColor3=C.CYAN,
	TextXAlignment=Enum.TextXAlignment.Center, TextYAlignment=Enum.TextYAlignment.Center, LayoutOrder=0
}, shopC)

-- ── TOGGLE MENU ──
local function openMenu()
	panelOpen = true
	panel.Position = UDim2.new(0.5,0,0,layout.by+layout.bh+6)
	panel.Visible = true
	panel.Size = UDim2.new(0,layout.pw,0,0); panel.BackgroundTransparency = 1
	grid.Visible = false
	TweenService:Create(panel, TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
		{Size=UDim2.new(0,layout.pw,0,layout.ph), BackgroundTransparency=0}):Play()
	task.delay(0.14, function() grid.Visible=true end)
end

local function closeMenu()
	panelOpen = false; grid.Visible = false -- [P45] panel samping dibiarkan terbuka
	TweenService:Create(panel, TweenInfo.new(0.18,Enum.EasingStyle.Quint,Enum.EasingDirection.In),
		{Size=UDim2.new(0,layout.pw,0,0), BackgroundTransparency=1}):Play()
	task.delay(0.18, function() panel.Visible=false end)
end
-- [P46] closeMenuAll: tutup menu utama SEKALIGUS semua panel samping
local function closeMenuAll()
	closeAllSub()
	if panelOpen then closeMenu() end
end

menuBtn.MouseButton1Click:Connect(function()
	if btnDeb then return end; btnDeb = true
	if panelOpen then closeMenuAll() else openMenu() end
	task.delay(0.35, function() btnDeb=false end)
end)
closeBtn.MouseButton1Click:Connect(function() if panelOpen then closeMenu() end end)

-- ── RESPONSIVE ROTATE (Mobile)
-- FIX: pakai GetPropertyChangedSignal bukan Heartbeat tiap frame
if M then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		local nl = L()
		menuBtn.Size = UDim2.new(0,nl.bw,0,nl.bh)
		menuBtn.Position = UDim2.new(0.5,0,0,nl.by)
		if panelOpen then
			panel.Size = UDim2.new(0,nl.pw,0,nl.ph)
			panel.Position = UDim2.new(0.5,0,0,nl.by+nl.bh+6)
		end
		gl.CellSize = UDim2.new(0,nl.cw,0,nl.ch)
		gl.CellPadding = UDim2.new(0,nl.cp,0,nl.cp)
	end)
end

-- [PATCH] dummy ListGui dihapus (SettingShiftlock lama tidak dipakai lagi)

-- ============================================================
-- TOP RIGHT BUTTONS — [Reset BC] [Leaderstat] [Hide UI]
-- Bentuk lingkaran, pojok kanan atas
-- ============================================================
local RS_TR = game:GetService("ReplicatedStorage")

local BTN_SIZE  = M and 36 or 42
local BTN_GAP   = M and 6 or 8
local BTN_TOP   = M and 8 or 10
local BTN_RIGHT = M and 8 or 12

local function makeCircleBtn(icon, color, bgColor, order, tooltip)
	local btn = make("TextButton", {
		Name = "TopBtn_"..order,
		Size = UDim2.fromOffset(BTN_SIZE, BTN_SIZE),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1,
			-(BTN_RIGHT + (BTN_SIZE + BTN_GAP) * (order - 1)),
			0, BTN_TOP),
		BackgroundColor3 = bgColor,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Text = icon,
		TextColor3 = color,
		Font = Enum.Font.GothamBold,
		TextSize = M and 14 or 17,
		AutoButtonColor = false,
		ZIndex = 15,
	}, sg)
	corner(btn, 100)

	local btnStroke = make("UIStroke", {
		Color = color, Thickness = 1.5, Transparency = 0.4,
	}, btn)
	btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	btn.MouseEnter:Connect(function()
		tw(btn, 0.12, {BackgroundTransparency = 0})
		btnStroke.Transparency = 0
	end)
	btn.MouseLeave:Connect(function()
		tw(btn, 0.12, {BackgroundTransparency = 0.15})
		btnStroke.Transparency = 0.4
	end)

	-- Tooltip desktop only
	if not M and tooltip then
		local tip = make("TextLabel", {
			Size = UDim2.new(0, 0, 0, 22),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 1, 4),
			BackgroundColor3 = Color3.fromRGB(10, 10, 14),
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			Text = tooltip,
			TextColor3 = color,
			Font = Enum.Font.GothamBold,
			TextSize = 9,
			AutomaticSize = Enum.AutomaticSize.X,
			Visible = false,
			ZIndex = 20,
		}, btn)
		make("UIPadding", {
			PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
		}, tip)
		corner(tip, 6)
		btn.MouseEnter:Connect(function() tip.Visible = true end)
		btn.MouseLeave:Connect(function() tip.Visible = false end)
	end

	return btn, btnStroke
end

-- ── 1. Hide UI (paling kanan) ────────────────────────────────
local uiHidden     = false
local hiddenGuiList = {}

local hideBtn, hideStroke = makeCircleBtn(
	"👁️",
	Color3.fromRGB(120, 140, 160),
	Color3.fromRGB(16, 18, 24),
	1, "Hide UI"
)

local function updateHideBtn()
	if uiHidden then
		hideBtn.Text       = "🙈"
		hideBtn.TextColor3 = Color3.fromRGB(255, 75, 75)
		hideStroke.Color   = Color3.fromRGB(255, 75, 75)
		tw(hideBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(32, 10, 10)})
	else
		hideBtn.Text       = "👁️"
		hideBtn.TextColor3 = Color3.fromRGB(120, 140, 160)
		hideStroke.Color   = Color3.fromRGB(120, 140, 160)
		tw(hideBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(16, 18, 24)})
	end
end

hideBtn.MouseButton1Click:Connect(function()
	uiHidden = not uiHidden
	if uiHidden then
		hiddenGuiList = {}
		for _, gui in pairs(playerGui:GetChildren()) do
			if gui:IsA("ScreenGui") and gui.Enabled
				and gui.Name ~= "ZayinMenuBaru"
				and gui.Name ~= "ZayinTimerGui"
				and gui.Name ~= "FreecamExitGui"
				and gui.Name ~= "FreecamMobileGui" then
				gui.Enabled = false
				table.insert(hiddenGuiList, gui)
			end
		end
		-- Sembunyikan panel + tombol menu utama
		if panelOpen then closeMenu() end
		menuBtn.Visible = false
	else
		for _, gui in ipairs(hiddenGuiList) do
			if gui and gui.Parent then gui.Enabled = true end
		end
		hiddenGuiList = {}
		menuBtn.Visible = true
	end
	updateHideBtn()
end)

-- ── 2. Leaderstat (tengah) ───────────────────────────────────
local lsBtn, lsStroke = makeCircleBtn(
	"🏆",
	Color3.fromRGB(0, 210, 200),
	Color3.fromRGB(0, 22, 20),
	2, "Leaderboard"
)

-- FIX: 1 klik = toggle. Biarkan LeaderstatClient handle open/close via ToggleRequest.
-- ZayinMenuBaru hanya kirim sinyal, tidak duplikat logic animasi.
local lsDeb = false
lsBtn.MouseButton1Click:Connect(function()
	if lsDeb then return end
	lsDeb = true

	local lsGui = playerGui:FindFirstChild("CustomLeaderstatGui")
	if lsGui then
		-- Kirim toggle signal ke LeaderstatClient (1 klik = 1 toggle)
		lsGui:SetAttribute("ToggleRequest", not (lsGui:GetAttribute("ToggleRequest") or false))
	end

	task.delay(0.35, function() lsDeb = false end)
end)

-- [PATCH] Sync highlight tombol via attribute signal (tanpa polling)
task.spawn(function()
	local lsGui = playerGui:WaitForChild("CustomLeaderstatGui", 15)
	if not lsGui then return end
	local function syncLs()
		local open = lsGui:GetAttribute("IsOpen") == true
		lsStroke.Transparency = open and 0 or 0.4
		lsBtn.BackgroundColor3 = open and Color3.fromRGB(0, 40, 38) or Color3.fromRGB(0, 22, 20)
	end
	lsGui:GetAttributeChangedSignal("IsOpen"):Connect(syncLs)
	syncLs()
end)

-- ── 3. Reset BC (paling kiri) + Konfirmasi ───────────────────
local resetBCBtn, resetBCStroke = makeCircleBtn(
	"🏠",
	Color3.fromRGB(255, 175, 40),
	Color3.fromRGB(30, 20, 0),
	3, "Reset ke BC"
)

-- Popup konfirmasi Reset BC
local confirmPopup = nil
local function showResetConfirm(onYes)
	-- [P40] dialog modern, modal di tengah layar
	if confirmPopup then confirmPopup:Destroy(); confirmPopup = nil end

	local vp = workspace.CurrentCamera.ViewportSize
	local W  = math.clamp(vp.X * (M and 0.80 or 0.28), 280, 400)
	local H  = M and 210 or 240

	-- Wadah modal (latar redup + kartu) — satu frame supaya mudah dihapus
	confirmPopup = make("Frame", {
		Name = "ResetConfirmModal",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 40,
	}, sg)

	TweenService:Create(confirmPopup, TweenInfo.new(0.18), {BackgroundTransparency = 0.45}):Play()

	-- Kartu dialog
	local card = make("Frame", {
		Size = UDim2.fromOffset(W, H),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(14, 17, 26),
		BorderSizePixel = 0,
		ZIndex = 41,
	}, confirmPopup)
	corner(card, 18)
	stroke(card, Color3.fromRGB(255, 180, 50), 2)

	-- Garis aksen atas
	local aksen = make("Frame", {
		Size = UDim2.new(1, -40, 0, 4),
		Position = UDim2.new(0, 20, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 190, 60),
		BorderSizePixel = 0,
		ZIndex = 42,
	}, card)
	corner(aksen, 4)

	-- Ikon rumah dalam lingkaran
	local ikonSz = M and 52 or 60
	local ikonBg = make("Frame", {
		Size = UDim2.fromOffset(ikonSz, ikonSz),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, M and 18 or 22),
		BackgroundColor3 = Color3.fromRGB(38, 28, 8),
		BorderSizePixel = 0,
		ZIndex = 42,
	}, card)
	corner(ikonBg, 100)
	stroke(ikonBg, Color3.fromRGB(255, 180, 50), 2)
	make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "🏠",
		TextSize = M and 26 or 30,
		Font = Enum.Font.GothamBold,
		ZIndex = 43,
	}, ikonBg)

	-- Judul
	make("TextLabel", {
		Size = UDim2.new(1, -24, 0, M and 24 or 28),
		Position = UDim2.new(0, 12, 0, (M and 18 or 22) + ikonSz + 10),
		BackgroundTransparency = 1,
		Text = "Reset ke Basecamp?",
		TextColor3 = Color3.fromRGB(255, 200, 70),
		Font = Enum.Font.GothamBold,
		TextSize = M and 17 or 20,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 42,
	}, card)

	-- Subteks
	make("TextLabel", {
		Size = UDim2.new(1, -36, 0, M and 16 or 18),
		Position = UDim2.new(0, 18, 0, (M and 18 or 22) + ikonSz + 10 + (M and 24 or 28)),
		BackgroundTransparency = 1,
		Text = "Kamu akan kembali ke titik awal pendakian",
		TextColor3 = Color3.fromRGB(150, 160, 175),
		Font = Enum.Font.Gotham,
		TextSize = M and 11 or 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextWrapped = true,
		ZIndex = 42,
	}, card)

	-- Tombol
	local BH = M and 40 or 44
	local BY = H - BH - (M and 16 or 20)

	local yaBtn = make("TextButton", {
		Size = UDim2.new(0.5, -18, 0, BH),
		Position = UDim2.new(0, 14, 0, BY),
		BackgroundColor3 = Color3.fromRGB(0, 48, 20),
		BorderSizePixel = 0,
		Text = "✓  Ya, Reset",
		TextColor3 = Color3.fromRGB(60, 230, 130),
		Font = Enum.Font.GothamBold,
		TextSize = M and 13 or 15,
		AutoButtonColor = false,
		ZIndex = 43,
	}, card)
	corner(yaBtn, 12)
	stroke(yaBtn, Color3.fromRGB(50, 210, 120), 1.5)
	yaBtn.MouseEnter:Connect(function()
		tw(yaBtn, 0.12, {BackgroundColor3 = Color3.fromRGB(0, 70, 30)})
	end)
	yaBtn.MouseLeave:Connect(function()
		tw(yaBtn, 0.12, {BackgroundColor3 = Color3.fromRGB(0, 48, 20)})
	end)

	local batalBtn = make("TextButton", {
		Size = UDim2.new(0.5, -18, 0, BH),
		Position = UDim2.new(0.5, 4, 0, BY),
		BackgroundColor3 = Color3.fromRGB(30, 32, 40),
		BorderSizePixel = 0,
		Text = "✕  Batal",
		TextColor3 = Color3.fromRGB(200, 210, 225),
		Font = Enum.Font.GothamBold,
		TextSize = M and 13 or 15,
		AutoButtonColor = false,
		ZIndex = 43,
	}, card)
	corner(batalBtn, 12)
	stroke(batalBtn, Color3.fromRGB(90, 100, 115), 1.5)
	batalBtn.MouseEnter:Connect(function()
		tw(batalBtn, 0.12, {BackgroundColor3 = Color3.fromRGB(45, 48, 58)})
	end)
	batalBtn.MouseLeave:Connect(function()
		tw(batalBtn, 0.12, {BackgroundColor3 = Color3.fromRGB(30, 32, 40)})
	end)

	-- Animasi masuk
	local sc = make("UIScale", {Scale = 0.85}, card)
	TweenService:Create(sc, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()

	local function closePopup()
		if not confirmPopup then return end
		local p = confirmPopup
		confirmPopup = nil
		TweenService:Create(p, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
		if sc then
			TweenService:Create(sc, TweenInfo.new(0.15), {Scale = 0.9}):Play()
		end
		task.delay(0.16, function()
			if p then p:Destroy() end
		end)
	end

	yaBtn.MouseButton1Click:Connect(function()
		closePopup()
		if onYes then onYes() end
	end)
	batalBtn.MouseButton1Click:Connect(closePopup)

	-- klik latar = batal
	local bgBtn = make("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 40,
	}, confirmPopup)
	bgBtn.MouseButton1Click:Connect(closePopup)
end

local resetBCDeb = false
resetBCBtn.MouseButton1Click:Connect(function()
	if resetBCDeb then return end

	-- Kalau popup sudah terbuka, tutup (toggle)
	if confirmPopup then
		confirmPopup:Destroy(); if modalBG then modalBG:Destroy() end -- [P39] hapus modal; confirmPopup = nil
		return
	end

	showResetConfirm(function()
		-- User tekan Ya
		if resetBCDeb then return end
		resetBCDeb = true

		resetBCBtn.Text = "⏳"
		resetBCStroke.Transparency = 0
		tw(resetBCBtn, 0.1, {BackgroundColor3 = Color3.fromRGB(60, 40, 0)})

		pcall(function()
			local ZR      = RS_TR:WaitForChild("ZayinRemotes", 5)
			local CPR     = ZR:WaitForChild("Checkpoint", 5)
			local ResetRE = CPR:WaitForChild("ResetToBC", 5)
			ResetRE:FireServer()
		end)

		task.delay(1.5, function()
			resetBCBtn.Text = "🏠"
			resetBCStroke.Transparency = 0.4
			tw(resetBCBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(30, 20, 0)})
			task.wait(1)
			resetBCDeb = false
		end)
	end)
end)

-- ── Sembunyikan tombol saat freecam aktif ────────────────────
task.spawn(function()
	local topBtns = {hideBtn, lsBtn, resetBCBtn}
	local _lastFcState = nil
	game:GetService("RunService").RenderStepped:Connect(function()
		local fcActive = _G.ZayinFreecamActive == true
		if fcActive == _lastFcState then return end
		_lastFcState = fcActive
		for _, b in ipairs(topBtns) do
			if b and b.Parent then b.Visible = not fcActive end
		end
	end)
end)

-- ── END TOP RIGHT BUTTONS ────────────────────────────────────

print("[ZayinMenuBaru v3.4] Ready! Mobile:", M)

-- [P55] transparansi panel: 50% untuk panel utama & sub-panel
task.spawn(function()
	local TRANS_PANEL  = 0.5   -- panel utama & sub-panel
	local TRANS_HEADER = 0.35  -- header di dalam panel

	local function terapkan()
		-- panel utama
		if panel then panel.BackgroundTransparency = TRANS_PANEL end
		if grid  then grid.BackgroundTransparency  = 1 end
		-- semua sub-panel
		if PANEL_MAP then
			for _, p in pairs(PANEL_MAP) do
				if p and p:IsA("GuiObject") then
					p.BackgroundTransparency = TRANS_PANEL
					for _, d in ipairs(p:GetChildren()) do
						if d:IsA("Frame") and d.Size.Y.Offset <= 44 and d.Size.X.Scale >= 1 then
							d.BackgroundTransparency = TRANS_HEADER
						end
					end
				end
			end
		end
	end

	for _ = 1, 20 do
		task.wait(0.5)
		pcall(terapkan)
	end
end)