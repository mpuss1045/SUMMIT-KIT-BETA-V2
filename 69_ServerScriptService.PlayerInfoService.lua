-- PlayerInfoService — sediakan data identitas pemain untuk panel klik
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local DSS     = game:GetService("DataStoreService")

local ZR = RS:WaitForChild("ZayinRemotes", 30)
local rf = ZR:FindFirstChild("GetPlayerInfo")
if not rf then
	rf = Instance.new("RemoteFunction")
	rf.Name = "GetPlayerInfo"
	rf.Parent = ZR
end

local GC
do
	local ok, m = pcall(function()
		return require(RS:WaitForChild("ZayinConfig"):WaitForChild("GameConfig"))
	end)
	if ok then GC = m end
end

local function formatDurasi(detik)
	detik = math.max(math.floor(detik or 0), 0)
	local j = math.floor(detik / 3600)
	local m = math.floor((detik % 3600) / 60)
	if j > 0 then return j .. "j " .. m .. "m" end
	return m .. "m"
end

local function ambilRole(p)
	local rid = p:GetAttribute("RoleId")
    if type(rid) == "string" and rid ~= "" and GC then
		local conf = GC.LeaderstatRoles and GC.LeaderstatRoles[rid]
		if conf then return conf.Text, conf.Color end
		return rid, Color3.fromRGB(200, 210, 225)
	end
	if p:GetAttribute("IsVIP") == true and GC and GC.LeaderstatRoles and GC.LeaderstatRoles.VIP then
		return GC.LeaderstatRoles.VIP.Text, GC.LeaderstatRoles.VIP.Color
	end
	return "PLAYER", Color3.fromRGB(160, 170, 185)
end

rf.OnServerInvoke = function(_, targetUserId)
	local p = Players:GetPlayerByUserId(targetUserId)
	if not p then return nil end

	local ls = p:FindFirstChild("leaderstats")
	local sum = ls and ls:FindFirstChild("Summit")
	local bt  = ls and ls:FindFirstChild("BestTime")
	local don = p:FindFirstChild("Donation")

	-- lama di server ini
	local mulai = p:GetAttribute("SessionStart")
	local sesi  = mulai and (tick() - mulai) or 0

	-- playtime total dari OrderedDataStore global
	local totalPlaytime = 0
	pcall(function()
		local ods = DSS:GetOrderedDataStore("ZayinGlobalPlaytime_v1")
		local v = ods:GetAsync(tostring(p.UserId))
		if type(v) == "number" then totalPlaytime = v end
	end)

	-- jenis avatar (Roblox tidak menyediakan gender)
	local jenis = p:GetAttribute("AvatarGender")
	if type(jenis) ~= "string" or jenis == "" then
		local ch = p.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		jenis = (hum and hum.RigType == Enum.HumanoidRigType.R15) and "R15" or "R6"
	end

	local roleText, roleColor = ambilRole(p)

	return {
		nama       = p.DisplayName,
		username   = p.Name,
		userId     = p.UserId,
		role       = roleText,
		roleColor  = roleColor,
		usiaAkun   = p.AccountAge,
		jenis      = jenis,
		sesi       = formatDurasi(sesi),
		playtime   = formatDurasi(totalPlaytime),
		summit     = sum and sum.Value or 0,
		speedrun   = (bt and bt.Value ~= "" and bt.Value) or "-",
		donasi     = don and don.Value or 0,
	}
end

print("[PlayerInfoService] Ready!")