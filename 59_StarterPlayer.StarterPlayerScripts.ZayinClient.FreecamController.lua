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

-- ── Exit GUI ──
local exitGui = Instance.new("ScreenGui")
exitGui.Name = "FreecamExitGui"
exitGui.ResetOnSpawn = false
exitGui.DisplayOrder = 999
exitGui.Enabled = false
exitGui.Parent = playerGui

local exitBtn = Instance.new("TextButton")
exitBtn.Size = UDim2.fromOffset(140, 40)
exitBtn.Position = UDim2.new(1, -150, 1, -55)
exitBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
exitBtn.BorderSizePixel = 0
exitBtn.Text = "📷  Exit Freecam"
exitBtn.TextColor3 = Color3.new(1,1,1)
exitBtn.Font = Enum.Font.GothamBold
exitBtn.TextSize = 13
exitBtn.ZIndex = 10
exitBtn.Parent = exitGui
Instance.new("UICorner", exitBtn).CornerRadius = UDim.new(0,10)
local sk = Instance.new("UIStroke", exitBtn)
sk.Color = Color3.fromRGB(255,80,80); sk.Thickness = 1.5

-- ── Tombol HIDE (lingkaran) di ATAS tombol Exit ──
-- Menyembunyikan / menampilkan tombol Exit Freecam. Bentuk lingkaran.
local hideBtn = Instance.new("TextButton")
hideBtn.Name = "HideExitBtn"
hideBtn.Size = UDim2.fromOffset(40, 40)
-- exitBtn di kanan bawah (1,-150 .. lebar 140 -> tengahnya 1,-80).
-- Taruh hideBtn tepat di ATAS exitBtn, rata tengah dengan exitBtn.
hideBtn.Position = UDim2.new(1, -90, 1, -105)
hideBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
hideBtn.BorderSizePixel = 0
hideBtn.Text = "👁"
hideBtn.TextColor3 = Color3.new(1,1,1)
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 18
hideBtn.ZIndex = 11
hideBtn.AutoButtonColor = true
hideBtn.Parent = exitGui
Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(1, 0) -- lingkaran penuh
local hsk = Instance.new("UIStroke", hideBtn)
hsk.Color = Color3.fromRGB(120,120,160); hsk.Thickness = 1.5

local exitTersembunyi = false
local function toggleHideExit()
	exitTersembunyi = not exitTersembunyi
	exitBtn.Visible = not exitTersembunyi
	hideBtn.Text = exitTersembunyi and "🚫" or "👁"
end
hideBtn.MouseButton1Click:Connect(toggleHideExit)
hideBtn.TouchTap:Connect(toggleHideExit)

-- ── Mobile UI ──
local mobileGui = Instance.new("ScreenGui")
mobileGui.Name = "FreecamMobileGui"
mobileGui.ResetOnSpawn = false
mobileGui.DisplayOrder = 998
mobileGui.Enabled = false
mobileGui.Parent = playerGui

-- Joystick base (kiri bawah)
local joyBase = Instance.new("Frame")
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

-- Joystick thumb
local joyThumb = Instance.new("Frame")
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

-- Up/Down buttons (mobile)
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
local upBtn   = makeBtn("▲", -150)
local downBtn = makeBtn("▼", -95)

-- ── Helper ──
local guisTersembunyi = false  -- [FREECAMFIX2] penjaga supaya snapshot tak dobel

local function hideAllGuis()
	-- [FREECAMFIX] kalau exitGui/mobileGui sudah lepas dari PlayerGui (mis. karena
	-- ganti avatar), pasang balik supaya tombol Exit pasti muncul.
	local pg = player:FindFirstChildOfClass("PlayerGui") or playerGui
	pcall(function()
		if exitGui.Parent ~= pg then exitGui.Parent = pg end
		if mobileGui.Parent ~= pg then mobileGui.Parent = pg end
	end)
	-- reset kondisi hide setiap masuk freecam supaya tombol Exit selalu terlihat
	exitTersembunyi = false
	exitBtn.Visible = true
	hideBtn.Text = "👁"

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
			gui ~= exitGui and gui ~= mobileGui then
			gui.Enabled = false
			table.insert(hiddenGuis, gui)
		end
	end
	guisTersembunyi = true
	exitGui.Enabled = true
	if isMobile then mobileGui.Enabled = true end
end

local function showAllGuis()
	exitGui.Enabled = false
	mobileGui.Enabled = false
	if #hiddenGuis > 0 then
		for _, gui in ipairs(hiddenGuis) do
			if gui and gui.Parent then gui.Enabled = true end
		end
	else
		-- [FREECAMFIX2] jaring pengaman: kalau daftar kosong (mis. state pernah
		-- tak sinkron), nyalakan kembali SEMUA ScreenGui game supaya menu tak
		-- hilang permanen. exitGui/mobileGui tetap dimatikan di atas.
		local pg = player:FindFirstChildOfClass("PlayerGui") or playerGui
		for _, gui in pairs(pg:GetChildren()) do
			if gui:IsA("ScreenGui") and gui ~= exitGui and gui ~= mobileGui then
				gui.Enabled = true
			end
		end
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

local function deactivateFreecam()
	isActive     = false
	isRightClick = false
	if not isMobile then setShiftLock(false) end
	joystickTouchId = nil
	lookTouchId     = nil
	joystickMove    = Vector2.new(0,0)
	lookDelta       = Vector2.new(0,0)
	joyThumb.Position = UDim2.new(0.5,0,0.5,0)
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

exitBtn.MouseButton1Click:Connect(deactivateFreecam)
exitBtn.TouchTap:Connect(deactivateFreecam)

-- ── Mobile Touch ──
local vp = camera.ViewportSize
local halfW = vp.X / 2

UserInputService.TouchStarted:Connect(function(touch, gpe)
	if not isActive then return end
	local pos = touch.Position
	if pos.X < halfW and not joystickTouchId then
		joystickTouchId = touch
		joystickCenter  = Vector2.new(pos.X, pos.Y)
		joyBase.Position = UDim2.fromOffset(pos.X - 60, pos.Y - 60)
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
		joyThumb.Position = UDim2.new(0.5, clamped.X, 0.5, clamped.Y)
	elseif touch == lookTouchId then
		lookDelta = Vector2.new(touch.Delta.X, touch.Delta.Y)
	end
end)

UserInputService.TouchEnded:Connect(function(touch, gpe)
	if touch == joystickTouchId then
		joystickTouchId = nil
		joystickMove = Vector2.new(0,0)
		joyThumb.Position = UDim2.new(0.5,0,0.5,0)
	elseif touch == lookTouchId then
		lookTouchId = nil
		lookDelta = Vector2.new(0,0)
	end
end)

-- Up/Down mobile buttons
local isUpHeld, isDownHeld = false, false
upBtn.MouseButton1Down:Connect(function() isUpHeld = true end)
upBtn.MouseButton1Up:Connect(function() isUpHeld = false end)
downBtn.MouseButton1Down:Connect(function() isDownHeld = true end)
downBtn.MouseButton1Up:Connect(function() isDownHeld = false end)

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
