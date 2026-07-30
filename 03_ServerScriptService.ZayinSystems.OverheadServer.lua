-- ============================================================
-- OverheadServer (Script)
-- Lokasi: ServerScriptService > ZayinSystems > OverheadServer
-- Fix: polling fallback agar overhead tetap muncul meski
--      CharacterAdded fired sebelum setupPlayer selesai
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================================
-- BACA DARI GAMECONFIG TERPUSAT
-- ============================================================
local ZayinConfig  = ReplicatedStorage:WaitForChild("ZayinConfig", 10)
local GameConfig   = require(ZayinConfig:WaitForChild("GameConfig", 10))

-- === Template ===
local Template = ReplicatedStorage:WaitForChild("Overhead", 10):WaitForChild("OverheadTemplate", 10)

-- === Remotes ===
local ZayinRemotes = ReplicatedStorage:WaitForChild("ZayinRemotes", 10)
local AdminFolder  = ZayinRemotes:WaitForChild("Admin", 10)
local GrantVIP     = AdminFolder:WaitForChild("GrantVIP", 10)
local RevokeVIP    = AdminFolder:WaitForChild("RevokeVIP", 10)
local SetRole      = AdminFolder:WaitForChild("SetRole", 10)

local RefreshOverhead = ZayinRemotes:FindFirstChild("RefreshOverhead") or (function()
	local r = Instance.new("RemoteEvent"); r.Name = "RefreshOverhead"; r.Parent = ZayinRemotes; return r
end)()

local SendDeviceType = ZayinRemotes:FindFirstChild("SendDeviceType") or (function()
	local r = Instance.new("RemoteEvent"); r.Name = "SendDeviceType"; r.Parent = ZayinRemotes; return r
end)()

-- ============================================================
-- TITLE CONFIG — sesuaikan threshold sesukamu
-- ============================================================
-- Title diambil dari GameConfig
local function getTitle(n)
	return GameConfig:GetTitle(n)
end

-- ============================================================
-- HELPER
-- ============================================================
local function getSummit(p)
	local ls = p:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("Summit") and ls.Summit.Value or 0
end

-- ============================================================
-- UPDATE TEKS OVERHEAD
-- ============================================================
local function updateOverhead(overhead, player)
	if not overhead or not overhead.Parent then return end

	local summit          = getSummit(player)
	local titleText, clr  = getTitle(summit)
	local isVIP           = player:GetAttribute("IsVIP") == true
	local role            = player:GetAttribute("Role") or ""

	local canvas = overhead:FindFirstChild("Canvas")
	if canvas then
		local nm = canvas:FindFirstChild("DisplayName")
		if nm then nm.Text = player.DisplayName; nm.TextColor3 = Color3.new(1,1,1) end

		local vl = canvas:FindFirstChild("VIP")
		if vl then
			vl.Visible = isVIP
			if isVIP then vl.Text = "[ VIP ]" end
		end

		-- Device: sembunyikan di server, client yang isi
		local dl = canvas:FindFirstChild("Device")
		if dl then dl.Visible = false end
	end

	-- LayoutOrder (dari atas ke bawah, angka kecil = lebih atas):
	-- 0 = Role (Owner/Admin/dll) — paling atas
	-- 1 = BadgeRow (icon badges) — dibuat oleh client
	-- 2 = Canvas (Device + Nama + VIP)
	-- 3 = TitleSummit (🔥 EXPERT)
	-- 4 = TotalSummit (🗻 328x Summit) — dekat kepala

	local rl = overhead:FindFirstChild("Role")
	if rl then
		rl.Text        = role
		rl.Visible     = role ~= ""
		rl.LayoutOrder = 0  -- paling atas
	end

	if canvas then
		canvas.LayoutOrder = 2
	end

	local tl = overhead:FindFirstChild("TitleSummit")
	if tl then
		tl.LayoutOrder = 3
		if titleText then
			tl.Text       = titleText
			tl.TextColor3 = clr
			tl.Visible    = true
		else
			tl.Text    = ""
			tl.Visible = false
		end
	end

	local sl = overhead:FindFirstChild("TotalSummit")
	if sl then
		sl.LayoutOrder = 4  -- paling bawah (dekat kepala)
		sl.Text        = summit .. " Summit"
		sl.TextColor3  = Color3.fromRGB(200, 200, 200)
		sl.Visible     = true
	end
end

-- ============================================================
-- BUILD OVERHEAD
-- ============================================================
local function buildOverhead(character, player)
	-- Tunggu Head muncul — penting untuk avatar custom
	local head = character:WaitForChild("Head", 10)
	if not head then
		warn("[OverheadServer] Head tidak ditemukan untuk " .. player.Name)
		return
	end

	local old = head:FindFirstChild("OverheadGui")
	if old then old:Destroy() end

	local overhead                  = Template:Clone()
	overhead.Name                   = "OverheadGui"
	overhead.Adornee                = head
	overhead.AlwaysOnTop            = false
	overhead.ResetOnSpawn           = false
	overhead.Size                   = UDim2.new(12, 0, 8, 0)
	overhead.StudsOffset            = Vector3.new(0, 7, 0)
	overhead.ClipsDescendants       = false  -- FIX: jangan potong badge/icon
	overhead.Parent                 = head

	-- Pastikan semua child tidak clip
	for _, c in ipairs(overhead:GetChildren()) do
		if c:IsA("GuiObject") then
			c.ClipsDescendants = false
		end
	end

	updateOverhead(overhead, player)

	-- Fire cepat agar icon langsung muncul
	task.delay(0.3, function()
		if player.Parent then RefreshOverhead:FireAllClients(player) end
	end)
	task.delay(1.0, function()
		if player.Parent then RefreshOverhead:FireAllClients(player) end
	end)

	print("[OverheadServer] Overhead berhasil dibuild untuk " .. player.Name)
end

-- ============================================================
-- [FIX] SATU PINTU BUILD — cegah build dobel/triple per respawn
-- Sebelumnya ada 3 jalur yang lomba build karakter yang sama:
--   (1) CharacterAdded  -> task.wait(0.5) -> buildOverhead
--   (2) watchHead poll  -> tiap 0.5s, Head belum punya OverheadGui -> build
--   (3) waitForCharacterAndBuild -> fallback saat join
-- Poll (2) selalu menang duluan, lalu (1) build ulang -> 2x per respawn,
-- dan di detik join (3) bisa nambah jadi 3x. Tiap build = Destroy + Clone
-- + 2x RefreshOverhead:FireAllClients ke SEMUA klien, jadi ini bukan
-- cuma log kotor tapi juga trafik & risiko kedip.
-- Kunci dipegang per KARAKTER (bukan per player) supaya respawn
-- berikutnya tetap boleh build. Weak key = otomatis bersih saat karakter
-- di-garbage collect, tak perlu pembersihan manual.
-- ============================================================
local sedangBuild = setmetatable({}, { __mode = "k" })

local function bangunOverhead(character, player)
	if not character or not character.Parent then return end
	if not player or not player.Parent then return end
	if sedangBuild[character] then return end   -- build lain sedang jalan

	-- Sudah ada overhead di karakter ini? tidak perlu build ulang.
	-- (Perubahan role/badge lewat scheduleRefresh -> updateOverhead,
	--  jalur terpisah, jadi refresh tetap jalan normal.)
	local head = character:FindFirstChild("Head")
	if head and head:FindFirstChild("OverheadGui") then return end

	sedangBuild[character] = true
	local ok, err = pcall(buildOverhead, character, player)
	sedangBuild[character] = nil
	if not ok then
		warn("[OverheadServer] build gagal untuk " .. player.Name .. ": " .. tostring(err))
	end
end

-- ============================================================
-- POLLING FALLBACK
-- Tunggu karakter muncul sampai max 30 detik setelah setupPlayer,
-- mengatasi kasus AvatarService delay spawn karakter
-- ============================================================
local function waitForCharacterAndBuild(player)
	local MAX_WAIT = 30
	local elapsed  = 0
	local STEP     = 0.5

	while elapsed < MAX_WAIT do
		if not player.Parent then return end  -- player sudah leave

		local char = player.Character
		if char then
			-- [FIX] lewat satu pintu; cek "sudah ada" pindah ke bangunOverhead
			task.spawn(bangunOverhead, char, player)
			return  -- selesai, CharacterAdded akan handle respawn
		end

		task.wait(STEP)
		elapsed += STEP
	end

	warn("[OverheadServer] Timeout menunggu karakter " .. player.Name)
end

-- ============================================================
-- DEBOUNCE REFRESH
-- ============================================================
local pendingRefresh = {}

local function scheduleRefresh(player)
	local uid = player.UserId
	if pendingRefresh[uid] then return end
	pendingRefresh[uid] = true
	task.delay(0.2, function()
		pendingRefresh[uid] = nil
		if not player.Parent then return end
		local char = player.Character
		local head = char and char:FindFirstChild("Head")
		local ov   = head and head:FindFirstChild("OverheadGui")
		if ov then
			updateOverhead(ov, player)
			RefreshOverhead:FireAllClients(player)
		end
	end)
end

-- ============================================================
-- SETUP PER PLAYER
-- ============================================================
-- ============================================================
-- ROLE CONFIG — dibaca dari GameConfig terpusat
-- Edit di ReplicatedStorage > ZayinConfig > GameConfig
-- ============================================================
local ROLE_CONFIG = GameConfig:BuildRoleConfig()

-- Text yang ditampilkan di overhead (boleh pakai emoji)
-- ROLE_DISPLAY dibaca dari GameConfig
local ROLE_DISPLAY = GameConfig:BuildRoleDisplay()

local function assignRole(player)
	local role = ROLE_CONFIG[player.UserId]
	if role then
		-- Simpan role ID murni untuk logic badge di client
		player:SetAttribute("RoleId", role)
		-- Simpan display text (dengan emoji) untuk tampilan overhead
		local displayText = ROLE_DISPLAY[role] or role
		player:SetAttribute("Role", displayText)
		-- Owner dan Developer otomatis verified
		if role == "Owner" or role == "Developer" then
			player:SetAttribute("IsVerified", true)
		end
	end
end

-- Cek VIP dari gamepass
local MarketplaceService = game:GetService("MarketplaceService")
local GAMEPASS_ID = 0  -- isi di sini atau di GamepassService

local function checkVIP(player)
	if GAMEPASS_ID == 0 then return end  -- skip jika belum ada gamepass
	local ok, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAMEPASS_ID)
	end)
	if ok and hasPass then
		player:SetAttribute("IsVIP", true)
	end
end

-- ============================================================
-- WATCH HEAD — cek setiap detik, rebuild jika OverheadGui hilang
-- Handle AvatarService yang swap karakter tanpa LoadCharacter()
-- ============================================================
local function watchHead(player)
	task.spawn(function()
		while player.Parent do
			local char = player.Character
			-- [FIX3] Jangan build selama AvatarService sedang menerapkan avatar —
			-- kalau tidak, poll ini yang akan membangun ke Head default sementara
			-- handler CharacterAdded sedang sabar menunggu avatar final.
			if char and not player:GetAttribute("AvatarSedangDiterapkan") then
				local head = char:FindFirstChild("Head")
				if head and not head:FindFirstChild("OverheadGui") then
					-- [FIX2] Tunggu Head "settle" dulu sebelum build.
					-- Ganti avatar pakai hum:ApplyDescription() = IN-PLACE, karakter
					-- tidak diganti tapi part Head DIGANTI (OverheadGui ikut mati).
					-- Kalau langsung build, kita bisa nempel ke Head perantara yang
					-- sebentar lagi dibuang -> build kepakai 2x untuk 1 ganti avatar.
					-- Solusi: jeda singkat, lalu pastikan Head-nya masih instance
					-- yang sama. Kalau sudah berganti, lewati saja — iterasi loop
					-- berikutnya (0.5 dtk) yang akan build ke Head final.
					task.wait(0.4)
					local masihSama = player.Parent
						and player.Character == char
						and char:FindFirstChild("Head") == head
						and not head:FindFirstChild("OverheadGui")
					if masihSama then
						bangunOverhead(char, player)
						task.delay(0.2, function()
							if player.Parent then RefreshOverhead:FireAllClients(player) end
						end)
					end
				end
			end
			task.wait(0.5)  -- cek lebih sering (tiap 0.5 detik)
		end
	end)
end

-- [FIX] cegah setupPlayer jalan 2x untuk player yang sama (PlayerAdded
-- + loop Players:GetPlayers() bisa bertabrakan kalau player join persis
-- saat script init). Tanpa ini SEMUA koneksi di bawah jadi dobel.
local sudahSetup = {}

local function setupPlayer(player)
	if sudahSetup[player] then return end
	sudahSetup[player] = true

	-- Set role otomatis saat join
	assignRole(player)
	task.spawn(checkVIP, player)  -- cek gamepass VIP

	-- [FIX] koneksi CharacterAdded digabung jadi SATU (dulu ada 2 koneksi
	-- terpisah ke sinyal yang sama: satu untuk build, satu untuk
	-- watchAvatarChange). Sekarang satu handler mengerjakan keduanya.

	-- Watch ganti avatar dari AvatarService
	-- AvatarService set attribute "AvatarChanged" saat ganti avatar
	local avatarChangedConn
	local function watchAvatarChange()
		if avatarChangedConn then avatarChangedConn:Disconnect() end
		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		-- Saat karakter Died (ganti/reset avatar), rebuild overhead setelah respawn
		avatarChangedConn = hum.Died:Connect(function()
			-- CharacterAdded akan handle rebuild, tidak perlu aksi di sini
			if avatarChangedConn then
				avatarChangedConn:Disconnect()
				avatarChangedConn = nil
			end
		end)
	end

	player.CharacterAdded:Connect(function(character)
		-- Delay untuk ganti avatar (AvatarService butuh waktu)
		task.wait(0.5)
		if player.Character ~= character then return end   -- sudah respawn lagi

		-- [FIX3] Kalau AvatarService akan menerapkan avatar pengganti, TUNGGU
		-- sampai selesai. Tanpa ini kita membangun overhead ke Head default yang
		-- sebentar lagi dibuang ApplyDescription -> build kepakai 2x per respawn.
		-- Batas 6 dtk supaya tidak menggantung kalau penanda tak pernah dilepas.
		local ditunggu = 0
		while player:GetAttribute("AvatarSedangDiterapkan") and ditunggu < 6 do
			task.wait(0.2)
			ditunggu += 0.2
			if player.Character ~= character then return end
		end

		bangunOverhead(character, player)
		watchAvatarChange()
	end)

	-- Watch pertama kali
	if player.Character then
		task.spawn(watchAvatarChange)
	end

	-- Polling fallback untuk join pertama
	task.spawn(waitForCharacterAndBuild, player)

	-- Watch head setiap 1 detik — handle AvatarService yang swap tanpa LoadCharacter
	watchHead(player)

	-- Watch attribute
	for _, attr in ipairs({ "IsVIP", "Role", "DeviceType" }) do
		player:GetAttributeChangedSignal(attr):Connect(function()
			scheduleRefresh(player)
		end)
	end

	-- [P9] refresh overhead awal: nilai summit sering baru tiba setelah overhead dibuild
	task.spawn(function()
		for _ = 1, 20 do
			task.wait(0.3)
			local ls = player:FindFirstChild("leaderstats")
			local sv = ls and ls:FindFirstChild("Summit")
			if sv and sv.Value > 0 then scheduleRefresh(player) break end
		end
	end)

	-- Watch summit
	task.spawn(function()
		local ls = player:WaitForChild("leaderstats", 20)
		if not ls then return end
		local sv = ls:WaitForChild("Summit", 20)
		if not sv then return end
		sv.Changed:Connect(function()
			scheduleRefresh(player)
		end)
	end)
end

-- ============================================================
-- REMOTE HANDLERS
-- ============================================================
-- [PATCH B1] gerbang admin: remote admin hanya boleh dipakai staff
local MIN_ADMIN_RANK = 2
local ADMIN_FALLBACK = { Owner = true, Developer = true, Admin = true, HeadAdmin = true }

local function isAdmin(sender)
	if typeof(sender) ~= "Instance" or not sender:IsA("Player") then return false end
	local rid = sender:GetAttribute("RoleId")
	if type(rid) ~= "string" or rid == "" then return false end
	-- [PATCH B1-FIX] GetRoleById menerima UserId dan mengembalikan (roleId, rank)
	local ok, _, rank = pcall(function() return GameConfig:GetRoleById(sender.UserId) end)
	if ok and type(rank) == "number" and rank >= MIN_ADMIN_RANK then
		return true
	end
	return ADMIN_FALLBACK[rid] == true
end
GrantVIP.OnServerEvent:Connect(function(sender, target)
	if not isAdmin(sender) then return end
	if target and target:IsA("Player") then
		target:SetAttribute("IsVIP", true)
		scheduleRefresh(target)
	end
end)

RevokeVIP.OnServerEvent:Connect(function(sender, target)
	if not isAdmin(sender) then return end
	if target and target:IsA("Player") then
		target:SetAttribute("IsVIP", false)
		scheduleRefresh(target)
	end
end)

SetRole.OnServerEvent:Connect(function(sender, target, role)
	if not isAdmin(sender) then return end
	if not (target and target:IsA("Player") and type(role) == "string") then return end
	-- [PATCH B1] hanya role yang terdaftar, bukan teks bebas
	if not ROLE_DISPLAY[role] then return end
	target:SetAttribute("RoleId", role)
	target:SetAttribute("Role", ROLE_DISPLAY[role])
	scheduleRefresh(target)
end)

-- Handle Verified (VerifiedAdd & VerifiedRemove sudah ada di ZayinRemotes > Admin)
local VerifiedAdd    = AdminFolder:FindFirstChild("VerifiedAdd")
local VerifiedRemove = AdminFolder:FindFirstChild("VerifiedRemove")
if VerifiedAdd then
	VerifiedAdd.OnServerEvent:Connect(function(sender, target)
		if not isAdmin(sender) then return end
		if target and target:IsA("Player") then
			target:SetAttribute("IsVerified", true)
		end
	end)
end
if VerifiedRemove then
	VerifiedRemove.OnServerEvent:Connect(function(sender, target)
		if not isAdmin(sender) then return end
		if target and target:IsA("Player") then
			target:SetAttribute("IsVerified", false)
		end
	end)
end

SendDeviceType.OnServerEvent:Connect(function(player, deviceType)
	local VALID = { PC=true, Mobile=true, Tablet=true, Console=true, VR=true }
	if type(deviceType) == "string" and VALID[deviceType] then
		player:SetAttribute("DeviceType", deviceType)
	end
end)

-- ============================================================
-- INIT
-- ============================================================
Players.PlayerAdded:Connect(setupPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, p)
end

Players.PlayerRemoving:Connect(function(p)
	pendingRefresh[p.UserId] = nil
	sudahSetup[p] = nil   -- [FIX] bebaskan penjaga saat player keluar
end)

print("[OverheadServer] Ready!")