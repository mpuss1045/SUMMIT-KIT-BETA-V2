-- ============================================
-- ZayinDonationClient
-- ============================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui", 10)

local DonationFolder = ReplicatedStorage:WaitForChild("DonationSystem", 15)
if not DonationFolder then warn("[DonationClient] DonationSystem tidak ditemukan!") return end

local PromptEvent   = DonationFolder:WaitForChild("DonationPrompt",   10)
local NotifyEvent   = DonationFolder:WaitForChild("DonationNotify",   10)
local MsgEvent      = DonationFolder:WaitForChild("DonationMessage",  10)
local UpdateUIEvent = DonationFolder:WaitForChild("DonationUpdateUI", 10)

local SDC = require(ReplicatedStorage:WaitForChild("ZayinConfig", 10):WaitForChild("ShopDonationConfig", 10))
local Config = SDC.Donation
local zw        = workspace:WaitForChild("ZayinWorkspace", 10)
local donFolder = zw and zw:WaitForChild("Donation", 10)
local papan     = donFolder and donFolder:WaitForChild("PapanDonation", 10)

local C = {
	bg      = Color3.fromRGB(6,   10,  20),
	bg3     = Color3.fromRGB(15,  22,  42),
	gold    = Color3.fromRGB(255, 215,   0),
	silver  = Color3.fromRGB(200, 215, 230),
	bronze  = Color3.fromRGB(205, 127,  50),
	white   = Color3.new(1, 1, 1),
	rowbg   = Color3.fromRGB(8,   13,  26),
	donGold = Color3.fromRGB(255, 200,  40),
	cyan    = Color3.fromRGB(0,  210, 255),
}
local TIER_COLORS = {
	C.gold, C.silver, C.bronze, C.cyan,
	Color3.fromRGB(160,80,255), Color3.fromRGB(80,230,170),
	Color3.fromRGB(255,100,100), Color3.fromRGB(100,150,255),
	Color3.fromRGB(255,150,0), Color3.fromRGB(200,100,255),
}
local MEDAL_COLORS = {C.gold, C.silver, C.bronze}
local MEDALS = {"🥇", "🥈", "🥉"}

local function make(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props) do obj[k] = v end
	if parent then obj.Parent = parent end
	return obj
end
local function addCorner(r, p) make("UICorner", {CornerRadius = UDim.new(0, r)}, p) end
local function addStroke(c, t, p) make("UIStroke", {Color = c, Thickness = t}, p) end
local function addTextStroke(p) make("UIStroke", {Color = Color3.new(0,0,0), Thickness = 1.5, Transparency = 0.2}, p) end

local donationGui = nil
local cachedTopList = {}

local function closeDonationUI()
	if not donationGui then return end
	local mf = donationGui:FindFirstChild("MainFrame")
	if mf then
		TweenService:Create(mf, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0)
		}):Play()
	end
	task.wait(0.25)
	if donationGui then donationGui:Destroy() end
	donationGui = nil
end

local function buildTopContent(scroll)
	for _, child in pairs(scroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
	end

	if #cachedTopList == 0 then
		make("TextLabel", {
			Size = UDim2.new(1,0,0,50),
			BackgroundTransparency = 1,
			Text = "Belum ada donasi 😢",
			TextColor3 = C.silver, Font = Enum.Font.Gotham, TextSize = 14
		}, scroll)
		return
	end

	for rank, entry in ipairs(cachedTopList) do
		local strokeColor = MEDAL_COLORS[rank] or C.cyan
		local row = make("Frame", {
			LayoutOrder = rank,
			Size = UDim2.new(1,-8,0, rank <= 3 and 60 or 50),
			BackgroundColor3 = C.rowbg, BackgroundTransparency = 0.1,
			BorderSizePixel = 0
		}, scroll)
		addCorner(10, row)
		addStroke(strokeColor, rank <= 3 and 1.8 or 1.2, row)

		local medal = make("Frame", {
			Size = UDim2.fromOffset(36,36),
			Position = UDim2.new(0,6,0.5,-18),
			BackgroundColor3 = C.bg3, BorderSizePixel = 0
		}, row)
		addCorner(8, medal)
		local ml = make("TextLabel", {
			Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
			Text = MEDALS[rank] or "#"..rank,
			TextColor3 = strokeColor, Font = Enum.Font.GothamBold,
			TextSize = rank <= 3 and 16 or 13
		}, medal)
		addTextStroke(ml)

		local nameBox = make("Frame", {
			Size = UDim2.new(1,-140,1,-10),
			Position = UDim2.new(0,50,0,5),
			BackgroundTransparency = 1
		}, row)
		local dn = make("TextLabel", {
			Size = UDim2.new(1,0,0.54,0), BackgroundTransparency = 1,
			Text = entry.displayName or entry.username or "?",
			TextColor3 = C.white, Font = Enum.Font.GothamBold, TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd
		}, nameBox)
		addTextStroke(dn)
		make("TextLabel", {
			Size = UDim2.new(1,0,0.42,0),
			Position = UDim2.new(0,0,0.56,0),
			BackgroundTransparency = 1,
			Text = "@"..(entry.username or "?"),
			TextColor3 = C.silver, Font = Enum.Font.Gotham, TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left
		}, nameBox)

		local vBox = make("Frame", {
			Size = UDim2.fromOffset(80,42),
			Position = UDim2.new(1,-84,0.5,-21),
			BackgroundColor3 = C.bg3, BorderSizePixel = 0
		}, row)
		addCorner(8, vBox)
		addStroke(C.donGold, 1.2, vBox)
		local vn = make("TextLabel", {
			Size = UDim2.new(1,0,0.55,0), BackgroundTransparency = 1,
			Text = tostring(entry.amount).." R$",
			TextColor3 = C.white, Font = Enum.Font.GothamBold, TextSize = 12
		}, vBox)
		addTextStroke(vn)
		make("TextLabel", {
			Size = UDim2.new(1,0,0.4,0),
			Position = UDim2.new(0,0,0.58,0),
			BackgroundTransparency = 1, Text = "💎 DONASI",
			TextColor3 = C.donGold, Font = Enum.Font.GothamBold, TextSize = 9
		}, vBox)
	end
end

local function showDonationUI()
	if donationGui then closeDonationUI() return end

	local g = Instance.new("ScreenGui")
	g.Name = "ZayinDonationGui"
	g.ResetOnSpawn = false
	g.DisplayOrder = 30
	g.IgnoreGuiInset = true
	g.Parent = PlayerGui
	donationGui = g

	local blur = make("TextButton", {
		Size = UDim2.new(1,0,1,0),
		BackgroundColor3 = Color3.new(0,0,0),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0, Text = ""
	}, g)
	blur.MouseButton1Click:Connect(closeDonationUI)

	local mf = make("Frame", {
		Name = "MainFrame",
		Size = UDim2.new(0,0,0,0),
		AnchorPoint = Vector2.new(0.5,0.5),
		Position = UDim2.new(0.5,0,0.5,0),
		BackgroundColor3 = C.bg,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0
	}, g)
	addCorner(16, mf)
	addStroke(C.donGold, 2, mf)

	TweenService:Create(mf, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0,440,0,600)
	}):Play()

	local header = make("Frame", {
		Size = UDim2.new(1,0,0,54),
		BackgroundColor3 = C.bg3, BorderSizePixel = 0
	}, mf)
	addCorner(16, header)
	local title = make("TextLabel", {
		Size = UDim2.new(1,-60,1,0),
		Position = UDim2.new(0,16,0,0),
		BackgroundTransparency = 1,
		Text = "💎 Papan Donasi",
		TextColor3 = C.donGold, Font = Enum.Font.GothamBold,
		TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left
	}, header)
	addTextStroke(title)
	local closeBtn = make("TextButton", {
		Size = UDim2.fromOffset(34,34),
		Position = UDim2.new(1,-42,0.5,-17),
		BackgroundColor3 = Color3.fromRGB(60,20,20),
		BorderSizePixel = 0, Text = "✕",
		TextColor3 = Color3.fromRGB(255,80,80),
		Font = Enum.Font.GothamBold, TextSize = 15
	}, header)
	addCorner(8, closeBtn)
	closeBtn.MouseButton1Click:Connect(closeDonationUI)

	local tabBar = make("Frame", {
		Size = UDim2.new(1,-20,0,34),
		Position = UDim2.new(0,10,0,60),
		BackgroundTransparency = 1
	}, mf)

	local tabDonasi = make("TextButton", {
		Size = UDim2.new(0.5,-4,1,0),
		BackgroundColor3 = C.donGold, BorderSizePixel = 0,
		Text = "💎 Donasi", TextColor3 = C.bg,
		Font = Enum.Font.GothamBold, TextSize = 13
	}, tabBar)
	addCorner(8, tabDonasi)

	local tabTop = make("TextButton", {
		Size = UDim2.new(0.5,-4,1,0),
		Position = UDim2.new(0.5,4,0,0),
		BackgroundColor3 = C.bg3, BorderSizePixel = 0,
		Text = "🏆 Top Donatur", TextColor3 = C.white,
		Font = Enum.Font.GothamBold, TextSize = 13
	}, tabBar)
	addCorner(8, tabTop)

	local contentArea = make("Frame", {
		Size = UDim2.new(1,-20,1,-112),
		Position = UDim2.new(0,10,0,102),
		BackgroundTransparency = 1
	}, mf)

	-- Tab Donasi
	local donasiFrame = make("Frame", {
		Size = UDim2.new(1,0,1,0),
		BackgroundTransparency = 1
	}, contentArea)

	local donasiScroll = make("ScrollingFrame", {
		Size = UDim2.new(1,0,1,0),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 5, ScrollBarImageColor3 = C.donGold,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0,0,0,0)
	}, donasiFrame)
	make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,6)}, donasiScroll)
	make("UIPadding", {PaddingTop = UDim.new(0,4), PaddingBottom = UDim.new(0,4)}, donasiScroll)

	for i, product in ipairs(Config.Products) do
		local tColor = TIER_COLORS[i] or C.cyan
		local btn = make("TextButton", {
			Name = "DProduct_"..i, LayoutOrder = i,
			Size = UDim2.new(1,-8,0,60),
			BackgroundColor3 = C.rowbg, BackgroundTransparency = 0.1,
			BorderSizePixel = 0, Text = "", AutoButtonColor = false
		}, donasiScroll)
		addCorner(10, btn)
		addStroke(tColor, 1.5, btn)

		local badge = make("Frame", {
			Size = UDim2.fromOffset(40,40),
			Position = UDim2.new(0,8,0.5,-20),
			BackgroundColor3 = C.bg3, BorderSizePixel = 0
		}, btn)
		addCorner(10, badge)
		addStroke(tColor, 1.2, badge)
		make("TextLabel", {
			Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
			Text = "💎", TextColor3 = tColor,
			Font = Enum.Font.GothamBold, TextSize = 18
		}, badge)

		local nb = make("Frame", {
			Size = UDim2.new(1,-140,1,-10),
			Position = UDim2.new(0,56,0,5),
			BackgroundTransparency = 1
		}, btn)
		local lbl = make("TextLabel", {
			Size = UDim2.new(1,0,0.55,0), BackgroundTransparency = 1,
			Text = product.Label, TextColor3 = tColor,
			Font = Enum.Font.GothamBold, TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left
		}, nb)
		addTextStroke(lbl)
		make("TextLabel", {
			Size = UDim2.new(1,0,0.4,0),
			Position = UDim2.new(0,0,0.58,0),
			BackgroundTransparency = 1, Text = "Klik untuk donasi ke game!",
			TextColor3 = C.silver, Font = Enum.Font.Gotham, TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left
		}, nb)

		local vBox = make("Frame", {
			Size = UDim2.fromOffset(82,46),
			Position = UDim2.new(1,-86,0.5,-23),
			BackgroundColor3 = C.bg3, BorderSizePixel = 0
		}, btn)
		addCorner(10, vBox)
		addStroke(C.donGold, 1.2, vBox)
		local vn = make("TextLabel", {
			Size = UDim2.new(1,0,0.55,0), BackgroundTransparency = 1,
			Text = tostring(product.Robux).." R$",
			TextColor3 = C.white, Font = Enum.Font.GothamBold, TextSize = 13
		}, vBox)
		addTextStroke(vn)
		make("TextLabel", {
			Size = UDim2.new(1,0,0.4,0),
			Position = UDim2.new(0,0,0.58,0),
			BackgroundTransparency = 1, Text = "💎 BELI",
			TextColor3 = C.donGold, Font = Enum.Font.GothamBold, TextSize = 10
		}, vBox)

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
		end)

		local pid = product.ProductId
		btn.MouseButton1Click:Connect(function()
			PromptEvent:FireServer(pid)
					end)
	end

	-- Tab Top Donatur
	local topFrame = make("Frame", {
		Size = UDim2.new(1,0,1,0),
		BackgroundTransparency = 1, Visible = false
	}, contentArea)

	local topScroll = make("ScrollingFrame", {
		Size = UDim2.new(1,0,1,0),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 5, ScrollBarImageColor3 = C.donGold,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0,0,0,0)
	}, topFrame)
	make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,6)}, topScroll)
	make("UIPadding", {PaddingTop = UDim.new(0,4), PaddingBottom = UDim.new(0,4)}, topScroll)

	buildTopContent(topScroll)

	tabDonasi.MouseButton1Click:Connect(function()
		donasiFrame.Visible = true
		topFrame.Visible = false
		tabDonasi.BackgroundColor3 = C.donGold; tabDonasi.TextColor3 = C.bg
		tabTop.BackgroundColor3 = C.bg3; tabTop.TextColor3 = C.white
	end)
	tabTop.MouseButton1Click:Connect(function()
		donasiFrame.Visible = false
		topFrame.Visible = true
		tabDonasi.BackgroundColor3 = C.bg3; tabDonasi.TextColor3 = C.white
		tabTop.BackgroundColor3 = C.donGold; tabTop.TextColor3 = C.bg
		buildTopContent(topScroll)
	end)

	print("[DonationClient] UI opened!")
end

-- ── ProximityPrompt ────────────────────────────────────────
task.spawn(function()
	task.wait(5)
	if not papan then return end
	local pp = papan:WaitForChild("DonationPrompt", 15)
	if not pp then return end
	pp.Triggered:Connect(function()
		showDonationUI()
	end)
	print("[DonationClient] ProximityPrompt connected!")
end)

-- ── UpdateUI dari server ───────────────────────────────────
UpdateUIEvent.OnClientEvent:Connect(function(topList)
	cachedTopList = topList or {}
end)

-- ── Notif donasi ───────────────────────────────────────────
local notifQueue = {}
local notifBusy = false
local notifProcessing = false

local function processNotif()
	-- [P47] kartu donasi modern: avatar + jumlah + pesan menyatu
	if notifBusy then return end
	notifBusy = true
	while #notifQueue > 0 do
		local data = table.remove(notifQueue, 1)
		local durasiTampil = 0
		local ok = pcall(function()
			local UIS = game:GetService("UserInputService")
			local TS  = game:GetService("TweenService")
			local M2  = UIS.TouchEnabled and not UIS.KeyboardEnabled
			local vp  = workspace.CurrentCamera.ViewportSize

			local old = PlayerGui:FindFirstChild("ZayinDonasiNotif")
			if old then old:Destroy() end

			local punyaPesan = data.message and data.message ~= ""
			local W = math.clamp(vp.X * (M2 and 0.92 or 0.32), 300, 470)
			local H = punyaPesan and (M2 and 150 or 168) or (M2 and 100 or 112)

			local g = Instance.new("ScreenGui")
			g.Name = "ZayinDonasiNotif"
			g.ResetOnSpawn = false
			g.IgnoreGuiInset = true
			g.DisplayOrder = 75
			print("[DONASI-C] GUI DIBUAT | tipe:", data.type, "| umur:", punyaPesan and 9 or 7)
			g.Parent = PlayerGui
			game:GetService("Debris"):AddItem(g, (punyaPesan and 10 or 8))

			local card = make("Frame", {
				Size = UDim2.fromOffset(W, H),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, -H - 20),
				BackgroundColor3 = Color3.fromRGB(13, 15, 22),
				BackgroundTransparency = 0.5,
				BorderSizePixel = 0,
			}, g)
			addCorner(14, card)
			addStroke(Color3.fromRGB(255, 200, 55), 2, card)

			-- garis aksen atas
			local top = make("Frame", {
				Size = UDim2.new(1, -30, 0, 3),
				Position = UDim2.new(0, 15, 0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 210, 70),
				BorderSizePixel = 0,
			}, card)
			addCorner(3, top)

			-- avatar bulat
			local avSz = M2 and 52 or 60
			local ring = make("Frame", {
				Size = UDim2.fromOffset(avSz, avSz),
				Position = UDim2.new(0, 12, 0, M2 and 16 or 18),
				BackgroundColor3 = Color3.fromRGB(255, 200, 55),
				BorderSizePixel = 0,
			}, card)
			addCorner(100, ring)
			local av = make("ImageLabel", {
				Size = UDim2.new(1, -4, 1, -4),
				Position = UDim2.new(0, 2, 0, 2),
				BackgroundColor3 = Color3.fromRGB(22, 24, 30),
				BorderSizePixel = 0,
				Image = data.userId and ("rbxthumb://type=AvatarHeadShot&id=" .. data.userId .. "&w=150&h=150") or "",
			}, ring)
			addCorner(100, av)

			local xT = avSz + 22
			local fB = M2 and 17 or 19
			local fS = M2 and 14 or 15

			-- nama donatur
			make("TextLabel", {
				Size = UDim2.new(1, -xT - 14, 0, fB + 3),
				Position = UDim2.new(0, xT, 0, M2 and 12 or 14),
				BackgroundTransparency = 1,
				Text = tostring(data.donor or "?"),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.GothamBold,
				TextSize = fB,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, card)

			-- baris jumlah / total
			-- [P50] info dipecah 2 baris supaya tidak terpotong
			local baris1, baris2
			if data.type == "message" then
				baris1 = "mengirim pesan"
				baris2 = "total semua donasi " .. tostring(data.total or 0) .. " R$"
			else
				baris1 = "telah mendonasikan sebesar " .. tostring(data.amount or 0) .. " R$"
				baris2 = "total semua donasi " .. tostring(data.total or 0) .. " R$"
			end

			make("TextLabel", {
				Size = UDim2.new(1, -xT - 14, 0, fS + 3),
				Position = UDim2.new(0, xT, 0, (M2 and 12 or 14) + fB + 3),
				BackgroundTransparency = 1,
				Text = baris1,
				TextColor3 = Color3.fromRGB(255, 205, 70),
				Font = Enum.Font.GothamBold,
				TextSize = fS + 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, card)

			make("TextLabel", {
				Size = UDim2.new(1, -xT - 14, 0, fS + 3),
				Position = UDim2.new(0, xT, 0, (M2 and 12 or 14) + fB + fS + 7),
				BackgroundTransparency = 1,
				Text = baris2,
				TextColor3 = Color3.fromRGB(255, 205, 70),
				Font = Enum.Font.GothamBold,
				TextSize = fS + 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, card)

            -- pesan (kalau ada) — menyatu di kartu yang sama
			if punyaPesan then
				local kotak = make("Frame", {
					Size = UDim2.new(1, -24, 0, M2 and 42 or 48),
					Position = UDim2.new(0, 12, 1, -(M2 and 50 or 56)),
					BackgroundColor3 = Color3.fromRGB(22, 25, 34),
					BackgroundTransparency = 0.35,
					BorderSizePixel = 0,
				}, card)
				addCorner(10, kotak)
				make("TextLabel", {
					Size = UDim2.new(1, -16, 1, 0),
					Position = UDim2.new(0, 8, 0, 0),
					BackgroundTransparency = 1,
					Text = '"' .. tostring(data.message) .. '"',
					TextColor3 = Color3.fromRGB(205, 215, 230),
					Font = Enum.Font.GothamMedium,
					TextSize = fS + 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
					TextTruncate = Enum.TextTruncate.AtEnd,
				}, kotak)
			end

			TS:Create(card, TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{Position = UDim2.new(0.5, 0, 0, M2 and 62 or 76)}):Play()
			local hidup = punyaPesan and 9 or 7
			durasiTampil = hidup
			task.delay(hidup, function()
				pcall(function()
					TS:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
						{Position = UDim2.new(0.5, 0, 0, -H - 20)}):Play()
				end)
				task.wait(0.34)
				pcall(function() if g then g:Destroy() end end)
			end)
		end)
		if ok then task.wait(durasiTampil + 0.45) else task.wait(0.2) end
	end
	notifBusy = false
end

NotifyEvent.OnClientEvent:Connect(function(data)
	-- NOTIF LAMA DIMATIKAN: digantikan ZayinNotifDonasi di StarterPlayerScripts
	if true then return end
	print("[DONASI-C] TERIMA | tipe:", data and data.type, "| donor:", data and data.donor, "| antrian:", #notifQueue, "| sibuk:", notifBusy)
	table.insert(notifQueue, data)
	task.spawn(processNotif)
end)

MsgEvent.OnClientEvent:Connect(function(action, total)
	if action ~= "OpenMessageInput" then return end
	-- [PATCH B4] dialog input pesan donasi
	local old = PlayerGui:FindFirstChild("ZayinDonasiMsgGui")
	if old then old:Destroy() end

	local g = Instance.new("ScreenGui")
	g.Name = "ZayinDonasiMsgGui"
	g.ResetOnSpawn = false
	g.DisplayOrder = 40
	g.Parent = PlayerGui

	local f = make("Frame", {
		Name = "MessageFrame",
		Size = UDim2.new(0, 340, 0, 150),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = C.bg, BorderSizePixel = 0
	}, g)
	addCorner(12, f)
	addStroke(C.donGold, 2, f)

	make("TextLabel", {
		Size = UDim2.new(1, -20, 0, 28), Position = UDim2.new(0, 10, 0, 8),
		BackgroundTransparency = 1,
		Text = "Terima kasih! Tulis pesanmu:",
		TextColor3 = C.donGold, Font = Enum.Font.GothamBold, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left
	}, f)

	local box = make("TextBox", {
		Size = UDim2.new(1, -20, 0, 54), Position = UDim2.new(0, 10, 0, 40),
		BackgroundColor3 = C.bg3, TextColor3 = C.white,
		PlaceholderText = "Pesan untuk semua pemain...",
		Font = Enum.Font.Gotham, TextSize = 13,
		TextWrapped = true, ClearTextOnFocus = false, Text = ""
	}, f)
	addCorner(8, box)

	local kirim = make("TextButton", {
		Size = UDim2.new(0.5, -14, 0, 32), Position = UDim2.new(0, 10, 1, -40),
		BackgroundColor3 = C.donGold, Text = "Kirim",
		TextColor3 = C.bg, Font = Enum.Font.GothamBold, TextSize = 13,
		BorderSizePixel = 0
	}, f)
	addCorner(8, kirim)

	local batal = make("TextButton", {
		Size = UDim2.new(0.5, -14, 0, 32), Position = UDim2.new(0.5, 4, 1, -40),
		BackgroundColor3 = C.bg3, Text = "Lewati",
		TextColor3 = C.silver, Font = Enum.Font.GothamBold, TextSize = 13,
		BorderSizePixel = 0
	}, f)
	addCorner(8, batal)

	kirim.MouseButton1Click:Connect(function()
		local teks = box.Text
		if teks and teks:gsub("%s", "") ~= "" then
			MsgEvent:FireServer("Send", teks:sub(1, 150))
		end
		g:Destroy()
	end)
	batal.MouseButton1Click:Connect(function()
		-- [P48] beri tahu server supaya notif donasi tetap tampil (tanpa pesan)
		pcall(function() MsgEvent:FireServer("Skip") end)
		g:Destroy()
	end)
end)

print("[ZayinDonationClient] Ready!")