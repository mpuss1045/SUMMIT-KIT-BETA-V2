-- ============================================================
-- GamepassService (Script) — [FIX] eksekusi dobel dihilangkan
-- Lokasi: ServerScriptService > ZayinSystems > GamepassService
-- Fungsi: Cek gamepass saat join dan saat beli, lalu give tool
-- ============================================================
--
-- MASALAH DI VERSI LAMA:
--   1. setupPlayer() memanggil checkGamepasses() LANGSUNG, padahal
--      CharacterAdded juga menyala saat join -> checkGamepasses jalan 2x.
--      Sama untuk checkStaffPerks. Ini sebab log "mendapat CoiL VIP"
--      dan "StaffPerks applied" tercetak dobel tiap respawn.
--   2. checkStaffPerks menunggu task.wait(3) menebak kapan RoleId siap.
--      Kalau OverheadServer lambat, perks gagal; kalau cepat, buang waktu
--      3 detik -- dan AutoEquipCoil keburu menyerah menunggu tool.
--   3. Owner punya CoilVIP=true DAN BundleVIP=true, sedangkan BundleVIP
--      memberi CoiL+BoomBox lagi -> giveTool dipanggil berulang.
--   4. Dua thread giveTool bisa jalan bersamaan dan sama-sama lolos
--      pengecekan "sudah punya" -> tool dobel di backpack.
--
-- PERBAIKAN:
--   - Semua pemberian tool lewat SATU jalur: CharacterAdded.
--     (CharacterAdded tetap menyala saat join, jadi tidak ada yang hilang.)
--   - Kunci per-pemain supaya tidak ada dua proses berjalan bersamaan.
--   - RoleId ditunggu lewat GetAttributeChangedSignal, bukan tebakan waktu.
--   - Penjagaan supaya setupPlayer tidak terpasang dua kali.
-- ============================================================

local Players            = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ServerStorage      = game:GetService("ServerStorage")

-- ============================================================
-- CONFIG — dibaca dari ShopDonationConfig
-- ============================================================
local RS2 = game:GetService("ReplicatedStorage")
local ShopDonationConfig = require(RS2:WaitForChild("ZayinConfig", 10):WaitForChild("ShopDonationConfig", 10))

local GAMEPASS_COIL_VIP  = ShopDonationConfig.Gamepass.CoilVIP.id
local GAMEPASS_BOOMBOX   = ShopDonationConfig.Gamepass.Boombox.id
local GAMEPASS_BUNDLE    = ShopDonationConfig.Gamepass.BundleVIP.id

-- ============================================================
-- TOOLS dari ServerStorage
-- ============================================================
local VIPTools   = ServerStorage:WaitForChild("VIPTools", 10)
local CoilVIP    = VIPTools:WaitForChild("CoiL VIP", 10)
local BoomBox    = VIPTools:WaitForChild("BoomBox", 10)

-- ============================================================
-- HELPER: Give tool ke player (aman dari pemberian dobel)
-- ============================================================
local function giveTool(player, toolTemplate)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then return false end

	-- Sudah ada di backpack atau sedang dipegang -> tidak perlu
	if backpack:FindFirstChild(toolTemplate.Name) then return false end
	if player.Character and player.Character:FindFirstChild(toolTemplate.Name) then return false end

	local clone = toolTemplate:Clone()
	clone.Parent = backpack
	print("[GamepassService] " .. player.Name .. " mendapat " .. toolTemplate.Name)
	return true
end

-- ============================================================
-- CEK GAMEPASS (dibeli)
-- ============================================================
local function punyaGamepass(player, id)
	if id == 0 then return false end
	local ok, has = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
	end)
	return ok and has
end

-- ============================================================
-- TUNGGU RoleId SIAP (diset OverheadServer) — maksimal 8 detik
-- Lebih andal daripada menebak dengan task.wait(3)
-- ============================================================
local function tungguRoleId(player, batasDetik)
	if player:GetAttribute("RoleId") then
		return player:GetAttribute("RoleId")
	end

	local selesai = false
	task.delay(batasDetik or 8, function() selesai = true end)

	while not selesai and player.Parent do
		local r = player:GetAttribute("RoleId")
		if r then return r end
		task.wait(0.2)
	end
	return player:GetAttribute("RoleId")
end

-- ============================================================
-- BERIKAN SEMUA HAK (gamepass + staff perks) — satu jalur
-- ============================================================
local sedangProses = {}   -- [player] = true, kunci anti-tumpang tindih

local function berikanSemuaHak(player)
	if sedangProses[player] then return end
	sedangProses[player] = true

	local ok, err = pcall(function()
		-- ---------- 1. GAMEPASS ----------
		local dapatCoil, dapatBoom = false, false

		if punyaGamepass(player, GAMEPASS_COIL_VIP) then
			dapatCoil = true
		end
		if punyaGamepass(player, GAMEPASS_BOOMBOX) then
			dapatBoom = true
		end
		if punyaGamepass(player, GAMEPASS_BUNDLE) then
			dapatCoil, dapatBoom = true, true
			player:SetAttribute("IsVIP", true)
		end

		-- ---------- 2. STAFF PERKS ----------
		local roleId = tungguRoleId(player, 8)
		if roleId then
			local perks = ShopDonationConfig.StaffPerks and ShopDonationConfig.StaffPerks[roleId]
			if perks then
				if perks.CoilVIP   then dapatCoil = true end
				if perks.Boombox   then dapatBoom = true end
				if perks.BundleVIP then
					dapatCoil, dapatBoom = true, true
					player:SetAttribute("IsVIP", true)
				end
				print("[GamepassService] StaffPerks applied untuk", player.Name, "(" .. roleId .. ")")
			end
		end

		-- ---------- 3. BERI TOOL (masing-masing maksimal sekali) ----------
		if dapatCoil then giveTool(player, CoilVIP) end
		if dapatBoom then giveTool(player, BoomBox) end
	end)

	sedangProses[player] = nil
	if not ok then
		warn("[GamepassService] error saat memberi hak untuk " .. player.Name .. ": " .. tostring(err))
	end
end

-- ============================================================
-- SETUP PEMAIN — hanya satu jalur: CharacterAdded
-- (CharacterAdded juga menyala saat join, jadi tidak ada yang terlewat)
-- ============================================================
local sudahSetup = {}

local function setupPlayer(player)
	if sudahSetup[player] then return end   -- cegah koneksi dobel
	sudahSetup[player] = true

	player.CharacterAdded:Connect(function()
		task.wait(1)   -- tunggu backpack siap
		berikanSemuaHak(player)
	end)

	-- Kalau character sudah ada saat script ini jalan (mis. reload Studio)
	if player.Character then
		task.spawn(function()
			task.wait(1)
			berikanSemuaHak(player)
		end)
	end
end

Players.PlayerRemoving:Connect(function(player)
	sudahSetup[player]   = nil
	sedangProses[player] = nil
end)

-- ============================================================
-- PROMPT PURCHASE CALLBACK
-- ============================================================
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, purchased)
	if not purchased then return end

	if gamepassId == GAMEPASS_COIL_VIP then
		giveTool(player, CoilVIP)
		print("[GamepassService] " .. player.Name .. " beli CoiL VIP!")

	elseif gamepassId == GAMEPASS_BOOMBOX then
		giveTool(player, BoomBox)
		print("[GamepassService] " .. player.Name .. " beli BoomBox!")

	elseif gamepassId == GAMEPASS_BUNDLE then
		giveTool(player, CoilVIP)
		giveTool(player, BoomBox)
		player:SetAttribute("IsVIP", true)
		print("[GamepassService] " .. player.Name .. " beli Bundle VIP!")
	end
end)

-- ============================================================
-- INIT
-- ============================================================
Players.PlayerAdded:Connect(setupPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, p)
end

print("[GamepassService] Ready!")