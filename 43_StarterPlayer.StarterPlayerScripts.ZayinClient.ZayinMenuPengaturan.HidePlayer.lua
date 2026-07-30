local HidePlayer = {}
local Players = game:GetService("Players")

local playerVisibilityStates = {}

function HidePlayer.Toggle(hide)
	local player = Players.LocalPlayer
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			if not playerVisibilityStates[p.UserId] then
				playerVisibilityStates[p.UserId] = {parts = {}}
			end
			local state = playerVisibilityStates[p.UserId]
			for _, part in pairs(p.Character:GetDescendants()) do
				if part:IsA("BasePart") or part:IsA("Decal") then
					if hide then
						if not state.parts[part] then state.parts[part] = part.Transparency end
						part.Transparency = 1
					else
						if state.parts[part] then
							part.Transparency = state.parts[part]
							state.parts[part] = nil
						else
							part.Transparency = 0
						end
					end
				end
			end
		end
	end
end

return HidePlayer