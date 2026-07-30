-- ============================================
-- ZayinSummitService (FIXED)
-- ============================================
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local ZR            = RS:WaitForChild("ZayinRemotes")
local SummitRemotes = ZR:WaitForChild("Summit")
local ReachedRE     = SummitRemotes:WaitForChild("Reached")
local CPRemotes     = ZR:WaitForChild("Checkpoint")
local CPReachedRE   = CPRemotes:WaitForChild("Reached")

-- Pastikan SummitBerhasil RemoteEvent ada
-- Gunakan SummitBerhasil yang sudah ada (permanen di game)
local SummitBerhasilRE = ZR:WaitForChild("SummitBerhasil", 10)
if not SummitBerhasilRE then
	warn("[Summit] SummitBerhasil tidak ditemukan!")
end

local ZC         = RS:WaitForChild("ZayinConfig")
local GameConfig = require(ZC:WaitForChild("GameConfig"))

GameConfig.SummitEasyReward = GameConfig.SummitEasyReward or (GameConfig.SummitReward and GameConfig.SummitReward.Easy) or 100
GameConfig.SummitHardReward = GameConfig.SummitHardReward or (GameConfig.SummitReward and GameConfig.SummitReward.Hard) or 1000

if not GameConfig.Checkpoints then task.wait(2) end

local playerCheckpoints = {}
local debounce          = {}

-- ── Restore tracker dari DataStore ────────────────────────
local function restoreTracker(player)
	task.spawn(function()
		local DS   = game:GetService("DataStoreService")
		local cpDS = DS:GetDataStore("ZayinCP_" .. GameConfig.DataVersion)
		local ok, data = pcall(function()
			return cpDS:GetAsync("cp_" .. player.UserId)
		end)

		if ok and type(data) == "table" and data.checkpoint then
			local cpName = data.checkpoint
			local checkpoints = GameConfig.Checkpoints
			for i = 1, 10 do
				if checkpoints then break end
				task.wait(0.5)
				checkpoints = GameConfig.Checkpoints
			end
			if checkpoints then
				if not playerCheckpoints[player.UserId] then
					playerCheckpoints[player.UserId] = {}
				end
				-- [PATCH B2d] anti-farm: kalau checkpoint tersimpan = puncak,
				-- pemain tetap spawn di puncak TAPI tracker dikosongkan,
				-- jadi summit berikutnya wajib mendaki ulang dari bawah.
				if cpName:find("Summit") then
					playerCheckpoints[player.UserId] = { ["Basecamp"] = true }
				else
					for _, cp in ipairs(checkpoints) do
						playerCheckpoints[player.UserId][cp] = true
						if cp == cpName then break end
					end
				end
			end
		end
	end)
end

-- ── Checkpoint validation ──────────────────────────────────
local function hasRequiredCheckpoints(userId, summitType)
	local touched = playerCheckpoints[userId]

	local skPlayer = game:GetService("Players"):GetPlayerByUserId(userId)
	if skPlayer then
		local skRole = skPlayer:GetAttribute("RoleId")
		if skRole and GameConfig.SkipCheckpoint and GameConfig.SkipCheckpoint[skRole] then
			return true
		end
	end	if not touched then return false end
	local checkpoints = GameConfig.Checkpoints
	if not checkpoints then return false end

	if summitType == "Easy" then
		-- FIX: Cek semua CP berurutan harus disentuh
		for _, cp in ipairs(checkpoints) do
			if cp:find("Summit") then break end -- stop di Summit
			if not touched[cp] then

				return false
			end
		end
		return true

	elseif summitType == "Hard" then
		for _, cp in ipairs(checkpoints) do
			if not cp:find("Summit") then
				if not touched[cp] then return false end
			end
		end
		return true
	end
	return false
end

-- ── Track checkpoint yang disentuh ────────────────────────
CPReachedRE.OnServerEvent:Connect(function(player, cpName)
	if type(cpName) ~= "string" then return end
	if not playerCheckpoints[player.UserId] then
		playerCheckpoints[player.UserId] = {}
	end
	playerCheckpoints[player.UserId][cpName] = true
end)

-- ── Player join ────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	playerCheckpoints[player.UserId] = { ["Basecamp"] = true }
	restoreTracker(player)

	player.CharacterAdded:Connect(function()
		if not playerCheckpoints[player.UserId] then
			playerCheckpoints[player.UserId] = {}
		end
		playerCheckpoints[player.UserId]["Basecamp"] = true
	end)
end)

-- Handle player yang sudah ada saat script jalan
for _, player in pairs(Players:GetPlayers()) do
	playerCheckpoints[player.UserId] = playerCheckpoints[player.UserId] or { ["Basecamp"] = true }
	restoreTracker(player)
end

-- [PATCH B2] validasi posisi + cooldown server
local SUMMIT_RADIUS   = 35
local SUMMIT_COOLDOWN = 5
local summitCooldown  = {}

local function isNearSummit(player, summitType)
	-- [P14] batas kotak: part Summit sangat besar & tipis, radius bola tidak cocok
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local zw = workspace:FindFirstChild("ZayinWorkspace")
	local sf = zw and zw:FindFirstChild("Summit")
	local obj = sf and sf:FindFirstChild("Summit" .. summitType)
	if not obj then return true end
	local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
	if not part then return true end
	local rel = part.CFrame:PointToObjectSpace(hrp.Position)
	local h, m = part.Size / 2, 20
	return math.abs(rel.X) <= h.X + m
		and math.abs(rel.Y) <= h.Y + m
		and math.abs(rel.Z) <= h.Z + m
end


-- ── Summit Reached ─────────────────────────────────────────
ReachedRE.OnServerEvent:Connect(function(player, summitType)
	if type(summitType) ~= "string" then return end
	if summitType ~= "Easy" and summitType ~= "Hard" then return end
	if debounce[player.UserId] then return end

	-- [PATCH B2] tolak kalau jauh dari puncak (anti fire-remote dari mana saja)
	if not isNearSummit(player, summitType) then
		-- [P14] notif jarak
		local dRE = ZR:FindFirstChild("SummitDitolak")
		if dRE then dRE:FireClient(player, summitType, "TERLALU JAUH|Dekati puncaknya") end
		return
	end

	-- [PATCH B2] cooldown server
	local _now = os.clock()
	local _last = summitCooldown[player.UserId]
	if _last and (_now - _last) < SUMMIT_COOLDOWN then
		local dRE = ZR:FindFirstChild("SummitDitolak")
		if dRE then dRE:FireClient(player, summitType, "TUNGGU SEBENTAR|Cooldown summit") end
		return
	end

	if not hasRequiredCheckpoints(player.UserId, summitType) then
		-- [P20] notif dobel dihapus (pakai SummitDitolak saja)

		-- Kirim notif ke client
		-- [P14] alasan skip
		local ditolakRE = ZR:FindFirstChild("SummitDitolak")
		if ditolakRE then
			ditolakRE:FireClient(player, summitType,
				"TIDAK DAPAT POIN|Kamu melewatkan checkpoint")
		end
		local _abaikan = ZR:FindFirstChild("SummitDitolak")

		return
	end

	debounce[player.UserId] = true
	summitCooldown[player.UserId] = os.clock()

	local reward = summitType == "Hard"
		and GameConfig.SummitHardReward
		or  GameConfig.SummitEasyReward

	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local summit = ls:FindFirstChild("Summit")
		if summit then
			summit.Value += reward

			if SummitBerhasilRE then
				SummitBerhasilRE:FireAllClients(player.UserId, player.DisplayName, summitType, reward)

			end
		end
	end

	local updateSummit = game:GetService("ServerScriptService"):FindFirstChild("UpdateSummitData", true)
	if updateSummit then updateSummit:Fire(player) end

	local cpName = summitType == "Hard" and "SummitHard" or "SummitEasy"
	local setSummitCP = game:GetService("ServerScriptService"):FindFirstChild("SetSummitCP", true)
	if setSummitCP then setSummitCP:Fire(player, cpName) end


	playerCheckpoints[player.UserId] = { ["Basecamp"] = true }

	task.wait(2)
	debounce[player.UserId] = nil
end)

Players.PlayerRemoving:Connect(function(player)
	debounce[player.UserId]          = nil
	playerCheckpoints[player.UserId] = nil
end)

-- ── Reset tracker ──────────────────────────────────────────
local resetTracker = Instance.new("BindableEvent")
resetTracker.Name   = "ResetSummitTracker"
resetTracker.Parent = game:GetService("ServerScriptService")
resetTracker.Event:Connect(function(player)
	playerCheckpoints[player.UserId] = { ["Basecamp"] = true }

end)

-- ── Sync tracker ───────────────────────────────────────────
local SyncTrackerRE = SummitRemotes:FindFirstChild("SyncTracker")
if not SyncTrackerRE then
	SyncTrackerRE = Instance.new("RemoteEvent")
	SyncTrackerRE.Name   = "SyncTracker"
	SyncTrackerRE.Parent = SummitRemotes
end
-- [PATCH B2c] SyncTracker dulu menandai SEMUA checkpoint = tombol cheat.
-- Sekarang hanya memulihkan tracker dari data tersimpan (tetap kena aturan anti-farm).
SyncTrackerRE.OnServerEvent:Connect(function(player)
	if not playerCheckpoints[player.UserId] then
		playerCheckpoints[player.UserId] = { ["Basecamp"] = true }
	end
	restoreTracker(player)
end)