-- ============================================================
--  SliderSpeed.lua  |  Speed Control  |  v2.0
--  Tombol − / + dengan hold-to-repeat
--  Step 0.1x | Range 0.5x–2.0x | Default 1.0x
--  Fix: holdThread di-cancel dengan benar saat lepas
-- ============================================================

local SliderSpeed = {}

local SPEED_MIN  = 0.5
local SPEED_MAX  = 2.0
local SPEED_DEF  = 1.0
local SPEED_STEP = 0.1

local HOLD_DELAY  = 0.4   -- detik sebelum repeat mulai
local HOLD_REPEAT = 0.12  -- interval repeat

local currentSpeed = SPEED_DEF

local function round1(n)
	return math.floor(n * 10 + 0.5) / 10
end

function SliderSpeed.Init(sliderFrame, onSpeedChanged)
	if not sliderFrame then return end

	local btnMinus = sliderFrame:FindFirstChild("BtnMinus")
	local btnPlus  = sliderFrame:FindFirstChild("BtnPlus")
	local valLbl   = sliderFrame:FindFirstChild("Value")
	local resetBtn = sliderFrame:FindFirstChild("ResetSpeedBtn")

	if not btnMinus or not btnPlus then
		warn("[SliderSpeed] BtnMinus / BtnPlus tidak ditemukan!")
		return
	end

	local function applySpeed(speed)
		currentSpeed = round1(math.clamp(speed, SPEED_MIN, SPEED_MAX))
		if valLbl then
			valLbl.Text = string.format("%.1fx", currentSpeed)
		end
		if onSpeedChanged then
			onSpeedChanged(currentSpeed)
		end
	end

	applySpeed(SPEED_DEF)

	-- Hold-to-repeat: tahan tombol → terus naik/turun
	local function makeHoldBtn(btn, delta)
		local holding    = false
		local holdThread = nil

		local function stopHold()
			holding = false
			if holdThread then
				task.cancel(holdThread)
				holdThread = nil
			end
		end

		local function startHold()
			if holding then return end
			holding = true
			holdThread = task.delay(HOLD_DELAY, function()
				while holding do
					applySpeed(currentSpeed + delta)
					task.wait(HOLD_REPEAT)
				end
			end)
		end

		-- Klik biasa
		btn.MouseButton1Click:Connect(function()
			applySpeed(currentSpeed + delta)
		end)

		-- PC hold
		btn.MouseButton1Down:Connect(startHold)
		btn.MouseButton1Up:Connect(stopHold)
		btn.MouseLeave:Connect(stopHold)

		-- Mobile hold
		btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				startHold()
			end
		end)
		btn.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				stopHold()
			end
		end)
	end

	makeHoldBtn(btnMinus, -SPEED_STEP)
	makeHoldBtn(btnPlus,   SPEED_STEP)

	if resetBtn then
		resetBtn.MouseButton1Click:Connect(function()
			applySpeed(SPEED_DEF)
		end)
	end
end

-- Getter untuk speed saat ini (optional, dipakai script lain)
function SliderSpeed.GetSpeed()
	return currentSpeed
end

return SliderSpeed