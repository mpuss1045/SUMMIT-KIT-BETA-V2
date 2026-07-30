local HideCoil = {}
local Players = game:GetService("Players")

local activeConnections = {}

local function HideSingleDescendant(descendant, character, hiddenAurasDict)
	if not hiddenAurasDict[character] then hiddenAurasDict[character] = {} end

	-- Jika objek sudah pernah di-hide, jangan timpa nilai original-nya
	if hiddenAurasDict[character][descendant] then return end

	local isAura = descendant:GetAttribute("AuraShop") or descendant:GetAttribute("IsAura") or descendant.Name:find("^Aura_") or descendant.Name:find("Coil")
	local isToolDescendant = descendant:FindFirstAncestorOfClass("Tool")

	if isAura and not isToolDescendant then
		hiddenAurasDict[character][descendant] = {
			parent  = descendant.Parent,
			action  = "Unparent"
		}
		descendant.Parent = nil
	end

	if descendant:IsA("Trail") or descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") or descendant:IsA("Fire") or descendant:IsA("Sparkles") or descendant:IsA("Light") then
		hiddenAurasDict[character][descendant] = {
			action = "Enabled",
			originalValue = descendant.Enabled
		}
		descendant.Enabled = false
	end
end

function HideCoil.RemoveAuras(character, includeOwnPlayer, hiddenAurasDict)
	local player = Players.LocalPlayer
	if not character then return end
	if not includeOwnPlayer and character == player.Character then return end

	if not hiddenAurasDict[character] then hiddenAurasDict[character] = {} end

	-- Hook listener agar tool baru yang diequip langsung ter-hide efeknya
	if activeConnections[character] then
		activeConnections[character]:Disconnect()
	end

	activeConnections[character] = character.DescendantAdded:Connect(function(descendant)
		task.wait() -- Tunggu properti ter-load
		if descendant.Parent then
			HideSingleDescendant(descendant, character, hiddenAurasDict)
		end
	end)

	for _, descendant in ipairs(character:GetDescendants()) do
		HideSingleDescendant(descendant, character, hiddenAurasDict)
	end
end

function HideCoil.RestoreAuras(character, hiddenAurasDict)
	if not character then return end

	if activeConnections[character] then
		activeConnections[character]:Disconnect()
		activeConnections[character] = nil
	end

	if not hiddenAurasDict[character] then return end

	for object, data in pairs(hiddenAurasDict[character]) do
		if data.action == "Unparent" then
			if object and data.parent then
				object.Parent = data.parent
			end
		elseif data.action == "Transparency" then
			if object then
				object.Transparency = data.originalValue
			end
		elseif data.action == "Enabled" then
			if object then
				object.Enabled = data.originalValue
			end
		end
	end
	hiddenAurasDict[character] = nil
end

function HideCoil.Toggle(hide, hiddenAurasDict)
	if hide then
		for _, p in pairs(Players:GetPlayers()) do
			if p.Character then
				HideCoil.RemoveAuras(p.Character, true, hiddenAurasDict)
			end
		end
	else
		for _, p in pairs(Players:GetPlayers()) do
			if p.Character then
				HideCoil.RestoreAuras(p.Character, hiddenAurasDict)
			end
		end
	end
end

return HideCoil