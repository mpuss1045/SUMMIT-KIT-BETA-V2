--Anti delay BY lynzee
--free script jangan di jual 
 
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local character = nil
local humanoid = nil
local rootPart = nil

local function setupCharacter(char)
	character = char
	humanoid = character:WaitForChild("Humanoid", 10)
	rootPart = character:WaitForChild("HumanoidRootPart", 10)

	if humanoid and rootPart then
		humanoid.AutoRotate = true
	else
	end
end

LocalPlayer.CharacterAdded:Connect(setupCharacter)

if LocalPlayer.Character then
	setupCharacter(LocalPlayer.Character)
end

RunService.RenderStepped:Connect(function(deltaTime)
	if not humanoid or not rootPart or not character then
		return
	end

	if humanoid.Health <= 0 then
		return
	end

	local isFlying = humanoid:GetAttribute("Flying") or false
	local isNoclip = humanoid:GetAttribute("Noclip") or false
	local isDisabled = humanoid:GetAttribute("Disabled") or false

	if isFlying or isNoclip or isDisabled then
		return
	end

	local moveDirection = humanoid.MoveDirection

	if moveDirection.Magnitude < 0.1 then
		return
	end

	local targetVelocity = moveDirection * (humanoid.WalkSpeed * 0.95)

	local currentVelocity = rootPart.AssemblyLinearVelocity
	local currentHorizontal = Vector3.new(currentVelocity.X, 0, currentVelocity.Z)

	local neededVelocity = Vector3.new(
		targetVelocity.X - currentHorizontal.X,
		0,
		targetVelocity.Z - currentHorizontal.Z
	)

	if neededVelocity.Magnitude > 9999 then
		neededVelocity = neededVelocity.Unit * 9999
	end

	local impulseStrength = 8 * rootPart.AssemblyMass * deltaTime
	rootPart:ApplyImpulse(neededVelocity * impulseStrength)
end)