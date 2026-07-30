-- ============================================================
--  GrafikMusicBar.lua  v3
--  Grafik DJ 20 bar smooth + EQ benar-benar mempengaruhi suara
--  via EqualizerSoundEffect Roblox
-- ============================================================

local GrafikMusicBar = {}
local RunService     = game:GetService("RunService")
local Playlist       = require(script.Parent.Playlist)

local bars       = {}
local connection = nil
local BAR_COUNT  = 20

-- ─── EQ Preset → EqualizerSoundEffect settings ────────────────
-- EqualizerSoundEffect memiliki: LowGain, MidGain, HighGain (-80 to 10 dB)
local EQ_SOUND_SETTINGS = {
	Normal     = {LowGain= 0,  MidGain= 0,  HighGain= 0},
	Bass       = {LowGain=10,  MidGain=-2,  HighGain=-4},
	Jazz       = {LowGain= 3,  MidGain= 4,  HighGain= 2},
	Pop        = {LowGain=-2,  MidGain= 5,  HighGain= 4},
	Electronic = {LowGain= 8,  MidGain= 0,  HighGain= 6},
}

-- Multiplier visual bar per preset
local EQ_VISUAL = {
	Normal     = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
	Bass       = {2.2,2.0,1.8,1.6,1.4,1.2,1.1,1.0,0.9,0.8,0.8,0.7,0.7,0.7,0.6,0.6,0.6,0.6,0.5,0.5},
	Jazz       = {1.2,1.3,1.4,1.3,1.2,1.1,1.0,0.9,1.0,1.1,1.2,1.3,1.4,1.3,1.2,1.1,1.0,1.1,1.2,1.1},
	Pop        = {0.8,0.9,1.0,1.2,1.4,1.6,1.5,1.4,1.2,1.1,1.1,1.2,1.4,1.5,1.6,1.5,1.3,1.1,0.9,0.8},
	Electronic = {1.8,1.7,1.5,1.3,1.1,0.9,0.8,0.9,1.1,1.3,1.5,1.7,1.9,2.0,2.0,1.9,1.8,1.7,1.6,1.5},
}

local currentPreset = "Normal"
local eqVisual      = EQ_VISUAL[currentPreset]

-- Warna bar berdasarkan posisi
local function barColor(i)
	local t = (i-1)/(BAR_COUNT-1)
	if t < 0.5 then
		local r = t/0.5
		return Color3.fromRGB(
			math.floor(0   + r*0),
			math.floor(220 - r*20),
			math.floor(255 - r*75))
	else
		local r = (t-0.5)/0.5
		return Color3.fromRGB(
			math.floor(0   + r*255),
			math.floor(200 + r*0),
			math.floor(180 - r*130))
	end
end

-- ─── Terapkan EQ ke Sound ────────────────────────────────────
local function applyEQToSound(sound, presetName)
	if not sound then return end
	local settings = EQ_SOUND_SETTINGS[presetName]
	if not settings then return end

	-- Cari atau buat EqualizerSoundEffect
	local eq = sound:FindFirstChildOfClass("EqualizerSoundEffect")
	if not eq then
		eq = Instance.new("EqualizerSoundEffect")
		eq.Name   = "MusicEQ"
		eq.Parent = sound
	end
	eq.LowGain  = settings.LowGain
	eq.MidGain  = settings.MidGain
	eq.HighGain = settings.HighGain
end

local function applyEQToAll(presetName)
	for _, sound in ipairs(Playlist.SoundList) do
		applyEQToSound(sound, presetName)
	end
end

function GrafikMusicBar.Setup(visualizerFrame)
	if not visualizerFrame then return end
	local panelRoot = visualizerFrame:FindFirstAncestor("MusikPanel")

	for _, ch in ipairs(visualizerFrame:GetChildren()) do ch:Destroy() end
	bars = {}

	local layout = Instance.new("UIListLayout")
	layout.FillDirection       = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment   = Enum.VerticalAlignment.Bottom
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.Padding             = UDim.new(0,2)
	layout.Parent              = visualizerFrame

	-- Hitung lebar bar berdasarkan frame
	task.defer(function()
		local frameW = visualizerFrame.AbsoluteSize.X
		local BAR_W  = math.max(math.floor((frameW - (BAR_COUNT-1)*2) / BAR_COUNT), 5)

		for i = 1, BAR_COUNT do
			local bar = Instance.new("Frame")
			bar.Name             = "Bar"..i
			bar.Size             = UDim2.new(0,BAR_W,0,4)
			bar.BackgroundColor3 = barColor(i)
			bar.BorderSizePixel  = 0
			bar.LayoutOrder      = i
			bar.Parent           = visualizerFrame

			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0,2); c.Parent = bar

			table.insert(bars, bar)
		end
	end)

	local t = 0
	local targetH  = {}
	local currentH = {}
	for i = 1, BAR_COUNT do targetH[i] = 4; currentH[i] = 4 end

	if connection then connection:Disconnect() end
	connection = RunService.RenderStepped:Connect(function(dt)
		if #bars == 0 then return end
		if panelRoot and not panelRoot.Visible then return end
		local sound = Playlist.GetCurrentSound()
		t = t + dt * 8

		if sound and sound.IsPlaying then
			local loudness   = sound.PlaybackLoudness
			local normalized = math.clamp(loudness / 400, 0, 1)

			for i = 1, math.min(#bars, BAR_COUNT) do
				local eq   = eqVisual[i] or 1
				local wave = math.abs(math.sin(t*1.1 + i*0.4))
					+ math.abs(math.sin(t*0.7 + i*0.65)) * 0.35
				local base = normalized > 0.01
					and (normalized * 40 * eq * wave)
					or  (math.abs(math.sin(t*0.45 + i*0.3)) * 5)
				targetH[i] = math.clamp(base + 4, 4, 50)
			end
		else
			for i = 1, BAR_COUNT do
				targetH[i] = 4 + math.abs(math.sin(t*0.35 + i*0.45)) * 4
			end
		end

		-- Smooth lerp
		for i, bar in ipairs(bars) do
			if not bar or not bar.Parent then continue end
			local lerp = math.min(dt * 20, 1)
			currentH[i] = currentH[i] + (targetH[i] - currentH[i]) * lerp
			local h = math.floor(currentH[i])
			if math.abs(bar.Size.Y.Offset - h) > 0.5 then
				bar.Size = UDim2.new(0, bar.Size.X.Offset, 0, h)
			end
		end
	end)
end

-- ─── Set Preset ──────────────────────────────────────────────
function GrafikMusicBar.SetPreset(presetName)
	local vis = EQ_VISUAL[presetName]
	if not vis then return end
	currentPreset = presetName
	eqVisual      = vis
	-- Terapkan ke semua sound
	applyEQToAll(presetName)
end

function GrafikMusicBar.GetPresets()
	local list = {}
	for k in pairs(EQ_VISUAL) do table.insert(list, k) end
	table.sort(list)
	return list
end

function GrafikMusicBar.GetCurrentPreset()
	return currentPreset
end

return GrafikMusicBar