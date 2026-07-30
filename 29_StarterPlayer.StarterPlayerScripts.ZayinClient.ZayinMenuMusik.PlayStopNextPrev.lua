-- ============================================================
--  PlayStopNextPrev.lua  v4
--  Fix: lagu selesai → pindah ke berikutnya (bukan balik 10 detik)
--  1 tombol mode: Normal → Loop → Repeat → Normal
--  Lampu tombol menyala saat aktif
-- ============================================================

local PlayStopNextPrev = {}
local Playlist   = require(script.Parent.Playlist)
local RunService = game:GetService("RunService")

PlayStopNextPrev.Mode      = "normal"
PlayStopNextPrev.Shuffle   = false
PlayStopNextPrev.IsPlaying = false
PlayStopNextPrev.UpdateConn= nil

local MODE_CYCLE = {"normal","loop","repeat"}

local function FormatTime(s)
	s = math.max(s or 0, 0)
	return string.format("%02d:%02d", math.floor(s/60), math.floor(s%60))
end

function PlayStopNextPrev.Setup(uiElements)
	local playBtn    = uiElements.PlayButton
	local pauseBtn   = uiElements.PauseButton
	local nextBtn    = uiElements.NextButton
	local prevBtn    = uiElements.PrevButton
	local modeBtn    = uiElements.ModeButton
	local modeLbl    = uiElements.ModeLabel
	local shuffleBtn = uiElements.ShuffleButton
	local shuffleLbl = uiElements.ShuffleLabel
	local nameLagu   = uiElements.NameLagu
	local detikLbl   = uiElements.DetikLagu
	local seekBG     = uiElements.SeekBG
	local seekFill   = uiElements.SeekFill
	local C          = uiElements.Colors or {}

	local COL_ON_MODE = {
		normal  = C.textB or Color3.fromRGB(120,180,210),
		loop    = C.cyan  or Color3.fromRGB(0,220,255),
		["repeat"] = C.gold or Color3.fromRGB(255,200,60),
	}
	local ICON_MODE  = {normal="➡", loop="🔁", ["repeat"]="🔂"}
	local LABEL_MODE = {normal="▶ Normal", loop="🔁 Loop", ["repeat"]="🔂 Repeat"}

	local function updateModeUI()
		local m = PlayStopNextPrev.Mode
		if modeBtn then
			modeBtn.Text       = ICON_MODE[m] or "➡"
			modeBtn.TextColor3 = COL_ON_MODE[m] or C.textB
			-- Lampu: aktif = border menyala, normal = border redup
			if m ~= "normal" then
				-- Hapus stroke lama lalu buat baru dengan warna menyala
				for _, ch in ipairs(modeBtn:GetChildren()) do
					if ch:IsA("UIStroke") then ch:Destroy() end
				end
				local s = Instance.new("UIStroke")
				s.Color       = COL_ON_MODE[m]
				s.Thickness   = 2
				s.Parent      = modeBtn
				s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			else
				for _, ch in ipairs(modeBtn:GetChildren()) do
					if ch:IsA("UIStroke") then ch:Destroy() end
				end
				local s = Instance.new("UIStroke")
				s.Color       = C.border or Color3.fromRGB(0,70,110)
				s.Thickness   = 1.2
				s.Parent      = modeBtn
				s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			end
		end
		if modeLbl then
			modeLbl.Text       = LABEL_MODE[m] or "▶ Normal"
			modeLbl.TextColor3 = COL_ON_MODE[m] or C.textB
		end
	end

	local function updateShuffleUI()
		local on = PlayStopNextPrev.Shuffle
		local col = on and (C.pink or Color3.fromRGB(255,80,160))
			or (C.textB or Color3.fromRGB(120,180,210))
		if shuffleBtn then
			shuffleBtn.TextColor3 = col
			-- Lampu shuffle
			for _, ch in ipairs(shuffleBtn:GetChildren()) do
				if ch:IsA("UIStroke") then ch:Destroy() end
			end
			local s = Instance.new("UIStroke")
			s.Color       = on and (C.pink or Color3.fromRGB(255,80,160))
				or (C.border or Color3.fromRGB(0,70,110))
			s.Thickness   = on and 2 or 1.2
			s.Parent      = shuffleBtn
			s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		end
		if shuffleLbl then
			shuffleLbl.Text       = on and "Shuffle: ON" or "Shuffle: OFF"
			shuffleLbl.TextColor3 = col
		end
	end

	local function updateNameUI()
		local sound = Playlist.GetCurrentSound()
		if nameLagu then nameLagu.Text = sound and sound.Name or "No Music" end
	end

	local function startTracking()
		if PlayStopNextPrev.UpdateConn then
			PlayStopNextPrev.UpdateConn:Disconnect()
			PlayStopNextPrev.UpdateConn = nil
		end
		PlayStopNextPrev.UpdateConn = RunService.RenderStepped:Connect(function()
			local sound = Playlist.GetCurrentSound()
			if not sound then return end
			if detikLbl then
				detikLbl.Text = FormatTime(sound.TimePosition).." / "..FormatTime(sound.TimeLength)
			end
			if seekFill and seekBG and not seekBG:GetAttribute("SeekDragging") then
				local dur = math.max(sound.TimeLength, 0.01)
				local pct = math.clamp(sound.TimePosition / dur, 0, 1)
				seekFill.Size = UDim2.new(pct, 0, 1, 0)
			end
		end)
	end

	local function getNextIdx()
		if PlayStopNextPrev.Shuffle then
			return math.random(1, math.max(#Playlist.SoundList, 1))
		end
		return (Playlist.CurrentIndex % #Playlist.SoundList) + 1
	end

	-- ── Koneksi "Ended" per sound — simpan agar tidak dobel ──
	local endedConns = {}  -- {[sound] = RBXScriptConnection}

	local playCurrent  -- forward declare

	local function bindEnded(sound)
		-- Putus koneksi lama jika ada
		if endedConns[sound] then
			endedConns[sound]:Disconnect()
			endedConns[sound] = nil
		end

		endedConns[sound] = sound.Ended:Connect(function()
			-- Pastikan ini masih lagu yang aktif
			if sound ~= Playlist.GetCurrentSound() then return end
			if not PlayStopNextPrev.IsPlaying then return end

			local mode = PlayStopNextPrev.Mode

			if mode == "loop" then
				-- Ulangi lagu yang sama dari awal
				sound.TimePosition = 0
				playCurrent()
			elseif mode == "repeat" then
				-- Pindah ke lagu berikutnya (wrap)
				Playlist.SetIndex(getNextIdx())
				playCurrent()
			else
				-- Normal: pindah ke berikutnya, stop di akhir playlist
				local nextIdx = getNextIdx()
				if PlayStopNextPrev.Shuffle or Playlist.CurrentIndex < #Playlist.SoundList then
					Playlist.SetIndex(nextIdx)
					playCurrent()
				else
					-- Sudah di lagu terakhir → stop
					PlayStopNextPrev.IsPlaying = false
					if playBtn  then playBtn.Visible  = true  end
					if pauseBtn then pauseBtn.Visible = false end
					if seekFill then seekFill.Size = UDim2.new(0,0,1,0) end
					if detikLbl then detikLbl.Text = "00:00 / 00:00" end
				end
			end
		end)
	end

	playCurrent = function()
		local sound = Playlist.GetCurrentSound()
		if not sound then return end

		-- Stop semua lainnya
		for _, s in ipairs(Playlist.SoundList) do
			if s ~= sound and s.IsPlaying then s:Stop() end
		end

		-- Hanya reset ke awal jika lagu baru (TimePosition = 0 atau baru diganti)
		if not sound.IsPlaying and sound.TimePosition == 0 then sound.TimePosition = 0 end
		if sound.TimePosition > 0 and not sound.IsPlaying then
			sound:Resume()
		else
			sound:Play()
		end
		PlayStopNextPrev.IsPlaying = true

		if playBtn  then playBtn.Visible  = false end
		if pauseBtn then pauseBtn.Visible = true  end

		updateNameUI()
		startTracking()
		bindEnded(sound)
	end

	-- ── API ───────────────────────────────────────────────────
	function PlayStopNextPrev.Play()  playCurrent() end

	function PlayStopNextPrev.Pause()
		local s = Playlist.GetCurrentSound()
		if s and s.IsPlaying then s:Pause() end
		PlayStopNextPrev.IsPlaying = false
		if playBtn  then playBtn.Visible  = true  end
		if pauseBtn then pauseBtn.Visible = false end
	end

	function PlayStopNextPrev.Next()
		local s = Playlist.GetCurrentSound()
		if s then s:Stop() end
		Playlist.SetIndex(getNextIdx())
		playCurrent()
	end

	function PlayStopNextPrev.Prev()
		local s = Playlist.GetCurrentSound()
		if s then s:Stop() end
		Playlist.Prev()
		playCurrent()
	end

	-- ── Tombol ────────────────────────────────────────────────
	if playBtn   then playBtn.MouseButton1Click:Connect(PlayStopNextPrev.Play)   end
	if pauseBtn  then pauseBtn.MouseButton1Click:Connect(PlayStopNextPrev.Pause) end
	if nextBtn   then nextBtn.MouseButton1Click:Connect(PlayStopNextPrev.Next)   end
	if prevBtn   then prevBtn.MouseButton1Click:Connect(PlayStopNextPrev.Prev)   end

	-- Mode button: Normal → Loop → Repeat → Normal
	if modeBtn then
		modeBtn.MouseButton1Click:Connect(function()
			local cur = PlayStopNextPrev.Mode
			local idx = table.find(MODE_CYCLE, cur) or 1
			idx = (idx % #MODE_CYCLE) + 1
			PlayStopNextPrev.Mode = MODE_CYCLE[idx]
			updateModeUI()
		end)
	end

	-- Shuffle button
	if shuffleBtn then
		shuffleBtn.MouseButton1Click:Connect(function()
			PlayStopNextPrev.Shuffle = not PlayStopNextPrev.Shuffle
			updateShuffleUI()
		end)
	end

	-- Seek bar
	if seekBG then
		seekBG:GetAttributeChangedSignal("SeekPercent"):Connect(function()
			local pct   = seekBG:GetAttribute("SeekPercent")
			local sound = Playlist.GetCurrentSound()
			if sound and sound.TimeLength > 0 then
				sound.TimePosition = math.clamp(pct * sound.TimeLength, 0, sound.TimeLength)
			end
		end)
	end

	updateModeUI()
	updateShuffleUI()
	updateNameUI()
	return PlayStopNextPrev
end

return PlayStopNextPrev