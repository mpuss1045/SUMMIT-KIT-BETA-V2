-- ============================================================
-- MusicFavoriteService (Script — ServerScriptService)
-- Fix: Playlist.lua dan Favorite.lua WaitForChild MusicRemotes/FavoriteRemotes
-- tapi tidak ada handler server → favorites tidak pernah save/load
-- Script ini membuat remote + DataStore handler untuk keduanya
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService  = game:GetService("DataStoreService")

local FavMusicDS  = DataStoreService:GetDataStore("ZayinMusicFavorites_v1")
local FavEmoteDS  = DataStoreService:GetDataStore("ZayinEmoteFavorites_v1")

-- ── Buat MusicRemotes ────────────────────────────────────────
local musicRemotes = ReplicatedStorage:FindFirstChild("MusicRemotes")
if not musicRemotes then
	musicRemotes      = Instance.new("Folder")
	musicRemotes.Name = "MusicRemotes"
	musicRemotes.Parent = ReplicatedStorage
end

local loadMusicRF = musicRemotes:FindFirstChild("LoadMusicFavorite")
if not loadMusicRF then
	loadMusicRF       = Instance.new("RemoteFunction")
	loadMusicRF.Name  = "LoadMusicFavorite"
	loadMusicRF.Parent = musicRemotes
end

local saveMusicRE = musicRemotes:FindFirstChild("SaveMusicFavorite")
if not saveMusicRE then
	saveMusicRE       = Instance.new("RemoteEvent")
	saveMusicRE.Name  = "SaveMusicFavorite"
	saveMusicRE.Parent = musicRemotes
end

-- ── Buat FavoriteRemotes ─────────────────────────────────────
local favRemotes = ReplicatedStorage:FindFirstChild("FavoriteRemotes")
if not favRemotes then
	favRemotes      = Instance.new("Folder")
	favRemotes.Name = "FavoriteRemotes"
	favRemotes.Parent = ReplicatedStorage
end

local loadFavRF = favRemotes:FindFirstChild("LoadFavorite")
if not loadFavRF then
	loadFavRF       = Instance.new("RemoteFunction")
	loadFavRF.Name  = "LoadFavorite"
	loadFavRF.Parent = favRemotes
end

local saveFavRE = favRemotes:FindFirstChild("SaveFavorite")
if not saveFavRE then
	saveFavRE       = Instance.new("RemoteEvent")
	saveFavRE.Name  = "SaveFavorite"
	saveFavRE.Parent = favRemotes
end

-- ── Cooldown anti-spam ────────────────────────────────────────
local saveCooldown = {}
local COOLDOWN     = 5 -- detik minimum antar save

local function canSave(userId)
	local now = tick()
	if saveCooldown[userId] and (now - saveCooldown[userId]) < COOLDOWN then
		return false
	end
	saveCooldown[userId] = now
	return true
end

-- ── Handlers: Musik Favorit ──────────────────────────────────
loadMusicRF.OnServerInvoke = function(player)
	local ok, data = pcall(function()
		return FavMusicDS:GetAsync(tostring(player.UserId))
	end)
	if ok and type(data) == "table" then return data end
	return {}
end

saveMusicRE.OnServerEvent:Connect(function(player, list)
	if not canSave(player.UserId) then return end
	if type(list) ~= "table" then return end
	-- Validasi: max 100 item, setiap item harus punya name (string)
	local clean = {}
	for i, item in ipairs(list) do
		if i > 100 then break end
		if type(item) == "table" and type(item.name) == "string" then
			table.insert(clean, { name = item.name:sub(1, 100), soundId = tostring(item.soundId or "") })
		end
	end
	pcall(function() FavMusicDS:SetAsync(tostring(player.UserId), clean) end)
end)

-- ── Handlers: Emote Favorit ──────────────────────────────────
loadFavRF.OnServerInvoke = function(player)
	local ok, data = pcall(function()
		return FavEmoteDS:GetAsync(tostring(player.UserId))
	end)
	if ok and type(data) == "table" then return data end
	return {}
end

saveFavRE.OnServerEvent:Connect(function(player, list)
	if not canSave(player.UserId .. "_emote") then return end
	if type(list) ~= "table" then return end
	local clean = {}
	for i, item in ipairs(list) do
		if i > 100 then break end
		if type(item) == "table" and type(item.name) == "string"
			and type(item.animId) == "number" then
			table.insert(clean, { name = item.name:sub(1, 100), animId = item.animId })
		end
	end
	pcall(function() FavEmoteDS:SetAsync(tostring(player.UserId), clean) end)
end)

-- Cleanup cooldown saat player keluar
Players.PlayerRemoving:Connect(function(player)
	saveCooldown[player.UserId]               = nil
	saveCooldown[player.UserId .. "_emote"]   = nil
end)

print("[MusicFavoriteService] Ready! MusicRemotes + FavoriteRemotes tersedia.")