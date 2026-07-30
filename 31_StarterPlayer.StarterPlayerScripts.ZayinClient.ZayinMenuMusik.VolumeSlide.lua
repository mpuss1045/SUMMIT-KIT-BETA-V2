-- ============================================================
--  VolumeControl.lua  v2
--  Ganti slider → tombol − / angka / +
--  Nama file tetap VolumeSlide agar tidak perlu ganti require
-- ============================================================

local VolumeSlide      = {}
local Playlist         = require(script.Parent.Playlist)

VolumeSlide.Volume = 0.8
local STEP   = 0.05
local V_MIN  = 0
local V_MAX  = 1

-- Hold-to-repeat
local HOLD_DELAY  = 0.35
local HOLD_REPEAT = 0.1

local function round(n)
	return math.floor(n * 100 + 0.5)
end

local function applyVolume(vol, uiElements)
	VolumeSlide.Volume = math.clamp(vol, V_MIN, V_MAX)
	for _, s in ipairs(Playlist.SoundList) do
		s.Volume = VolumeSlide.Volume
	end

	-- Update label
	if uiElements.VolLabel then
		uiElements.VolLabel.Text = tostring(round(VolumeSlide.Volume)) .. "%"
	end
end

local function makeHoldBtn(btn, delta, uiElements)
	if not btn then return end
	local holding = false
	local thr     = nil

	local function startHold()
		holding = true
		thr = task.spawn(function()
			task.wait(HOLD_DELAY)
			while holding do
				applyVolume(VolumeSlide.Volume + delta, uiElements)
				task.wait(HOLD_REPEAT)
			end
		end)
	end
	local function stopHold()
		holding = false
		if thr then task.cancel(thr); thr = nil end
	end

	btn.MouseButton1Click:Connect(function()
		applyVolume(VolumeSlide.Volume + delta, uiElements)
	end)
	btn.MouseButton1Down:Connect(startHold)
	btn.MouseButton1Up:Connect(stopHold)
	btn.MouseLeave:Connect(stopHold)
	btn.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.Touch then startHold() end
	end)
	btn.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.Touch then stopHold() end
	end)
end

function VolumeSlide.Setup(uiElements)
	applyVolume(VolumeSlide.Volume, uiElements)
	makeHoldBtn(uiElements.VolMinBtn, -STEP, uiElements)
	makeHoldBtn(uiElements.VolPlusBtn, STEP, uiElements)

	-- Mute/Unmute toggle
	if uiElements.VolMuteBtn then
		local isMuted = false
		local lastVol = VolumeSlide.Volume
		uiElements.VolMuteBtn.MouseButton1Click:Connect(function()
			isMuted = not isMuted
			if isMuted then
				lastVol = VolumeSlide.Volume
				applyVolume(0, uiElements)
				uiElements.VolMuteBtn.Text = "🔇"
				uiElements.VolMuteBtn.TextColor3 = Color3.fromRGB(255,80,80)
			else
				applyVolume(lastVol > 0 and lastVol or 0.5, uiElements)
				uiElements.VolMuteBtn.Text = "🔊"
				uiElements.VolMuteBtn.TextColor3 = Color3.fromRGB(120,140,150)
			end
		end)
	end
end

return VolumeSlide