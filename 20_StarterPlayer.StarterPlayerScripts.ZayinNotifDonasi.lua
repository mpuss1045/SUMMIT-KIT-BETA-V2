--[[
	═══════════════════════════════════════════════════════════════
	ZayinNotifDonasi  (LocalScript)
	Lokasi pasang : StarterPlayer > StarterPlayerScripts
	═══════════════════════════════════════════════════════════════

	Sistem notif donasi DITULIS ULANG DARI NOL.
	Menggantikan blok notif lama di DonationClient (processNotif).

	KENAPA DIPISAH:
	  Notif lama terselip di DonationClient yang 628 baris bersama
	  panel donasi, papan top-donatur, dan dialog pesan. Dipisah
	  supaya bisa dibaca, diperbaiki, atau dihapus tanpa menyentuh
	  fitur lain yang sudah benar.

	PERBAIKAN DARI VERSI LAMA:
	  1. ANTRIAN SUNGGUHAN — notif lama saling membunuh karena
	     old:Destroy() dipanggil tiap notif baru dan loop tidak
	     pernah menunggu. Di sini tiap kartu punya hidupnya sendiri.
	  2. BERTUMPUK — sampai 3 kartu sekaligus, jadi donasi beruntun
	     terlihat semua. Lebih dari itu mengantre.
	  3. UMUR LEBIH PANJANG — 8 detik, cukup untuk menutup dialog
	     pembelian Roblox yang menutupi layar lebih dulu.
	  4. TAHAN RESPAWN — ResetOnSpawn = false, GUI dibuat sekali.

	SUMBER DATA (dikirim server lewat DonationNotify):
	  data.type    "donation" | "message" | "gift"
	  data.donor   nama penampil
	  data.userId  untuk avatar
	  data.amount  jumlah donasi (tipe donation)
	  data.total   total semua donasi
	  data.message pesan opsional
	═══════════════════════════════════════════════════════════════
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════════════════
-- PENGATURAN — ubah di sini kalau mau menyetel
-- ═══════════════════════════════════════════════════════
local MAKS_TUMPUK = 3      -- kartu tampil bersamaan maksimal
local DURASI      = 8      -- detik tiap kartu bertahan
local JEDA_MUNCUL = 0.25   -- jeda antar kartu supaya animasi rapi
local DEBUG       = false  -- true = cetak log ke Output

local M = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local WARNA = {
	kartu  = Color3.fromRGB(13, 15, 22),
	emas   = Color3.fromRGB(255, 200, 55),
	emasT  = Color3.fromRGB(255, 210, 70),
	putih  = Color3.fromRGB(255, 255, 255),
	teks   = Color3.fromRGB(255, 205, 70),
	pesan  = Color3.fromRGB(205, 215, 230),
	kotak  = Color3.fromRGB(22, 25, 34),
}

local function dbg(...)
	if DEBUG then print("[NotifDonasi]", ...) end
end

-- ═══════════════════════════════════════════════════════
-- HELPER
-- ═══════════════════════════════════════════════════════
local function buat(kelas, sifat, induk)
	local o = Instance.new(kelas)
	for k, v in pairs(sifat) do o[k] = v end
	o.Parent = induk
	return o
end

local function sudut(r, induk)
	buat("UICorner", { CornerRadius = UDim.new(0, r) }, induk)
end

local function garis(warna, tebal, induk)
	buat("UIStroke", { Color = warna, Thickness = tebal }, induk)
end

-- ═══════════════════════════════════════════════════════
-- GUI INDUK — dibuat sekali, tahan respawn
-- ═══════════════════════════════════════════════════════
local lama = PlayerGui:FindFirstChild("ZayinNotifDonasi")
if lama then lama:Destroy() end

local gui = buat("ScreenGui", {
	Name           = "ZayinNotifDonasi",
	ResetOnSpawn   = false,
	IgnoreGuiInset = true,
	DisplayOrder   = 200,
}, PlayerGui)

-- wadah penumpuk di tengah atas
local wadah = buat("Frame", {
	Name                   = "Wadah",
	AnchorPoint            = Vector2.new(0.5, 0),
	Position               = UDim2.new(0.5, 0, 0, M and 54 or 70),
	Size                   = UDim2.new(1, 0, 0, 0),
	BackgroundTransparency = 1,
}, gui)

local tata = buat("UIListLayout", {
	SortOrder          = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding            = UDim.new(0, 8),
}, wadah)

-- ═══════════════════════════════════════════════════════
-- BANGUN SATU KARTU NOTIF
-- ═══════════════════════════════════════════════════════
local urutan = 0

local function bangunKartu(data)
	local adaPesan = data.message ~= nil and data.message ~= ""
	local vp = workspace.CurrentCamera.ViewportSize
	local W  = math.clamp(vp.X * (M and 0.92 or 0.32), 300, 470)
	local H  = adaPesan and (M and 150 or 168) or (M and 100 or 112)

	urutan += 1

	local kartu = buat("Frame", {
		Name                   = "Kartu",
		LayoutOrder            = urutan,
		Size                   = UDim2.fromOffset(W, H),
		BackgroundColor3       = WARNA.kartu,
		BackgroundTransparency = 1,   -- mulai transparan, dimunculkan lewat tween
		BorderSizePixel        = 0,
	}, wadah)
	sudut(14, kartu)
	garis(WARNA.emas, 2, kartu)

	-- garis aksen atas
	local aksen = buat("Frame", {
		Size             = UDim2.new(1, -30, 0, 3),
		Position         = UDim2.new(0, 15, 0, 0),
		BackgroundColor3 = WARNA.emasT,
		BorderSizePixel  = 0,
	}, kartu)
	sudut(3, aksen)

	-- avatar bulat
	local avSz = M and 52 or 60
	local ring = buat("Frame", {
		Size             = UDim2.fromOffset(avSz, avSz),
		Position         = UDim2.new(0, 12, 0, M and 16 or 18),
		BackgroundColor3 = WARNA.emas,
		BorderSizePixel  = 0,
	}, kartu)
	sudut(100, ring)

	local av = buat("ImageLabel", {
		Size             = UDim2.new(1, -4, 1, -4),
		Position         = UDim2.new(0, 2, 0, 2),
		BackgroundColor3 = Color3.fromRGB(22, 24, 30),
		BorderSizePixel  = 0,
		Image = data.userId
			and ("rbxthumb://type=AvatarHeadShot&id=" .. data.userId .. "&w=150&h=150")
			or "",
	}, ring)
	sudut(100, av)

	local xT = avSz + 22
	local fB = M and 17 or 19
	local fS = M and 14 or 15
	local atas = M and 12 or 14

	-- nama donatur
	buat("TextLabel", {
		Size                   = UDim2.new(1, -xT - 14, 0, fB + 3),
		Position               = UDim2.new(0, xT, 0, atas),
		BackgroundTransparency = 1,
		Text                   = tostring(data.donor or "?"),
		TextColor3             = WARNA.putih,
		Font                   = Enum.Font.GothamBold,
		TextSize               = fB,
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextTruncate           = Enum.TextTruncate.AtEnd,
	}, kartu)

	-- dua baris keterangan
	local baris1, baris2
	if data.type == "message" then
		baris1 = "mengirim pesan"
	elseif data.type == "gift" then
		baris1 = "memberi hadiah"
	else
		baris1 = "telah mendonasikan sebesar " .. tostring(data.amount or 0) .. " R$"
	end
	baris2 = "total semua donasi " .. tostring(data.total or 0) .. " R$"

	buat("TextLabel", {
		Size                   = UDim2.new(1, -xT - 14, 0, fS + 3),
		Position               = UDim2.new(0, xT, 0, atas + fB + 3),
		BackgroundTransparency = 1,
		Text                   = baris1,
		TextColor3             = WARNA.teks,
		Font                   = Enum.Font.GothamBold,
		TextSize               = fS + 1,
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextTruncate           = Enum.TextTruncate.AtEnd,
	}, kartu)

	buat("TextLabel", {
		Size                   = UDim2.new(1, -xT - 14, 0, fS + 3),
		Position               = UDim2.new(0, xT, 0, atas + fB + fS + 7),
		BackgroundTransparency = 1,
		Text                   = baris2,
		TextColor3             = WARNA.teks,
		Font                   = Enum.Font.GothamBold,
		TextSize               = fS + 1,
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextTruncate           = Enum.TextTruncate.AtEnd,
	}, kartu)

	-- pesan opsional
	if adaPesan then
		local kotak = buat("Frame", {
			Size                   = UDim2.new(1, -24, 0, M and 42 or 48),
			Position               = UDim2.new(0, 12, 1, -(M and 50 or 56)),
			BackgroundColor3       = WARNA.kotak,
			BackgroundTransparency = 0.35,
			BorderSizePixel        = 0,
		}, kartu)
		sudut(10, kotak)

		buat("TextLabel", {
			Size                   = UDim2.new(1, -16, 1, 0),
			Position               = UDim2.new(0, 8, 0, 0),
			BackgroundTransparency = 1,
			Text                   = '"' .. tostring(data.message) .. '"',
			TextColor3             = WARNA.pesan,
			Font                   = Enum.Font.GothamMedium,
			TextSize               = fS + 1,
			TextXAlignment         = Enum.TextXAlignment.Left,
			TextWrapped            = true,
			TextTruncate           = Enum.TextTruncate.AtEnd,
		}, kotak)
	end

	return kartu, H
end

-- ═══════════════════════════════════════════════════════
-- TAMPILKAN SATU KARTU (punya siklus hidup sendiri)
-- ═══════════════════════════════════════════════════════
local aktif = 0

local function tampilkan(data)
	aktif += 1
	dbg("tampil:", data.type, data.donor, "| aktif:", aktif)

	local ok = pcall(function()
		local kartu, H = bangunKartu(data)

		-- masuk: geser turun + memudar masuk
		kartu.Position = UDim2.new(0, 0, 0, -H)
		TweenService:Create(kartu,
			TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 0.5 }):Play()

		task.wait(DURASI)

		-- keluar: memudar
		if kartu.Parent then
			TweenService:Create(kartu,
				TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
				{ BackgroundTransparency = 1 }):Play()
			for _, d in ipairs(kartu:GetDescendants()) do
				if d:IsA("TextLabel") then
					TweenService:Create(d, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
				elseif d:IsA("ImageLabel") then
					TweenService:Create(d, TweenInfo.new(0.3), { ImageTransparency = 1 }):Play()
				elseif d:IsA("UIStroke") then
					TweenService:Create(d, TweenInfo.new(0.3), { Transparency = 1 }):Play()
				elseif d:IsA("Frame") then
					TweenService:Create(d, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
				end
			end
			task.wait(0.32)
			kartu:Destroy()
		end
	end)

	if not ok then dbg("gagal membangun kartu") end
	aktif -= 1
end

-- ═══════════════════════════════════════════════════════
-- ANTRIAN — kartu ke-4 dst menunggu giliran
-- ═══════════════════════════════════════════════════════
local antrian  = {}
local memproses = false

local function proses()
	if memproses then return end
	memproses = true

	while #antrian > 0 do
		if aktif >= MAKS_TUMPUK then
			task.wait(0.3)          -- tunggu ada slot kosong
		else
			local data = table.remove(antrian, 1)
			task.spawn(tampilkan, data)
			task.wait(JEDA_MUNCUL)
		end
	end

	memproses = false
end

-- ═══════════════════════════════════════════════════════
-- SAMBUNG KE SERVER
-- ═══════════════════════════════════════════════════════
local folder = ReplicatedStorage:WaitForChild("DonationSystem", 20)
if not folder then
	warn("[NotifDonasi] DonationSystem tidak ditemukan!")
	return
end

local notifRE = folder:WaitForChild("DonationNotify", 20)
if not notifRE then
	warn("[NotifDonasi] DonationNotify tidak ditemukan!")
	return
end

notifRE.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then return end
	table.insert(antrian, data)
	dbg("terima:", data.type, "| antrian:", #antrian)
	task.spawn(proses)
end)

print("[ZayinNotifDonasi] Ready!")