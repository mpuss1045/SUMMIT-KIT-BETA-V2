-- PlayerInfoPanel — klik pemain -> panel identitas + tombol aksi
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")

local plr = Players.LocalPlayer
local gui = plr:WaitForChild("PlayerGui")
local cam = workspace.CurrentCamera

local ZR = RS:WaitForChild("ZayinRemotes", 30)
local getInfo = ZR:WaitForChild("GetPlayerInfo", 30)

local M = UIS.TouchEnabled and not UIS.KeyboardEnabled

local function mk(kelas, props, induk)
	local o = Instance.new(kelas)
	for k, v in pairs(props) do o[k] = v end
	if induk then o.Parent = induk end
	return o
end
local function sudut(o, r) mk("UICorner", {CornerRadius = UDim.new(0, r)}, o) end
local function garis(o, warna, tebal)
	mk("UIStroke", {Color = warna, Thickness = tebal or 1.5}, o)
end

local panelAktif = nil

-- [P80] pesan kecil di tengah atas
local function pesanKecil(teks)
	local old = gui:FindFirstChild("ZayinPesanKecil")
	if old then old:Destroy() end
	local g = Instance.new("ScreenGui")
	g.Name = "ZayinPesanKecil"; g.ResetOnSpawn = false
	g.IgnoreGuiInset = true; g.DisplayOrder = 80; g.Parent = gui
	local f = Instance.new("Frame")
	f.Size = UDim2.fromOffset(math.clamp(#teks * 7 + 40, 180, 340), 34)
	f.AnchorPoint = Vector2.new(0.5, 0)
	f.Position = UDim2.new(0.5, 0, 0, 70)
	f.BackgroundColor3 = Color3.fromRGB(14, 18, 26)
	f.BackgroundTransparency = 0.15
	f.BorderSizePixel = 0; f.Parent = g
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
	local st = Instance.new("UIStroke", f)
	st.Color = Color3.fromRGB(0, 200, 230); st.Thickness = 1.5
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1
	t.Text = teks; t.TextColor3 = Color3.fromRGB(225, 238, 250)
	t.Font = Enum.Font.GothamMedium; t.TextSize = 12; t.Parent = f
	task.delay(2.5, function() if g then g:Destroy() end end)
end
local sedangSync = nil -- [P80] state sync: siapa yang sedang di-sync

local function tutupPanel()
	if not panelAktif then return end
	local p = panelAktif
	panelAktif = nil
	local sk = p:FindFirstChildOfClass("Frame")
	if sk then
		local us = sk:FindFirstChildOfClass("UIScale")
		if us then TS:Create(us, TweenInfo.new(0.15), {Scale = 0.9}):Play() end
	end
	task.delay(0.16, function() if p then p:Destroy() end end)
end

local function bukaPanel(target)
    if panelAktif then tutupPanel() end

	local ok, info = pcall(function() return getInfo:InvokeServer(target.UserId) end)
	if not (ok and info) then return end

	local vp = cam.ViewportSize
	local W = math.clamp(vp.X * (M and 0.68 or 0.19), 250, 300)
	local H = M and 372 or 396

	local sg = mk("ScreenGui", {
		Name = "ZayinPlayerInfo", ResetOnSpawn = false,
		IgnoreGuiInset = true, DisplayOrder = 65,
	}, gui)
	panelAktif = sg

	local bg = mk("TextButton", {
		Size = UDim2.fromScale(1,1), BackgroundColor3 = Color3.new(0,0,0),
		BackgroundTransparency = 0.55, Text = "", BorderSizePixel = 0, ZIndex = 65,
	}, sg)

	local card = mk("Frame", {
		Size = UDim2.fromOffset(W, H),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(13, 16, 24),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0, ZIndex = 66,
	}, sg)
	sudut(card, 16); garis(card, Color3.fromRGB(0, 190, 220), 2)
	local skala = mk("UIScale", {Scale = 0.88}, card)

	-- aksen atas
	local aks = mk("Frame", {
		Size = UDim2.new(1, -40, 0, 4), Position = UDim2.new(0, 20, 0, 0),
		BackgroundColor3 = Color3.fromRGB(0, 210, 240), BorderSizePixel = 0, ZIndex = 67,
	}, card)
	sudut(aks, 4)

	-- avatar
	local avSz = M and 54 or 60
	local ring = mk("Frame", {
		Size = UDim2.fromOffset(avSz, avSz),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, M and 16 or 20),
		BackgroundColor3 = info.roleColor or Color3.fromRGB(0, 200, 230),
		BorderSizePixel = 0, ZIndex = 67,
	}, card)
	sudut(ring, 100)
	local av = mk("ImageLabel", {
		Size = UDim2.new(1, -5, 1, -5), Position = UDim2.new(0, 2.5, 0, 2.5),
		BackgroundColor3 = Color3.fromRGB(24, 28, 38), BorderSizePixel = 0,
		Image = "rbxthumb://type=AvatarHeadShot&id="..info.userId.."&w=180&h=180",
		ZIndex = 68,
	}, ring)
	sudut(av, 100)

	local yT = (M and 16 or 20) + avSz + 8

	mk("TextLabel", {
		Size = UDim2.new(1, -24, 0, M and 20 or 23), Position = UDim2.new(0, 12, 0, yT),
		BackgroundTransparency = 1, Text = info.nama,
		TextColor3 = Color3.fromRGB(240, 248, 255), Font = Enum.Font.GothamBold,
		TextSize = M and 14 or 15, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 67,
	}, card)

	mk("TextLabel", {
		Size = UDim2.new(1, -24, 0, M and 14 or 16), Position = UDim2.new(0, 12, 0, yT + (M and 20 or 23)),
		BackgroundTransparency = 1, Text = "@"..info.username,
		TextColor3 = Color3.fromRGB(130, 145, 165), Font = Enum.Font.Gotham,
		TextSize = M and 10 or 10, ZIndex = 67,
	}, card)

	-- badge role
	local badge = mk("Frame", {
		Size = UDim2.fromOffset(M and 78 or 86, M and 18 or 20),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, yT + (M and 38 or 43)),
		BackgroundColor3 = Color3.fromRGB(20, 26, 36), BorderSizePixel = 0, ZIndex = 67,
	}, card)
	sudut(badge, 10); garis(badge, info.roleColor or Color3.fromRGB(0,200,230), 1.5)
	mk("TextLabel", {
		Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Text = info.role,
		TextColor3 = info.roleColor or Color3.fromRGB(0,210,240),
		Font = Enum.Font.GothamBold, TextSize = M and 10 or 11, ZIndex = 68,
	}, badge)

	-- daftar data
	local dataY = yT + (M and 58 or 64)
	local baris = {
		{"Usia akun",  info.usiaAkun.." hari"},
		{"Jenis avatar", info.jenis},
		{"Di server ini", info.sesi},
		{"Playtime", info.playtime},
		{"Summit", tostring(info.summit)},
		{"SpeedRun", tostring(info.speedrun)},
		{"Donasi", info.donasi.." R$"},
	}
	local bh = M and 19 or 21
	for i, b in ipairs(baris) do
		local y = dataY + (i-1) * (bh + 3)
		local row = mk("Frame", {
			Size = UDim2.new(1, -24, 0, bh), Position = UDim2.new(0, 12, 0, y),
			BackgroundColor3 = Color3.fromRGB(18, 22, 31),
			BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 67,
		}, card)
		sudut(row, 8)
		mk("TextLabel", {
			Size = UDim2.new(0.5, -10, 1, 0), Position = UDim2.new(0, 10, 0, 0),
			BackgroundTransparency = 1, Text = b[1],
			TextColor3 = Color3.fromRGB(135, 148, 168), Font = Enum.Font.Gotham,
			TextSize = M and 9 or 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 68,
		}, row)
		mk("TextLabel", {
			Size = UDim2.new(0.5, -10, 1, 0), Position = UDim2.new(0.5, 0, 0, 0),
			BackgroundTransparency = 1, Text = b[2],
			TextColor3 = Color3.fromRGB(225, 235, 248), Font = Enum.Font.GothamBold,
			TextSize = M and 10 or 11, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 68,
		}, row)
	end

	-- tombol aksi (2x2)
	local btnY = dataY + #baris * (bh + 3) + 10
	local bw = (W - 30) / 2
	local bh2 = M and 26 or 29
	local aksi = {
		{"Teman",  Color3.fromRGB(60,150,255), function()
			-- [P80] cek dulu: sudah berteman?
			local sudah = false
			pcall(function() sudah = plr:IsFriendsWith(target.UserId) end)
			if sudah then
				pesanKecil("Kamu sudah berteman dengan "..target.DisplayName)
				return
			end
			pcall(function()
				game:GetService("StarterGui"):SetCore("PromptSendFriendRequest", target)
			end)
		end},
		{"Carry",   Color3.fromRGB(255,170,50), function()
			local re = RS:FindFirstChild("CarryRemote")
			print("[CARRY] remote:", re and "ADA" or "TIDAK ADA", "| target:", target.Name, target.UserId)
			if re then
				re:FireServer("Request", {targetId = target.UserId})
				print("[CARRY] permintaan dikirim")
			end
		end},
		{"Avatar",  Color3.fromRGB(180,110,255), function()
			local av2 = ZR:FindFirstChild("Avatar")
			local ch2 = av2 and av2:FindFirstChild("Change")
			if ch2 then ch2:FireServer(target.UserId) end
		end},
		{(sedangSync == target) and "Stop Sync" or "Sync", Color3.fromRGB(70,220,140), function()
			-- [P80] toggle sync
			local sf = RS:FindFirstChild("Syncing")
			if not sf then return end
			if sedangSync == target then
				local ue = sf:FindFirstChild("UnSync")
				if ue then ue:FireServer() end
				sedangSync = nil
				pesanKecil("Sync dihentikan")
			else
				local se = sf:FindFirstChild("Sync")
				if se then se:FireServer(target) end
				sedangSync = target
			end
		end},
	}

	for i, a in ipairs(aksi) do
		local kol = (i - 1) % 2
		local bar = math.floor((i - 1) / 2)
		local btn = mk("TextButton", {
			Size = UDim2.fromOffset(bw, bh2),
			Position = UDim2.new(0, 12 + kol * (bw + 6), 0, btnY + bar * (bh2 + 6)),
			BackgroundColor3 = Color3.fromRGB(20, 25, 35),
			BorderSizePixel = 0, Text = a[1], TextColor3 = Color3.fromRGB(240, 246, 255),
			Font = Enum.Font.GothamSemibold, TextSize = M and 11 or 12,
			AutoButtonColor = false, ZIndex = 68,
		}, card)
		sudut(btn, 10); garis(btn, a[2], 1.5)
		btn.MouseEnter:Connect(function()
			TS:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(30, 38, 52)}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TS:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(20, 25, 35)}):Play()
		end)
		btn.MouseButton1Click:Connect(function()
			local us = mk("UIScale", {Scale = 1}, btn)
			TS:Create(us, TweenInfo.new(0.08), {Scale = 0.93}):Play()
			task.delay(0.09, function()
				TS:Create(us, TweenInfo.new(0.1), {Scale = 1}):Play()
				task.delay(0.12, function() if us then us:Destroy() end end)
			end)
			pcall(a[3])
			task.delay(0.2, tutupPanel)
		end)
	end

	-- tombol tutup
	local tutup = mk("TextButton", {
		Size = UDim2.fromOffset(M and 46 or 52, M and 20 or 23),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		BackgroundColor3 = Color3.fromRGB(40, 12, 12),
		Text = "Tutup", TextColor3 = Color3.fromRGB(255, 95, 95),
		Font = Enum.Font.GothamBold, TextSize = M and 9 or 10,
		BorderSizePixel = 0, ZIndex = 69,
	}, card)
	sudut(tutup, 8)
	tutup.MouseButton1Click:Connect(tutupPanel)
	bg.MouseButton1Click:Connect(tutupPanel)

	TS:Create(skala, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

-- ── Deteksi klik pemain ──────────────────────────────────
local rayP = RaycastParams.new()
rayP.FilterType = Enum.RaycastFilterType.Exclude

local function segarkanFilter()
	local daftar = {}
	if plr.Character then table.insert(daftar, plr.Character) end
	rayP.FilterDescendantsInstances = daftar
end
segarkanFilter()
plr.CharacterAdded:Connect(function() task.wait(0.5); segarkanFilter() end)

local function cariPemain(posLayar)
	-- 1) raycast biasa
	local ray = cam:ViewportPointToRay(posLayar.X, posLayar.Y)
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 150, rayP)
	if hit then
		local ch = hit.Instance:FindFirstAncestorOfClass("Model")
		local target = ch and Players:GetPlayerFromCharacter(ch)
		if target and target ~= plr then return target end
	end

	-- [P83] cadangan proyeksi: tangkap pemain yang digendong / menempel
	local terdekat, jarakTerdekat = nil, 90
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= plr and other.Character then
			local hrp = other.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local titik, terlihat = cam:WorldToViewportPoint(hrp.Position)
				if terlihat and titik.Z > 0 then
					local d = (Vector2.new(titik.X, titik.Y) - Vector2.new(posLayar.X, posLayar.Y)).Magnitude
					local jarakDunia = (hrp.Position - cam.CFrame.Position).Magnitude
					if d < jarakTerdekat and jarakDunia <= 150 then
						terdekat, jarakTerdekat = other, d
					end
				end
			end
		end
	end
	return terdekat
end

if M then
	UIS.TouchTapInWorld:Connect(function(pos, prosesUI)
		if prosesUI or panelAktif then return end
		local t = cariPemain(pos)
		if t then bukaPanel(t) end
	end)
else
	UIS.InputBegan:Connect(function(inp, prosesUI)
		if prosesUI or panelAktif then return end
		if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local m = UIS:GetMouseLocation()
		local t = cariPemain(m)
		if t then bukaPanel(t) end
	end)
end

print("[PlayerInfoPanel] Ready!")

-- [P82] balasan carry: tampilkan alasan kalau permintaan ditolak server
task.spawn(function()
	local re = RS:WaitForChild("CarryRemote", 30)
	if not re then return end
	re.OnClientEvent:Connect(function(aksi, data)
		if aksi == "TooFar" then
			pesanKecil("Terlalu jauh — dekati pemainnya dulu")
		elseif aksi == "Busy" then
			pesanKecil("Pemain sedang sibuk / sudah digendong")
		elseif aksi == "Limit" then
			pesanKecil("Batas gendong tercapai")
		elseif aksi == "Declined" then
			pesanKecil("Permintaan gendong ditolak")
		elseif aksi == "Failed" then
			pesanKecil("Gagal menggendong")
		end
	end)
end)