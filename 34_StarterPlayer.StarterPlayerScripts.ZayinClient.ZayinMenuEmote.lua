-- ============================================================
--  ZayinMenuEmote  |  LocalScript  |  v2.0
--  Fix: tidak pakai ListGui, embed langsung ke ZayinMenuBaru
--  Fix: panelHiddenPos, drag system, sync filter UI
--  Optimasi: updateList recycle, no dummy wait
-- ============================================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)

-- ── Modules ──────────────────────────────────────────────────
local Dance       = require(script:WaitForChild("Dance",       10))
local Emote       = require(script:WaitForChild("Emote",       10))
local Favorite    = require(script:WaitForChild("Favorite",    10))
local SliderSpeed = require(script:WaitForChild("SliderSpeed", 10))
local UiBuilder   = require(script:WaitForChild("UiBuilder",   10))
local Sync        = require(script:WaitForChild("Sync",        10))

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled


-- Connection registry untuk cleanup
local connections = {}
local function conn(c) table.insert(connections, c); return c end
local function cleanAllConns()
	for _, c in ipairs(connections) do
		if c and c.Connected then c:Disconnect() end
	end
	connections = {}
end
-- ── Warna ────────────────────────────────────────────────────
local COL = {
	DEFAULT  = Color3.fromRGB(22,  42,  64),
	HOVER    = Color3.fromRGB(28,  52,  78),
	PLAYING  = Color3.fromRGB(40,  230, 140),
	FEEDBACK = Color3.fromRGB(0,   180, 220),
	TEXT_DEF = Color3.fromRGB(220, 245, 255),
	TEXT_ON  = Color3.fromRGB(0,   20,  10),
	FAV_ON   = Color3.fromRGB(255, 200, 60),
	FAV_OFF  = Color3.fromRGB(120, 180, 210),
	CYAN     = Color3.fromRGB(0,   220, 255),
	CYND     = Color3.fromRGB(0,   150, 145),
}

local TAB_COLORS = {
	dance    = Color3.fromRGB(255, 60,  160),
	emote    = Color3.fromRGB(255, 200, 50),
	favorite = Color3.fromRGB(0,   220, 255),
}

-- ── TweenInfo cache ──────────────────────────────────────────
local TI = {
	fast  = TweenInfo.new(0.12, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
	med   = TweenInfo.new(0.20, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
	open  = TweenInfo.new(0.26, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
	close = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
}

-- ── State ────────────────────────────────────────────────────
local currentTrack         = nil
local currentMode          = "dance"
local currentPlayingButton = nil
local currentPlaybackSpeed = 1.0
local isFrameOpen          = false

-- Referensi UI (diisi setelah Build)
local EmotePanel, ScrollingFrame, TemplateButton
local DanceListButton, EmoteListButton, FavoriteListButton
local SliderFrame
local tabBtns = {}

-- ── Helper tween ─────────────────────────────────────────────
local function tw(obj, ti, props)
	TweenService:Create(obj, ti, props):Play()
end

-- ── Animasi ──────────────────────────────────────────────────
local function stopTrack()
	if currentTrack then
		currentTrack:Stop(0)
		task.defer(function() pcall(function() currentTrack:Destroy() end) end)
		currentTrack = nil
	end
end

local function playAnimationRaw(animIdStr, timePos, speed)
	local char     = player.Character or player.CharacterAdded:Wait()
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local animator = humanoid:FindFirstChildOfClass("Animator")
		or humanoid:WaitForChild("Animator", 5)
	if not animator then return end

	stopTrack()

	local anim = Instance.new("Animation")
	anim.AnimationId = animIdStr

	local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
	if not ok or not track then return end

	pcall(function() track.Priority = Enum.AnimationPriority.Action4 end)
	track:Play(0, 1.0, speed or currentPlaybackSpeed)
	currentTrack = track

	if timePos and timePos > 0 then
		task.wait(0.05)
		pcall(function() track.TimePosition = timePos end)
	end
end

local function resetBtn(btn)
	if not btn or not btn.Parent then return end
	tw(btn, TI.fast, {BackgroundColor3 = COL.DEFAULT})
	btn.TextColor3 = COL.TEXT_DEF
end

local function setPlayingBtn(btn)
	if not btn or not btn.Parent then return end
	tw(btn, TI.fast, {BackgroundColor3 = COL.PLAYING})
	btn.TextColor3 = COL.TEXT_ON
end

local function playAnimation(animId, btnClicked)
	-- Toggle off jika klik tombol yang sedang main
	if currentPlayingButton == btnClicked and currentTrack and currentTrack.IsPlaying then
		stopTrack()
		resetBtn(btnClicked)
		currentPlayingButton = nil
		return
	end

	resetBtn(currentPlayingButton)

	if btnClicked then
		tw(btnClicked, TI.fast, {BackgroundColor3 = COL.FEEDBACK})
		task.wait(0.06)
		setPlayingBtn(btnClicked)
		currentPlayingButton = btnClicked
	end

	playAnimationRaw("rbxassetid://" .. tostring(animId), 0, currentPlaybackSpeed)
end

-- ── Update list (recycle button) ─────────────────────────────
local btnPool = {}  -- cache button yang sudah dibuat

local function updateList()
	if not ScrollingFrame or not TemplateButton then return end

	-- Sembunyikan semua button dulu
	for _, btn in pairs(btnPool) do
		btn.Visible = false
		btn.LayoutOrder = 999
	end

	local list
	if currentMode == "dance" then
		list = Dance
	elseif currentMode == "emote" then
		list = Emote
	else
		list = Favorite.GetFavorites()
	end

	-- Recycle atau buat baru
	for i, item in ipairs(list) do
		local btn = btnPool[i]
		if not btn then
			btn = TemplateButton:Clone()
			btn.Name   = "AnimButton"
			btn.Parent = ScrollingFrame
			btnPool[i] = btn

			-- Hover (hanya PC)
			if not isMobile then
				btn.MouseEnter:Connect(function()
					if currentPlayingButton ~= btn then
						tw(btn, TI.fast, {BackgroundColor3 = COL.HOVER})
					end
				end)
				btn.MouseLeave:Connect(function()
					if currentPlayingButton ~= btn then
						tw(btn, TI.fast, {BackgroundColor3 = COL.DEFAULT})
					end
				end)
			end

			-- Klik main animasi
			btn.MouseButton1Click:Connect(function()
				-- Ambil animId dari attribute (lebih aman dari closure lama)
				local id = btn:GetAttribute("AnimId")
				if id then playAnimation(id, btn) end
			end)

			-- Fav icon
			local favIcon = btn:FindFirstChild("FavIcon")
			if favIcon then
				favIcon.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch then
						local id   = btn:GetAttribute("AnimId")
						local name = btn:GetAttribute("AnimName")
						if not id then return end
						local isNowFav = Favorite.Toggle(name, id)
						favIcon.Text       = isNowFav and "★" or "☆"
						favIcon.TextColor3 = isNowFav and COL.FAV_ON or COL.FAV_OFF
						if currentMode == "favorite" then
							task.wait(0.1)
							updateList()
						end
					end
				end)
			end
		end

		-- Set data via Attribute (aman dari stale closure)
		btn:SetAttribute("AnimId",   item.animId)
		btn:SetAttribute("AnimName", item.name)

		btn.Text        = "  " .. item.name
		btn.BackgroundColor3 = COL.DEFAULT
		btn.TextColor3  = COL.TEXT_DEF
		btn.LayoutOrder = i
		btn.Visible     = true

		-- Reset state playing
		if currentPlayingButton == btn then
			if currentTrack and currentTrack.IsPlaying then
				setPlayingBtn(btn)
			else
				currentPlayingButton = nil
			end
		end

		local favIcon = btn:FindFirstChild("FavIcon")
		if favIcon then
			local isFav = Favorite.IsFavorite(item.animId)
			favIcon.Text       = isFav and "★" or "☆"
			favIcon.TextColor3 = isFav and COL.FAV_ON or COL.FAV_OFF
		end
	end
end

-- ── Switch tab ───────────────────────────────────────────────
local function switchMode(mode)
	currentMode = mode
	for m, btn in pairs(tabBtns) do
		if not btn then continue end
		if m == mode then
			tw(btn, TI.med, {BackgroundColor3 = TAB_COLORS[m], BackgroundTransparency = 0})
			btn.TextColor3 = Color3.fromRGB(220, 245, 255)
		else
			tw(btn, TI.med, {BackgroundColor3 = Color3.fromRGB(22,42,64), BackgroundTransparency = 0.3})
			btn.TextColor3 = Color3.fromRGB(120, 180, 210)
		end
	end
	-- [P73] ganti tab: JANGAN hentikan animasi yang sedang berjalan
	updateList()

	-- setelah daftar dibangun ulang, tandai lagi tombol yang sedang aktif
	if currentTrack and currentTrack.IsPlaying and currentPlayingButton then
		task.defer(function()
			if currentPlayingButton and currentPlayingButton.Parent then
				setPlayingBtn(currentPlayingButton)
			end
		end)
	end
end

-- ── Buka / tutup panel ───────────────────────────────────────
local function openFrame()
	if isFrameOpen or not EmotePanel then return end
	isFrameOpen = true
	EmotePanel.Visible = true
	tw(EmotePanel, TI.open, {BackgroundTransparency = 0})
end

local function closeFrame()
	if not isFrameOpen or not EmotePanel then return end
	isFrameOpen = false
	tw(EmotePanel, TI.close, {BackgroundTransparency = 1})
	task.delay(0.15, function()
		if not isFrameOpen then EmotePanel.Visible = false end
	end)
end

-- ── Drag system (fix: pakai AbsolutePosition saat InputBegan) ─
local function makeDraggable(panel, dragHandle)
	if not panel or not dragHandle then return end

	local dragging   = false
	local dragStartP = Vector2.zero   -- posisi input saat mulai drag
	local panelStartP = Vector2.zero  -- AbsolutePosition panel saat mulai drag

	local function beginDrag(input)
		local t = input.UserInputType
		if t ~= Enum.UserInputType.MouseButton1
			and t ~= Enum.UserInputType.Touch then return end
		dragging   = true
		dragStartP = Vector2.new(input.Position.X, input.Position.Y)
		-- Simpan posisi absolut panel saat drag mulai (bukan offset UDim2)
		panelStartP = Vector2.new(panel.AbsolutePosition.X, panel.AbsolutePosition.Y)
	end

	local function moveDrag(input)
		if not dragging then return end
		local t = input.UserInputType
		if t ~= Enum.UserInputType.MouseMovement
			and t ~= Enum.UserInputType.Touch then return end

		local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartP
		local newAbs = panelStartP + delta

		-- Clamp ke dalam viewport
		local vp = workspace.CurrentCamera.ViewportSize
		local pw = panel.AbsoluteSize.X
		local ph = panel.AbsoluteSize.Y
		newAbs = Vector2.new(
			math.clamp(newAbs.X, 0, math.max(0, vp.X - pw)),
			math.clamp(newAbs.Y, 0, math.max(0, vp.Y - ph))
		)

		-- Konversi ke UDim2 (Scale 0, Offset = pixel absolut)
		panel.Position = UDim2.new(0, newAbs.X, 0, newAbs.Y)
	end

	local function endDrag(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1
			or t == Enum.UserInputType.Touch then
			dragging = false
		end
	end

	dragHandle.InputBegan:Connect(beginDrag)
	UserInputService.InputChanged:Connect(moveDrag)
	UserInputService.InputEnded:Connect(endDrag)
end

-- ── Inisialisasi utama ───────────────────────────────────────
local function initialize()
	-- Tunggu ZayinMenuBaru ScreenGui
	local sg = playerGui:WaitForChild("ZayinMenuBaru", 15)
	if not sg then
		warn("[ZayinMenuEmote] ZayinMenuBaru tidak ditemukan!")
		return
	end

	-- Cari sub panel Emote (sudah dinamai "EmotePanel" oleh ZayinMenuBaru v2.0)
	local emoteP = sg:WaitForChild("EmotePanel", 10)
	if not emoteP then
		warn("[ZayinMenuEmote] EmotePanel tidak ditemukan di ZayinMenuBaru!")
		return
	end

	-- Ambil Content (ScrollingFrame tempat kita taruh UI)
	local content = emoteP:WaitForChild("Content", 5)
	if not content then
		warn("[ZayinMenuEmote] Content tidak ditemukan di EmotePanel!")
		return
	end

	-- Bersihkan semua placeholder dari ZayinMenuBaru
	for _, c in pairs(content:GetChildren()) do
		if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
	end

	-- Build UI Emote langsung ke content (SizeConstraint agar pas)
	local builtPanel = Instance.new("Frame")
	builtPanel.Name                   = "EmoteUI"
	builtPanel.Size                   = UDim2.new(1, 0, 0, 440)
	builtPanel.BackgroundTransparency = 1
	builtPanel.BorderSizePixel        = 0
	builtPanel.Parent                 = content
	-- Reset guard OuterGlass agar BuildEmotePanel bisa rebuild
	local oldGlass = builtPanel:FindFirstChild("OuterGlass")
	if oldGlass then oldGlass:Destroy() end
	UiBuilder.BuildEmotePanel(builtPanel)

	-- Buat SyncPrompt di playerGui
	UiBuilder.CreateSyncPrompt(playerGui)

	EmotePanel         = builtPanel
	ScrollingFrame     = builtPanel:FindFirstChild("ScrollingFrame",  true)
	TemplateButton     = ScrollingFrame and ScrollingFrame:FindFirstChild("Button", true)
	DanceListButton    = builtPanel:FindFirstChild("DanceButton",     true)
	EmoteListButton    = builtPanel:FindFirstChild("EmoteButton",     true)
	FavoriteListButton = builtPanel:FindFirstChild("FavoriteButton",  true)
	SliderFrame        = builtPanel:FindFirstChild("SliderFrame",     true)

	if not ScrollingFrame or not TemplateButton then
		warn("[ZayinMenuEmote] ScrollingFrame / TemplateButton tidak ditemukan!")
		return
	end

	-- Tab buttons map
	tabBtns = {
		dance    = DanceListButton,
		emote    = EmoteListButton,
		favorite = FavoriteListButton,
	}

	-- Speed control
	if SliderFrame then
		SliderSpeed.Init(SliderFrame, function(newSpeed)
			currentPlaybackSpeed = newSpeed
			if currentTrack and currentTrack.IsPlaying then
				pcall(function() currentTrack:AdjustSpeed(currentPlaybackSpeed) end)
			end
		end)
	end

	-- Tab klik
	if DanceListButton then
		DanceListButton.MouseButton1Click:Connect(function() switchMode("dance") end)
	end
	if EmoteListButton then
		EmoteListButton.MouseButton1Click:Connect(function() switchMode("emote") end)
	end
	if FavoriteListButton then
		FavoriteListButton.MouseButton1Click:Connect(function() switchMode("favorite") end)
	end

	-- Tombol Close — tutup emoteP (sub panel ZayinMenuBaru)
	local closeBtn = builtPanel:FindFirstChild("CloseButton", true)
	if closeBtn then
		closeBtn.MouseButton1Click:Connect(function()
			emoteP.Visible = false
		end)
	end

	-- Tombol Stop
	local stopBtn = builtPanel:FindFirstChild("StopButton", true)
	if stopBtn then
		stopBtn.MouseButton1Click:Connect(function()
			stopTrack()
			resetBtn(currentPlayingButton)
			currentPlayingButton = nil
		end)
	end

	-- Drag tidak diperlukan lagi (panel dikelola ZayinMenuBaru)
	-- Tapi tetap aktifkan drag pada header builtPanel jika mau
	local dragHandle = builtPanel:FindFirstChild("Header", true)
	if dragHandle then
		makeDraggable(emoteP, dragHandle)
	end

	-- Sync animasi dengan player lain
	Sync.Init(function(targetName, animIdStr, timePos, speed)
		if UserInputService:GetFocusedTextBox() then return end
		UiBuilder.ShowSyncPrompt(targetName, function()
			playAnimationRaw(animIdStr, timePos, speed)
		end)
	end)

	-- Load favorit dari server
	task.spawn(function()
		Favorite.Load()
		task.wait(0.3)
		if currentMode == "favorite" then updateList() end
	end)

	-- Set tab awal
	switchMode("dance")

	-- Expose openFrame/closeFrame untuk ZayinMenuBaru
	-- (ZayinMenuBaru v2.0 sudah handle via panel.Visible langsung)
	script:SetAttribute("Ready", true)

	print("[ZayinMenuEmote v2.0] Ready!")
end

-- ── Jalankan ─────────────────────────────────────────────────
task.spawn(function()
	task.wait(1.5)  -- tunggu ZayinMenuBaru selesai build
	local ok, err = pcall(initialize)
	if not ok then
		warn("[ZayinMenuEmote ERROR]:", err)
	end
end)