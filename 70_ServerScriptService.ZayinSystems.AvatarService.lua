-- ============================================
-- ZayinAvatarService (FIXED)
-- ============================================
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local ZR           = RS:WaitForChild("ZayinRemotes")
local AvatarRemotes = ZR:WaitForChild("Avatar")
local ChangeRE     = AvatarRemotes:WaitForChild("Change")
local ResetRE      = AvatarRemotes:WaitForChild("Reset")

local originalDesc = {} -- avatar asli player
local currentDesc  = {} -- avatar yang sedang dipakai
local currentId    = {} -- avatarId yang sedang dipakai (0 = avatar asli)

-- ── Apply description ke karakter ─────────────────────────
local function applyDesc(player, desc)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	-- Simpan SEMUA tool di karakter (CoiL + BoomBox sekaligus)
	local equippedTools = {}
	local equippedTool  = nil  -- tool utama (di tangan)
	for _, item in pairs(char:GetChildren()) do
		if item:IsA("Tool") then
			table.insert(equippedTools, item)
			-- BoomBox = tool utama yang di tangan
			if item.Name == "BoomBox" then
				equippedTool = item
			elseif not equippedTool then
				equippedTool = item
			end
		end
	end
	-- Simpan juga tool di backpack yang berkaitan (CoiL)
	local backpack = player:FindFirstChild("Backpack")
	local coilNames = {"CoiL VIP", "CoiL 1", "CoiL 2"}
	local savedCoil = nil
	if backpack then
		for _, item in pairs(backpack:GetChildren()) do
			if item:IsA("Tool") then
				for _, n in ipairs(coilNames) do
					if item.Name == n then savedCoil = item; break end
				end
			end
		end
	end

	-- [PATCH P4] simpan musik sebelum ganti avatar, pulihkan setelahnya
	local snapBE = game:GetService("ServerStorage"):FindFirstChild("BoomboxSnapshot")
	if snapBE then pcall(function() snapBE:Fire(player, "save") end) end

	pcall(function() hum:ApplyDescription(desc) end)

	if snapBE then
		task.delay(0.35, function() pcall(function() snapBE:Fire(player, "restore") end) end)
	end

	-- Re-equip semua tool setelah ApplyDescription
	task.wait(0.2)
	hum:UnequipTools()
	task.wait(0.1)
	-- Re-equip CoiL dulu (ke karakter tanpa equip jika BoomBox aktif)
	local hasBoombox = equippedTool and equippedTool.Name == "BoomBox"
	local coilTool = nil
	for _, t in ipairs(equippedTools) do
		for _, n in ipairs(coilNames) do
			if t.Name == n then coilTool = t; break end
		end
	end
	if not coilTool then coilTool = savedCoil end
	if hasBoombox and coilTool then
		-- Pindah CoiL ke karakter (efek tetap aktif)
		task.wait(0.05)
		coilTool.Parent = char
	end
	-- [P80] tangan kosong: kalau sebelumnya tidak memegang tool, jangan equip apa pun
	if #equippedTools == 0 then
		return
	end

	-- [PATCH P4] utamakan CoiL di tangan; BoomBox tetap di punggung (holster)
	local pilih = coilTool or equippedTool
	if pilih and pilih.Name ~= "BoomBox" then
		task.wait(0.05)
		pcall(function() hum:EquipTool(pilih) end)
	elseif equippedTool then
		task.wait(0.05)
		pcall(function() hum:EquipTool(equippedTool) end)
	end
end
-- ── Load avatar asli ───────────────────────────────────────
local function loadOriginalDesc(player)
	if originalDesc[player.UserId] then return originalDesc[player.UserId] end
	local ok, desc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(player.UserId)
	end)
	if ok and desc then
		originalDesc[player.UserId] = desc
		return desc
	end
	return nil
end

-- ── Player join ────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	currentId[player.UserId] = 0 -- 0 = pakai avatar asli

	player.CharacterAdded:Connect(function(char)
		-- [FIX] Tandai SEBELUM task.wait(1) kalau avatar pengganti akan diterapkan.
		-- Alasan: karakter selalu spawn dengan avatar default dulu, lalu 1 detik
		-- kemudian ApplyDescription menukar Head. OverheadGui adalah ANAK Head,
		-- jadi ikut mati dan overhead harus dibangun ulang -> 2x build per respawn.
		-- Dengan penanda ini OverheadServer bisa menunggu avatar final dulu.
		local pakaiPengganti = currentId[player.UserId] ~= nil
			and currentId[player.UserId] ~= 0
		if pakaiPengganti then
			player:SetAttribute("AvatarSedangDiterapkan", true)
			-- Jaring pengaman: kalau ada error di bawah, penanda tetap dilepas
			-- supaya overhead tidak menggantung selamanya.
			task.delay(8, function()
				if player.Parent then
					player:SetAttribute("AvatarSedangDiterapkan", false)
				end
			end)
		end

		task.wait(1)

		-- Load avatar asli kalau belum ada
		loadOriginalDesc(player)

		-- Apply ulang avatar yang sedang dipakai
		if currentId[player.UserId] and currentId[player.UserId] ~= 0 then
			-- Pakai avatar pengganti
			local desc = currentDesc[player.UserId]
			if desc then
				applyDesc(player, desc)

			end
		end
		-- Kalau currentId == 0, biarkan avatar default Roblox

		if pakaiPengganti and player.Parent then
			player:SetAttribute("AvatarSedangDiterapkan", false)
		end
	end)
end)

-- ── Player leave ───────────────────────────────────────────
Players.PlayerRemoving:Connect(function(player)
	originalDesc[player.UserId] = nil
	currentDesc[player.UserId]  = nil
	currentId[player.UserId]    = nil
end)

-- ── Ganti avatar ───────────────────────────────────────────
ChangeRE.OnServerEvent:Connect(function(player, avatarId)
	if not avatarId then return end
	local ok, desc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(avatarId)
	end)
	if ok and desc then
		currentDesc[player.UserId] = desc
		currentId[player.UserId]   = avatarId
		applyDesc(player, desc)

	end
end)

-- ── Reset ke avatar asli ───────────────────────────────────
ResetRE.OnServerEvent:Connect(function(player)
	currentDesc[player.UserId] = nil
	currentId[player.UserId]   = 0
	local desc = loadOriginalDesc(player)
	if desc then
		applyDesc(player, desc)

	end
end)