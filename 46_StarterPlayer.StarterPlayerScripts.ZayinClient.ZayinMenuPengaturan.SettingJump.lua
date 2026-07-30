local SettingJump = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local jumpControlGui = nil
local originalJumpSize = UDim2.new(0, 90, 0, 90)
local originalJumpPos = UDim2.new(1, -100, 1, -100)

local jumpSettings = {
	Size = UDim2.new(0, 90, 0, 90),
	Position = UDim2.new(1, -100, 1, -100),
	Locked = true
}

local dragging = false
local dragStart, startPos
local dragConnections = {}

local plusHolding = false
local minusHolding = false
local holdConnection = nil

local function findTouchGuiElements()
	local playerGui = player:WaitForChild("PlayerGui", 10)
	local touchGui = playerGui:FindFirstChild("TouchGui")
	if not touchGui then return nil, nil, nil end
	local controlFrame = touchGui:FindFirstChild("TouchControlFrame")
	if not controlFrame then return touchGui, nil, nil end
	local jumpBtn = controlFrame:FindFirstChild("JumpButton")
	return touchGui, controlFrame, jumpBtn
end

function SettingJump.Apply()
	local _, _, jumpBtn = findTouchGuiElements()
	if jumpBtn then
		jumpBtn.Size = jumpSettings.Size
		jumpBtn.Position = jumpSettings.Position
	end
end

local function cleanupDragConnections()
	for _, conn in pairs(dragConnections) do
		if conn then conn:Disconnect() end
	end
	dragConnections = {}
end

local function setupDragSystem(jumpBtn)
	if not jumpBtn then return end
	cleanupDragConnections()
	if not jumpSettings.Locked then
		local conn1 = jumpBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos  = jumpBtn.Position
			end
		end)
		local conn2 = jumpBtn.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				jumpBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)
		local conn3 = jumpBtn.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		table.insert(dragConnections, conn1)
		table.insert(dragConnections, conn2)
		table.insert(dragConnections, conn3)
	end
end

function SettingJump.Toggle(isLocked, updateToggleUIFunc, settingFrame)
	jumpSettings.Locked = isLocked
	if jumpSettings.Locked then
		updateToggleUIFunc(settingFrame, false, true)
		cleanupDragConnections()
		SettingJump.Apply()
		if jumpControlGui then
			jumpControlGui:Destroy()
			jumpControlGui = nil
		end
	else
		updateToggleUIFunc(settingFrame, true, true)
		SettingJump.CreateGUI(updateToggleUIFunc, settingFrame)
	end
end

function SettingJump.CreateGUI(updateToggleUIFunc, settingFrame)
	if jumpControlGui then jumpControlGui:Destroy() jumpControlGui = nil end
	local _, _, jumpBtn = findTouchGuiElements()
	if not jumpBtn then return end

	SettingJump.Apply()
	setupDragSystem(jumpBtn)

	if not jumpSettings.Locked then
		local playerGui = player:WaitForChild("PlayerGui", 10)
		jumpControlGui = Instance.new("ScreenGui")
		jumpControlGui.Name = "JumpControlGui"
		jumpControlGui.ResetOnSpawn = false
		jumpControlGui.Parent = playerGui

		local controlContainer = Instance.new("Frame")
		controlContainer.Name = "ControlContainer"
		controlContainer.Size = UDim2.new(0, 170, 0, 40)
		controlContainer.BackgroundTransparency = 1
		controlContainer.Parent = jumpControlGui

		local function updateControlPosition()
			local jumpPos  = jumpBtn.AbsolutePosition
			local jumpSize = jumpBtn.AbsoluteSize
			controlContainer.Position = UDim2.new(0, jumpPos.X + (jumpSize.X / 2) - 85, 0, math.max(10, jumpPos.Y - 60))
		end

		updateControlPosition()

		local function makeBtn(text, xOffset, fontSize)
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(0, 35, 0, 35)
			btn.Position = UDim2.new(0, xOffset, 0, 2.5)
			btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			btn.Text = text
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = fontSize or 20
			btn.Parent = controlContainer

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.15, 0)
			corner.Parent = btn

			local stroke = Instance.new("UIStroke")
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Color = Color3.fromRGB(56, 56, 56)
			stroke.Thickness = 1.5
			stroke.Transparency = 0
			stroke.Parent = btn

			return btn
		end

		local minusBtn = makeBtn("-", 0)
		local resetBtn = makeBtn("Reset", 40, 11); resetBtn.Size = UDim2.new(0, 45, 0, 35)
		local saveBtn  = makeBtn("Save", 90, 11);  saveBtn.Size  = UDim2.new(0, 45, 0, 35)
		local plusBtn  = makeBtn("+", 140)

		local function stopHolding()
			plusHolding = false
			minusHolding = false
			if holdConnection then holdConnection:Disconnect() holdConnection = nil end
		end

		minusBtn.MouseButton1Down:Connect(function()
			minusHolding = true
			jumpBtn.Size = UDim2.new(0, math.max(30, jumpBtn.Size.X.Offset - 10), 0, math.max(30, jumpBtn.Size.X.Offset - 10))
			updateControlPosition()
			task.wait(0.3)
			if minusHolding then
				holdConnection = RunService.Heartbeat:Connect(function()
					if minusHolding then
						local s = math.max(30, jumpBtn.Size.X.Offset - math.min(5, jumpBtn.Size.X.Offset * 0.02))
						jumpBtn.Size = UDim2.new(0, s, 0, s)
						updateControlPosition()
					end
				end)
			end
		end)
		minusBtn.MouseButton1Up:Connect(stopHolding)
		minusBtn.MouseLeave:Connect(stopHolding)

		plusBtn.MouseButton1Down:Connect(function()
			plusHolding = true
			local screenH = jumpBtn.Parent.AbsoluteSize.Y
			local s = math.min(screenH, jumpBtn.Size.X.Offset + 10)
			jumpBtn.Size = UDim2.new(0, s, 0, s)
			updateControlPosition()
			task.wait(0.3)
			if plusHolding then
				holdConnection = RunService.Heartbeat:Connect(function()
					if plusHolding then
						local screenH2 = jumpBtn.Parent.AbsoluteSize.Y
						local s2 = math.min(screenH2, jumpBtn.Size.X.Offset + math.min(5, jumpBtn.Size.X.Offset * 0.02))
						jumpBtn.Size = UDim2.new(0, s2, 0, s2)
						updateControlPosition()
					end
				end)
			end
		end)
		plusBtn.MouseButton1Up:Connect(stopHolding)
		plusBtn.MouseLeave:Connect(stopHolding)

		resetBtn.MouseButton1Click:Connect(function()
			jumpBtn.Size = originalJumpSize
			jumpBtn.Position = originalJumpPos
			updateControlPosition()
		end)

		saveBtn.MouseButton1Click:Connect(function()
			jumpSettings.Size = jumpBtn.Size
			jumpSettings.Position = jumpBtn.Position
			jumpSettings.Locked = true

			for _, child in pairs({minusBtn, resetBtn, saveBtn, plusBtn}) do
				TweenService:Create(child, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
			end
			task.wait(0.3)

			if jumpControlGui then jumpControlGui:Destroy() jumpControlGui = nil end
			cleanupDragConnections()
			SettingJump.Apply()

			if updateToggleUIFunc and settingFrame then
				updateToggleUIFunc(settingFrame, false, true)
			end
		end)

		local updateConn
		updateConn = RunService.RenderStepped:Connect(function()
			if jumpControlGui and jumpControlGui.Parent then
				updateControlPosition()
			else
				if updateConn then updateConn:Disconnect() end
			end
		end)

		jumpControlGui.Destroying:Connect(function()
			cleanupDragConnections()
			stopHolding()
		end)
	end
end

return SettingJump