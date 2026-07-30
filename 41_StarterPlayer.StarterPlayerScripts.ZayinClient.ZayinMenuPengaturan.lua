-- ============================================================
--  ZayinMenuPengaturan | LocalScript | v3.1
--  Shiftlock icon di atas tombol Jump (bukan di dalam menu)
--  Semua panel draggable, ukuran mobile optimal
-- ============================================================

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)
local char      = player.Character or player.CharacterAdded:Wait()
local M         = UIS.TouchEnabled and not UIS.KeyboardEnabled

local HideName         = require(script:WaitForChild("HideName",         10))
local HidePlayer       = require(script:WaitForChild("HidePlayer",       10))
local HideCoil         = require(script:WaitForChild("HideCoil",         10))
local GraphicMode      = require(script:WaitForChild("GraphicMode",      10))
local SettingJump      = require(script:WaitForChild("SettingJump",      10))
local MobileShiftlock = require(script:WaitForChild("MobileShiftlock", 10))

local hiddenAurasDict = {}
GraphicMode.Initialize()

local C = {
	BG1    = Color3.fromRGB(10,  10,  12),
	BG2    = Color3.fromRGB(16,  18,  22),
	BG3    = Color3.fromRGB(22,  26,  32),
	BG4    = Color3.fromRGB(28,  34,  44),
	CYAN   = Color3.fromRGB(0,   210, 200),
	CYND   = Color3.fromRGB(0,   150, 145),
	GOLD   = Color3.fromRGB(255, 200, 60),
	GREEN  = Color3.fromRGB(40,  215, 115),
	RED    = Color3.fromRGB(255, 75,  75),
	REDBG  = Color3.fromRGB(32,  10,  10),
	ORANGE = Color3.fromRGB(250, 130, 50),
	TEXT   = Color3.fromRGB(220, 230, 235),
	TEXTS  = Color3.fromRGB(120, 140, 150),
	BORDER = Color3.fromRGB(40,  40,  48),
	BORDC  = Color3.fromRGB(0,   180, 175),
	OFF    = Color3.fromRGB(38,  38,  45),
}

local function make(cls,props,parent)
	local i=Instance.new(cls)
	for k,v in pairs(props or {}) do i[k]=v end
	if parent then i.Parent=parent end; return i
end
local function corner(obj,r) make("UICorner",{CornerRadius=UDim.new(0,r or 8)},obj) end
local function stroke(obj,col,t)
	local s=make("UIStroke",{Color=col or C.BORDER,Thickness=t or 1},obj)
	s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; return s
end
local function tw(o,t,props) TweenService:Create(o,TweenInfo.new(t),props):Play() end

-- ============================================================
-- SHIFTLOCK ICON — muncul di atas tombol Jump (mobile only)
-- Posisi: tepat di atas JumpButton, bisa digeser juga
-- ============================================================
local shiftIconGui = nil
local shiftIconEnabled = false

local function findJumpButton()
	local pg = player:WaitForChild("PlayerGui",10)
	local tg = pg:FindFirstChild("TouchGui")
	if not tg then return nil end
	local cf = tg:FindFirstChild("TouchControlFrame")
	if not cf then return nil end
	return cf:FindFirstChild("JumpButton")
end

local function findShiftButton()
	local pg = player:WaitForChild("PlayerGui",10)
	local lg = pg:FindFirstChild("ListGui")
	if not lg then return nil,nil end
	local sf = lg:FindFirstChild("Shift")
	if not sf then return nil,nil end
	return sf:FindFirstChild("ShiftButton"), sf
end

local function createShiftlockIcon()
	if shiftIconGui then shiftIconGui:Destroy(); shiftIconGui=nil end
	if not M then return end

	local pg = player:WaitForChild("PlayerGui",10)
	shiftIconGui = make("ScreenGui",{
		Name="ZayinShiftlockIcon",ResetOnSpawn=false,
		DisplayOrder=20,IgnoreGuiInset=true,
	},pg)

	-- Icon button (lingkaran + panah 4 arah)
	local iconSize = 52
	local iconBtn = make("ImageButton",{
		Name="ShiftlockIconBtn",
		Size=UDim2.fromOffset(iconSize,iconSize),
		Position=UDim2.new(1,-iconSize-10,1,-iconSize-10), -- default kanan bawah dulu
		BackgroundColor3=Color3.fromRGB(0,0,0),
		BackgroundTransparency=0.35,
		BorderSizePixel=0,
		Image="",
		AutoButtonColor=false,
	},shiftIconGui)
	corner(iconBtn,100)
	stroke(iconBtn,C.CYND,2)

	-- Panah atas
	make("TextLabel",{Size=UDim2.new(0,14,0,14),AnchorPoint=Vector2.new(0.5,0),
		Position=UDim2.new(0.5,0,0,3),BackgroundTransparency=1,Text="▲",
		TextScaled=false,TextSize=10,Font=Enum.Font.GothamBold,TextColor3=C.CYAN},iconBtn)
	-- Panah bawah
	make("TextLabel",{Size=UDim2.new(0,14,0,14),AnchorPoint=Vector2.new(0.5,1),
		Position=UDim2.new(0.5,0,1,-3),BackgroundTransparency=1,Text="▼",
		TextScaled=false,TextSize=10,Font=Enum.Font.GothamBold,TextColor3=C.CYAN},iconBtn)
	-- Panah kiri
	make("TextLabel",{Size=UDim2.new(0,14,0,14),AnchorPoint=Vector2.new(0,0.5),
		Position=UDim2.new(0,3,0.5,0),BackgroundTransparency=1,Text="◀",
		TextScaled=false,TextSize=10,Font=Enum.Font.GothamBold,TextColor3=C.CYAN},iconBtn)
	-- Panah kanan
	make("TextLabel",{Size=UDim2.new(0,14,0,14),AnchorPoint=Vector2.new(1,0.5),
		Position=UDim2.new(1,-3,0.5,0),BackgroundTransparency=1,Text="▶",
		TextScaled=false,TextSize=10,Font=Enum.Font.GothamBold,TextColor3=C.CYAN},iconBtn)
	-- Titik tengah
	local dot=make("Frame",{Size=UDim2.fromOffset(7,7),AnchorPoint=Vector2.new(0.5,0.5),
		Position=UDim2.new(0.5,0,0.5,0),BackgroundColor3=C.CYAN,BorderSizePixel=0},iconBtn)
	corner(dot,100)

	-- State shiftlock aktif/nonaktif
	local shiftActive = false
	local function updateShiftIcon()
		if shiftActive then
			tw(iconBtn,0.15,{BackgroundTransparency=0.05})
			stroke(iconBtn,C.GREEN,2.5)
			dot.BackgroundColor3=C.GREEN
		else
			tw(iconBtn,0.15,{BackgroundTransparency=0.35})
			stroke(iconBtn,C.CYND,2)
			dot.BackgroundColor3=C.CYAN
		end
	end

	iconBtn.MouseButton1Click:Connect(function()
		MobileShiftlock.Toggle()
		shiftActive = MobileShiftlock.IsActive()
		updateShiftIcon()
	end)


	-- Posisikan icon di atas tombol Jump secara otomatis
	local function positionAboveJump()
		local jumpBtn = findJumpButton()
		if jumpBtn then
			local jPos  = jumpBtn.AbsolutePosition
			local jSize = jumpBtn.AbsoluteSize
			local vp    = workspace.CurrentCamera.ViewportSize
			-- Tepat di atas jump button, di tengahnya
			local ix = math.clamp(jPos.X + jSize.X/2 - iconSize/2, 4, vp.X - iconSize - 4)
			local iy = math.clamp(jPos.Y - iconSize - 8, 4, vp.Y - iconSize - 4)
			iconBtn.Position = UDim2.fromOffset(ix, iy)
		end
	end

	-- Update posisi tiap frame sampai jump button ditemukan
	local conn
	conn = RunService.RenderStepped:Connect(function()
		positionAboveJump()
		-- Jika sudah dapat posisi, berhenti update tiap frame
		-- tapi tetap update saat resize
	end)

	-- Drag support untuk icon shiftlock
	local dragging=false; local dragStart,startPos2
	iconBtn.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.Touch then
			-- Jika hold > 0.4 detik = drag mode, tap cepat = toggle
			local t0=tick()
			input.Changed:Connect(function()
				if input.UserInputState==Enum.UserInputState.End then
					if tick()-t0 < 0.35 then
						-- tap cepat: toggle shiftlock sudah di MouseButton1Click
					else
						dragging=false
					end
				end
			end)
		end
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
			dragStart=input.Position; startPos2=iconBtn.Position
			input.Changed:Connect(function()
				if input.UserInputState==Enum.UserInputState.End then dragging=false end
			end)
		end
	end)
	iconBtn.InputChanged:Connect(function(input)
		if (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
			if dragStart then
				local delta=input.Position-dragStart
				if delta.Magnitude > 8 then -- minimal geser 8px baru drag
					dragging=true
					conn:Disconnect() -- stop auto-position saat drag
					local vp=workspace.CurrentCamera.ViewportSize
					local nx=math.clamp(startPos2.X.Offset+delta.X,0,vp.X-iconSize)
					local ny=math.clamp(startPos2.Y.Offset+delta.Y,0,vp.Y-iconSize)
					iconBtn.Position=UDim2.fromOffset(nx,ny)
				end
			end
		end
	end)

	shiftIconGui.Destroying:Connect(function()
		if conn then conn:Disconnect() end
	end)

	return shiftIconGui
end

local function showShiftIcon(show)
	shiftIconEnabled = show
	if show then
		if not shiftIconGui or not shiftIconGui.Parent then
			createShiftlockIcon()
		end
		if shiftIconGui then shiftIconGui.Enabled=true end
	else
		if shiftIconGui then shiftIconGui.Enabled=false end
	end
end

-- ============================================================
-- HELPERS UI
-- ============================================================
local function makeSep(parent,text,lo)
	local f=make("Frame",{Size=UDim2.new(1,0,0,M and 26 or 32),BackgroundColor3=C.BG2,
		BorderSizePixel=0,LayoutOrder=lo},parent)
	corner(f,6); stroke(f,C.CYND,1)
	make("TextLabel",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,10,0,0),
		BackgroundTransparency=1,Text=text,TextColor3=C.CYAN,Font=Enum.Font.GothamBold,
		TextSize=M and 9 or 12,TextXAlignment=Enum.TextXAlignment.Left},f)
	return f
end

local function makeToggle(parent,icon,label,lo,onToggle)
	local row=make("Frame",{Size=UDim2.new(1,0,0,M and 44 or 52),
		BackgroundColor3=C.BG3,BorderSizePixel=0,LayoutOrder=lo},parent)
	corner(row,10); stroke(row,C.BORDER,1)
	local ic=make("TextLabel",{Size=UDim2.new(0,M and 30 or 38,0,M and 30 or 38),
		AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,8,0.5,0),
		BackgroundColor3=C.BG4,Text=icon,TextScaled=false,TextSize=M and 15 or 18,
		Font=Enum.Font.Gotham,TextColor3=C.TEXT,BorderSizePixel=0},row)
	corner(ic,8); stroke(ic,C.BORDER,1)
	make("TextLabel",{Size=UDim2.new(1,-(M and 112 or 128),1,0),
		Position=UDim2.new(0,M and 46 or 54,0,0),BackgroundTransparency=1,
		Text=label,TextColor3=C.TEXT,Font=Enum.Font.GothamBold,
		TextSize=M and 9 or 12,TextXAlignment=Enum.TextXAlignment.Left},row)
	local isOn=false
	local btn=make("TextButton",{Size=UDim2.new(0,M and 54 or 66,0,M and 24 or 30),
		AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0),
		BackgroundColor3=C.OFF,BorderSizePixel=0,Text="OFF",TextColor3=C.TEXTS,
		Font=Enum.Font.GothamBold,TextSize=M and 8 or 11,AutoButtonColor=false},row)
	corner(btn,20); local bs=stroke(btn,C.BORDER,1)
	local function refresh()
		if isOn then tw(btn,0.15,{BackgroundColor3=C.GREEN}); btn.Text="ON"; btn.TextColor3=Color3.fromRGB(0,20,10); bs.Color=C.GREEN; bs.Thickness=1.5
		else tw(btn,0.15,{BackgroundColor3=C.OFF}); btn.Text="OFF"; btn.TextColor3=C.TEXTS; bs.Color=C.BORDER; bs.Thickness=1 end
	end
	btn.MouseButton1Click:Connect(function() isOn=not isOn; refresh(); if onToggle then onToggle(isOn) end end)
	return row, function() return isOn end, function(v) isOn=v; refresh() end
end

local function makeGraphicRow(parent,lo)
	local row=make("Frame",{Size=UDim2.new(1,0,0,M and 44 or 52),
		BackgroundColor3=C.BG3,BorderSizePixel=0,LayoutOrder=lo},parent)
	corner(row,10); stroke(row,C.BORDER,1)
	local ic=make("TextLabel",{Size=UDim2.new(0,M and 30 or 38,0,M and 30 or 38),
		AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,8,0.5,0),
		BackgroundColor3=C.BG4,Text="🎨",TextScaled=false,TextSize=M and 15 or 18,
		Font=Enum.Font.Gotham,TextColor3=C.TEXT,BorderSizePixel=0},row)
	corner(ic,8); stroke(ic,C.BORDER,1)
	make("TextLabel",{Size=UDim2.new(0.42,0,1,0),Position=UDim2.new(0,M and 46 or 54,0,0),
		BackgroundTransparency=1,Text="Kualitas Grafis",TextColor3=C.TEXT,
		Font=Enum.Font.GothamBold,TextSize=M and 9 or 12,TextXAlignment=Enum.TextXAlignment.Left},row)
	local LEVELS={"Auto","Low","Medium","High"}; local cur=1
	local lbl=make("TextButton",{Size=UDim2.new(0,M and 68 or 82,0,M and 24 or 30),
		AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0),
		BackgroundColor3=C.BG4,Text=LEVELS[cur],TextColor3=C.CYAN,
		Font=Enum.Font.GothamBold,TextSize=M and 8 or 11,BorderSizePixel=0,AutoButtonColor=false},row)
	corner(lbl,8); stroke(lbl,C.CYAN,1)
	lbl.MouseButton1Click:Connect(function()
		cur=(cur%#LEVELS)+1; lbl.Text=LEVELS[cur]
		pcall(function() GraphicMode.ToggleGraphic(LEVELS[cur]=="Low",HideCoil,hiddenAurasDict) end)
	end)
	return row
end

local function makeActionRow(parent,icon,label,btnText,btnColor,lo,onAction)
	local row=make("Frame",{Size=UDim2.new(1,0,0,M and 44 or 52),
		BackgroundColor3=C.BG3,BorderSizePixel=0,LayoutOrder=lo},parent)
	corner(row,10); stroke(row,C.BORDER,1)
	local ic=make("TextLabel",{Size=UDim2.new(0,M and 30 or 38,0,M and 30 or 38),
		AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,8,0.5,0),
		BackgroundColor3=C.BG4,Text=icon,TextScaled=false,TextSize=M and 15 or 18,
		Font=Enum.Font.Gotham,TextColor3=C.TEXT,BorderSizePixel=0},row)
	corner(ic,8); stroke(ic,C.BORDER,1)
	make("TextLabel",{Size=UDim2.new(1,-(M and 112 or 128),1,0),
		Position=UDim2.new(0,M and 46 or 54,0,0),BackgroundTransparency=1,
		Text=label,TextColor3=C.TEXT,Font=Enum.Font.GothamBold,
		TextSize=M and 9 or 12,TextXAlignment=Enum.TextXAlignment.Left},row)
	local btn=make("TextButton",{Size=UDim2.new(0,M and 54 or 66,0,M and 24 or 30),
		AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0),
		BackgroundColor3=C.BG4,BorderSizePixel=0,Text=btnText,
		TextColor3=btnColor or C.CYAN,Font=Enum.Font.GothamBold,
		TextSize=M and 8 or 11,AutoButtonColor=false},row)
	corner(btn,8); stroke(btn,btnColor or C.CYAN,1)
	local isAdjusting=false
	btn.MouseButton1Click:Connect(function()
		isAdjusting=not isAdjusting
		if isAdjusting then
			btn.Text="SELESAI"; btn.TextColor3=C.GREEN; stroke(btn,C.GREEN,1)
			tw(btn,0.15,{BackgroundColor3=Color3.fromRGB(0,28,14)})
			if onAction then onAction(true) end
		else
			btn.Text=btnText; btn.TextColor3=btnColor or C.CYAN; stroke(btn,btnColor or C.CYAN,1)
			tw(btn,0.15,{BackgroundColor3=C.BG4})
			if onAction then onAction(false) end
		end
	end)
	return row,btn
end

-- Mute Boombox
local function muteBoombox(mute)
	local function muteSounds(parent)
		for _,obj in pairs(parent:GetDescendants()) do
			if obj:IsA("Sound") then obj.Volume = mute and 0 or 1 end
		end
	end
	-- Mute BoomBox milik sendiri
	local bp = player:FindFirstChild("Backpack")
	if bp then local bb=bp:FindFirstChild("BoomBox"); if bb then muteSounds(bb) end end
	if player.Character then local bb=player.Character:FindFirstChild("BoomBox"); if bb then muteSounds(bb) end end
	-- Mute BoomBox semua player lain di server (agar tidak terganggu)
	for _, p in pairs(game:GetService("Players"):GetPlayers()) do
		if p ~= player then
			if p.Character then
				local bb = p.Character:FindFirstChild("BoomBox")
				if bb then muteSounds(bb) end
				-- Cek juga Holster (BoomBox di punggung)
				local holster = p.Character:FindFirstChild("Holster")
				if holster then muteSounds(holster) end
			end
		end
	end
	_G.ZayinBoomboxMuted = mute
end
task.spawn(function()
	local function watchChar(character)
		character.ChildAdded:Connect(function(child)
			if child.Name=="BoomBox" and _G.ZayinBoomboxMuted then
				task.wait(0.1)
				for _,obj in pairs(child:GetDescendants()) do
					if obj:IsA("Sound") then obj.Volume=0 end
				end
			end
		end)
	end
	if player.Character then watchChar(player.Character) end
	player.CharacterAdded:Connect(watchChar)
end)

-- ============================================================
-- INISIALISASI
-- ============================================================
local function initialize()
	local sg=playerGui:WaitForChild("ZayinMenuBaru",15)
	if not sg then warn("[ZayinMenuPengaturan] ZayinMenuBaru tidak ditemukan!"); return end
	local settingP=sg:WaitForChild("SettingPanel",10)
	if not settingP then warn("[ZayinMenuPengaturan] SettingPanel tidak ditemukan!"); return end
	local content=settingP:WaitForChild("Content",5)
	if not content then warn("[ZayinMenuPengaturan] Content tidak ditemukan!"); return end

	for _,c in pairs(content:GetChildren()) do c:Destroy() end

	local wrapper=make("Frame",{Name="SettingUI",Size=UDim2.new(1,0,0,0),
		AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0},content)
	make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5)},wrapper)

	-- TAMPILAN
	makeSep(wrapper,"👁️  TAMPILAN",1)
	makeToggle(wrapper,"🏷️","Sembunyikan Nama Judul",2,function(on)
		pcall(function() HideName.Toggle(on) end) end)
	makeToggle(wrapper,"🌀","Sembunyikan Coil",3,function(on)
		pcall(function() HideCoil.Toggle(on,hiddenAurasDict) end) end)
	makeToggle(wrapper,"👥","Sembunyikan Player Lain",4,function(on)
		pcall(function() HidePlayer.Toggle(on) end) end)
	makeToggle(wrapper,"🌑","Sembunyikan Bayangan",5,function(on)
		pcall(function() GraphicMode.ToggleShadow(on,HideCoil,hiddenAurasDict) end) end)

	-- GRAFIS
	makeSep(wrapper,"🎨  GRAFIS",10)
	makeGraphicRow(wrapper,11)

	-- AUDIO
	makeSep(wrapper,"🔊  AUDIO",20)
	makeToggle(wrapper,"🔇","Mute Boombox",21,function(on)
		pcall(function() muteBoombox(on) end) end)

	-- KONTROL MOBILE
	makeSep(wrapper,"📱  KONTROL",30)

	if not M then
		make("TextLabel",{Size=UDim2.new(1,0,0,38),BackgroundTransparency=1,
			Text="ℹ️  Fitur ini khusus perangkat mobile",TextSize=10,Font=Enum.Font.Gotham,
			TextColor3=C.TEXTS,TextXAlignment=Enum.TextXAlignment.Center,
			TextYAlignment=Enum.TextYAlignment.Center,LayoutOrder=31},wrapper)
	else
		-- Tombol Jump Adjust
		makeActionRow(wrapper,"🕹️","Posisi Tombol Jump","ATUR",C.ORANGE,31,function(adjusting)
			pcall(function()
				SettingJump.Toggle(not adjusting,function() end,nil)
			end)
		end)

		-- Shiftlock Icon Toggle (show/hide icon di atas jump button)
		makeToggle(wrapper,"🔒","Tampilkan Icon Shiftlock",32,function(on)
			showShiftIcon(on)
		end)

		-- Info
		local info=make("Frame",{Size=UDim2.new(1,0,0,M and 46 or 54),
			BackgroundColor3=Color3.fromRGB(12,18,28),BorderSizePixel=0,LayoutOrder=33},wrapper)
		corner(info,8); stroke(info,C.CYND,1)
		make("TextLabel",{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,6,0,0),
			BackgroundTransparency=1,
			Text="💡  Icon 🔒 muncul di atas tombol Jump.\nTap icon untuk toggle shiftlock.\nTahan & seret untuk geser posisi.",
			TextSize=M and 7 or 10,Font=Enum.Font.Gotham,TextColor3=C.TEXTS,
			TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,
			TextWrapped=true},info)
	end

	-- [PATCH] SettingShiftlock dihapus
	pcall(function() SettingJump.Apply() end)

	script:SetAttribute("Ready",true)
	print("[ZayinMenuPengaturan v3.1] Ready! Mobile:",M)
end

task.spawn(function()
	task.wait(1.5)
	local ok,err=pcall(initialize)
	if not ok then warn("[ZayinMenuPengaturan ERROR]:",err) end
end)