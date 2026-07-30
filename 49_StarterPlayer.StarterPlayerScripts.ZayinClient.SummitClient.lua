local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ZR            = RS:WaitForChild("ZayinRemotes")
local SummitRemotes = ZR:WaitForChild("Summit")
local ReachedRE     = SummitRemotes:WaitForChild("Reached")
local GameConfig    = require(RS:WaitForChild("ZayinConfig"):WaitForChild("GameConfig"))

local debounce     = {}
local summitLoops  = {}
local isRespawning = false

-- ── Notif DITOLAK ─────────────────────────────────────────
local ditolakRE = ZR:WaitForChild("SummitDitolak", 10)
if ditolakRE then
-- [P24] handler notif DITOLAK lama dimatikan (diganti dRE versi teks besar)
end

-- ── Notif Summit utama ─────────────────────────────────────
-- [P22] notif lama dimatikan (diganti versi teks besar di bawah)
local function _showSummitNotif_LAMA(summitType, reward)
	local mainText = summitType == "Hard"
		and "✨ Assalamualaikum Summit ✨"
		or  "BERHASIL"
	local color = summitType == "Hard"
		and Color3.fromRGB(255, 215, 0)
		or  Color3.fromRGB(0, 255, 180)
	pcall(function()
		local old = playerGui:FindFirstChild("SummitNotif")
		if old then old:Destroy() end
		local g = Instance.new("ScreenGui")
		g.Name = "SummitNotif"
		g.ResetOnSpawn = false
		g.DisplayOrder = 15
		g.Parent = playerGui
		local f = Instance.new("Frame", g)
		f.Size = UDim2.new(0.28, 0, 0, 44)
		f.AnchorPoint = Vector2.new(0.5, 0)
		f.Position = UDim2.new(0.5, 0, -0.15, 0)
		f.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
		f.BackgroundTransparency = 0.15
		f.BorderSizePixel = 0
		Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
		local stroke = Instance.new("UIStroke", f)
		stroke.Color = color
		stroke.Thickness = 2
		local lbl = Instance.new("TextLabel", f)
		lbl.Size = UDim2.new(1, 0, 0.6, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = mainText
		lbl.TextColor3 = color
		lbl.TextScaled = true
		lbl.Font = Enum.Font.GothamBold
		local rewardLbl = Instance.new("TextLabel", f)
		rewardLbl.Size = UDim2.new(1, 0, 0.4, 0)
		rewardLbl.Position = UDim2.new(0, 0, 0.6, 0)
		rewardLbl.BackgroundTransparency = 1
		rewardLbl.Text = "+" .. reward .. " Summit"
		rewardLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
		rewardLbl.TextScaled = true
		rewardLbl.Font = Enum.Font.Gotham
		TweenService:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.45, 0)
		}):Play()
		task.wait(4)
		local tw = TweenService:Create(f, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, -0.15, 0)
		})
		tw:Play()
		tw.Completed:Connect(function() g:Destroy() end)
	end)
end

-- ── Popup avatar Hard (tampil ke semua) ───────────────────
local function showHardPopup(userId, displayName)
	task.spawn(function()
		pcall(function()
			local UIS = game:GetService("UserInputService")
			local TS  = game:GetService("TweenService")
			local M2  = UIS.TouchEnabled and not UIS.KeyboardEnabled
			local vp  = workspace.CurrentCamera.ViewportSize

			local old = playerGui:FindFirstChild("SummitHardPopup")
			if old then old:Destroy() end

			local W = math.clamp(vp.X * (M2 and 0.62 or 0.26), 230, 380)
			local H = W * 0.235

			local g = Instance.new("ScreenGui")
			g.Name = "SummitHardPopup"
			g.ResetOnSpawn = false
			g.IgnoreGuiInset = true
			g.DisplayOrder = 70
			g.Parent = playerGui

			local f = Instance.new("Frame", g)
			f.Size = UDim2.new(0, W, 0, H)
			f.AnchorPoint = Vector2.new(0.5, 0)
			f.Position = UDim2.new(0.5, 0, -0.2, 0)
			f.BackgroundColor3 = Color3.fromRGB(14, 12, 8)
			f.BackgroundTransparency = 0.04
			f.BorderSizePixel = 0
			Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)

			-- gradient emas halus di latar
			local grad = Instance.new("UIGradient", f)
			grad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 24, 10)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 12, 8)),
			})
			grad.Rotation = 90

			local stroke = Instance.new("UIStroke", f)
			stroke.Color = Color3.fromRGB(255, 200, 45)
			stroke.Thickness = 2
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

			-- garis aksen emas di atas
			local top = Instance.new("Frame", f)
			top.Size = UDim2.new(1, 0, 0, 3)
			top.Position = UDim2.new(0, 0, 0, 0)
			top.BackgroundColor3 = Color3.fromRGB(255, 210, 60)
			top.BorderSizePixel = 0
			local topc = Instance.new("UICorner", top); topc.CornerRadius = UDim.new(0, 3)

			-- avatar bulat berbingkai emas
			local ring = Instance.new("Frame", f)
			ring.Size = UDim2.new(0, H - 14, 0, H - 14)
			ring.Position = UDim2.new(0, 9, 0.5, -(H - 14) / 2)
			ring.BackgroundColor3 = Color3.fromRGB(255, 200, 45)
			Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)

			local avatar = Instance.new("ImageLabel", ring)
			avatar.Size = UDim2.new(1, -4, 1, -4)
			avatar.Position = UDim2.new(0, 2, 0, 2)
			avatar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150&h=150"
			Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

			local xText = H + 2
			local fontBig = math.clamp(H * 0.32, 13, 20)
			local fontSm  = math.clamp(H * 0.24, 10, 15)

			-- badge kecil "SUMMIT HARD"
			local badge = Instance.new("TextLabel", f)
			badge.Size = UDim2.new(1, -xText - 10, 0, fontSm + 2)
			badge.Position = UDim2.new(0, xText, 0, 8)
			badge.BackgroundTransparency = 1
			badge.Text = "🏔 SUMMIT HARD"
			badge.TextColor3 = Color3.fromRGB(255, 205, 50)
			badge.Font = Enum.Font.GothamBlack
			badge.TextSize = fontSm
			badge.TextXAlignment = Enum.TextXAlignment.Left

			-- nama pemain
			local nameLabel = Instance.new("TextLabel", f)
			nameLabel.Size = UDim2.new(1, -xText - 10, 0, fontBig + 2)
			nameLabel.Position = UDim2.new(0, xText, 0, 8 + fontSm + 2)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = displayName
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = fontBig
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
			local ns = Instance.new("UIStroke", nameLabel)
			ns.Color = Color3.new(0, 0, 0); ns.Thickness = 1.5

			-- deskripsi
			local desc = Instance.new("TextLabel", f)
			desc.Size = UDim2.new(1, -xText - 10, 0, fontSm + 2)
			desc.Position = UDim2.new(0, xText, 1, -(fontSm + 8))
			desc.BackgroundTransparency = 1
			desc.Text = "berhasil menaklukkan puncak tersulit!"
			desc.TextColor3 = Color3.fromRGB(200, 195, 175)
			desc.Font = Enum.Font.Gotham
			desc.TextSize = fontSm
			desc.TextXAlignment = Enum.TextXAlignment.Left
			desc.TextTruncate = Enum.TextTruncate.AtEnd

			-- animasi masuk (turun) lalu keluar (naik)
			TS:Create(f, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, 0, 0, 12)
			}):Play()

			-- kilau garis atas
			task.spawn(function()
				local tg = Instance.new("UIGradient", top)
				tg.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 120)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 220)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 120)),
				})
				for _ = 1, 3 do
					tg.Offset = Vector2.new(-1, 0)
					TS:Create(tg, TweenInfo.new(0.8), {Offset = Vector2.new(1, 0)}):Play()
					task.wait(0.9)
				end
			end)

			task.wait(5)
			local tw = TS:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, -0.2, 0)
			})
			tw:Play()
			tw.Completed:Connect(function() g:Destroy() end)
		end)
	end)
end

-- ── SummitBerhasil — FIX: satu handler saja ───────────────
task.spawn(function()
	local berhasilRE = ZR:WaitForChild("SummitBerhasil", 30)
	if not berhasilRE then
		warn("[SummitClient] SummitBerhasil tidak ditemukan!")
		return
	end
	print("[SummitClient] SummitBerhasil connected!")
	berhasilRE.OnClientEvent:Connect(function(userId, displayName, summitType, reward)
		-- Notif utama hanya untuk player sendiri
		if userId == player.UserId then
			task.spawn(showSummitNotif, summitType, reward)
		end
		-- Popup Hard tampil ke semua player
		if summitType == "Hard" then
			showHardPopup(userId, displayName)
		end
	end)
end)

-- ── Clear summit loops ─────────────────────────────────────
local function clearSummitLoops()
	for _, loop in pairs(summitLoops) do
		if loop and loop.Connected then loop:Disconnect() end
	end
	summitLoops = {}
end

-- ── Setup Summit proximity ─────────────────────────────────
local function setupSummitParts()
	clearSummitLoops()
	debounce     = {}
	isRespawning = true

	local zw = workspace:WaitForChild("ZayinWorkspace", 10)
	if not zw then return end
	local summitFolder = zw:FindFirstChild("Summit")
	if not summitFolder then return end

	local easyPart = summitFolder:FindFirstChild("SummitEasy")
	local hardPart = summitFolder:FindFirstChild("SummitHard")

	task.spawn(function()
		task.wait(0.2)
		isRespawning = false
		print("[SummitClient] Summit detection aktif")
	end)

	local loop = RunService.Heartbeat:Connect(function()
		if isRespawning then return end
		local char = player.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local pos = hrp.Position

		if easyPart and not debounce["Easy"] then
			local rel = pos - easyPart.Position
			if math.abs(rel.X) <= easyPart.Size.X/2
			and math.abs(rel.Y) <= easyPart.Size.Y/2
			and math.abs(rel.Z) <= easyPart.Size.Z/2 then
				debounce["Easy"] = true
				task.spawn(function()
					ReachedRE:FireServer("Easy")
					task.wait(1)
					debounce["Easy"] = nil
				end)
			end
		end

		if hardPart and not debounce["Hard"] then
			local rel = pos - hardPart.Position
			if math.abs(rel.X) <= hardPart.Size.X/2
			and math.abs(rel.Y) <= hardPart.Size.Y/2
			and math.abs(rel.Z) <= hardPart.Size.Z/2 then
				debounce["Hard"] = true
				task.spawn(function()
					ReachedRE:FireServer("Hard")
					task.wait(1)
					debounce["Hard"] = nil
				end)
			end
		end
	end)

	table.insert(summitLoops, loop)
end

-- ── Player events ──────────────────────────────────────────
player.CharacterAdded:Connect(function()
	task.wait(0.3)
	setupSummitParts()
end)

if player.Character then
	task.wait(0.3)
	setupSummitParts()
end

print("[SummitClient] Ready!")

-- [P10] deteksi Touched: pemicu instan begitu kaki menyentuh part Summit
task.spawn(function()
	local Players    = game:GetService("Players")
	local RS         = game:GetService("ReplicatedStorage")
	local plr        = Players.LocalPlayer
	local ZR2        = RS:WaitForChild("ZayinRemotes", 20)
	local SR2        = ZR2 and ZR2:WaitForChild("Summit", 20)
	local Reached2   = SR2 and SR2:WaitForChild("Reached", 20)
	if not Reached2 then return end

	local zw = workspace:WaitForChild("ZayinWorkspace", 20)
	local sf = zw and zw:WaitForChild("Summit", 20)
	if not sf then return end

	local cd = {}
	local function pasangTouch(part, tipe)
		if not (part and part:IsA("BasePart")) then return end
		part.CanTouch = true
		part.Touched:Connect(function(hit)
			local ch = hit and hit.Parent
			if not ch or Players:GetPlayerFromCharacter(ch) ~= plr then return end
			local now = os.clock()
			if cd[tipe] and now - cd[tipe] < 1 then return end
			cd[tipe] = now
			Reached2:FireServer(tipe)
		end)
	end

	pasangTouch(sf:FindFirstChild("SummitEasy"), "Easy")
	pasangTouch(sf:FindFirstChild("SummitHard"), "Hard")
end)

-- P11 TOUCHED — pemicu instan saat menyentuh part Summit
task.spawn(function()
	local Players = game:GetService("Players")
	local RS      = game:GetService("ReplicatedStorage")
	local plr     = Players.LocalPlayer
	local ZR3     = RS:WaitForChild("ZayinRemotes", 30)
	local SR3     = ZR3:WaitForChild("Summit", 30)
	local RE3     = SR3:WaitForChild("Reached", 30)
	local zw3     = workspace:WaitForChild("ZayinWorkspace", 30)
	local sf3     = zw3:WaitForChild("Summit", 30)

	local cd = {}
	local function pasang(part, tipe)
		if not (part and part:IsA("BasePart")) then
			return
		end
		part.CanTouch = true
		part.Touched:Connect(function(hit)
			local ch = hit and hit.Parent
			if not ch then return end
			if Players:GetPlayerFromCharacter(ch) ~= plr then return end
			local now = os.clock()
			if cd[tipe] and now - cd[tipe] < 1 then return end
			cd[tipe] = now
			RE3:FireServer(tipe)
		end)
	end

	pasang(sf3:WaitForChild("SummitEasy", 30), "Easy")
	pasang(sf3:WaitForChild("SummitHard", 30), "Hard")
end)

-- [P14] pendengar notif: tampilkan pesan alasan dari server
task.spawn(function()
	local Players = game:GetService("Players")
	local RS      = game:GetService("ReplicatedStorage")
	local plr     = Players.LocalPlayer
	local gui     = plr:WaitForChild("PlayerGui")
	local ZR4     = RS:WaitForChild("ZayinRemotes", 30)

	local function tampil(pesan, warna)
		-- [P20] gaya teks besar bergaris tepi, tanpa kotak
		local old = gui:FindFirstChild("ZayinPesanNotif")
		if old then old:Destroy() end

		local UIS = game:GetService("UserInputService")
		local TS  = game:GetService("TweenService")
		local M2  = UIS.TouchEnabled and not UIS.KeyboardEnabled
		local vp  = workspace.CurrentCamera.ViewportSize

		local judul, sub = pesan, nil
		local pos = pesan:find("|", 1, true)
		if pos then
			judul = pesan:sub(1, pos - 1)
			sub   = pesan:sub(pos + 1)
		end

		local g = Instance.new("ScreenGui")
		g.Name = "ZayinPesanNotif"; g.ResetOnSpawn = false
		g.IgnoreGuiInset = true; g.DisplayOrder = 90; g.Parent = gui

		local holder = Instance.new("Frame")
		holder.Size = UDim2.new(1, 0, 0, 0)
		holder.AutomaticSize = Enum.AutomaticSize.Y
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = UDim2.new(0.5, 0, 0.32, 0)
		holder.BackgroundTransparency = 1
		holder.Parent = g

		local list = Instance.new("UIListLayout", holder)
		list.FillDirection = Enum.FillDirection.Vertical
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = UDim.new(0, M2 and 2 or 6)

		local skalaBesar = math.clamp(vp.X / (M2 and 20 or 26), 26, 46)
		local skalaKecil = math.clamp(vp.X / (M2 and 32 or 44), 15, 24)

		local function teks(isi, ukuran, urut)
			local t = Instance.new("TextLabel")
			t.Size = UDim2.new(1, 0, 0, ukuran + 8)
			t.LayoutOrder = urut
			t.BackgroundTransparency = 1
			t.Text = isi
			t.TextColor3 = warna or Color3.fromRGB(255, 200, 40)
			t.Font = Enum.Font.LuckiestGuy
			t.TextSize = ukuran
			t.TextStrokeColor3 = Color3.new(0, 0, 0)
			t.TextStrokeTransparency = 0
			t.TextScaled = false
			t.Parent = holder
			local st = Instance.new("UIStroke", t)
			st.Color = Color3.new(0, 0, 0)
			st.Thickness = math.max(1.5, ukuran * 0.06)
			st.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
			return t, st
		end

		local t1, s1 = teks(judul, skalaBesar, 1)
		local t2, s2 = nil, nil
		if sub then t2, s2 = teks(sub, skalaKecil, 2) end

		-- animasi: muncul membesar, lalu memudar
		local sc0 = Instance.new("UIScale", holder)
		sc0.Scale = 0.82
		t1.TextTransparency = 1; s1.Transparency = 1
		if t2 then t2.TextTransparency = 1; s2.Transparency = 1 end

		TS:Create(sc0, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		TS:Create(t1, TweenInfo.new(0.1), {TextTransparency = 0}):Play()
		TS:Create(s1, TweenInfo.new(0.1), {Transparency = 0}):Play()
		if t2 then
			TS:Create(t2, TweenInfo.new(0.1), {TextTransparency = 0}):Play()
			TS:Create(s2, TweenInfo.new(0.1), {Transparency = 0}):Play()
		end

		task.delay(1.8, function()
			if not g or not g.Parent then return end
			local ti = TweenInfo.new(0.22)
			TS:Create(t1, ti, {TextTransparency = 1}):Play()
			TS:Create(s1, ti, {Transparency = 1}):Play()
			if t2 then
				TS:Create(t2, ti, {TextTransparency = 1}):Play()
				TS:Create(s2, ti, {Transparency = 1}):Play()
			end
			TS:Create(sc0, ti, {Scale = 1.12}):Play()
			task.wait(0.4)
			if g then g:Destroy() end
		end)
	end
	_G.ZayinTampilNotif = tampil -- [P26] tampil global (dipakai notif summit)

	local dRE = ZR4:WaitForChild("SummitDitolak", 30)
	if dRE then
		dRE.OnClientEvent:Connect(function(_, pesan)
			tampil(pesan or "Summit ditolak.", Color3.fromRGB(255, 120, 90))
		end)
	end

	local nf = ZR4:WaitForChild("Notif", 30)
	local showRE = nf and nf:WaitForChild("Show", 30)
	if showRE then
		showRE.OnClientEvent:Connect(function(data)
			local pesan = type(data) == "table" and data.message or tostring(data)
			-- [P17] warna: hijau untuk sukses, oranye untuk peringatan
			local jenis = type(data) == "table" and data.type or "warning"
			local warna = (jenis == "success") and Color3.fromRGB(70, 220, 130) or Color3.fromRGB(255, 200, 60)
			tampil(pesan, warna)
		end)
	end
end)

---- [P24] blok notif P21 dihapus (duplikat)

-- [P22] summit notif baru: Easy & Hard sama-sama tampil, warna berbeda
task.spawn(function()
	for _ = 1, 80 do
		if _G.ZayinTampilNotif then break end
		task.wait(0.1)
	end
	showSummitNotif = function(summitType, reward)
		-- [P26] notif summit tunggu tampil siap (maks 3 detik)
		local f = _G.ZayinTampilNotif
		if not f then
			for _ = 1, 30 do task.wait(0.1); f = _G.ZayinTampilNotif; if f then break end end
		end
		if not f then return end
		if summitType == "Hard" then
			f("SUMMIT|+" .. tostring(reward or 0), Color3.fromRGB(255, 170, 40))
		else
			f("SUMMIT|+" .. tostring(reward or 0), Color3.fromRGB(80, 235, 140))
		end
	end
end)