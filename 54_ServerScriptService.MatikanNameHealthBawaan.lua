-- Matikan nama + health bar bawaan Roblox (overhead custom sudah menanganinya)
local Players = game:GetService("Players")

local function matikan(char)
	local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 10)
	if not hum then return end
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType   = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.NameDisplayDistance = 0
	hum.HealthDisplayDistance = 0
end

local function pasang(p)
	if p.Character then matikan(p.Character) end
	p.CharacterAdded:Connect(matikan)
end

Players.PlayerAdded:Connect(pasang)
for _, p in ipairs(Players:GetPlayers()) do pasang(p) end