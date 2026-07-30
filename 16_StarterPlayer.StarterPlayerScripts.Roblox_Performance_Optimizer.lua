-- ================================================
-- Roblox Performance Optimizer v4.0 (FINAL)
-- Perbaikan: collectgarbage argumen benar, GUI dihapus
-- Tempat: StarterPlayer > StarterPlayerScripts
-- ================================================

local RunService     = game:GetService("RunService")
local Lighting       = game:GetService("Lighting")
local Workspace      = game:GetService("Workspace")
local Players        = game:GetService("Players")
local LocalPlayer    = Players.LocalPlayer

-- ================================================
-- KONFIGURASI
-- ================================================
local CONFIG = {
	QualityLevel        = 1,     -- 1 (terendah) ~ 21 (tertinggi)
	MaxFPS              = 0,    -- 30 | 60 | 144 | 0 = unlimited
	DisableShadows      = true,
	DisableBloom        = true,
	DisableSunRays      = true,
	DisableBlur         = true,
	DisableParticles    = false,
	DisableTrails       = false,
	LowQualityTerrain   = true,
	MemoryCleanInterval = 30,    -- detik antar pembersihan memori
	UnloadFarTextures   = true,
	FarTextureDistance  = 250,   -- studs
}

-- ================================================
-- UTILITAS
-- ================================================
local function safeSet(obj, prop, val)
	pcall(function() obj[prop] = val end)
end

-- ================================================
-- 1. GRAFIS & FPS CAP
-- ================================================
local function applyGraphics()
	pcall(function()
		settings().Rendering.QualityLevel =
			Enum.QualityLevel["Level0" .. CONFIG.QualityLevel]
	end)
	pcall(function()
		local gs = UserSettings():GetService("UserGameSettings")
		gs.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel01
	end)
	if CONFIG.MaxFPS > 0 then
		local minDt = 1 / CONFIG.MaxFPS
		RunService.RenderStepped:Connect(function(dt)
			if dt < minDt then task.wait(minDt - dt) end
		end)
	end
end

-- ================================================
-- 2. PENCAHAYAAN
-- ================================================
local function applyLighting()
	safeSet(Lighting, "GlobalShadows", not CONFIG.DisableShadows)
	safeSet(Lighting, "Technology", Enum.Technology.Compatibility)
	local disableMap = {
		BloomEffect        = CONFIG.DisableBloom,
		SunRaysEffect      = CONFIG.DisableSunRays,
		BlurEffect         = CONFIG.DisableBlur,
		DepthOfFieldEffect = true,
	}
	for _, child in ipairs(Lighting:GetChildren()) do
		if disableMap[child.ClassName] then
			safeSet(child, "Enabled", false)
		end
	end
end

-- ================================================
-- 3. PARTIKEL, TRAIL, TERRAIN
-- ================================================
local function applyParticles(root)
	for _, obj in ipairs(root:GetDescendants()) do
		if CONFIG.DisableParticles and
			(obj:IsA("ParticleEmitter") or
				obj:IsA("Fire") or obj:IsA("Smoke")) then
			safeSet(obj, "Enabled", false)
		end
		if CONFIG.DisableTrails and obj:IsA("Trail") then
			safeSet(obj, "Enabled", false)
		end
	end
end

local function applyTerrain()
	if not CONFIG.LowQualityTerrain then return end
	local t = Workspace:FindFirstChildOfClass("Terrain")
	if t then
		safeSet(t, "Decoration",      false)
		safeSet(t, "WaterWaveSize",    0)
		safeSet(t, "WaterWaveSpeed",   0)
		safeSet(t, "WaterReflectance", 0)
	end
end

-- ================================================
-- 4. MEMORY MANAGER
-- FIX: collectgarbage wajib pakai argumen string
-- ================================================
local function cleanMemory()
	-- Hapus ScreenGui yang dinonaktifkan
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if pg then
		for _, g in ipairs(pg:GetChildren()) do
			if g:IsA("ScreenGui") and not g.Enabled then
				g:Destroy()
			end
		end
	end

	-- FIX: collectgarbage butuh argumen "collect"
	pcall(function()
		collectgarbage("collect")
	end)

end

local function unloadFarTextures()
	if not CONFIG.UnloadFarTextures then return end
	local camPos = Workspace.CurrentCamera.CFrame.Position
	local dist   = CONFIG.FarTextureDistance
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			local far = (obj.Position - camPos).Magnitude > dist
			for _, c in ipairs(obj:GetChildren()) do
				if c:IsA("Decal") or c:IsA("Texture") then
					safeSet(c, "Transparency", far and 1 or 0)
				end
			end
		end
	end
end

-- ================================================
-- 5. AUTO-MONITOR & JADWAL PEMBERSIHAN
-- ================================================
local function startScheduler()
	Workspace.DescendantAdded:Connect(function(obj)
		if CONFIG.DisableParticles and
			(obj:IsA("ParticleEmitter") or
				obj:IsA("Fire") or obj:IsA("Smoke")) then
			task.defer(function() safeSet(obj, "Enabled", false) end)
		end
		if CONFIG.DisableTrails and obj:IsA("Trail") then
			task.defer(function() safeSet(obj, "Enabled", false) end)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(CONFIG.MemoryCleanInterval)
			cleanMemory()
			unloadFarTextures()
		end
	end)
end

-- ================================================
-- INISIALISASI (tanpa GUI)
-- ================================================
local function init()
	applyGraphics()
	applyLighting()
	applyTerrain()
	applyParticles(Workspace)
	startScheduler()
	cleanMemory()
end

init()