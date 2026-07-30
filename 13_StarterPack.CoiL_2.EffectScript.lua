-- ============================================
-- EffectScript (CoiL 2) — FIXED
-- Fix:
--   • Variabel salah nama: "ServerStorage" diisi ReplicatedStorage
--     → AuroraTool ada di ReplicatedStorage bukan ServerStorage
--     → Script ini LocalScript, tidak bisa akses ServerStorage
--   • Hapus semua warn/print debug
--   • Tambah guard nil check sebelum clone
-- ============================================

local Tool              = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- FIX: AuroraTool ada di ReplicatedStorage (bisa diakses LocalScript)
local auroraToolFolder = ReplicatedStorage:FindFirstChild("AuroraTool")
local sourceTorso      = auroraToolFolder and auroraToolFolder:FindFirstChild("Torso2")

local EFFECT_TYPES = {
	"Beam", "ParticleEmitter", "Trail",
	"PointLight", "SpotLight", "SurfaceLight", "Sound"
}

local clonedInstances = {}

local function isEffect(instance)
	for _, effectType in ipairs(EFFECT_TYPES) do
		if instance.ClassName == effectType then return true end
	end
	return false
end

local function Equipped()
	if not sourceTorso then return end

	local character   = Tool.Parent
	local playerTorso = character:FindFirstChild("Torso")
		or character:FindFirstChild("UpperTorso")
	if not playerTorso then return end

	-- Clone attachments dulu
	local clonedAttachments = {}
	for _, child in ipairs(sourceTorso:GetChildren()) do
		if child.ClassName == "Attachment" then
			local ok, cloned = pcall(function() return child:Clone() end)
			if ok and cloned then
				cloned.Parent = playerTorso
				clonedAttachments[child.Name] = cloned
				table.insert(clonedInstances, cloned)
				for _, effect in ipairs(cloned:GetChildren()) do
					table.insert(clonedInstances, effect)
				end
			end
		end
	end

	-- Clone effects
	for _, child in ipairs(sourceTorso:GetChildren()) do
		if isEffect(child) then
			local ok, cloned = pcall(function() return child:Clone() end)
			if ok and cloned then
				cloned.Parent = playerTorso
				table.insert(clonedInstances, cloned)
				-- Fix trail attachments
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