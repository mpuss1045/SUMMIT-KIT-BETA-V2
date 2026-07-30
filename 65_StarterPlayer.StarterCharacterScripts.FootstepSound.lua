--[[
	STRUKTUR: StarterCharacterScripts/FootstepSound
	
	Footstep Sound System - Fixed Version
	- No delay
	- Synced with actual movement
	- Bug-free (no phantom sounds)
	- Proper state detection
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Character = script.Parent
local Humanoid = Character:WaitForChild("Humanoid", 10)
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 10)

-- Material sounds
local MaterialSounds = {
	[Enum.Material.Grass] = "rbxassetid://507863105",
	[Enum.Material.Metal] = "rbxassetid://944089664",
	[Enum.Material.DiamondPlate] = "rbxassetid://944089664",
	[Enum.Material.Pebble] = "rbxassetid://944090255",
	[Enum.Material.Wood] = "rbxassetid://944075408",
	[Enum.Material.WoodPlanks] = "rbxassetid://944075408",
	[Enum.Material.Plastic] = "rbxassetid://944075408",
	[Enum.Material.SmoothPlastic] = "rbxassetid://944075408",
	[Enum.Material.Sand] = "rbxassetid://944090255",
	[Enum.Material.Brick] = "rbxassetid://4981969796",
	[Enum.Material.Cobblestone] = "rbxassetid://4981969796",
	[Enum.Material.Concrete] = "rbxassetid://944075408",
	[Enum.Material.CorrodedMetal] = "rbxassetid://4981969796",
	[Enum.Material.Fabric] = "rbxassetid://4981969796",
	[Enum.Material.Foil] = "rbxassetid://4981969796",
	[Enum.Material.ForceField] = "rbxassetid://4981969796",
	[Enum.Material.Glass] = "rbxassetid://944075408",
	[Enum.Material.Granite] = "rbxassetid://944075408",
	[Enum.Material.Ice] = "rbxassetid://4981969796",
	[Enum.Material.Marble] = "rbxassetid://944075408",
	[Enum.Material.Neon] = "rbxassetid://4981969796",
	[Enum.Material.Slate] = "rbxassetid://944075408",
}

local DEFAULT_SOUND = "rbxasset://sounds/action_footsteps_plastic.mp3"
local BASE_WALKSPEED = 40
local MIN_VELOCITY = 0.5 -- Minimum velocity to play sound

-- State
local isDead = false
local connections = {}
local lastPosition = HumanoidRootPart.Position

-- Remove default sounds
local function removeDefaultSounds()
	for _, child in ipairs(HumanoidRootPart:GetChildren()) do
		if child:IsA("Sound") and child.Name ~= "CustomFootstep" then
			child:Destroy()
		end
	end

	local Head = Character:FindFirstChild("Head")
	if Head then
		for _, child in ipairs(Head:GetChildren()) do
			if child:IsA("Sound") then
				child:Destroy()
			end
		end
	end
end

removeDefaultSounds()

-- Block new default sounds
connections.childAdded = HumanoidRootPart.ChildAdded:Connect(function(child)
	if child:IsA("Sound") and child.Name ~= "CustomFootstep" then
		child:Destroy()
	end
end)

-- Create footstep sound
local FootstepSound = Instance.new("Sound")
FootstepSound.Name = "CustomFootstep"
FootstepSound.Parent = HumanoidRootPart
FootstepSound.Looped = true
FootstepSound.Volume = 0.3
FootstepSound.RollOffMode = Enum.RollOffMode.Linear
FootstepSound.RollOffMinDistance = 5
FootstepSound.RollOffMaxDistance = 100

-- Update sound based on material
local function updateMaterial()
	local material = Humanoid.FloorMaterial
	FootstepSound.SoundId = MaterialSounds[material] or DEFAULT_SOUND
end

-- Check if character is actually moving on ground
local function isActuallyMoving()
	if isDead then return false end

	-- Check humanoid state
	local state = Humanoid:GetState()
	if state == Enum.HumanoidStateType.Dead or
		state == Enum.HumanoidStateType.Freefall or
		state == Enum.HumanoidStateType.Jumping or
		state == Enum.HumanoidStateType.Flying then
		return false
	end

	-- Check if on ground
	if Humanoid.FloorMaterial == Enum.Material.Air then
		return false
	end

	-- Check actual velocity (horizontal only)
	local velocity = HumanoidRootPart.AssemblyLinearVelocity
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude

	return horizontalSpeed > MIN_VELOCITY
end

-- Main update loop using Heartbeat for accuracy
local lastSoundState = false

connections.heartbeat = RunService.Heartbeat:Connect(function()
	if isDead then return end

	local shouldPlay = isActuallyMoving()

	-- Only change state when needed
	if shouldPlay ~= lastSoundState then
		lastSoundState = shouldPlay

		if shouldPlay then
			-- Update material and speed before playing
			updateMaterial()
			local speedRatio = math.clamp(Humanoid.WalkSpeed / BASE_WALKSPEED, 0.5, 2)
			FootstepSound.PlaybackSpeed = speedRatio

			if not FootstepSound.IsPlaying then
				FootstepSound:Play()
			end
		else
			if FootstepSound.IsPlaying then
				FootstepSound:Stop()
			end
		end
	end

	-- Update playback speed while moving
	if shouldPlay then
		local speedRatio = math.clamp(Humanoid.WalkSpeed / BASE_WALKSPEED, 0.5, 2)
		FootstepSound.PlaybackSpeed = speedRatio
	end
end)

-- Material change handler
connections.material = Humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
	if not isDead and isActuallyMoving() then
		updateMaterial()
	end
end)

-- State change handler for immediate response
connections.state = Humanoid.StateChanged:Connect(function(_, newState)
	if isDead then return end

	-- Immediately stop on air states
	if newState == Enum.HumanoidStateType.Freefall or
		newState == Enum.HumanoidStateType.Jumping or
		newState == Enum.HumanoidStateType.Flying or
		newState == Enum.HumanoidStateType.Dead then
		lastSoundState = false
		if FootstepSound.IsPlaying then
			FootstepSound:Stop()
		end
	end
end)

-- Death handler
connections.died = Humanoid.Died:Connect(function()
	isDead = true
	lastSoundState = false

	if FootstepSound.IsPlaying then
		FootstepSound:Stop()
	end

	-- Cleanup
	for _, conn in pairs(connections) do
		if conn then
			pcall(function() conn:Disconnect() end)
		end
	end

	if FootstepSound then
		FootstepSound:Destroy()
	end
end)

-- Initial material update
updateMaterial()