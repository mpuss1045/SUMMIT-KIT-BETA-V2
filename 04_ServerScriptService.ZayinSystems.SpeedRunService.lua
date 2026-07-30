-- ============================================
-- ZayinSpeedRunService (FIXED + OPTIMIZED + LIFECYCLE FIX)
-- Riwayat fix lama:
--   • Hapus duplikat formatTimeShort (didefinisikan 2x sebelumnya)
--   • Hapus finishParts yang dibuat tapi tidak pernah diisi
--   • Hapus print debug production
--   • Tambah pcall guard di DataStore calls
-- Fix baru (Jul 30):
--   • [LC1] Buang task.wait(1) buta -> pakai WaitForChild("HumanoidRootPart")
--           supaya deteksi tersambung TEPAT saat karakter siap.
--           Menghilangkan "jendela mati" 1 detik yang bikin Start kadang
--           tidak kebaca, dan balapan dengan ApplyDescription (ganti avatar).
--   • [LC2] resetTimer dipanggil di SETIAP CharacterAdded -> state bersih
--           tiap spawn (respawn & ganti avatar tidak lagi menyisakan run basi).
--   • [LC3] Penjaga anti-setup-dobel (armGen) supaya CharacterAdded yang
--           beruntun (respawn + ApplyDescription) tidak memasang loop ganda.
--   • [LC4] Bersihkan debounce sub-key dengan benar di PlayerRemoving.
--   • DEBUG flag: nyalakan untuk melacak alur di Output.
-- ============================================
local Players    = game:GetService("Players")
local DS         = game:GetService("DataStoreService")
local RS         = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ZR        = RS:WaitForChild("ZayinRemotes")
local SRRemotes = ZR:WaitForChild("SpeedRun")
local StartRE   = SRRemotes:WaitForChild("Start")
local FinishRE  = SRRemotes:WaitForChild("Finish")
local FailedRE  = SRRemotes:WaitForChild("Failed")

local srDS    = DS:GetDataStore("ZayinSpeedRun_v1")
local srODS   = DS:GetOrderedDataStore("ZayinGlobalSpeedRun_v1")

-- ── DEBUG ──────────────────────────────────────────────────
-- true  = cetak alur lengkap ke Output (dipakai untuk diagnosa)
-- false = senyap (produksi)
local DEBUG = true
local function dbg(...)
	if DEBUG then print("[SpeedRun]", ...) end
end

-- ── FIX: hanya satu definisi formatTimeShort ─────────────
local function formatTimeShort(seconds)
	local m  = math.floor(seconds / 60)
	local s  = math.floor(seconds % 60)
	local ms = math.floor((seconds % 1) * 1000)
	return string.format("%02d:%02d.%03d", m, s, ms)
end

local timers    = {}
local bestTimes = {}
local debounce  = {}
local armGen    = {} -- [LC3] generasi setup terakhir per pemain

-- ── DataStore ─────────────────────────────────────────────
local function loadBestTime(player)
	local ok, data = pcall(function()
		return srDS:GetAsync("sr_" .. player.UserId)
	end)
	bestTimes[player.UserId] = (ok and type(data) == "number" and data) or nil
	if bestTimes[player.UserId] then
		local ls = player:FindFirstChild("leaderstats")
		if ls then
			local bt = ls:FindFirstChild("BestTime")
			if bt then bt.Value = formatTimeShort(bestTimes[player.UserId]) end
		end
	end
end

local function saveBestTime(player, seconds)
	local current = bestTimes[player.UserId]
	if not current or seconds < current then
		pcall(function() srDS:SetAsync("sr_" .. player.UserId, seconds) end)
		pcall(function() srODS:SetAsync(tostring(player.UserId), math.floor(seconds * 1000)) end)
		bestTimes[player.UserId] = seconds
		local ls = player:FindFirstChild("leaderstats")
		if ls then
			local bt = ls:FindFirstChild("BestTime")
			if bt then bt.Value = formatTimeShort(seconds) end
		end
		return true
	end
	return false
end

-- ── Reset timer ───────────────────────────────────────────
local function resetTimer(player)
	timers[player.UserId] = {
		startTime  = nil,
		savepoints = {},
		active     = false,
	}
end

-- ── Start timer ───────────────────────────────────────────
local function startTimer(player)
	timers[player.UserId] = {
		startTime  = tick(),
		savepoints = {},
		active     = true,
	}
	StartRE:FireClient(player)
	dbg(player.Name, "TIMER START")
end

-- ── Cek semua SavePoint sudah disentuh ───────────────────
local function allSavePointsTouched(timer, saveParts)
	for _, sp in pairs(saveParts) do
		if not timer.savepoints[sp.Name] then
			return false, sp.Name
		end
	end
	return true, nil
end

-- ── Connection management ─────────────────────────────────
local playerConnections = {}

local function clearConnections(userId)
	if playerConnections[userId] then
		for _, c in pairs(playerConnections[userId]) do
			if c and c.Connected then c:Disconnect() end
		end
		playerConnections[userId] = {}
	end
end

-- ── Setup proximity detection ─────────────────────────────
local function setupProximity(player)
	clearConnections(player.UserId)
	playerConnections[player.UserId] = {}

	local zw = workspace:WaitForChild("ZayinWorkspace", 10)
	if not zw then dbg(player.Name, "ZayinWorkspace TIDAK ADA"); return end

	-- Start parts
	local startParts = {}
	local srFolder = zw:FindFirstChild("SpeedRun")
	if srFolder then
		for _, part in pairs(srFolder:GetChildren()) do
			if part:IsA("BasePart") and part.Name:find("Start") then
				table.insert(startParts, part)
			end
		end
	end

	-- SavePoint parts
	local saveParts = {}
	local spFolder = zw:FindFirstChild("SavePoint")
	if spFolder then
		for _, part in pairs(spFolder:GetChildren()) do
			if part:IsA("BasePart") then
				table.insert(saveParts, part)
				local conn = part.Touched:Connect(function(hit)
					local char = hit.Parent
					if not char then return end
					local p = Players:GetPlayerFromCharacter(char)
					if not p or p ~= player then return end
					local t = timers[p.UserId]
					if not t or not t.active then return end
					if not t.savepoints[part.Name] then
						t.savepoints[part.Name] = true
						dbg(p.Name, "SAVEPOINT", part.Name)
					end
				end)
				table.insert(playerConnections[player.UserId], conn)
			end
		end
	end

	-- Summit parts
	local summitFolder  = zw:FindFirstChild("Summit")
	local summitHardPart = summitFolder and summitFolder:FindFirstChild("SummitHard")
	local summitEasyPart = summitFolder and summitFolder:FindFirstChild("SummitEasy")

	dbg(player.Name, "SETUP OK | start:", #startParts, "savepoint:", #saveParts,
		"easy:", summitEasyPart ~= nil, "hard:", summitHardPart ~= nil)

	-- Heartbeat loop — deteksi proximity
	local loop = RunService.Heartbeat:Connect(function()
		local char = player.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local pos   = hrp.Position
		local timer = timers[player.UserId]
		if not timer then return end

		-- Start / Reset (pad diinjak dari atas -> cek X/Z saja, SENGAJA)
		for _, part in pairs(startParts) do
			local halfX = part.Size.X / 2
			local halfZ = part.Size.Z / 2
			local rel   = pos - part.Position
			if math.abs(rel.X) <= halfX and math.abs(rel.Z) <= halfZ then
				if not debounce[player.UserId .. "_start"] then
					debounce[player.UserId .. "_start"] = true
					startTimer(player)
					task.spawn(function()
						task.wait(2)
						debounce[player.UserId .. "_start"] = nil
					end)
				end
				break
			end
		end

		-- SummitHard = FINISH  (dicek DULU, sebelum Easy)
		-- [urutan] finish diperiksa lebih dulu supaya kalau kotak Easy & Hard
		-- kebetulan bertumpang-tindih, FINISH yang menang, bukan CURANG.
		if timer.active and summitHardPart then
			local rel = pos - summitHardPart.Position
			if math.abs(rel.X) <= summitHardPart.Size.X/2
				and math.abs(rel.Y) <= summitHardPart.Size.Y/2
				and math.abs(rel.Z) <= summitHardPart.Size.Z/2 then
				if not debounce[player.UserId .. "_finish"] then
					debounce[player.UserId .. "_finish"] = true

					local allTouched, kurang = allSavePointsTouched(timer, saveParts)
					if allTouched then
						local elapsed = tick() - timer.startTime
						saveBestTime(player, elapsed)
						FinishRE:FireClient(player, elapsed, bestTimes[player.UserId])
						dbg(player.Name, "FINISH", string.format("%.3f", elapsed))
					else
						FailedRE:FireClient(player)
						dbg(player.Name, "FINISH DITOLAK - savepoint kurang:", kurang)
					end

					timer.active     = false
					timer.savepoints = {}

					task.spawn(function()
						task.wait(3)
						debounce[player.UserId .. "_finish"] = nil
					end)
				end
				return -- sudah selesai frame ini
			end
		end

		-- SummitEasy = CURANG saat speedrun aktif
		if timer.active and summitEasyPart then
			local rel = pos - summitEasyPart.Position
			if math.abs(rel.X) <= summitEasyPart.Size.X/2
				and math.abs(rel.Y) <= summitEasyPart.Size.Y/2
				and math.abs(rel.Z) <= summitEasyPart.Size.Z/2 then
				if not debounce[player.UserId .. "_easy"] then
					debounce[player.UserId .. "_easy"] = true
					FailedRE:FireClient(player)
					timer.active     = false
					timer.savepoints = {}
					dbg(player.Name, "CURANG (SummitEasy saat lari)")
					task.spawn(function()
						task.wait(3)
						debounce[player.UserId .. "_easy"] = nil
					end)
				end
			end
		end
	end)

	table.insert(playerConnections[player.UserId], loop)
end

-- ── [LC1+LC3] Pasang deteksi begitu karakter siap (tanpa wait buta) ──
local function armProximity(player, character)
	character = character or player.Character
	if not character then return end

	-- [LC3] tandai generasi setup ini; kalau CharacterAdded lain menyusul
	-- (mis. ApplyDescription memicu ulang), generasi lama berhenti diam-diam.
	local myGen = (armGen[player.UserId] or 0) + 1
	armGen[player.UserId] = myGen

	task.spawn(function()
		-- tunggu HRP benar-benar ada, bukan menebak 1 detik
		local hrp = character:WaitForChild("HumanoidRootPart", 10)
		if not hrp then dbg(player.Name, "HRP tak muncul dalam 10s"); return end
		-- kalau sudah ada generasi setup yang lebih baru, batalkan yang ini
		if armGen[player.UserId] ~= myGen then
			dbg(player.Name, "arm dibatalkan (ada setup lebih baru)")
			return
		end
		-- kalau karakter sudah diganti, batalkan
		if player.Character ~= character then
			dbg(player.Name, "arm dibatalkan (karakter berganti)")
			return
		end
		setupProximity(player)
	end)
end

-- ── Player join ───────────────────────────────────────────
local function onPlayerAdded(player)
	resetTimer(player)
	loadBestTime(player)
	playerConnections[player.UserId] = {}

	-- [P10] BestTime isi ulang: leaderstats mungkin belum ada saat loadBestTime jalan
	task.spawn(function()
		for _ = 1, 30 do
			task.wait(0.3)
			local bt = bestTimes[player.UserId]
			local ls = player:FindFirstChild("leaderstats")
			local v  = ls and ls:FindFirstChild("BestTime")
			if bt and v then
				v.Value = formatTimeShort(bt)
				return
			end
		end
	end)

	player.CharacterAdded:Connect(function(character)
		resetTimer(player)                 -- [LC2] state bersih tiap spawn
		armProximity(player, character)    -- [LC1] pasang saat HRP siap
	end)

	if player.Character then
		resetTimer(player)
		armProximity(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- Handle player yang sudah ada saat script jalan
for _, player in pairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- ── Player leave ──────────────────────────────────────────
Players.PlayerRemoving:Connect(function(player)
	clearConnections(player.UserId)
	timers[player.UserId]    = nil
	bestTimes[player.UserId] = nil
	armGen[player.UserId]    = nil
	-- [LC4] bersihkan sub-key debounce yang sebenarnya (bukan cuma UserId)
	debounce[player.UserId .. "_start"]  = nil
	debounce[player.UserId .. "_easy"]   = nil
	debounce[player.UserId .. "_finish"] = nil
end)

-- [TP-LANJUT] Teleport TIDAK membatalkan speedrun. Dulu handler ini memanggil
-- resetTimer (startTime/savepoints dihapus, active=false) sehingga kena part
-- Teleport = speedrun batal diam-diam. Sekarang timer & savepoint DIBIARKAN
-- utuh; cuma armProximity supaya detektor tetap aktif setelah pindah posisi.
-- (spawnAtCheckpoint memindahkan HRP via CFrame, bukan LoadCharacter, jadi tak
-- ada CharacterAdded/resetTimer dari jalur lain.)
local _ZR = game:GetService("ReplicatedStorage"):WaitForChild("ZayinRemotes", 10)
local _tpOccurred = _ZR and _ZR:FindFirstChild("TeleportOccurred")
if _tpOccurred then
	_tpOccurred.OnServerEvent:Connect(function(player)
		armProximity(player, player.Character)
	end)
end

print("[SpeedRunService FIXED] Ready!")
