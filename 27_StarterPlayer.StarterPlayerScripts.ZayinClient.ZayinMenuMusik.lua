-- ============================================================
--  ZayinMenuMusik  |  LocalScript  |  v2.1
--  Fix: embed ke MusikPanel ZayinMenuBaru, hapus ListGui dep
-- ============================================================

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)

local UiBuilder        = require(script.UiBuilder)
local Playlist         = require(script.Playlist)
local PlayStopNextPrev = require(script.PlayStopNextPrev)
local VolumeSlide      = require(script.VolumeSlide)
local GrafikMusicBar   = require(script.GrafikMusicBar)

local AUTO_PLAY = false

local function Init()
	-- 1. Tunggu MusikPanel dari ZayinMenuBaru
	local sg = playerGui:WaitForChild("ZayinMenuBaru", 15)
	if not sg then warn("[ZayinMenuMusik] ZayinMenuBaru tidak ditemukan!"); return end

	local musikP = sg:WaitForChild("MusikPanel", 10)
	if not musikP then warn("[ZayinMenuMusik] MusikPanel tidak ditemukan!"); return end

	local content = musikP:WaitForChild("Content", 5)
	if not content then warn("[ZayinMenuMusik] Content tidak ditemukan!"); return end

	-- Bersihkan placeholder
	for _, c in pairs(content:GetChildren()) do c:Destroy() end

	-- 2. Init Playlist
	local hasMusic = Playlist.Initialize()
	if not hasMusic then return end

	-- 3. Load Favorite (async)
	task.spawn(function() Playlist.LoadFavorites() end)

	-- 4. Build UI — embed ke content
	local ui = UiBuilder.BuildEmbedded(content)
	local C  = ui.Colors

	if ui.UpdateCount then ui.UpdateCount(#Playlist.SoundList) end

	local connections = {}
	local function conn(c) table.insert(connections, c); return c end

	-- ── TAB SWITCHING ─────────────────────────────────────────
	local currentTab = "Player"
	local function switchTab(tabName)
		currentTab = tabName
		local map = {
			Player=ui.PlayerContainer, Playlist=ui.PlaylistContainer,
			Favorit=ui.FavoritContainer, EQ=ui.EQContainer,
		}
		for name, frame in pairs(map) do
			if frame then frame.Visible = (name == tabName) end
		end
		local tabMap = {
			Player=ui.PlayerTabBtn, Playlist=ui.PlaylistTabBtn,
			Favorit=ui.FavoritTabBtn, EQ=ui.EQTabBtn,
		}
		for name, btn in pairs(tabMap) do
			if btn then
				btn.TextColor3 = (name==tabName) and C.textA or C.textB
				btn.BackgroundTransparency = (name==tabName) and 0 or 0.3
				if name==tabName then
					local cols = {Player=C.cyan, Playlist=C.teal, Favorit=C.gold, EQ=C.amber}
					btn.BackgroundColor3 = cols[name] or C.cyan
				else
					btn.BackgroundColor3 = C.bg4
				end
				local ind = btn:FindFirstChild("Indicator")
				if ind then ind.Visible = (name==tabName) end
			end
		end
	end

	-- ── STAR / FAVORIT ────────────────────────────────────────
	local function refreshStar()
		local cur = Playlist.GetCurrentSound()
		if not cur then
			ui.StarIcon.Text = "☆"; ui.StarIcon.TextColor3 = C.textB; return
		end
		if Playlist.IsFavorite(cur) then
			ui.StarIcon.Text = "★"; ui.StarIcon.TextColor3 = C.gold
		else
			ui.StarIcon.Text = "☆"; ui.StarIcon.TextColor3 = C.textB
		end
	end

	local isMobile = game:GetService("UserInputService").TouchEnabled
		and not game:GetService("UserInputService").KeyboardEnabled

	local refreshFavTab -- forward declaration
	local function buildFavRow(sound, playbackSys)
		local btn = Instance.new("TextButton")
		btn.Name             = "FavRow_"..sound.Name
		btn.Size             = UDim2.new(1,0,0,isMobile and 34 or 36)
		btn.BackgroundColor3 = Color3.fromRGB(16,24,16)
		btn.Text             = "  ★ "..sound.Name
		btn.TextColor3       = C.gold
		btn.TextSize         = isMobile and 12 or 13
		btn.Font             = Enum.Font.GothamMedium
		btn.TextXAlignment   = Enum.TextXAlignment.Left
		btn.BorderSizePixel  = 0
		btn.Parent           = ui.FavoritScroll
		local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,7); c.Parent=btn
		-- no stroke (clean look)
		do
			local snd2 = sound
			local rmIcon = Instance.new("TextButton")
			rmIcon.Size = UDim2.new(0,24,0,24)
			rmIcon.AnchorPoint = Vector2.new(1,0.5)
			rmIcon.Position = UDim2.new(1,-4,0.5,0)
			rmIcon.BackgroundTransparency = 1
			rmIcon.BorderSizePixel = 0
			rmIcon.Text = "★"
			rmIcon.TextColor3 = Color3.fromRGB(255,200,60)
			rmIcon.TextSize = 15
			rmIcon.Font = Enum.Font.GothamBold
			rmIcon.Parent = btn
			conn(rmIcon.MouseButton1Click:Connect(function()
				Playlist.ToggleFavorite(snd2)
				refreshFavTab(playbackSys)
			end))
		end
		conn(btn.MouseButton1Click:Connect(function()
			for i,s2 in ipairs(Playlist.SoundList) do
				if s2==sound then Playlist.SetIndex(i); break end
			end
			playbackSys.Play(); if refreshStar then refreshStar() end
		end))
	end

	refreshFavTab = function(playbackSys)
		if not ui.FavoritScroll then return end
		for _,ch in ipairs(ui.FavoritScroll:GetChildren()) do
			if ch:IsA("TextButton") then ch:Destroy() end
		end
		local favList = {}
		for sound, _ in pairs(Playlist.Favorites or {}) do
			table.insert(favList, sound)
		end
		local hasFav = #favList > 0
		if ui.FavoritEmptyLabel then ui.FavoritEmptyLabel.Visible = not hasFav end
		if ui.FavoritScroll then ui.FavoritScroll.Visible = hasFav end
		for _,s in ipairs(favList) do buildFavRow(s, playbackSys) end
	end
	-- ── PLAYBACK ──────────────────────────────────────────────
	local playbackSystem = PlayStopNextPrev.Setup(ui)
	if not playbackSystem then warn('[ZayinMenuMusik] playbackSystem nil!'); return end
	VolumeSlide.Setup(ui)
	GrafikMusicBar.Setup(ui.VisualizerFrame)

	-- ── EQUALIZER ─────────────────────────────────────────────
	if ui.EQButtons then
		for presetName, def in pairs(ui.EQButtons) do
			conn(def.btn.MouseButton1Click:Connect(function()
				GrafikMusicBar.SetPreset(presetName)
				for pn2, def2 in pairs(ui.EQButtons) do
					local isActive = (pn2 == presetName)
					def2.row.BackgroundColor3 = isActive and Color3.fromRGB(0,40,30) or C.bg3
					def2.btn.Text = isActive and "✓ AKTIF" or "PILIH"
					for _, ch in ipairs(def2.btn:GetChildren()) do
						if ch:IsA("UIStroke") then ch:Destroy() end
					end
					local st = Instance.new("UIStroke")
					st.Color=isActive and def2.col or C.border
					st.Thickness=isActive and 2 or 1
					st.Parent=def2.btn
					st.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
				end
				if ui.EQInfoLabel then ui.EQInfoLabel.Text = "EQ: "..presetName end
			end))
		end
	end

	-- ── POPULATE PLAYLIST ─────────────────────────────────────
	for i, sound in ipairs(Playlist.SoundList) do
		local btn = Instance.new("TextButton")
		btn.Size             = UDim2.new(1,0,0,isMobile and 30 or 34)
		btn.BackgroundColor3 = Color3.fromRGB(16,20,26)
		btn.Text             = "  "..i..". "..sound.Name
		btn.TextColor3       = C.textA
		btn.TextSize         = isMobile and 12 or 13
		btn.Font             = Enum.Font.GothamMedium
		btn.TextXAlignment   = Enum.TextXAlignment.Left
		btn.BorderSizePixel  = 0
		btn.Parent           = ui.PlaylistScroll
		local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,7); c.Parent=btn
		-- no stroke (clean look)
		do
			local snd = sound
			local favIcon = Instance.new("TextButton")
			favIcon.Size = UDim2.new(0,24,0,24)
			favIcon.AnchorPoint = Vector2.new(1,0.5)
			favIcon.Position = UDim2.new(1,-4,0.5,0)
			favIcon.BackgroundTransparency = 1
			favIcon.BorderSizePixel = 0
			favIcon.Text = Playlist.IsFavorite(snd) and "★" or "☆"
			favIcon.TextColor3 = Playlist.IsFavorite(snd) and Color3.fromRGB(255,200,60) or Color3.fromRGB(100,120,140)
			favIcon.TextSize = 15
			favIcon.Font = Enum.Font.GothamBold
			favIcon.Parent = btn
			favIcon.Active = true  -- block event propagation ke parent
			conn(favIcon.MouseButton1Click:Connect(function()
				Playlist.ToggleFavorite(snd)
				local isFav = Playlist.IsFavorite(snd)
				favIcon.Text = isFav and "★" or "☆"
				favIcon.TextColor3 = isFav and Color3.fromRGB(255,200,60) or Color3.fromRGB(100,120,140)
				if refreshFavTab then refreshFavTab(playbackSystem) end
			end))






		end

















		btn.MouseEnter:Connect(function() if btn.BackgroundColor3~=Color3.fromRGB(0,80,60) then btn.BackgroundColor3=C.bg4 end end)
		btn.MouseLeave:Connect(function() if btn.BackgroundColor3~=Color3.fromRGB(0,80,60) then btn.BackgroundColor3=C.bg3 end end)
		conn(btn.MouseButton1Click:Connect(function()
			-- Reset semua btn warna normal
			for _,child in pairs(ui.PlaylistScroll:GetChildren()) do
				if child:IsA('TextButton') then child.BackgroundColor3=C.bg3; child.TextColor3=C.textA end
			end
			-- Highlight btn aktif
			btn.BackgroundColor3=Color3.fromRGB(0,80,60)
			btn.TextColor3=Color3.fromRGB(40,230,140)
			Playlist.SetIndex(i)
			if playbackSystem and playbackSystem.Play then playbackSystem.Play() end
			if refreshStar then refreshStar() end
		end))
	end  -- end for i, sound in ipairs


	-- ── TAB CONNECTIONS ───────────────────────────────────────
	conn(ui.PlayerTabBtn.MouseButton1Click:Connect(function() switchTab("Player") end))
	conn(ui.PlaylistTabBtn.MouseButton1Click:Connect(function() switchTab("Playlist") end))
	conn(ui.FavoritTabBtn.MouseButton1Click:Connect(function()
		refreshFavTab(playbackSystem); switchTab("Favorit")
	end))
	if ui.EQTabBtn then
		conn(ui.EQTabBtn.MouseButton1Click:Connect(function() switchTab("EQ") end))
	end

	-- Star button
	conn(ui.StarIcon.MouseButton1Click:Connect(function()
		local cur = Playlist.GetCurrentSound()
		if not cur then return end
		Playlist.ToggleFavorite(cur); refreshStar()
		if currentTab == "Favorit" then refreshFavTab(playbackSystem) end
	end))

	-- Close button — tutup MusikPanel
	if ui.CloseButton then
		conn(ui.CloseButton.MouseButton1Click:Connect(function()
			musikP.Visible = false
		end))
	end

	-- Polling update bintang
	task.spawn(function()
		local last = Playlist.CurrentIndex
		while true do
			task.wait(0.4)
			if Playlist.CurrentIndex ~= last then
				last = Playlist.CurrentIndex
				if refreshStar then refreshStar() end
						end
		end
	end)

	-- Init tab awal
	switchTab("Player")

	if AUTO_PLAY then
		playbackSystem.Play(); refreshStar()
	end

	script:SetAttribute("Ready", true)
	print("[ZayinMenuMusik v2.1] Ready!")
end

task.spawn(function()
	task.wait(1.5)
	local ok, err = pcall(Init)
	if not ok then warn("[ZayinMenuMusik ERROR]: "..tostring(err)) end
end)