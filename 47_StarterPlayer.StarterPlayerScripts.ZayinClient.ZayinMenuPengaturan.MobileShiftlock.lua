-- MobileShiftlock | ModuleScript [PATCH]
-- Shiftlock manual untuk touch: karakter selalu menghadap arah kamera.
local MobileShiftlock = {}
local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")
local player     = Players.LocalPlayer

local active = false
local conn   = nil
local CAMERA_OFFSET = Vector3.new(1.75, 0, 0) -- geser bahu; Vector3.zero kalau tak mau

local function getHum()
	local c = player.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

function MobileShiftlock.Set(on)
	active = on
	local hum = getHum()
	if on then
		if hum then
			hum.AutoRotate   = false
			hum.CameraOffset = CAMERA_OFFSET
		end
		if conn then conn:Disconnect() end
		conn = RunService.RenderStepped:Connect(function()
			local cam = workspace.CurrentCamera
			if cam.CameraType == Enum.CameraType.Scriptable then return end -- jangan lawan Freecam
			local h    = getHum()
			local ch   = player.Character
			local hrp  = ch and ch:FindFirstChild("HumanoidRootPart")
			if not (h and hrp) then return end
			if h.Sit or h.PlatformStand then return end -- jangan lawan gendong/duduk
			local look = cam.CFrame.LookVector
			local yaw  = math.atan2(-look.X, -look.Z)
			hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, yaw, 0)
		end)
	else
		if conn then conn:Disconnect(); conn = nil end
		if hum then
			hum.AutoRotate   = true
			hum.CameraOffset = Vector3.zero
		end
	end
end

function MobileShiftlock.Toggle()   MobileShiftlock.Set(not active) end
function MobileShiftlock.IsActive() return active end

player.CharacterAdded:Connect(function()
	task.wait(0.3)
	if active then MobileShiftlock.Set(true) end
end)

return MobileShiftlock