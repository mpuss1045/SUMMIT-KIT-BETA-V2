-- ============================================================
-- AutoEquipCoil v9 — [FIX] verifikasi equip benar-benar berhasil
-- Lokasi: StarterPlayer > StarterCharacterScripts
-- Tipe  : LocalScript
-- ============================================================
--
-- MASALAH DI v8:
--   equipTarget() mengembalikan true SEGERA setelah hum:EquipTool(tool)
--   dipanggil, tanpa memeriksa apakah tool benar-benar pindah ke
--   character. Kalau EquipTool gagal diam-diam (tool baru tiba dari
--   GamepassService, Handle belum siap, Humanoid masih sibuk), loop
--   tetap break -> selesai=true -> penjaga dilepas -> CoiL nyangkut
--   di backpack.
--
-- PERBAIKAN v9:
--   1. Setelah EquipTool, VERIFIKASI tool sudah jadi anak character.
--   2. Kalau belum, coba lagi sampai batas waktu (bukan langsung menyerah).
--   3. Batas waktu dinaikkan jadi 10 detik, karena StaffPerks di
--      GamepassService bisa baru memberi tool pada detik ke-3+.
--   4. Tetap berhenti total begitu berhasil — pemain bebas ganti coil.
-- ============================================================

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local char   = script.Parent
local hum    = char:WaitForChild("Humanoid")

local DEBUG = false   -- set false kalau sudah stabil
local function dbg(...)
	if DEBUG then print("[AutoEquipCoil]", ...) end
end

local ltd = RS:WaitForChild("LastToolData", 10)
if not ltd then dbg("LastToolData tidak ada") return end

-- ============================================================
-- Tentukan coil target dari server
-- ============================================================
local target
local getCoil = ltd:WaitForChild("GetLastCoil", 5)
if getCoil then
	local ok, nama = pcall(function() return getCoil:InvokeServer() end)
	if ok and type(nama) == "string" and nama ~= "" then
		target = nama
	end
end

if not target or target == "BoomBox" then
	dbg("tidak ada target coil, berhenti")
	return
end

dbg("target =", target)

local backpack = player:WaitForChild("Backpack")
local selesai  = false

-- ============================================================
-- PENJAGA: cegah tool otomatis lain menyerobot ke tangan
-- sebelum coil target terpasang
-- ============================================================
local BATAS_DETIK = 10
local batas   = os.clock() + BATAS_DETIK
local penjaga

penjaga = char.ChildAdded:Connect(function(c)
	if selesai or os.clock() > batas then
		if penjaga then penjaga:Disconnect() penjaga = nil end
		return
	end
	if not c:IsA("Tool") then return end
	if c.Name == target or c.Name == "BoomBox" then return end
	c.Parent = backpack
end)

-- ============================================================
-- Cari tool target di backpack
-- ============================================================
local function cariDiBackpack()
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.Name == target then
			return tool
		end
	end
	return nil
end

-- Apakah target SUDAH benar-benar di tangan?
local function sudahDiTangan()
	local t = char:FindFirstChild(target)
	return t ~= nil and t:IsA("Tool")
end

-- ============================================================
-- LOOP UTAMA — coba equip, lalu VERIFIKASI
-- ============================================================
local percobaan = 0

while os.clock() < batas do
	-- sudah di tangan (mis. dipasang script lain) -> selesai
	if sudahDiTangan() then
		dbg("berhasil terpasang setelah", percobaan, "percobaan")
		selesai = true
		break
	end

	local tool = cariDiBackpack()
	if tool then
		percobaan += 1
		hum:EquipTool(tool)

		-- [FIX INTI] beri waktu, lalu PERIKSA hasilnya
		task.wait(0.25)

		if sudahDiTangan() then
			dbg("berhasil terpasang setelah", percobaan, "percobaan")
			selesai = true
			break
		end
		-- gagal diam-diam -> ulangi di iterasi berikutnya
	else
		-- tool belum tiba (GamepassService belum memberi) -> tunggu
		task.wait(0.2)
	end
end

if not selesai then
	dbg("GAGAL — target", target, "tidak terpasang dalam", BATAS_DETIK, "detik")
	if DEBUG then
		local isi = {}
		for _, t in ipairs(backpack:GetChildren()) do
			if t:IsA("Tool") then table.insert(isi, t.Name) end
		end
		dbg("  isi backpack:", #isi > 0 and table.concat(isi, ",") or "(kosong)")
	end
end

-- Tugas selesai: lepas penjaga, pemain bebas ganti coil kapan saja
selesai = true
if penjaga then penjaga:Disconnect() penjaga = nil end