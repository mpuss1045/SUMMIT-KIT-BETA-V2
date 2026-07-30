-- ============================================================
--  Playlist.lua  v2  FIXED
-- ============================================================
local Playlist          = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Playlist.SoundList    = {}
Playlist.CurrentIndex = 1
Playlist.Favorites    = {}

local _loaded = false
local _loadRE = nil
local _saveRE = nil

local function ensureRemotes()
	if _loadRE and _saveRE then return true end
	local folder = ReplicatedStorage:FindFirstChild("MusicRemotes")
		or ReplicatedStorage:WaitForChild("MusicRemotes", 10)
	if not folder then return false end
	_loadRE = folder:FindFirstChild("LoadMusicFavorite")
		or folder:WaitForChild("LoadMusicFavorite", 8)
	_saveRE = folder:FindFirstChild("SaveMusicFavorite")
		or folder:WaitForChild("SaveMusicFavorite", 8)
	return _loadRE ~= nil and _saveRE ~= nil
end

-- FIX: Path musik sekarang ke ZayinWorkspace.MusicSystem
function Playlist.Initialize()
	local zw = workspace:WaitForChild("ZayinWorkspace", 10)
	if not zw then warn("[MusicSystem] ZayinWorkspace not found") return false end
	local musicFolder = zw:WaitForChild("MusicSystem", 10)
	if not musicFolder then warn("[MusicSystem] MusicSystem not found") return false end

	Playlist.SoundList = {}
	for _, sound in ipairs(musicFolder:GetChildren()) do
		if sound:IsA("Sound") then
			table.insert(Playlist.SoundList, sound)
		end
	end
	return #Playlist.SoundList > 0
end

function Playlist.LoadFavorites()
	if _loaded then return end
	_loaded = true
	if not ensureRemotes() then return end
	local ok, data = pcall(function() return _loadRE:InvokeServer() end)
	if not (ok and type(data) == "table") then return end
	for _, item in ipairs(data) do
		for _, sound in ipairs(Playlist.SoundList) do
			if sound.Name == item.name then
				Playlist.Favorites[sound] = true
				break
			end
		end
	end
end

local function saveFavorites()
	if not ensureRemotes() then return end
	local list = {}
	for sound in pairs(Playlist.Favorites) do
		table.insert(list, { name = sound.Name, soundId = tostring(sound.SoundId or "") })
	end
	pcall(function() _saveRE:FireServer(list) end)
end

function Playlist.GetCurrentSound()
	if #Playlist.SoundList == 0 then return nil end
	return Playlist.SoundList[Playlist.CurrentIndex]
end

function Playlist.SetIndex(index)
	if index >= 1 and index <= #Playlist.SoundList then
		Playlist.CurrentIndex = index
	end
end

function Playlist.Next()
	if #Playlist.SoundList == 0 then return nil end
	Playlist.CurrentIndex = (Playlist.CurrentIndex % #Playlist.SoundList) + 1
	return Playlist.GetCurrentSound()
end

function Playlist.Prev()
	if #Playlist.SoundList == 0 then return nil end
	Playlist.CurrentIndex = Playlist.CurrentIndex - 1
	if Playlist.CurrentIndex < 1 then
		Playlist.CurrentIndex = #Playlist.SoundList
	end
	return Playlist.GetCurrentSound()
end

function Playlist.ToggleFavorite(sound)
	if not sound then return end
	if Playlist.Favorites[sound] then
		Playlist.Favorites[sound] = nil
	else
		Playlist.Favorites[sound] = true
	end
	saveFavorites()
end

function Playlist.IsFavorite(sound)
	return Playlist.Favorites[sound] == true
end

return Playlist