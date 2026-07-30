-- ============================================================
-- ShopDonationConfig (ModuleScript)
-- Lokasi: ReplicatedStorage > ZayinConfig > ShopDonationConfig
-- Fungsi: Konfigurasi terpusat untuk Gamepass Shop dan Donasi
-- ============================================================

local ShopDonationConfig = {}

-- ============================================================
-- GAMEPASS SHOP
-- Isi id dan robux setelah buat gamepass di Roblox
-- id   = Gamepass ID dari roblox.com/game-passes
-- robux = Harga yang kamu set di Roblox (untuk tampilan)
-- ============================================================

ShopDonationConfig.Gamepass = {
	CoilVIP = {
		id      = 1927482802,
		robux   = 1,
		name    = "CoiL VIP",
		desc    = "Dapatkan CoiL eksklusif VIP dengan efek spesial dan speed boost!",
		icon    = "rbxassetid://96435424025676",
		color   = Color3.fromRGB(80, 200, 255),
		gives   = {
			tool  = "CoiL VIP",   -- nama tool di ServerStorage > VIPTools
			vip   = false,         -- dapat tag VIP atau tidak
		},
	},
	Boombox = {
		id      = 1927752752,
		robux   = 2,
		name    = "Boombox",
		desc    = "Putar musik favoritmu di dalam game untuk semua player!",
		icon    = "rbxassetid://109712524420605",
		color   = Color3.fromRGB(255, 160, 60),
		gives   = {
			tool  = "BoomBox",    -- nama tool di ServerStorage > VIPTools
			vip   = false,
		},
	},
	BundleVIP = {
		id      = 1927296791,
		robux   = 3,
		name    = "Bundle VIP",
		desc    = "Paket lengkap: CoiL VIP + Boombox + tag VIP eksklusif!",
		icon    = "rbxassetid://132250362817685",
		color   = Color3.fromRGB(255, 215, 0),
		gives   = {
			tool  = {"CoiL VIP", "BoomBox"},  -- dapat dua tool sekaligus
			vip   = true,                       -- dapat tag VIP
		},
	},
}

-- ============================================================
-- DONASI
-- ============================================================

ShopDonationConfig.Donation = {

	-- DataStore name (jangan ubah kecuali mau reset data donasi)
	DataStoreName  = "ZayinDonation_v1",
	NamesStoreName = "ZayinDonationNames_v1",

	-- Minimum Robux untuk bisa kirim pesan setelah donasi
	MinMessageRobux = 10,

	-- Jumlah entry di leaderboard donasi
	LeaderboardSize = 10,

	-- Interval refresh leaderboard donasi (detik)
	-- Jika nil, akan pakai GameConfig.LeaderboardRefresh
	UpdateInterval  = nil,

	-- Daftar produk donasi
	-- ProductId = ID dari Developer Product di Roblox
	Products = {
		{ ProductId = 3611543180, Robux = 5,    Label = "5 R$ Donasi" },
		{ ProductId = 3611543202, Robux = 10,   Label = "10 R$ Donasi" },
		{ ProductId = 3611543224, Robux = 30,   Label = "30 R$ Donasi" },
		{ ProductId = 3611543246, Robux = 50,   Label = "50 R$ Donasi" },
		{ ProductId = 3611543273, Robux = 100,  Label = "100 R$ Donasi" },
		{ ProductId = 3611543297, Robux = 300,  Label = "300 R$ Donasi" },
		{ ProductId = 3611543313, Robux = 500,  Label = "500 R$ Donasi" },
		{ ProductId = 3611543418, Robux = 1000, Label = "1000 R$ Donasi" },
	},

	-- ProductMap untuk ProcessReceipt (otomatis dibuild dari Products)
	ProductMap = {},
}

-- Build ProductMap otomatis dari Products
for _, p in ipairs(ShopDonationConfig.Donation.Products) do
	ShopDonationConfig.Donation.ProductMap[p.ProductId] = p.Robux
end

-- ============================================================
-- STAFF PERKS
-- Atur apakah role tertentu otomatis dapat item saat join
-- true  = otomatis dapat item (tanpa beli gamepass)
-- false = harus beli gamepass seperti player biasa
-- ============================================================

ShopDonationConfig.StaffPerks = {
	Owner = {
		CoilVIP   = true,   -- Owner otomatis dapat CoiL VIP
		Boombox   = true,   -- Owner otomatis dapat Boombox
		BundleVIP = true,   -- Owner otomatis dapat Bundle VIP + tag VIP
	},
	Developer = {
		CoilVIP   = true,
		Boombox   = true,
		BundleVIP = true,
	},
	HeadAdmin = {
		CoilVIP   = true,
		Boombox   = true,
		BundleVIP = true,
	},
	Admin = {
		CoilVIP   = true,
		Boombox   = true,
		BundleVIP = true,
	},
	Moderator = {
		CoilVIP   = true,
		Boombox   = true,
		BundleVIP = true,
	},
}

-- ============================================================
-- HELPER: Ambil semua gamepass sebagai list (untuk ZayinMenuShop)
-- ============================================================

function ShopDonationConfig:GetShopItems()
	local items = {}
	local order = {"CoilVIP", "Boombox", "BundleVIP"}
	for _, key in ipairs(order) do
		local gp = self.Gamepass[key]
		table.insert(items, {
			id    = gp.id,
			type  = "gamepass",
			name  = gp.name,
			desc  = gp.desc,
			price = "Gamepass",
			robux = gp.robux,
			icon  = gp.icon,
			color = gp.color,
		})
	end
	return items
end

-- Helper: Cek gamepass dari ID
function ShopDonationConfig:GetGamepassByID(id)
	for key, gp in pairs(self.Gamepass) do
		if gp.id == id then
			return key, gp
		end
	end
	return nil, nil
end


-- [P52] PRODUK GIFT (Developer Product) — edit ID & harga di sini
ShopDonationConfig.GiftProducts = {
	CoilVIP   = { productId = 3611544014, robux = 1, name = "CoiL VIP",   tool = "CoiL VIP" },
	Boombox   = { productId = 3611544049, robux = 2, name = "Boombox",    tool = "BoomBox"  },
	BundleVIP = { productId = 3611544079, robux = 3, name = "Bundle VIP", tool = {"CoiL VIP","BoomBox"}, vip = true },
}

-- Peta cepat: productId -> kunci
ShopDonationConfig.GiftMap = {}
for kunci, g in pairs(ShopDonationConfig.GiftProducts) do
	ShopDonationConfig.GiftMap[g.productId] = kunci
end
return ShopDonationConfig