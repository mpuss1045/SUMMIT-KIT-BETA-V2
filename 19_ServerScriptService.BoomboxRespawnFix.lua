-- BoomboxRespawnFix v4 — [P8] jeda dipersingkat
local Players = game:GetService("Players")
local SS      = game:GetService("ServerStorage")

local terakhir = {}

-- [FIX4] jembatan: biar BoomboxServerScript bisa baca snapshot 'terakhir' sebagai fallback
local SS_bridge = game:GetService("ServerStorage")
local getTerakhirBF = SS_bridge:FindFirstChild("GetTerakhirSnapshot")
if not getTerakhirBF then
	getTerakhirBF = Instance.new("BindableFunction")
	getTerakhirBF.Name = "GetTerakhirSnapshot"
	getTerakhirBF.Parent = SS_bridge
end
getTerakhirBF.OnInvoke = function(userId)
	return terakhir[userId]
end

task.spawn(function()
	while true do
		task.wait(0.5)
		for _, p in ipairs(Players:GetPlayers()) do
			local char = p.Character
			if char then
				local holster = char:FindFirstChild("Holster")
				local handle  = char:FindFirstChild("BoomBox")
				handle = handle and handle:FindFirstChild("Handle")
				local s = (holster and holster:FindFirstChild("BoomboxSound"))
					or (handle and handle:FindFirstChild("BoomboxSound"))
				if s and s.IsPlaying and s.SoundId ~= "" then
					terakhir[p.UserId] = {
						songId  = tonumber(s.SoundId:match("%d+") or "0") or 0,
						timePos = s.TimePosition,
						volume  = s.Volume,
						eq      = tostring(s:GetAttribute("EQName") or "Flat"),
						playing = true,
					}
				elseif not s then
					-- [FIX2] clear snapshot HANYA kalau karakter stabil (bukan transisi avatar/respawn)
					-- Karakter stabil = punya HumanoidRootPart, torso, dan Humanoid hidup.
					-- Saat ganti avatar (ApplyDescription) atau baru respawn, bagian ini
					-- belum lengkap → JANGAN clear (biar restore avatar/respawn tetap jalan).
					local hum = char:FindFirstChildOfClass("Humanoid")
					local stabil = char:FindFirstChild("HumanoidRootPart")
						and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"))
						and hum and hum.Health > 0
					if stabil then
						terakhir[p.UserId] = nil
					end
				end
			end
		end
	end
end)

local function pasang(p)
	p.CharacterAdded:Connect(function(char)
		local data = terakhir[p.UserId]
		if not (data and data.songId > 0) then return end
		terakhir[p.UserId] = nil

		char:WaitForChild("HumanoidRootPart", 10)
		for _ = 1, 15 do
			if char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") then break end
			task.wait(0.2)
		end
		local bp = p:FindFirstChildOfClass("Backpack")
		for _ = 1, 20 do
			if bp and bp:FindFirstChild("BoomBox") then break end
			task.wait(0.2)
			bp = p:FindFirstChildOfClass("Backpack")
		end

		local snapBE = SS:FindFirstChild("BoomboxSnapshot")
		if snapBE then snapBE:Fire(p, "restoreWith", data) end
	end)
end

Players.PlayerAdded:Connect(pasang)
for _, p in ipairs(Players:GetPlayers()) do pasang(p) end