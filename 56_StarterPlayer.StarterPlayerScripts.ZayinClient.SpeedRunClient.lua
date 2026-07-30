-- SpeedRunClient FIXED
-- Fix: hapus double assignment timerFrame.Position (baris duplikat)
-- Fix: bestLabel text/color properties diurutkan dengan benar

local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ZR        = RS:WaitForChild("ZayinRemotes")
local SRRemotes = ZR:WaitForChild("SpeedRun")
local StartRE   = SRRemotes:WaitForChild("Start")
local FinishRE  = SRRemotes:WaitForChild("Finish")
local FailedRE  = SRRemotes:WaitForChild("Failed")

local timerRunning = false
local startTime    = 0
local timerConn    = nil

local function formatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%02d:%06.3f", mins, secs)
end

local function formatTimeShort(seconds)
	local m  = math.floor(seconds / 60)
	local s  = math.floor(seconds % 60)
	local ms = math.floor((seconds % 1) * 1000)
	return string.format("%02d:%02d.%03d", m, s, ms)
end

-- ── Timer GUI ──
local timerGui = Instance.new("ScreenGui")
timerGui.Name         = "ZayinTimerGui"
timerGui.ResetOnSpawn = false
timerGui.DisplayOrder = 10
timerGui.Enabled      = false
timerGui.Parent       = playerGui

-- [GUIFIX] Sebagian jalur ganti avatar (ApplyDescription/rebuild) bisa
-- melepas ScreenGui dari PlayerGui walau ResetOnSpawn=false. Pasang ulang
-- otomatis kalau itu terjadi, supaya StartRE/FailedRE tidak jatuh ke GUI yatim.
local function pastikanTerpasang()
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if pg and timerGui.Parent ~= pg then
		timerGui.Parent = pg
	end
end
timerGui.AncestryChanged:Connect(function(_, parent)
	if parent == nil then
		task.defer(pastikanTerpasang)
	end
end)
player.CharacterAdded:Connect(function()
	-- beri waktu PlayerGui/avatar selesai lalu pastikan GUI masih nempel
	task.delay(0.2, pastikanTerpasang)
	task.delay(1.5, pastikanTerpasang)
end)

local timerFrame = Instance.new("Frame", timerGui)
timerFrame.Size             = UDim2.new(0, 150, 0, 36)
timerFrame.AnchorPoint      = Vector2.new(0.5, 0)
-- FIX: hanya satu assignment Position (sebelumnya duplikat)
timerFrame.Position         = UDim2.new(0.5, 0, 0.01, 0)
timerFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
timerFrame.BackgroundTransparency = 0.2
timerFrame.BorderSizePixel  = 0
Instance.new("UICorner", timerFrame).CornerRadius = UDim.new(0, 8)
local timerStroke = Instance.new("UIStroke", timerFrame)
timerStroke.Color     = Color3.fromRGB(0, 255, 220)
timerStroke.Thickness = 1.5

local timerLabel = Instance.new("TextLabel", timerFrame)
timerLabel.Size               = UDim2.new(1, 0, 0.55, 0)
timerLabel.Position           = UDim2.new(0, 0, 0, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.Text               = "00:00.000"
timerLabel.TextColor3         = Color3.fromRGB(0, 255, 220)
timerLabel.TextScaled         = true
timerLabel.Font               = Enum.Font.GothamBold

local bestLabel = Instance.new("TextLabel", timerFrame)
bestLabel.Size               = UDim2.new(1, 0, 0.4, 0)
bestLabel.Position           = UDim2.new(0, 0, 0.58, 0)
bestLabel.BackgroundTransparency = 1
bestLabel.Text               = "Best: -"
bestLabel.TextColor3         = Color3.fromRGB(255, 215, 0)
bestLabel.TextScaled         = true
bestLabel.Font               = Enum.Font.Gotham

-- Load BestTime dari leaderstats
task.spawn(function()
	local ls = player:WaitForChild("leaderstats", 10)
	if ls then
		local bt = ls:WaitForChild("BestTime", 10)
		if bt then
			local function updateBest()
				if bt.Value ~= "-" then bestLabel.Text = "Best: " .. bt.Value end
			end
			updateBest()
			bt.Changed:Connect(updateBest)
		end
	end
end)

-- ── Timer functions ──
local function startTimer()
	if timerConn then timerConn:Disconnect() end
	pastikanTerpasang() -- [GUIFIX] jaga GUI nempel walau habis ganti avatar
	timerRunning = true; startTime = tick()
	timerGui.Enabled = true
	timerLabel.TextColor3 = Color3.fromRGB(0, 255, 220)
	timerLabel.Text = "00:00.000"
	timerConn = RunService.Heartbeat:Connect(function()
		if not timerRunning then return end
		timerLabel.Text = formatTime(tick() - startTime)
	end)
end

local function stopTimer(elapsed)
	timerRunning = false
	if timerConn then timerConn:Disconnect(); timerConn = nil end
	if elapsed then timerLabel.Text = formatTime(elapsed) end
end

local function hideTimer()
	timerGui.Enabled = false
	timerLabel.Text = "00:00.000"
	timerLabel.TextColor3 = Color3.fromRGB(0, 255, 220)
end

-- ── Remote events ──
StartRE.OnClientEvent:Connect(function()
	startTimer()
end)

FinishRE.OnClientEvent:Connect(function(elapsed, bestTime)
	pastikanTerpasang() -- [GUIFIX]
	timerGui.Enabled = true
	stopTimer(elapsed)
	if bestTime then bestLabel.Text = "Best: " .. formatTimeShort(bestTime) end
	task.delay(9, function() if not timerRunning then hideTimer() end end)
end)

FailedRE.OnClientEvent:Connect(function()
	pastikanTerpasang() -- [GUIFIX]
	timerGui.Enabled = true
	stopTimer(nil)
	timerLabel.Text = "CURANG ❌"
	timerLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	task.delay(9, function() if not timerRunning then hideTimer() end end)
end)

print("[SpeedRunClient FIXED] Ready!")