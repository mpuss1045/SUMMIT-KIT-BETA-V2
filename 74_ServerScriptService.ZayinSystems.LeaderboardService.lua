-- ============================================
-- ZayinLeaderboardService (OPTIMIZED + NO MEMORY LEAK)
-- ============================================
local Players    = game:GetService("Players")
local DS         = game:GetService("DataStoreService")
local RS         = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local globalSummitODS   = DS:GetOrderedDataStore("ZayinGlobalSummit_v1")
local globalSpeedRunODS = DS:GetOrderedDataStore("ZayinGlobalSpeedRun_v1")
local globalPlaytimeODS = DS:GetOrderedDataStore("ZayinGlobalPlaytime_v1")

local ZC         = RS:WaitForChild("ZayinConfig")
local GameConfig = require(ZC:WaitForChild("GameConfig"))

-- ── Format waktu ───────────────────────────────────────────
local function formatTime(seconds)
	local m  = math.floor(seconds / 60)
	local s  = math.floor(seconds % 60)
	local ms = math.floor((seconds % 1) * 1000)
	return string.format("%02d:%02d.%03d", m, s, ms)
end

-- ── Get user info ──────────────────────────────────────────
local function getUserInfo(userId)
	for _, p in pairs(Players:GetPlayers()) do
		if p.UserId == userId then
			return p.DisplayName, p.Name
		end
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	local username = ok and name or "Player"
	return username, username
end

-- ── Cek staff ──────────────────────────────────────────────
local function isStaff(userId)
	for _, admin in pairs(GameConfig.AdminBoard or {}) do
		if admin.userId == userId and admin.isStaff then
			return true
		end
	end
	return false
end

-- ── Update SurfaceGui ──────────────────────────────────────
local function updateSurfaceGui(part, title, entries, valueTag)
	local sg = part:FindFirstChild("SurfaceGui")
	if not sg then return end
	local frame = sg:FindFirstChild("Frame")
	if not frame then return end
	local list = frame:FindFirstChild("List")
	if not list then return end
	local listContent = list:FindFirstChild("ListContent")
	if not listContent then return end
	local items = listContent:FindFirstChild("Items")
	if not items then return end

	for _, child in pairs(items:GetChildren()) do
		if child.Name:find("Entry_") then child:Destroy() end
	end

	local nothing = items:FindFirstChild("Nothing")
	if nothing then nothing.Visible = #entries == 0 end

	local existingPad = items:FindFirstChildOfClass("UIPadding")
	if not existingPad then
		local pad = Instance.new("UIPadding", items)
		pad.PaddingLeft   = UDim.new(0, 2)
		pad.PaddingRight  = UDim.new(0, 2)
		pad.PaddingTop    = UDim.new(0, 3)
		pad.PaddingBottom = UDim.new(0, 3)
	end

	local borderColors = {
		Color3.fromRGB(255, 215, 0),
		Color3.fromRGB(192, 192, 192),
		Color3.fromRGB(205, 127, 50),
	}
	local medals = {"🥇", "🥈", "🥉"}

	for i, entry in ipairs(entries) do
		local borderColor = i <= 3 and borderColors[i] or Color3.fromRGB(0, 200, 180)

		local bar = Instance.new("Frame")
		bar.Name = "Entry_" .. i
		bar.Size = UDim2.new(0.92, 0, 0, 40)
		bar.Position = UDim2.new(0.04, 0, 0, 0)
		bar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
		bar.BackgroundTransparency = 0.1
		bar.BorderSizePixel = 0
		bar.Parent = items
		Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)
		local stroke = Instance.new("UIStroke", bar)
		stroke.Color = borderColor
		stroke.Thickness = 1.5

		local medalBox = Instance.new("Frame", bar)
		medalBox.Size = UDim2.new(0, 30, 0, 30)
		medalBox.Position = UDim2.new(0, 4, 0.5, -15)
		medalBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		medalBox.BackgroundTransparency = 0.3
		medalBox.BorderSizePixel = 0
		Instance.new("UICorner", medalBox).CornerRadius = UDim.new(0, 6)
		local medalStroke = Instance.new("UIStroke", medalBox)
		medalStroke.Color = borderColor
		medalStroke.Thickness = 1
		local medalLabel = Instance.new("TextLabel", medalBox)
		medalLabel.Size = UDim2.new(1, 0, 1, 0)
		medalLabel.BackgroundTransparency = 1
		medalLabel.Text = i <= 3 and medals[i] or "#" .. i
		medalLabel.TextColor3 = borderColor
		medalLabel.TextScaled = true
		medalLabel.Font = Enum.Font.GothamBold

		local avatarFrame = Instance.new("Frame", bar)
		avatarFrame.Size = UDim2.new(0, 32, 0, 32)
		avatarFrame.Position = UDim2.new(0, 38, 0.5, -16)
		avatarFrame.BackgroundColor3 = borderColor
		avatarFrame.BackgroundTransparency = 0.5
		avatarFrame.BorderSizePixel = 0
		Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1, 0)
		local avatarImg = Instance.new("ImageLabel", avatarFrame)
		avatarImg.Size = UDim2.new(1, -2, 1, -2)
		avatarImg.Position = UDim2.new(0, 1, 0, 1)
		avatarImg.BackgroundTransparency = 1
		avatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. (entry.userId or 0) .. "&w=150&h=150"
		Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)

		local nameLabel = Instance.new("TextLabel", bar)
		nameLabel.Size = UDim2.new(0, 110, 0.5, 0)
		nameLabel.Position = UDim2.new(0, 74, 0, 2)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = entry.displayName or entry.name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left

		local atLabel = Instance.new("TextLabel", bar)
		atLabel.Size = UDim2.new(0, 110, 0.42, 0)
		atLabel.Position = UDim2.new(0, 74, 0.54, 0)
		atLabel.BackgroundTransparency = 1
		atLabel.Text = "@" .. entry.name
		atLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
		atLabel.TextScaled = true
		atLabel.Font = Enum.Font.GothamBold
		atLabel.TextXAlignment = Enum.TextXAlignment.Left

		local valBox = Instance.new("Frame", bar)
		valBox.Size = UDim2.new(0, 72, 0, 32)
		valBox.Position = UDim2.new(1, -82, 0.5, -16)
		valBox.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
		valBox.BackgroundTransparency = 0.2
		valBox.BorderSizePixel = 0
		Instance.new("UICorner", valBox).CornerRadius = UDim.new(0, 6)
		local valStroke = Instance.new("UIStroke", valBox)
		valStroke.Color = Color3.fromRGB(0, 200, 180)
		valStroke.Thickness = 1

		local valNum = Instance.new("TextLabel", valBox)
		valNum.Size = UDim2.new(1, 0, 0.55, 0)
		valNum.BackgroundTransparency = 1
		valNum.Text = entry.value
		valNum.TextColor3 = Color3.fromRGB(0, 230, 200)
		valNum.TextScaled = true
		valNum.Font = Enum.Font.GothamBold

		local valSub = Instance.new("TextLabel", valBox)
		valSub.Size = UDim2.new(1, 0, 0.4, 0)
		valSub.Position = UDim2.new(0, 0, 0.58, 0)
		valSub.BackgroundTransparency = 1
		valSub.Text = valueTag or "SUMMIT"
		valSub.TextColor3 = Color3.fromRGB(0, 180, 160)
		valSub.TextScaled = true
		valSub.Font = Enum.Font.GothamBold
	end

end

-- ══════════════════════════════════════════════════════════
-- PATUNG CONFIG (edit posisi di sini)
-- SCALE  = ukuran patung (1.0 = normal)
-- ANGLE  = arah hadap dalam derajat (0 = depan, 180 = belakang)
-- Y_OFFSET = ketinggian di atas kotak
-- ══════════════════════════════════════════════════════════
local PATUNG_GLOBAL_SUMMIT = { SCALE = 1.0, ANGLE = 90, Y_OFFSET = 0 }
local PATUNG_SERVER_SUMMIT = { SCALE = 1.0, ANGLE = 90, Y_OFFSET = 0 }
local PATUNG_SPEEDRUN      = { SCALE = 1.0, ANGLE = 90, Y_OFFSET = 0 }
local PATUNG_PLAYTIME      = { SCALE = 1.0, ANGLE = 270, Y_OFFSET = 0 }

-- ── Patung: track model yang dibuat ───────────────────────
local patungModels = {} -- {folderName = {rank = model}}

local function destroyPatung(folderName, rank)
	if patungModels[folderName] and patungModels[folderName][rank] then
		local m = patungModels[folderName][rank]
		if m and m.Parent then m:Destroy() end
		patungModels[folderName][rank] = nil
	end
	-- Hard cleanup
	for _, v in pairs(workspace:GetChildren()) do
		if v.Name == "PatungChar_" .. folderName .. "_" .. rank then
			v:Destroy()
		end
	end
end

-- [P34] cache juara: ingat siapa juara terakhir per slot agar tak rebuild sia-sia
local patungJuara = {}   -- [folderName][rank] = userId
local patungData  = {}   -- [folderName][rank] = {displayName, username, value, leaderboardType}

local function loadPatung(part, userId, config, folderName, rank)
	if not part or not userId or userId == 0 then return end
	config = config or {SCALE = 1.0, ANGLE = 0, Y_OFFSET = 2}

	-- [P34] skip rebuild: juara slot ini tidak berubah -> jangan unduh ulang avatar
	patungJuara[folderName] = patungJuara[folderName] or {}
	patungData[folderName]  = patungData[folderName]  or {}
	if patungJuara[folderName][rank] == userId then
		local m = patungModels[folderName] and patungModels[folderName][rank]
		if m and m.Parent then
			-- cukup perbarui angka overhead, model & avatar dibiarkan (mulus, tanpa kedip)
			local d = patungData[folderName][rank]
			if d then
				pcall(function()
					createOverhead(m, rank, d.displayName, d.username, d.value, d.leaderboardType)
				end)
			end
			return
		end
	end


	-- Hapus patung lama di slot ini
	destroyPatung(folderName, rank)
	-- [P34] reset saat ganti juara (dipanggil hanya saat rebuild sungguhan)

	-- Hapus BillboardGui fallback lama
	for _, v in pairs(part:GetChildren()) do
		if v.Name == "PatungGui" then v:Destroy() end
	end

	task.wait(0.2)

	-- Load HumanoidDescription dengan retry
	local desc = nil
	for attempt = 1, 3 do
		local ok, result = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(userId)
		end)
		if ok and result then desc = result break end
		if attempt < 3 then task.wait(2) end
	end

	if not desc then
		warn("[Patung] Gagal get desc userId:", userId)
		return
	end

	-- Buat model karakter
	local ok2, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok2 or not model then
		warn("[Patung] Gagal create model userId:", userId)
		return
	end

	model.Name = "PatungChar_" .. folderName .. "_" .. rank
	model:SetAttribute("ZayinPatung", true)
	model:SetAttribute("ZayinPatungFolder", folderName)
	model:SetAttribute("ZayinPatungRank", rank)
	model:SetAttribute("ZayinPatungUserId", userId)

	-- Hapus komponen berat
	for _, v in pairs(model:GetDescendants()) do
		if v:IsA("Script") or v:IsA("LocalScript") then
			v:Destroy()
		elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") then
			v:Destroy()
		elseif v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
			v:Destroy()
		end
	end

	-- Setup Humanoid untuk animasi
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.HealthDisplayType   = Enum.HumanoidHealthDisplayType.AlwaysOff
		hum.WalkSpeed  = 0
		hum.JumpHeight = 0
		hum.AutoRotate = false
	end
	if not hum:FindFirstChildOfClass("Animator") then
		Instance.new("Animator", hum)
	end

	-- Anchor semua part KECUALI HumanoidRootPart agar animasi jalan
	for _, v in pairs(model:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
			if v.Name == "HumanoidRootPart" then
				v.Anchored = true -- HRP di-anchor untuk lock posisi
			else
				v.Anchored = false -- limbs bebas untuk animasi
			end
		end
	end

	local boxSize = math.min(part.Size.X, part.Size.Z)
	local targetScale = math.clamp(boxSize / 3 * (config.SCALE or 1.0), 1.0, 4)
	model:ScaleTo(targetScale)

	-- Fix joint setelah ScaleTo
	task.wait(0.1)
	for _, v in pairs(model:GetDescendants()) do
		if v:IsA("Motor6D") then
			v.Enabled = true
		end
	end

	-- Pastikan Animator ada

	-- Pastikan Animator ada
	local humCheck = model:FindFirstChildOfClass("Humanoid")
	if humCheck and not humCheck:FindFirstChildOfClass("Animator") then
		Instance.new("Animator", humCheck)
	end

	-- Parent ke workspace
	model.Parent = workspace

	-- Posisikan tepat di atas kotak (tidak mengambang)
	task.wait(0.1)
	if model.PrimaryPart then
		local yOff = model:GetExtentsSize().Y / 2
		-- Y_OFFSET 0 = nempel di atas kotak
		local targetPos = part.Position + Vector3.new(0, part.Size.Y / 2 + yOff + (config.Y_OFFSET or 0), 0)
		model:SetPrimaryPartCFrame(
			CFrame.new(targetPos) * CFrame.Angles(0, math.rad(config.ANGLE or 0), 0)
		)
	end

	-- Re-anchor HRP setelah posisi
	for _, v in pairs(model:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.Anchored = v.Name == "HumanoidRootPart"
		end
	end

	-- Animasi dihandle PatungAnimator di client via ZayinPatung attribute

	-- Simpan referensi
	if not patungModels[folderName] then patungModels[folderName] = {} end
	patungModels[folderName][rank] = model

	-- [P61] catat juara slot ini (posisi benar: setelah patung dibuat)
	patungJuara[folderName] = patungJuara[folderName] or {}
	patungJuara[folderName][rank] = userId


end

-- ── Overhead keren di atas patung ─────────────────────────
local RANK_COLORS = {
	Color3.fromRGB(255, 215,   0), -- Gold  #1
	Color3.fromRGB(192, 192, 192), -- Silver #2
	Color3.fromRGB(205, 127,  50), -- Bronze #3
}
local RANK_ICONS  = {"👑", "⚡", "🔥"}
local RANK_SUFFIX = {"1st", "2nd", "3rd"}
local RANK_LABELS = {"#1", "#2", "#3"}

local TYPE_CONFIG = {
	GlobalSummit  = {icon = "🏔️", label = "Global Summit",  color = Color3.fromRGB(0,   220, 180)},
	ServerSummit  = {icon = "⚡",  label = "Server Summit",  color = Color3.fromRGB(100, 180, 255)},
	GlobalSpeedRun= {icon = "⏱️", label = "Speed Run",      color = Color3.fromRGB(255, 200,  50)},
	Playtime      = {icon = "⌛",  label = "Playtime",       color = Color3.fromRGB(180, 100, 255)},
	Donation      = {icon = "💎",  label = "Top Donasi",     color = Color3.fromRGB(255, 100, 150)},
}

local function createOverhead(model, rank, displayName, username, value, leaderboardType)
	local head = model:FindFirstChild("Head")
	if not head then return end
	local old = head:FindFirstChild("ZayinOverhead")
	if old then old:Destroy() end


	local rankColor  = RANK_COLORS[rank]  or Color3.fromRGB(0, 200, 180)
	local rankIcon   = RANK_ICONS[rank]   or "★"
	local rankSuffix = RANK_SUFFIX[rank]  or tostring(rank)
	local typeConf   = TYPE_CONFIG[leaderboardType] or TYPE_CONFIG.GlobalSummit

	-- BillboardGui: 4 baris teks
	local bb = Instance.new("BillboardGui")
	bb.Name           = "ZayinOverhead"
	bb.AlwaysOnTop    = false
	bb.Size           = UDim2.new(0, 200, 0, 80)
	bb.StudsOffset = Vector3.new(0, 10, 0)
	bb.MaxDistance    = 60
	bb.LightInfluence = 0
	bb.Parent         = head

	local function makeLine(text, color, yPos, ySize, font)
		local lbl = Instance.new("TextLabel", bb)
		lbl.Size                   = UDim2.new(1, 0, ySize, 0)
		lbl.Position               = UDim2.new(0, 0, yPos, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text                   = text
		lbl.TextColor3             = color
		lbl.TextScaled             = true
		lbl.Font                   = font or Enum.Font.GothamBold
		lbl.TextXAlignment         = Enum.TextXAlignment.Center
		local stroke = Instance.new("UIStroke", lbl)
		stroke.Color     = Color3.fromRGB(0, 0, 0)
		stroke.Thickness = 1.5
		return lbl
	end

	-- Baris 1: icon rank + suffix (1st/2nd/3rd)
	makeLine(rankIcon .. "  " .. rankSuffix, rankColor, 0, 0.25)

	-- Baris 2: icon tipe + nama leaderboard
	makeLine(typeConf.icon .. "  " .. typeConf.label, typeConf.color, 0.26, 0.24)

	-- Baris 3: nama player
	makeLine(displayName, Color3.fromRGB(255, 255, 255), 0.51, 0.25)

	-- Baris 4: nilai/angka
	makeLine(tostring(value), rankColor, 0.76, 0.24, Enum.Font.GothamBold)


end

local function updatePatungByFolder(folderName, entries, config)
	local lb = workspace:FindFirstChild("ZayinWorkspace")
	lb = lb and lb:FindFirstChild("LeaderBoard")
	local folder = lb and lb:FindFirstChild(folderName)
	if not folder then return end

	local suffix = folderName:match("Patung(.+)")
	task.spawn(function()
		task.wait(1) -- tunggu server stabil
		for rank = 1, 3 do
			local partName = suffix .. rank
			local part = folder:FindFirstChild(partName)
			if part then
				local entry = entries[rank]
				local userId = entry and tonumber(entry.userId) or 0
				-- Tentukan leaderboard type dari folderName
				local lbType = folderName
					:gsub("PatungTop", "")
					:gsub("Global", "Global")
				task.spawn(function()
					loadPatung(part, userId, config, folderName, rank)
					-- Tunggu model selesai load lalu buat overhead
					task.wait(0.5)
					local modelName = "PatungChar_" .. folderName .. "_" .. rank
					local model = workspace:FindFirstChild(modelName)
					if model and entry then
						-- [P61] simpan data overhead untuk refresh mulus
						patungData[folderName] = patungData[folderName] or {}
						patungData[folderName][rank] = {
							displayName = entry.displayName or entry.name or "?",
							username = entry.name or "?",
							value = entry.value or "0",
							leaderboardType = lbType,
						}
						createOverhead(
							model, rank,
							entry.displayName or entry.name or "?",
							entry.name or "?",
							entry.value or "0",
							lbType
						)
					end
				end)
				task.wait(4) -- delay antar patung
			end
		end
	end)
end

-- ── Fungsi patung per leaderboard ─────────────────────────
local function updatePatungGlobalSummit(entries)
	updatePatungByFolder("PatungTopGlobalSummit", entries, PATUNG_GLOBAL_SUMMIT)
end
local function updatePatungServerSummit(entries)
	updatePatungByFolder("PatungTopServerSummit", entries, PATUNG_SERVER_SUMMIT)
end
local function updatePatungSpeedRun(entries)
	updatePatungByFolder("PatungTopGlobalSpeedRun", entries, PATUNG_SPEEDRUN)
end
local function updatePatungPlaytime(entries)
	updatePatungByFolder("PatungTopPlaytime", entries, PATUNG_PLAYTIME)
end

-- ── Admin Board ────────────────────────────────────────────
local adminBoardUpdating = false
local function updateAdminBoard()
	if adminBoardUpdating then return end
	adminBoardUpdating = true
	task.delay(0.5, function() adminBoardUpdating = false end)
	local lb = workspace:FindFirstChild("ZayinWorkspace")
	lb = lb and lb:FindFirstChild("LeaderBoard")
	local part = lb and lb:FindFirstChild("AdminLeaderboard")
	if not part then return end

	local sg = part:FindFirstChild("SurfaceGui")
	if not sg then return end
	local frame = sg:FindFirstChild("Frame")
	if not frame then return end
	local listContent = frame:FindFirstChild("ListContent")
	if not listContent then
		local list = frame:FindFirstChild("List")
		listContent = list and list:FindFirstChild("ListContent")
	end
	if not listContent then return end
	-- Clear semua children kecuali UIPadding dan UIListLayout
	for _, child in pairs(listContent:GetChildren()) do
		if not child:IsA("UIPadding") and not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	local nothing = listContent:FindFirstChild("Nothing")
	if nothing then nothing.Visible = false end

	local existingPad = listContent:FindFirstChildOfClass("UIPadding")
	if not existingPad then
		local pad = Instance.new("UIPadding", listContent)
		pad.PaddingLeft   = UDim.new(0, 2)
		pad.PaddingRight  = UDim.new(0, 2)
		pad.PaddingTop    = UDim.new(0, 3)
		pad.PaddingBottom = UDim.new(0, 3)
	end

	local adminList = {}
	for _, v in pairs(GameConfig.AdminBoard or {}) do
		table.insert(adminList, v)
	end
	table.sort(adminList, function(a, b)
		return (a.rank or 0) > (b.rank or 0)
	end)

	for i, admin in ipairs(adminList) do
		local isOnline = false
		for _, p in pairs(Players:GetPlayers()) do
			if p.UserId == admin.userId then isOnline = true break end
		end

		local displayName, username = getUserInfo(admin.userId)
		local rank = admin.rank or 1
		local roleColors = GameConfig.RoleColors or {}
		local borderColor =
			rank == 7 and (roleColors.Owner     or Color3.fromRGB(255, 215,   0)) or
			rank == 6 and (roleColors.Developer  or Color3.fromRGB(  0, 200, 180)) or
			rank == 5 and (roleColors.HeadAdmin  or Color3.fromRGB(255, 100, 100)) or
			rank == 4 and (roleColors.Admin      or Color3.fromRGB(100, 150, 255)) or
			rank == 3 and (roleColors.Moderator  or Color3.fromRGB(100, 255, 100)) or
			rank == 2 and (roleColors.Caster     or Color3.fromRGB(255, 150,   0)) or
			(roleColors.VIP        or Color3.fromRGB(200, 100, 255))
		local isOwner = rank == 7

		local bar = Instance.new("Frame")
		bar.Name = "Entry_" .. i
		bar.Size = UDim2.new(0.92, 0, 0, 44)
		bar.Position = UDim2.new(0.04, 0, 0, 0)
		bar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
		bar.BackgroundTransparency = 0.1
		bar.BorderSizePixel = 0
		bar.Parent = listContent
		Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)
		local stroke = Instance.new("UIStroke", bar)
		stroke.Color = borderColor
		stroke.Thickness = 1.5

		local numLabel = Instance.new("TextLabel", bar)
		numLabel.Size = UDim2.new(0, 28, 1, 0)
		numLabel.Position = UDim2.new(0, 2, 0, 0)
		numLabel.BackgroundTransparency = 1
		numLabel.Text = "#" .. i
		numLabel.TextColor3 = borderColor
		numLabel.TextScaled = true
		numLabel.Font = Enum.Font.GothamBold

		local avatarFrame = Instance.new("Frame", bar)
		avatarFrame.Size = UDim2.new(0, 34, 0, 34)
		avatarFrame.Position = UDim2.new(0, 32, 0.5, -17)
		avatarFrame.BackgroundColor3 = borderColor
		avatarFrame.BackgroundTransparency = 0.5
		avatarFrame.BorderSizePixel = 0
		Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1, 0)
		local avatarImg = Instance.new("ImageLabel", avatarFrame)
		avatarImg.Size = UDim2.new(1, -2, 1, -2)
		avatarImg.Position = UDim2.new(0, 1, 0, 1)
		avatarImg.BackgroundTransparency = 1
		avatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. admin.userId .. "&w=150&h=150"
		Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)

		local nameLabel = Instance.new("TextLabel", bar)
		nameLabel.Size = UDim2.new(0, 95, 0.5, 0)
		nameLabel.Position = UDim2.new(0, 70, 0, 2)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = displayName
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left

		local atLabel = Instance.new("TextLabel", bar)
		atLabel.Size = UDim2.new(0, 95, 0.42, 0)
		atLabel.Position = UDim2.new(0, 70, 0.54, 0)
		atLabel.BackgroundTransparency = 1
		atLabel.Text = "@" .. username
		atLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
		atLabel.TextScaled = true
		atLabel.Font = Enum.Font.GothamBold
		atLabel.TextXAlignment = Enum.TextXAlignment.Left

		local roleBox = Instance.new("Frame", bar)
		roleBox.Size = UDim2.new(0, 65, 0, 22)
		roleBox.Position = UDim2.new(1, -150, 0.5, -11)
		roleBox.BackgroundColor3 = isOwner and Color3.fromRGB(80, 50, 0) or Color3.fromRGB(0, 40, 40)
		roleBox.BackgroundTransparency = 0.3
		roleBox.BorderSizePixel = 0
		Instance.new("UICorner", roleBox).CornerRadius = UDim.new(0, 6)
		local roleStroke = Instance.new("UIStroke", roleBox)
		roleStroke.Color = borderColor
		roleStroke.Thickness = 1
		local roleLabel = Instance.new("TextLabel", roleBox)
		roleLabel.Size = UDim2.new(1, 0, 1, 0)
		roleLabel.BackgroundTransparency = 1
		roleLabel.Text = admin.role
		roleLabel.TextColor3 = borderColor
		roleLabel.TextScaled = true
		roleLabel.Font = Enum.Font.GothamBold

		local statusBox = Instance.new("Frame", bar)
		statusBox.Size = UDim2.new(0, 65, 0, 22)
		statusBox.Position = UDim2.new(1, -80, 0.5, -11)
		statusBox.BackgroundColor3 = isOnline and Color3.fromRGB(0, 60, 0) or Color3.fromRGB(40, 0, 0)
		statusBox.BackgroundTransparency = 0.3
		statusBox.BorderSizePixel = 0
		Instance.new("UICorner", statusBox).CornerRadius = UDim.new(0, 6)
		local statusStroke = Instance.new("UIStroke", statusBox)
		statusStroke.Color = isOnline and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
		statusStroke.Thickness = 1
		local statusLabel = Instance.new("TextLabel", statusBox)
		statusLabel.Size = UDim2.new(1, 0, 1, 0)
		statusLabel.BackgroundTransparency = 1
		statusLabel.Text = isOnline and "● ONLINE" or "○ OFFLINE"
		statusLabel.TextColor3 = isOnline and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 80, 80)
		statusLabel.TextScaled = true
		statusLabel.Font = Enum.Font.GothamBold
	end

end

-- ── Timer countdown ────────────────────────────────────────
local countdownConnections = {}

local function startCountdown(part, timerPartName, seconds, onFinish)
	if not part then return end
	local timerPart = part:FindFirstChild(timerPartName)
	if not timerPart then return end
	local gui = timerPart:FindFirstChild("CountdownGui")
	if not gui then return end
	local mainFrame = gui:FindFirstChild("MainFrame")
	if not mainFrame then return end

	local countdown = nil
	for _, v in pairs(mainFrame:GetChildren()) do
		if v:IsA("TextLabel") and (v.Text:find("%d") or v.Text == "00:00") then
			countdown = v
			break
		end
	end
	if not countdown then return end

	local key = part.Name
	if countdownConnections[key] then
		countdownConnections[key]:Disconnect()
		countdownConnections[key] = nil
	end

	local remaining = seconds
	countdown.Text = tostring(seconds) .. "s"

	-- Ganti Heartbeat ke task.spawn loop - hemat 60x lipat CPU
	local loopActive = true
	countdownConnections[key] = {
		Disconnect = function() loopActive = false end,
		Connected  = true,
	}
	task.spawn(function()
		while loopActive do
			task.wait(1)
			if not loopActive then break end
			remaining = remaining - 1
			if remaining <= 0 then
				remaining = seconds
				if onFinish then task.spawn(onFinish) end
			end
			if countdown and countdown.Parent then
				countdown.Text = math.ceil(remaining) .. "s"
			end
		end
	end)

end

-- ── Global Summit ──────────────────────────────────────────
local function updateGlobalSummit()
	local lb = workspace:FindFirstChild("ZayinWorkspace")
	lb = lb and lb:FindFirstChild("LeaderBoard")
	local part = lb and lb:FindFirstChild("GlobalSummitLeaderboard")
	if not part then return end

	local ok, pages = pcall(function()
		return globalSummitODS:GetSortedAsync(false, 10)
	end)
	if not ok then return end

	local filter = GameConfig.LeaderboardFilter
	local entries = {}
	for _, entry in ipairs(pages:GetCurrentPage()) do
		local uid = tonumber(entry.key)
		if not (filter and filter.ShowStaffInGlobalSummit == false and isStaff(uid)) then
			local displayName, username = getUserInfo(uid)
			table.insert(entries, {
				name        = username,
				displayName = displayName,
				userId      = uid,
				value       = tostring(entry.value)
			})
		end
	end
	updateSurfaceGui(part, "🏆 Global Summit", entries, "SUMMIT")
	task.spawn(updatePatungGlobalSummit, entries)
end

-- ── Server Summit ──────────────────────────────────────────
local function updateServerSummit()
	local lb = workspace:FindFirstChild("ZayinWorkspace")
	lb = lb and lb:FindFirstChild("LeaderBoard")
	local part = lb and lb:FindFirstChild("ServerSummitLeaderboard")
	if not part then return end

	local filter = GameConfig.LeaderboardFilter
	local data = {}
	for _, p in pairs(Players:GetPlayers()) do
		local ls = p:FindFirstChild("leaderstats")
		if ls and ls:FindFirstChild("Summit") then
			if not (filter and filter.ShowStaffInServerSummit == false and isStaff(p.UserId)) then
				table.insert(data, {
					name        = p.Name,
					displayName = p.DisplayName,
					userId      = p.UserId,
					value       = tostring(ls.Summit.Value)
				})
			end
		end
	end
	table.sort(data, function(a, b)
		return tonumber(a.value) > tonumber(b.value)
	end)
	updateSurfaceGui(part, "⚡ Server Summit", data, "LIVE")
	task.spawn(updatePatungServerSummit, data)
end

-- ── SpeedRun ───────────────────────────────────────────────
local function updateSpeedRun()
	local lb = workspace:FindFirstChild("ZayinWorkspace")
	lb = lb and lb:FindFirstChild("LeaderBoard")
	local part = lb and lb:FindFirstChild("SpeedRunLeaderboard")
	if not part then return end

	local ok, pages = pcall(function()
		return globalSpeedRunODS:GetSortedAsync(true, 10)
	end)
	if not ok then return end

	local filter = GameConfig.LeaderboardFilter
	local entries = {}
	for _, entry in ipairs(pages:GetCurrentPage()) do
		local uid = tonumber(entry.key)
		if not (filter and filter.ShowStaffInSpeedRun == false and isStaff(uid)) then
			local displayName, username = getUserInfo(uid)
			local seconds = entry.value / 1000
			table.insert(entries, {
				name        = username,
				displayName = displayName,
				userId      = uid,
				value       = formatTime(seconds)
			})
		end
	end
	updateSurfaceGui(part, "⏱️ SpeedRun", entries, "TIME")
	task.spawn(updatePatungSpeedRun, entries)
end

-- ── Playtime ───────────────────────────────────────────────
local function updatePlaytime()
	local lb = workspace:FindFirstChild("ZayinWorkspace")
	lb = lb and lb:FindFirstChild("LeaderBoard")
	local part = lb and lb:FindFirstChild("TopPlaytime")
	if not part then return end

	local ok, pages = pcall(function()
		return globalPlaytimeODS:GetSortedAsync(false, 10)
	end)
	if not ok then return end

	local entries = {}
	for _, entry in ipairs(pages:GetCurrentPage()) do
		local uid = tonumber(entry.key)
		local displayName, username = getUserInfo(uid)
		local totalSecs = entry.value
		local days = math.floor(totalSecs / 86400)
		local hrs  = math.floor((totalSecs % 86400) / 3600)
		local mins = math.floor((totalSecs % 3600) / 60)
		local secs = totalSecs % 60
		local timeStr
		if days > 0 then
			timeStr = string.format("%dd%dh%dm", days, hrs, mins)
		elseif hrs > 0 then
			timeStr = string.format("%dh%dm%ds", hrs, mins, secs)
		else
			timeStr = string.format("%dm%ds", mins, secs)
		end
		table.insert(entries, {
			name        = username,
			displayName = displayName,
			userId      = uid,
			value       = timeStr
		})
	end
	updateSurfaceGui(part, "⌛ Playtime", entries, "PLAYTIME")
	task.spawn(updatePatungPlaytime, entries)
end

-- ── Update ODS saat summit berubah ────────────────────────
Players.PlayerAdded:Connect(function(player)
	task.wait(3)
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local summit = ls:FindFirstChild("Summit")
		if summit then
			summit.Changed:Connect(function(val)
				pcall(function()
					globalSummitODS:SetAsync(tostring(player.UserId), val)
				end)
				task.spawn(updateGlobalSummit)
				task.spawn(updateServerSummit)
			end)
		end
	end
	task.spawn(updateServerSummit)
	task.spawn(updateAdminBoard)
end)

Players.PlayerRemoving:Connect(function()
	task.wait(1)
	task.spawn(updateServerSummit)
	task.spawn(updateAdminBoard)
end)

-- ── Cleanup patung saat server tutup ──────────────────────
game:BindToClose(function()
	for _, v in pairs(workspace:GetChildren()) do
		if v:GetAttribute("ZayinPatung") then v:Destroy() end
	end
	for key, conn in pairs(countdownConnections) do
		if conn then conn:Disconnect() end
		countdownConnections[key] = nil
	end
end)

-- ── Init ───────────────────────────────────────────────────
task.spawn(function()
	task.wait(1)
	local lb = workspace:WaitForChild("ZayinWorkspace"):WaitForChild("LeaderBoard")

	updateGlobalSummit()
	updateServerSummit()
	updateSpeedRun()
	updatePlaytime()
	updateAdminBoard()

	startCountdown(lb:FindFirstChild("GlobalSummitLeaderboard"), "GlobalTimerCuntdown", (GameConfig.LeaderboardRefresh or 60) , updateGlobalSummit)
	startCountdown(lb:FindFirstChild("ServerSummitLeaderboard"), "ServerTimerCuntdown", (GameConfig.LeaderboardRefresh or 60) , updateServerSummit)
	startCountdown(lb:FindFirstChild("SpeedRunLeaderboard"),     "SpeedRunTimerCuntdown", (GameConfig.LeaderboardRefresh or 60) , updateSpeedRun)
	startCountdown(lb:FindFirstChild("TopPlaytime"),             "TopPlaytimeCuntdown", (GameConfig.LeaderboardRefresh or 60) , updatePlaytime)
	startCountdown(lb:FindFirstChild("AdminLeaderboard"),        "AdminTimerCuntdown", (GameConfig.LeaderboardRefresh or 60) , updateAdminBoard)
end)