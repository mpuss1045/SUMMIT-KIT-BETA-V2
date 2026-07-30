local GraphicMode = {}
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local originalLightingSettings = {}

function GraphicMode.Initialize()
	originalLightingSettings = {
		Brightness               = Lighting.Brightness,
		Ambient                  = Lighting.Ambient,
		GlobalShadows            = Lighting.GlobalShadows,
		OutdoorAmbient           = Lighting.OutdoorAmbient,
		EnvironmentDiffuseScale  = Lighting.EnvironmentDiffuseScale,
		EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
	}
end

function GraphicMode.ToggleShadow(hide, hideCoilModule, hiddenAurasDict)
	Lighting.GlobalShadows = not hide
	if hide then
		if Players.LocalPlayer.Character then hideCoilModule.RemoveAuras(Players.LocalPlayer.Character, true, hiddenAurasDict) end
	else
		if Players.LocalPlayer.Character then hideCoilModule.RestoreAuras(Players.LocalPlayer.Character, hiddenAurasDict) end
	end
end

function GraphicMode.ToggleGraphic(isLow, hideCoilModule, hiddenAurasDict)
	if not isLow then
		for key, value in pairs(originalLightingSettings) do
			pcall(function() Lighting[key] = value end)
		end
		for _, p in pairs(Players:GetPlayers()) do
			if p.Character then hideCoilModule.RestoreAuras(p.Character, hiddenAurasDict) end
		end
	else
		pcall(function() Lighting.GlobalShadows = false end)
		pcall(function() Lighting.Brightness = 2 end)
		pcall(function() Lighting.EnvironmentDiffuseScale = 0.5 end)
		pcall(function() Lighting.EnvironmentSpecularScale = 0.5 end)
		for _, p in pairs(Players:GetPlayers()) do
			if p.Character then hideCoilModule.RemoveAuras(p.Character, true, hiddenAurasDict) end
		end
	end
end

return GraphicMode