-- ============================================================
-- EffectScriptV2 — OPTIMIZED
-- Perubahan:
--   • Hapus semua warn() debug (tidak perlu di production)
--   • Hapus print debug
--   • Tidak ada perubahan logika
-- (Script ini sama untuk ShopTools/CoiL VIP dan VIPTools/CoiL VIP)
-- ============================================================

local Tool = script.Parent
local ServerStorage = game:GetService("ServerStorage")

local auroraToolFolder = ServerStorage:FindFirstChild("AuroraTool")
local sourceMain = auroraToolFolder and auroraToolFolder:FindFirstChild("Main")

local EFFECT_TYPES = {
	"Beam","ParticleEmitter","Trail",
	"PointLight","SpotLight","SurfaceLight","Sound"
}

local clonedInstances = {}

local function isEffect(instance)
	for _, effectType in ipairs(EFFECT_TYPES) do
		if instance.ClassName == effectType then return true end
	end
	return false
end

local function getCharacterType(character)
	local upperTorso = character:FindFirstChild("UpperTorso")
	local lowerTorso = character:FindFirstChild("LowerTorso")
	return (upperTorso and lowerTorso) and "R15" or "R6"
end

local function getTargetParts(character, charType)
	if charType == "R15" then
		return {
			character:FindFirstChild("RightHand"),
			character:FindFirstChild("LeftHand"),
			character:FindFirstChild("RightFoot"),
			character:FindFirstChild("LeftFoot"),
		}
	else
		return {
			character:FindFirstChild("Right Arm"),
			character:FindFirstChild("Left Arm"),
			character:FindFirstChild("Right Leg"),
			character:FindFirstChild("Left Leg"),
		}
	end
end

local function cloneEffectsToTarget(sourcePart, targetPart)
	if not sourcePart or not targetPart then return end

	local clonedAttachments = {}

	for _, child in ipairs(sourcePart:GetChildren()) do
		if child.ClassName == "Attachment" then
			local ok, cloned = pcall(function() return child:Clone() end)
			if ok and cloned then
				cloned.Parent = targetPart
				clonedAttachments[child.Name] = cloned
				table.insert(clonedInstances, cloned)
				for _, effect in ipairs(cloned:GetChildren()) do
					table.insert(clonedInstances, effect)
				end
			end
		end
	end

	for _, child in ipairs(sourcePart:GetChildren()) do
		if isEffect(child) then
			local ok, cloned = pcall(function() return child:Clone() end)
			if ok and cloned then
				cloned.Parent = targetPart
				table.insert(clonedInstances, cloned)
				if cloned.ClassName == "Trail" then
					local a0 = child.Attachment0 and child.Attachment0.Name
					local a1 = child.Attachment1 and child.Attachment1.Name
					if a0 and clonedAttachments[a0] then cloned.Attachment0 = clonedAttachments[a0] end
					if a1 and clonedAttachments[a1] then cloned.Attachment1 = clonedAttachments[a1] end
				end
			end
		end
	end
end

local function Equipped()
	if not sourceMain then return end
	local character  = Tool.Parent
	local charType   = getCharacterType(character)
	local targetParts = getTargetParts(character, charType)
	for _, targetPart in ipairs(targetParts) do
		if targetPart then cloneEffectsToTarget(sourceMain, targetPart) end
	end
end

local function Unequipped()
	for _, instance in ipairs(clonedInstances) do
		if instance and instance.Parent then
			pcall(function() instance:Destroy() end)
		end
	end
	clonedInstances = {}
end

Tool.Equipped:Connect(Equipped)
Tool.Unequipped:Connect(Unequipped)