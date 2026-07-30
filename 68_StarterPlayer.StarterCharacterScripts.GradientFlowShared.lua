local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)

local SPEED = 0.6
local gradients = {}

local function registerGradient(obj)
	if not obj:IsA("UIGradient") then return end
	if not obj:GetAttribute("GradientFlow") then return end
	for _, entry in ipairs(gradients) do
		if entry[1] == obj then return end
	end
	table.insert(gradients, {obj, -1})
end

local function scanGui(gui)
	for _, desc in ipairs(gui:GetDescendants()) do
		registerGradient(desc)
	end
	gui.DescendantAdded:Connect(function(desc)
		registerGradient(desc)
	end)
end

task.spawn(function()
	task.wait(0.5)
	for _, gui in ipairs(playerGui:GetChildren()) do
		scanGui(gui)
	end
	playerGui.ChildAdded:Connect(function(gui)
		task.wait(0.1)
		scanGui(gui)
	end)
end)

RunService.RenderStepped:Connect(function(dt)
	local i = 1
	while i <= #gradients do
		local entry = gradients[i]
		local grad  = entry[1]
		if not grad or not grad.Parent then
			table.remove(gradients, i)
			continue
		end
		entry[2] = entry[2] + SPEED * dt
		if entry[2] > 1 then entry[2] = -1 end
		grad.Offset = Vector2.new(entry[2], 0)
		i += 1
	end
end)