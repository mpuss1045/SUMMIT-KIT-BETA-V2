-- FreecamController v2.0
-- Kompatibel dengan ZayinMenuBaru v3.2
-- BindableEvent dibuat lebih awal sebelum apapun

local Players              = game:GetService("Players")
local RunService           = game:GetService("RunService")
local UserInputService     = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RS                   = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera    = workspace.CurrentCamera

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local isActive     = false
local savedCamType = nil
local isRightClick = false
local speed        = 80
local sensitivity  = 0.4
local yaw, pitch   = 0, 0
local hiddenGuis   = {}
local savedHum     = nil

-- Mobile joystick state
local joystickMove = Vector2.new(0, 0)
local lookDelta    = Vector2.new(0, 0)
local joystickTouchId  = nil
local lookTouchId      = nil
local joystickCenter   = Vector2.new(0, 0)

-- ============================================================
-- BUAT BINDABLEEVENT LEBIH AWAL (sebelum apapun)
-- ============================================================
local old = RS:FindFirstChild("FreecamToggle")
if old then old:Destroy() end
local toggleBE = Instance.new("BindableEvent")
toggleBE.Name = "FreecamToggle"
toggleBE.Parent = RS
print("[FreecamController] BindableEvent FreecamToggle dibuat di ReplicatedStorage")

-- ============================================================
-- [FREECAMFIX3] Semua GUI freecam dibangun lewat FUNGSI supaya
-- bisa DIBUAT ULANG dari nol kalau ter-Destroy oleh jalur ganti
-- avatar. Objek yang sudah Destroy() Parent-nya terkunci NULL dan
-- TAK BISA di-parent ulang -> pasang-balik saja tidak cukup, harus
-- bikin baru. Ini pola yang sama dengan fix ZayinTimerGui.
-- ============================================================

-- Forward declaration (dipakai lintas fungsi)
local exitGui, exitBtn, hideBtn
local mobileGui, joyBase, joyThumb, upBtn, downBtn
local deactivateFreecam            -- didefinisikan jauh di bawah
local exitTersembunyi = false
local isUpHeld, isDownHeld = false, false

-- Toggle sembunyikan/tampilkan tombol Exit (dipakai di dalam builder)
local function toggleHideExit()
	exitTersembunyi = not exitTersembunyi
	if exitBtn then exitBtn.Visible = not exitTersembunyi end
	if hideBtn then hideBtn.Text = exitTersembunyi and "🚫" or "👁" end
end

-- ── Builder Exit GUI (tombol Exit + tombol Hide lingkaran) ──
local function buatExitGui()
	local pg = player:FindFirstChildOfClass("PlayerGui") or playerGui

	exitGui = Instance.new("ScreenGui")
	exitGui.Name = "FreecamExitGui"
	exitGui.ResetOnSpawn = false
	exitGui.DisplayOrder = 999
	exitGui.Enabled = false
	exitGui.Parent = pg

	exitBtn = Instance.new("TextButton")
	exitBtn.Size = UDim2.fromOffset(140, 40)
	exitBtn.Position = UDim2.new(1, -150, 1, -55)
	exitBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
	exitBtn.BorderSizePixel = 0
	exitBtn.Text = "📷  Exit Freecam"
	exitBtn.TextColor3 = Color3.new(1,1,1)
	exitBtn.Font = Enum.Font.GothamBold
	exitBtn.TextSize = 13
	exitBtn.ZIndex = 10
	exitBtn.Visible = true
	exitBtn.Parent = exitGui
	Instance.new("UICorner", exitBtn).CornerRadius = UDim.new(0,10)
	local sk = Instance.new("UIStroke", exitBtn)
	sk.Color = Color3.fromRGB(255,80,80); sk.Thickness = 1.5

	-- Tombol HIDE (lingkaran) di ATAS tombol Exit
	hideBtn = Instance.new("TextButton")
	hideBtn.Name = "HideExitBtn"
	hideBtn.Size = UDim2.fromOffset(40, 40)
	hideBtn.Position = UDim2.new(1, -90, 1, -105)
	hideBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	hideBtn.BorderSizePixel = 0
	hideBtn.Text = "👁"
	hideBtn.TextColor3 = Color3.new(1,1,1)
	hideBtn.Font = Enum.Font.GothamBold
	hideBtn.TextSize = 18
	hideBtn.ZIndex = 11
	hideBtn.AutoButtonColor = true
	hideBtn.Visible = true
	hideBtn.Parent = exitGui
	Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(1, 0)
	local hsk = Instance.new("UIStroke", hideBtn)
	hsk.Color = Color3.fromRGB(120,120,160); hsk.Thickness = 1.5

	-- reset kondisi hide setiap GUI dibangun ulang
	exitTersembunyi = false

	-- Wiring tombol (harus di-wire ulang tiap GUI baru)
	exitBtn.MouseButton1Click:Connect(function() if deactivateFreecam then deactivateFreecam() end end)
	exitBtn.TouchTap:Connect(function() if deactivateFreecam then deactivateFreecam() end end)
	hideBtn.MouseButton1Click:Connect(toggleHideExit)
	hideBtn.TouchTap:Connect(toggleHideExit)
end

-- ── Builder Mobile GUI (joystick + tombol naik/turun) ──
local function buatMobileGui()
	local pg = player:FindFirstChildOfClass("PlayerGui") or playerGui

	mobileGui = Instance.new("ScreenGui")
	mobileGui.Name = "FreecamMobileGui"
	mobileGui.ResetOnSpawn = false
	mobileGui.DisplayOrder = 998
	mobileGui.Enabled = false
	mobileGui.Parent = pg

	joyBase = Instance.new("Frame")
	joyBase.Name = "JoyBase"
	joyBase.Size = UDim2.fromOffset(120, 120)
	joyBase.Position = UDim2.new(0, 20, 1, -150)
	joyBase.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	joyBase.BackgroundTransparency = 0.6
	joyBase.BorderSizePixel = 0
	joyBase.ZIndex = 10
	joyBase.Parent = mobileGui
	Instance.new("UICorner", joyBase).CornerRadius = UDim.new(1, 0)
	local joyStroke = Instance.new("UIStroke", joyBase)
	joyStroke.Color = Color3.fromRGB(0,210,255); joyStroke.Thickness = 2

	joyThumb = Instance.new("Frame")
	joyThumb.Name = "JoyThumb"
	joyThumb.Size = UDim2.fromOffset(50, 50)
	joyThumb.AnchorPoint = Vector2.new(0.5, 0.5)
	joyThumb.Position = UDim2.new(0.5, 0, 0.5, 0)
	joyThumb.BackgroundColor3 = Color3.fromRGB(0, 210, 255)
	joyThumb.BackgroundTransparency = 0.3
	joyThumb.BorderSizePixel = 0
	joyThumb.ZIndex = 11
	joyThumb.Parent = joyBase
	Instance.new("UICorner", joyThumb).CornerRadius = UDim.new(1, 0)

	local function makeBtn(txt, posY)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(50, 50)
		b.Position = UDim2.new(0, 150, 1, posY)
		b.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
		b.BackgroundTransparency = 0.4
		b.BorderSizePixel = 0
		b.Text = txt
		b.TextColor3 = Color3.fromRGB(0,210,255)
		b.Font = Enum.Font.GothamBold
		b.TextSize = 20
		b.ZIndex = 10
		b.Parent = mobileGui
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
		return b
	end
	upBtn   = makeBtn("▲", -150)
	downBtn = makeBtn("▼", -95)

	-- Wiring tombol naik/turun (di-wire ulang tiap GUI baru)
	upBtn.MouseButton1Down:Connect(function() isUpHeld = true end)
	upBtn.MouseButton1Up:Connect(function() isUpHeld = false end)
	downBtn.MouseButton1Down:Connect(function() isDownHeld = true end)
	downBtn.MouseButton1Up:Connect(function() isDownHeld = false end)
end

-- Bangun pertama kali
buatExitGui()
if isMobile then buatMobileGui() end

-- [FREECAMFIX3] Pastikan GUI hidup & terpasang; bangun ulang kalau mati/ter-Destroy.
local function guiPerluBangunUlang(gui)
	if not gui then return true end
	local pg = player:FindFirstChildOfClass("PlayerGui") or playerGui
	local ok, par = pcall(function() return gui.Parent end)
	if not ok then return true end          -- objek rusak
	if par == nil then return true end       -- lepas / ter-Destroy
	if pg and par ~= pg then
		-- coba pasang balik; kalau gagal (locked karena Destroy) -> bangun ulang
		local ok2 = pcall(function() gui.Parent = pg end)
		if not ok2 then return true end
		local ok3, par2 = pcall(function() return gui.Parent end)
		if not ok3 or par2 ~= pg then return true end
	end
	return false
end

local function pastikanGuiFreecam()
	if guiPerluBangunUlang(exitGui) then buatExitGui() end
	if isMobile and guiPerluBangunUlang(mobileGui) then buatMobileGui() end
end

-- ── Helper ──
local guisTersembunyi = false  -- [FREECAMFIX2] penjaga supaya snapshot tak dobel

local function hideAllGuis()
	-- [FREECAMFIX3] pastikan exitGui/mobileGui benar-benar HIDUP & terpasang.
	-- Kalau ter-Destroy oleh ganti avatar, dibangun ulang dari nol di sini.
	pastikanGuiFreecam()

	local pg = player:FindFirstChildOfClass("PlayerGui") or playerGui

	-- reset kondisi hide setiap masuk freecam supaya tombol Exit selalu terlihat
	exitTersembunyi = false
	if exitBtn then exitBtn.Visible = true end
	if hideBtn then hideBtn.Text = "👁" end

	-- [FREECAMFIX2] JANGAN ambil snapshot dua kali. Kalau sudah tersembunyi
	-- (hideAllGuis terpanggil lagi tanpa showAllGuis di antaranya), semua GUI game
	-- sudah Enabled=false -> scan kedua menghasilkan hiddenGuis KOSONG -> showAllGuis
	-- nanti tak mengembalikan apa pun -> semua menu hilang permanen. Penjaga ini
	-- memastikan snapshot cuma diambil sekali per sesi freecam.
	if guisTersembunyi then
		exitGui.Enabled = true
		if isMobile then mobileGui.Enabled = true end
		return
	end

	hiddenGuis = {}
	for _, gui in pairs(pg:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Enabled and
			gui ~= exitGui and gui ~= mobileGui and
			gui.Name ~= "ZayinTimerGui" then
			gui.Enabled = false
			table.insert(hiddenGuis, gui)
		end
	end
	guisTersembunyi = true
	exitGui.Enabled = true
	if isMobile then mobileGui.Enabled = true end
end

local function showAllGuis()
	if exitGui then exitGui.Enabled = false end
	if mobileGui then mobileGui.Enabled = false end

	-- [FREECAMFIX6] Kembalikan HANYA GUI yang freecam matikan (snapshot presisi).
	-- Dulu FIX4 "paksa nyalakan SEMUA ScreenGui" — itu terlalu luas: ikut menyalakan
	-- ScreenGui yang memang seharusnya Enabled=false (overlay/prompt kontekstual,
	-- panel boombox, dsb) yang lalu bisa MENUTUPI menu → menu tampak "hilang".
	-- Konflik dua-sistem-hide sudah ditangani di sisi ZayinMenuBaru (FREECAMGUARD +
	-- FREECAMGUARD2) & double-snapshot dijaga guisTersembunyi (FIX2), jadi snapshot
	-- presisi kini aman. ZayinTimerGui tak pernah masuk hiddenGuis (di-skip FIX5 di
	-- hideAllGuis), jadi timer tetap murni dikelola SpeedRunClient.
	for _, gui in ipairs(hiddenGuis) do
		if gui and gui.Parent then gui.Enabled = true end
	end

	hiddenGuis = {}
	guisTersembunyi = false  -- [FREECAMFIX2] sesi hide selesai
end

local BLOCKED_KEYS = {
	Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
	Enum.KeyCode.Space, Enum.KeyCode.Up, Enum.KeyCode.Down,
	Enum.KeyCode.Left, Enum.KeyCode.Right,
}

local function blockCharacterInput()
	for _, key in ipairs(BLOCKED_KEYS) do
		ContextActionService:BindActionAtPriority(
			"FCBlock_"..key.Name,
			function() return Enum.ContextActionResult.Sink end,
			false, Enum.ContextActionPriority.High.Value + 1, key
		)
	end
end

local function unblockCharacterInput()
	for _, key in ipairs(BLOCKED_KEYS) do
		ContextActionService:UnbindAction("FCBlock_"..key.Name)
	end
end

local function activateFreecam()
	if isActive then return end  -- [FREECAMFIX2] cegah aktivasi ganda (hideAllGuis dobel)
	isActive = true
	savedCamType = camera.CameraType
	local lv = camera.CFrame.LookVector
	yaw   = math.deg(math.atan2(-lv.X, -lv.Z))
	pitch = math.deg(math.asin(math.clamp(lv.Y, -1, 1)))
	camera.CameraType = Enum.CameraType.Scriptable
	local char = player.Character
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		savedHum = {ws = hum.WalkSpeed, jh = hum.JumpHeight, ar = hum.AutoRotate}
		hum.AutoRotate = false
		hum.WalkSpeed  = 0
		hum.JumpHeight = 0
	end
	blockCharacterInput()
	hideAllGuis()
	joystickMove = Vector2.new(0,0)
	_G.ZayinFreecamActive = true  -- sync ke ZayinMenuBaru
	print("[Freecam] ON")
end

local isShiftLock = false
local function setShiftLock(enabled)
	isShiftLock = enabled
	if enabled then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		local sl = exitGui:FindFirstChild('ShiftLockIndicator')
		if not sl then
			sl = Instance.new('TextLabel')
			sl.Name = 'ShiftLockIndicator'
			sl.Size = UDim2.fromOffset(130, 28)
			sl.Position = UDim2.new(1, -150, 1, -100)
			sl.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
			sl.BackgroundTransparency = 0.2
			sl.BorderSizePixel = 0
			sl.Text = '🔒 ShiftLock ON'
			sl.TextColor3 = Color3.new(1,1,1)
			sl.Font = Enum.Font.GothamBold
			sl.TextSize = 11
			sl.ZIndex = 10
			sl.Parent = exitGui
			Instance.new('UICorner', sl).CornerRadius = UDim.new(0,8)
		end
		sl.Visible = true
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		local sl = exitGui:FindFirstChild('ShiftLockIndicator')
		if sl then sl.Visible = false end
	end
end

deactivateFreecam = function()
	isActive     = false
	isRightClick = false
	if not isMobile then setShiftLock(false) end
	joystickTouchId = nil
	lookTouchId     = nil
	joystickMove    = Vector2.new(0,0)
	lookDelta       = Vector2.new(0,0)
	if joyThumb then joyThumb.Position = UDim2.new(0.5,0,0.5,0) end
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	camera.CameraType = savedCamType or Enum.CameraType.Custom
	local char = player.Character
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.AutoRotate = (savedHum and savedHum.ar ~= nil) and savedHum.ar or true
		hum.WalkSpeed  = savedHum and savedHum.ws or 16
		hum.JumpHeight = savedHum and savedHum.jh or 7.2
		savedHum = nil
	end
	unblockCharacterInput()
	showAllGuis()
	_G.ZayinFreecamActive = false  -- sync ke ZayinMenuBaru
	print("[Freecam] OFF")
end

-- ── Mobile Touch ──
local vp = camera.ViewportSize
local halfW = vp.X / 2

UserInputService.TouchStarted:Connect(function(touch, gpe)
	if not isActive then return end
	local pos = touch.Position
	if pos.X < halfW and not joystickTouchId then
		joystickTouchId = touch
		joystickCenter  = Vector2.new(pos.X, pos.Y)
		if joyBase then joyBase.Position = UDim2.fromOffset(pos.X - 60, pos.Y - 60) end
	elseif pos.X >= halfW and not lookTouchId then
		lookTouchId = touch
	end
end)

UserInputService.TouchMoved:Connect(function(touch, gpe)
	if not isActive then return end
	local pos = touch.Position
	if touch == joystickTouchId then
		local delta = Vector2.new(pos.X - joystickCenter.X, pos.Y - joystickCenter.Y)
		local maxR = 40
		local clamped = delta.Magnitude > maxR and delta.Unit * maxR or delta
		joystickMove = clamped / maxR
		if joyThumb then joyThumb.Position = UDim2.new(0.5, clamped.X, 0.5, clamped.Y) end
	elseif touch == lookTouchId then
		lookDelta = Vector2.new(touch.Delta.X, touch.Delta.Y)
	end
end)

UserInputService.TouchEnded:Connect(function(touch, gpe)
	if touch == joystickTouchId then
		joystickTouchId = nil
		joystickMove = Vector2.new(0,0)
		if joyThumb then joyThumb.Position = UDim2.new(0.5,0,0.5,0) end
	elseif touch == lookTouchId then
		lookTouchId = nil
		lookDelta = Vector2.new(0,0)
	end
end)

-- ── Desktop: klik kanan untuk look ──
UserInputService.InputBegan:Connect(function(input, gpe)
	if not isActive or isMobile then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isRightClick = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if not isActive or isMobile then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isRightClick = false
		if not isShiftLock then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	end
end)

-- ── Toggle via BindableEvent ──
toggleBE.Event:Connect(function()
	if isActive then deactivateFreecam() else activateFreecam() end
end)

player.CharacterAdded:Connect(function()
	if isActive then deactivateFreecam() end
end)

-- ── RenderStepped ──
RunService.RenderStepped:Connect(function(dt)
	if not isActive then return end

	-- Baca speed dari ZayinMenuBaru jika ada
	if _G.ZayinFreecamSpeed then speed = _G.ZayinFreecamSpeed end

	if isMobile then
		yaw   = yaw   - lookDelta.X * sensitivity * 0.5
		pitch = pitch - lookDelta.Y * sensitivity * 0.5
		pitch = math.clamp(pitch, -80, 80)
		lookDelta = Vector2.new(0,0)
	elseif isRightClick then
		local delta = UserInputService:GetMouseDelta()
		yaw   = yaw   - delta.X * sensitivity * 0.4
		pitch = pitch - delta.Y * sensitivity * 0.4
		pitch = math.clamp(pitch, -80, 80)
	end

	local cf  = CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(pitch), 0, 0)
	local spd = speed * dt
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then spd = spd * 2.5 end

	local move
	if isMobile then
		move = Vector3.new(
			joystickMove.X,
			(isUpHeld and 1 or 0) - (isDownHeld and 1 or 0),
			joystickMove.Y
		)
	else
		move = Vector3.new(
			(UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
			(UserInputService:IsKeyDown(Enum.KeyCode.E) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.Q) and 1 or 0),
			(UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
		)
	end

	camera.CFrame = CFrame.new(camera.CFrame.Position) * cf * CFrame.new(move * spd)
end)

print("[FreecamController v2.0] Ready! BindableEvent sudah dibuat.")
