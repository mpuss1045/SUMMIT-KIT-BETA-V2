-- ============================================================
-- LastToolTracker (RAMPING)
-- Tugasnya cuma satu: mencatat CoiL terakhir yang MASUK KE KARAKTER
-- (dipegang pemain), lalu menyediakannya lewat RemoteFunction
-- GetLastCoil. Satu-satunya konsumen = AutoEquipCoil
-- (StarterCharacterScripts) yang memakainya untuk equip ulang CoiL
-- yang benar setelah respawn. JANGAN DIHAPUS.
--
-- [BERSIH Jul 30] 5 remote yatim dibuang (nol konsumen di seluruh
-- codebase, sudah diverifikasi lewat grep): SetLastCoil, SetLastTool,
-- GetLastTool, SetBoomboxState, GetBoomboxState. State boombox
-- ditangani BoomboxRespawnFix + BoomboxSnapshot, bukan di sini.
-- Ikut hilang: tabel toolState & boomboxState (tak ada lagi pembaca)
-- dan helper getOrMakeRE (tak ada lagi RemoteEvent yang dibuat).
-- ============================================================
local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local coilState = {}

local function getOrMakeRF(parent, name)
	local r = parent:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteFunction")
		r.Name = name; r.Parent = parent
		warn("[LastToolTracker] Dibuat otomatis: " .. name)
	end
	return r
end

local ltd = RS:WaitForChild("LastToolData", 10)
if not ltd then
	warn("[LastToolTracker] LastToolData tidak ditemukan!")
	return
end

-- CoiL State — SATU-SATUNYA remote yang hidup
local getCoil = getOrMakeRF(ltd, "GetLastCoil")
getCoil.OnServerInvoke = function(p)
	return coilState[p.UserId] or ""
end

-- Cleanup
-- [FIX] reset saat leave
Players.PlayerRemoving:Connect(function(p)
	coilState[p.UserId] = nil
end)

-- [PATCH P5] dua slot: coil (nama persis) + boombox, agar keduanya bisa dipulihkan
local function catat(p, nama)
	if type(nama) ~= "string" or nama == "" then return end
	if nama:lower():find("coil") then
		coilState[p.UserId] = nama          -- "CoiL 1" / "CoiL 2" / "CoiL VIP"
	end
end

local function watchChar(p, char)
	char.ChildAdded:Connect(function(c)
		if c:IsA("Tool") then catat(p, c.Name) end
	end)
	for _, c in ipairs(char:GetChildren()) do
		if c:IsA("Tool") then catat(p, c.Name) end
	end
	-- [FIX] jangan catat dari backpack: pemberian otomatis GamepassService
	-- bukan pilihan pemain, jadi tidak boleh dianggap 'tool terakhir'.
end
local function watchPlayer(p)
	if p.Character then watchChar(p, p.Character) end
	p.CharacterAdded:Connect(function(char) watchChar(p, char) end)
end
Players.PlayerAdded:Connect(watchPlayer)
for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end

print("[LastToolTracker] Ready! Pencatat tool otomatis aktif")