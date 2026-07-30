-- ============================================================
--  BoomboxFavServer.lua
--  Lokasi: ServerScriptService
--  Fungsi: Save/Load favorit boombox per player
-- ============================================================

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local function getOrCreate(parent, name, class)
	return parent:FindFirstChild(name) or (function()
		local r = Instance.new(class); r.Name=name; r.Parent=parent; return r
	end)()
end

local folder   = getOrCreate(ReplicatedStorage, "BoomboxFavRemotes", "Folder")
local loadRE   = getOrCreate(folder, "LoadBoomboxFav",  "RemoteFunction")
local saveRE   = getOrCreate(folder, "SaveBoomboxFav",  "RemoteEvent")

local FavStore = DataStoreService:GetDataStore("BoomboxFavorites_v1")

-- Load
loadRE.OnServerInvoke = function(player)
	local key="bbfav_"..tostring(player.UserId)
	local ok,data=pcall(function() return FavStore:GetAsync(key) end)
	if ok and type(data)=="table" then return data end
	return {}
end

-- Save
saveRE.OnServerEvent:Connect(function(player, favList)
	if type(favList)~="table" then return end
	local clean={}
	for _,id in ipairs(favList) do
		if type(id)=="number" then table.insert(clean,id) end
	end
	local key="bbfav_"..tostring(player.UserId)
	pcall(function() FavStore:SetAsync(key,clean) end)
end)