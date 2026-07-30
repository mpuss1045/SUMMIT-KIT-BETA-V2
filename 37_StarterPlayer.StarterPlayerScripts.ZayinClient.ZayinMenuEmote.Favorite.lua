-- ============================================================
--  Favorite.lua  |  Client Module  |  v2.0
--  Fix: metatable tidak konflik dengan method
--  Fix: Load idempoten, safe pcall semua remote call
-- ============================================================

local Favorite         = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Data internal — TIDAK di-expose via metatable lagi
-- (metatable __index konflik dengan Favorite.Load, Favorite.Add, dll)
local _list   = {}
local _loaded = false

-- Remote cache
local _loadRE, _saveRE = nil, nil

local function ensureRemotes()
	if _loadRE and _saveRE then return true end
	local folder = ReplicatedStorage:FindFirstChild("FavoriteRemotes")
		or ReplicatedStorage:WaitForChild("FavoriteRemotes", 8)
	if not folder then return false end
	_loadRE = folder:FindFirstChild("LoadFavorite") or folder:WaitForChild("LoadFavorite", 5)
	_saveRE = folder:FindFirstChild("SaveFavorite") or folder:WaitForChild("SaveFavorite", 5)
	return _loadRE ~= nil and _saveRE ~= nil
end

-- ── Load dari server ─────────────────────────────────────────
function Favorite.Load()
	if _loaded then return end
	_loaded = true
	if not ensureRemotes() then return end
	local ok, data = pcall(function()
		return _loadRE:InvokeServer()
	end)
	if ok and type(data) == "table" then
		_list = data
	end
end

-- ── Save ke server (fire and forget) ─────────────────────────
local function save()
	if not ensureRemotes() then return end
	task.spawn(function()
		pcall(function() _saveRE:FireServer(_list) end)
	end)
end

-- ── API publik ───────────────────────────────────────────────
function Favorite.Add(animName, animId)
	for _, fav in ipairs(_list) do
		if fav.animId == animId then return false end
	end
	table.insert(_list, {name = animName, animId = animId})
	save()
	return true
end

function Favorite.Remove(animId)
	for i, fav in ipairs(_list) do
		if fav.animId == animId then
			table.remove(_list, i)
			save()
			return true
		end
	end
	return false
end

function Favorite.Toggle(animName, animId)
	if Favorite.IsFavorite(animId) then
		Favorite.Remove(animId)
		return false
	else
		Favorite.Add(animName, animId)
		return true
	end
end

function Favorite.IsFavorite(animId)
	for _, fav in ipairs(_list) do
		if fav.animId == animId then return true end
	end
	return false
end

-- GetFavorites mengembalikan copy agar caller tidak bisa mutasi internal
function Favorite.GetFavorites()
	local copy = {}
	for i, v in ipairs(_list) do copy[i] = v end
	return copy
end

function Favorite.Count()
	return #_list
end

-- Reset (untuk testing atau logout)
function Favorite.Reset()
	_list   = {}
	_loaded = false
end

return Favorite