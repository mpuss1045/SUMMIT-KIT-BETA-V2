-- ============================================================
-- GameConfig (ModuleScript)
-- Lokasi: ReplicatedStorage > ZayinConfig > GameConfig
-- Fungsi: Konfigurasi TERPUSAT untuk semua sistem game UJI COBA
-- Edit di satu tempat, berlaku di semua sistem
-- ============================================================

local GameConfig = {}

-- ============================================================
-- 1. DATA ROLE STAFF
-- Tambah UserId dan Username sesuai tim kamu
-- ============================================================

GameConfig.Roles = {
	{
		Rank   = 6,
		RoleId = "Owner",
		Users  = {
			{ UserId = 10503418720, Username = "iTzme_yunnitaa" },
		},
	},
	{
		Rank   = 5,
		RoleId = "Developer",
		Users  = {
			{ UserId = 8944405718, Username = "kayz_zx" },-- { UserId = 0, Username = "namadev" },
		},
	},
	{
		Rank   = 4,
		RoleId = "HeadAdmin",
		Users  = {
			-- { UserId = 0, Username = "namaheadadmin" },
		},
	},
	{
		Rank   = 3,
		RoleId = "Admin",
		Users  = {
			-- { UserId = 0, Username = "namaadmin" },
		},
	},
	{
		Rank   = 2,
		RoleId = "Moderator",
		Users  = {
			-- { UserId = 0, Username = "namamod" },
		},
	},
}

-- ============================================================
-- 2. PAPAN STAFF LEADERBOARD
-- ============================================================

GameConfig.StaffBoard = {
	Owner     = { DisplayText = "👑Owner👑",      Color = Color3.fromRGB(255,  50,  50) },
	Developer = { DisplayText = "🛠Developer🛠",  Color = Color3.fromRGB(255,  60, 200) },
	HeadAdmin = { DisplayText = "⚡ Head Admin", Color = Color3.fromRGB(255, 140,   0) },
	Admin     = { DisplayText = "🛡 Admin",      Color = Color3.fromRGB(255, 165,   0) },
	Moderator = { DisplayText = "🔧 Moderator",  Color = Color3.fromRGB( 80, 180, 255) },
	VIP       = { DisplayText = "⭐ VIP",        Color = Color3.fromRGB(255, 215,   0) },
}

-- ============================================================
-- 3. OVERHEAD (di atas kepala karakter)
-- RGB = true → animasi rainbow | false → warna polos
-- ============================================================

GameConfig.Overhead = {
	Owner = {
		DisplayText = "👑Owner👑",
		Color       = Color3.fromRGB(255, 50, 50),
		RGB         = true,
		TextSize    = 18,
		Font        = Enum.Font.GothamBold,
	},
	Developer = {
		DisplayText = "💻 Developer",
		Color       = Color3.fromRGB(255, 60, 200),
		RGB         = true,
		TextSize    = 16,
		Font        = Enum.Font.GothamBold,
	},
	HeadAdmin = {
		DisplayText = "⚡ Head Admin",
		Color       = Color3.fromRGB(255, 140, 0),
		RGB         = false,
		TextSize    = 16,
		Font        = Enum.Font.GothamBold,
	},
	Admin = {
		DisplayText = "🛡 Admin",
		Color       = Color3.fromRGB(255, 165, 0),
		RGB         = false,
		TextSize    = 16,
		Font        = Enum.Font.GothamBold,
	},
	Moderator = {
		DisplayText = "🔧 Mod",
		Color       = Color3.fromRGB(80, 180, 255),
		RGB         = false,
		TextSize    = 16,
		Font        = Enum.Font.GothamBold,
	},
	VIP = {
		DisplayText = "[ VIP ]",
		Color       = Color3.fromRGB(255, 215, 0),
		RGB         = false,
		TextSize    = 16,
		Font        = Enum.Font.GothamBold,
	},
}

-- ============================================================
-- 4. CHAT TAG
-- ============================================================

GameConfig.ChatTag = {
	Owner     = { Text = "OWNER",   Color = Color3.fromRGB(255,  50,  50) },
	Developer = { Text = "DEV",     Color = Color3.fromRGB(255,  60, 200) },
	HeadAdmin = { Text = "H.ADMIN", Color = Color3.fromRGB(255, 140,   0) },
	Admin     = { Text = "ADMIN",   Color = Color3.fromRGB(255, 165,   0) },
	Moderator = { Text = "MOD",     Color = Color3.fromRGB( 80, 180, 255) },
	VIP       = { Text = "VIP",     Color = Color3.fromRGB(255, 215,   0) },
}

GameConfig.ChatNameColor = {
	Owner     = Color3.fromRGB(255, 61, 210),
	Developer = Color3.fromRGB(115, 255, 0),
	HeadAdmin = Color3.fromRGB(255, 140,   0),
	Admin     = Color3.fromRGB(255, 165,   0),
	Moderator = Color3.fromRGB( 80, 180, 255),
	VIP       = Color3.fromRGB(255, 215,   0),
}

-- ============================================================
-- 5. LEADERBOARD FILTER
-- true  = staff MUNCUL di papan leaderboard
-- false = staff TIDAK MUNCUL di papan leaderboard
-- ============================================================

GameConfig.LeaderboardFilter = {
	ShowStaffInGlobalSummit  = true,
	ShowStaffInServerSummit  = true,
	ShowStaffInSpeedRun      = true,
}

-- ============================================================
-- 6. SPECTATE
-- ============================================================

GameConfig.Spectate = {
	Owner     = true,
	Developer = true,
	HeadAdmin = true,
	Admin     = true,
	Moderator = true,
	VIP       = true,
	Player    = true,
}

-- ============================================================
-- 7. SKIP CHECKPOINT
-- true = bisa skip | false = harus berurutan
-- ============================================================

GameConfig.SkipCheckpoint = {
	Owner     = true,
	Developer = false,
	HeadAdmin = false,
	Admin     = false,
	Moderator = false,
	VIP       = false,
	Player    = false,
}

-- ============================================================
-- 8. SUMMIT REWARD
-- ============================================================

GameConfig.SummitReward = {
	Hard = 1000,
	Easy = 100,
}
GameConfig.SummitHardReward = 1000
GameConfig.SummitEasyReward = 100

-- ============================================================
-- 9. INTERVAL REFRESH LEADERBOARD (detik)
-- ============================================================

GameConfig.LeaderboardRefresh = 180

-- ============================================================
-- 10. PLAYTIME
-- ============================================================

GameConfig.PlaytimeInterval = 30
GameConfig.PlaytimeReward   = 1

-- ============================================================
-- 11. SUMMIT TIER / TITLE
-- ============================================================

GameConfig.SummitTiers = {
	{ Min = 0,    Max = 0,    Title = "Pemula",         Color = Color3.fromRGB(180, 180, 180) },
	{ Min = 1,    Max = 5,    Title = "Pendaki Baru",   Color = Color3.fromRGB(160, 220, 160) },
	{ Min = 6,    Max = 10,   Title = "Pendaki Muda",   Color = Color3.fromRGB(100, 210, 100) },
	{ Min = 11,   Max = 20,   Title = "Petualang",      Color = Color3.fromRGB(100, 200, 255) },
	{ Min = 21,   Max = 35,   Title = "Penjelajah",     Color = Color3.fromRGB( 60, 160, 255) },
	{ Min = 36,   Max = 50,   Title = "Pendaki Handal", Color = Color3.fromRGB(180, 100, 255) },
	{ Min = 51,   Max = 75,   Title = "Ahli Gunung",    Color = Color3.fromRGB(255, 180,  80) },
	{ Min = 76,   Max = 100,  Title = "Master Summit",  Color = Color3.fromRGB(255, 140,   0) },
	{ Min = 101,  Max = 150,  Title = "Legenda",        Color = Color3.fromRGB(255,  80,  80) },
	{ Min = 151,  Max = 999,  Title = "APEX",           Color = Color3.fromRGB(255, 220,   0) },
	{ Min = 1000, Max = 9999999999, Title = "JAGOAN",         Color = Color3.fromRGB( 41,  34, 255) },
}

-- ============================================================
-- DATASTORE (jangan ubah kecuali mau reset semua data)
-- ============================================================

GameConfig.DataVersion    = "v1"
GameConfig.LeaderboardSize = 100
GameConfig.Checkpoints    = nil  -- diisi otomatis oleh CheckpointService

-- ============================================================
-- ADMIN BOARD (untuk papan staff leaderboard)
-- Dibuild otomatis dari Roles — tidak perlu edit manual
-- ============================================================

GameConfig.AdminBoard = {}
do
	local rankMap = {
		Owner=7, Developer=6, HeadAdmin=5,
		Admin=4, Moderator=3, Caster=2, VIP=1
	}
	for _, roleData in ipairs(GameConfig.Roles) do
		local rank = rankMap[roleData.RoleId] or 1
		local boardCfg = GameConfig.StaffBoard[roleData.RoleId]
		local roleText = boardCfg and boardCfg.DisplayText or roleData.RoleId
		for _, user in ipairs(roleData.Users) do
			table.insert(GameConfig.AdminBoard, {
				userId  = user.UserId,
				rank    = rank,
				role    = roleText,
				isStaff = true,
			})
		end
	end
end

-- ============================================================
-- ROLE COLORS (warna border papan staff leaderboard)
-- ============================================================

GameConfig.RoleColors = {
	Owner     = Color3.fromRGB(255, 215,   0),
	Developer = Color3.fromRGB(  0, 200, 180),
	HeadAdmin = Color3.fromRGB(255, 100, 100),
	Admin     = Color3.fromRGB(100, 150, 255),
	Moderator = Color3.fromRGB(100, 255, 100),
	Caster    = Color3.fromRGB(255, 150,   0),
	VIP       = Color3.fromRGB(200, 100, 255),
}

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

function GameConfig:GetRoleById(userId)
	for _, roleData in ipairs(self.Roles) do
		for _, user in ipairs(roleData.Users) do
			if user.UserId == userId then
				return roleData.RoleId, roleData.Rank
			end
		end
	end
	return nil, 0
end

function GameConfig:GetSummitTier(summit)
	for _, tier in ipairs(self.SummitTiers) do
		if summit >= tier.Min and summit <= tier.Max then
			return tier
		end
	end
	return self.SummitTiers[1]
end

function GameConfig:GetTitle(summit)
	for _, tier in ipairs(self.SummitTiers) do
		if summit >= tier.Min and summit <= tier.Max then
			return tier.Title, tier.Color
		end
	end
	return nil, nil
end

function GameConfig:BuildRoleConfig()
	local config = {}
	for _, roleData in ipairs(self.Roles) do
		for _, user in ipairs(roleData.Users) do
			config[user.UserId] = roleData.RoleId
		end
	end
	return config
end

function GameConfig:BuildRoleDisplay()
	local display = {}
	for roleId, cfg in pairs(self.Overhead) do
		display[roleId] = cfg.DisplayText
	end
	return display
end


-- [P35] Konfigurasi role di panel Leaderstat (atur teks & warna di sini)
-- Kunci = RoleId (dari attribute RoleId pemain). "Default" dipakai kalau tak ada role.
GameConfig.LeaderstatRoles = {
	Owner     = { Text = "OWNER",     Color = Color3.fromRGB(200, 255, 0)  },
	Developer = { Text = "DEVELOPER", Color = Color3.fromRGB(0, 187, 255) },
	Admin     = { Text = "ADMIN",     Color = Color3.fromRGB(255, 180, 50) },
	HeadAdmin = { Text = "HEAD ADMIN",Color = Color3.fromRGB(255, 160, 50) },
	Moderator = { Text = "MODERATOR", Color = Color3.fromRGB(90, 200, 255) },
	VIP       = { Text = "VIP",       Color = Color3.fromRGB(255, 215, 0)  },
	Default   = { Text = "PLAYER",    Color = Color3.fromRGB(160, 170, 185)},
}


-- [P65] Role yang boleh MENGHAPUS lagu di Boombox (true = boleh)
-- Kunci = RoleId. Pemain tanpa role di sini hanya bisa menambah lagu.
GameConfig.BoomboxAdminRoles = {
	Owner     = true,
	Developer = true,
	HeadAdmin = true,
	Admin     = true,
	Moderator = false,
	VIP       = false,
}
return GameConfig