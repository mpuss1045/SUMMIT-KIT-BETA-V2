-- ============================================================
-- ZayinMenuShop (LocalScript)
-- Lokasi: StarterPlayer > StarterPlayerScripts > ZayinClient > ZayinMenuShop
-- Fungsi: Isi ShopPanel di ZayinMenuBaru dengan item Coil, Boombox, VIP
--         + fitur Gift ke player lain
-- ============================================================

local Players           = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================
-- CONFIG ITEM SHOP
-- Isi ID gamepass/product saat sudah ada
-- Type: "gamepass" = beli sekali permanent | "product" = developer product (beli berkali)
-- ============================================================
-- ============================================================
-- SHOP ITEMS — dibaca dari ShopDonationConfig
-- Edit di ReplicatedStorage > ZayinConfig > ShopDonationConfig
-- ============================================================
local RS2 = game:GetService("ReplicatedStorage")
local ShopDonationConfig = require(RS2:WaitForChild("ZayinConfig", 10):WaitForChild("ShopDonationConfig", 10))
local SHOP_ITEMS = ShopDonationConfig:GetShopItems()

-- ============================================================
-- WARNA
-- ============================================================
local C = {
	bg      = Color3.fromRGB(10,  14,  26),
	bg2     = Color3.fromRGB(18,  24,  42),
	border  = Color3.fromRGB(40,  60, 120),
	accent  = Color3.fromRGB(0,  200, 180),
	white   = Color3.new(1, 1, 1),
	gray    = Color3.fromRGB(140, 155, 180),
	red     = Color3.fromRGB(220,  60,  60),
	green   = Color3.fromRGB( 60, 200, 100),
}

-- ============================================================
-- HELPER UI
-- ============================================================
local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color     = color or C.border
	s.Thickness = thickness or 1
	s.Parent    = parent
	return s
end

local function label(parent, text, size, color, font, xa)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text         = text
	l.TextSize     = size or 14
	l.TextColor3   = color or C.white
	l.Font         = font or Enum.Font.Gotham
	l.TextXAlignment = xa or Enum.TextXAlignment.Left
	l.TextWrapped  = true
	l.Size         = UDim2.new(1, 0, 0, size and size * 1.4 or 20)
	l.Parent       = parent
	return l
end

-- ============================================================
-- GIFT DIALOG
-- ============================================================
local giftDialog

local function showGiftDialog(item)
	if giftDialog then giftDialog:Destroy() end

	-- Gift dialog muncul di samping kanan ShopPanel
	local menu = playerGui:WaitForChild("ZayinMenuBaru", 5)
	local shopFrame = nil
	if menu then
		for _, c in ipairs(menu:GetChildren()) do
			if c:IsA("Frame") then
				for _, desc in ipairs(c:GetDescendants()) do
					if desc:IsA("TextLabel") and desc.Text == "Shop" then
						shopFrame = c; break
					end
				end
			end
			if shopFrame then break end
		end
	end

	local dialog = Instance.new("Frame")
	dialog.BackgroundColor3   = C.bg
	dialog.BorderSizePixel    = 0
	dialog.ZIndex             = 21
	-- Gift dialog di ScreenGui terpisah agar tidak menimpa ShopPanel
	local giftSG = Instance.new("ScreenGui")
	giftSG.Name           = "GiftDialogSG"
	giftSG.ResetOnSpawn   = false
	giftSG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	giftSG.Parent         = playerGui
	giftDialog = giftSG  -- simpan reference ke ScreenGui

	task.wait(0.1)
	-- Cari MenuPanel (menu utama) untuk posisi di sebelah kirinya
	local menuPanel = nil
	if shopFrame then
		local menuObj = shopFrame.Parent
		menuPanel = menuObj and menuObj:FindFirstChild("MenuPanel")
	end

	local dW = 280
	-- Tinggi Gift dialog sesuai MenuPanel agar sejajar
	local dH = 540
	if menuPanel then
		dH = math.max(menuPanel.AbsoluteSize.Y, 340)
	end
	dialog.Size = UDim2.new(0, dW, 0, dH)

	if menuPanel then
		local mPos  = menuPanel.AbsolutePosition
		local mSize = menuPanel.AbsoluteSize
		local vp    = workspace.CurrentCamera.ViewportSize
		-- Posisi: kiri MenuPanel - gap 8px, Y sejajar dengan MenuPanel
		local xLeft = mPos.X - dW - 8
		local yTop  = mPos.Y  -- sejajar tepat dengan atas MenuPanel
		-- Pastikan tidak keluar layar kiri
		xLeft = math.max(8, xLeft)
		dialog.Position = UDim2.new(0, xLeft, 0, yTop)
	else
		dialog.Position = UDim2.new(0, 8, 0, 60)
	end
	dialog.Parent = giftSG
	corner(dialog, 12)
	stroke(dialog, C.accent, 1.5)
	giftDialog = dialog

	-- Header
	local header = Instance.new("Frame")
	header.Size             = UDim2.new(1, 0, 0, 44)
	header.BackgroundColor3 = C.bg2
	header.BorderSizePixel  = 0
	header.ZIndex           = 22
	header.Parent           = dialog
	corner(header, 12)

	local headerLabel = Instance.new("TextLabel")
	headerLabel.Size               = UDim2.new(1, -50, 1, 0)
	headerLabel.Position           = UDim2.new(0, 14, 0, 0)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Text               = "🎁 Gift " .. item.name
	headerLabel.TextSize           = 15
	headerLabel.Font               = Enum.Font.GothamBold
	headerLabel.TextColor3         = C.white
	headerLabel.TextXAlignment     = Enum.TextXAlignment.Left
	headerLabel.ZIndex             = 23
	headerLabel.Parent             = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size               = UDim2.new(0, 60, 0, 28)
	closeBtn.Position           = UDim2.new(1, -68, 0, 8)
	closeBtn.BackgroundColor3   = C.red
	closeBtn.BorderSizePixel    = 0
	closeBtn.Text               = "Tutup"
	closeBtn.TextSize           = 12
	closeBtn.Font               = Enum.Font.GothamBold
	closeBtn.TextColor3         = C.white
	closeBtn.ZIndex             = 23
	closeBtn.Parent             = header
	corner(closeBtn, 6)
	closeBtn.MouseButton1Click:Connect(function()
		if giftDialog then giftDialog:Destroy() end
		giftDialog = nil
	end)

	-- Info item
	local infoFrame = Instance.new("Frame")
	infoFrame.Size               = UDim2.new(1, -20, 0, 70)
	infoFrame.Position           = UDim2.new(0, 10, 0, 54)
	infoFrame.BackgroundColor3   = C.bg2
	infoFrame.BorderSizePixel    = 0
	infoFrame.ZIndex             = 22
	infoFrame.Parent             = dialog
	corner(infoFrame, 8)

	local itemIcon = Instance.new("ImageLabel")
	itemIcon.Size               = UDim2.new(0, 50, 0, 50)
	itemIcon.Position           = UDim2.new(0, 10, 0, 10)
	itemIcon.BackgroundColor3   = C.bg
	itemIcon.Image              = item.icon
	itemIcon.ScaleType          = Enum.ScaleType.Fit
	itemIcon.ZIndex             = 23
	itemIcon.Parent             = infoFrame
	corner(itemIcon, 25)  -- lingkaran

	local itemName = Instance.new("TextLabel")
	itemName.Size               = UDim2.new(1, -70, 0, 22)
	itemName.Position           = UDim2.new(0, 68, 0, 12)
	itemName.BackgroundTransparency = 1
	itemName.Text               = item.name
	itemName.TextSize           = 14
	itemName.Font               = Enum.Font.GothamBold
	itemName.TextColor3         = item.color
	itemName.TextXAlignment     = Enum.TextXAlignment.Left
	itemName.ZIndex             = 23
	itemName.Parent             = infoFrame

	local itemPrice = Instance.new("TextLabel")
	itemPrice.Size               = UDim2.new(1, -70, 0, 18)
	itemPrice.Position           = UDim2.new(0, 68, 0, 36)
	itemPrice.BackgroundTransparency = 1
	itemPrice.Text               = item.price
	itemPrice.TextSize           = 12
	itemPrice.Font               = Enum.Font.Gotham
	itemPrice.TextColor3         = C.gray
	itemPrice.TextXAlignment     = Enum.TextXAlignment.Left
	itemPrice.ZIndex             = 23
	itemPrice.Parent             = infoFrame

	-- Label pilih player
	local pickLabel = Instance.new("TextLabel")
	pickLabel.Size               = UDim2.new(1, -20, 0, 20)
	pickLabel.Position           = UDim2.new(0, 10, 0, 134)
	pickLabel.BackgroundTransparency = 1
	pickLabel.Text               = "Pilih player untuk di-gift:"
	pickLabel.TextSize           = 12
	pickLabel.Font               = Enum.Font.Gotham
	pickLabel.TextColor3         = C.gray
	pickLabel.TextXAlignment     = Enum.TextXAlignment.Left
	pickLabel.ZIndex             = 22
	pickLabel.Parent             = dialog

	-- List player
	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Size               = UDim2.new(1, -20, 1, -200)  -- ikut tinggi dialog
	listFrame.Position           = UDim2.new(0, 10, 0, 158)
	listFrame.BackgroundColor3   = C.bg2
	listFrame.BorderSizePixel    = 0
	listFrame.ScrollBarThickness = 3
	listFrame.ScrollBarImageColor3 = C.accent
	listFrame.ZIndex             = 22
	listFrame.Parent             = dialog
	corner(listFrame, 8)

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding    = UDim.new(0, 4)
	listLayout.Parent     = listFrame

	local listPad = Instance.new("UIPadding")
	listPad.PaddingTop    = UDim.new(0, 6)
	listPad.PaddingBottom = UDim.new(0, 6)
	listPad.PaddingLeft   = UDim.new(0, 6)
	listPad.PaddingRight  = UDim.new(0, 6)
	listPad.Parent        = listFrame

	-- Isi daftar player di server
	local allPlayers = Players:GetPlayers()
	local selectedPlayer = nil

	for _, p in ipairs(allPlayers) do
		if p ~= player then  -- tidak bisa gift ke diri sendiri
			local btn = Instance.new("TextButton")
			btn.Size               = UDim2.new(1, 0, 0, 36)
			btn.BackgroundColor3   = C.bg
			btn.BorderSizePixel    = 0
			btn.Text               = ""
			btn.ZIndex             = 23
			btn.Parent             = listFrame
			corner(btn, 6)

			-- Avatar mini
			local ava = Instance.new("ImageLabel")
			ava.Size               = UDim2.new(0, 26, 0, 26)
			ava.Position           = UDim2.new(0, 5, 0.5, -13)
			ava.BackgroundColor3   = C.bg2
			ava.ZIndex             = 24
			ava.Parent             = btn
			corner(ava, 13)
			task.spawn(function()
				local ok, img = pcall(function()
					return Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
				end)
				if ok then ava.Image = img end
			end)

			local nameL = Instance.new("TextLabel")
			nameL.Size               = UDim2.new(1, -40, 1, 0)
			nameL.Position           = UDim2.new(0, 36, 0, 0)
			nameL.BackgroundTransparency = 1
			nameL.Text               = p.DisplayName
			nameL.TextSize           = 13
			nameL.Font               = Enum.Font.Gotham
			nameL.TextColor3         = C.white
			nameL.TextXAlignment     = Enum.TextXAlignment.Left
			nameL.ZIndex             = 24
			nameL.Parent             = btn

			btn.MouseButton1Click:Connect(function()
				selectedPlayer = p
				-- Reset semua highlight
				for _, child in ipairs(listFrame:GetChildren()) do
					if child:IsA("TextButton") then
						child.BackgroundColor3 = C.bg
						stroke(child, C.border, 1)
					end
				end
				-- Highlight yang dipilih
				btn.BackgroundColor3 = Color3.fromRGB(20, 40, 80)
				for _, s in ipairs(btn:GetChildren()) do
					if s:IsA("UIStroke") then s:Destroy() end
				end
				stroke(btn, C.accent, 1.5)
			end)
		end
	end

	-- Update canvas size
	listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 12)
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 12)
	end)

	-- Tombol konfirmasi gift
	local giftBtn = Instance.new("TextButton")
	giftBtn.Size               = UDim2.new(1, -20, 0, 40)
	giftBtn.Position           = UDim2.new(0, 10, 1, -50)
	giftBtn.BackgroundColor3   = C.accent
	giftBtn.BorderSizePixel    = 0
	giftBtn.Text               = "🎁 Kirim Gift"
	giftBtn.TextSize           = 14
	giftBtn.Font               = Enum.Font.GothamBold
	giftBtn.TextColor3         = Color3.new(0, 0, 0)
	giftBtn.ZIndex             = 22
	giftBtn.Parent             = dialog
	corner(giftBtn, 8)

	giftBtn.MouseButton1Click:Connect(function()
		if not selectedPlayer then
			-- Flash merah jika belum pilih player
			giftBtn.BackgroundColor3 = C.red
			giftBtn.Text = "⚠ Pilih player dulu!"
			task.delay(1.5, function()
				giftBtn.BackgroundColor3 = C.accent
				giftBtn.Text = "🎁 Kirim Gift"
			end)
			return
		end

		if item.id == 0 then
			giftBtn.Text = "⚠ ID belum diisi!"
			task.delay(1.5, function() giftBtn.Text = "🎁 Kirim Gift" end)
			return
		end

		-- Buka prompt gift Roblox
		local ok, err = pcall(function()
			MarketplaceService:PromptGamePassPurchase(selectedPlayer, item.id)
		end)

		if not ok then
			giftBtn.Text = "Gagal: " .. tostring(err):sub(1, 30)
			task.delay(2, function() giftBtn.Text = "🎁 Kirim Gift" end)
		else
			giftBtn.BackgroundColor3 = C.green
			giftBtn.Text = "✅ Gift dikirim!"
			task.delay(2, function()
				if giftDialog and giftDialog.Parent then giftDialog:Destroy() end
				giftDialog = nil
			end)
		end
	end)
end

-- ============================================================
-- BUILD SHOP PANEL
-- ============================================================
local function buildShopPanel(shopPanel)
	-- Perbesar ShopPanel agar semua item muat tanpa terpotong
	shopPanel.Size = UDim2.new(0, 280, 0, 410)

	-- Bersihkan konten lama (Coming Soon)
	local content = shopPanel:FindFirstChild("Content")
	if content then
		for _, c in ipairs(content:GetChildren()) do
			c:Destroy()
		end
	else
		-- Buat Content ScrollingFrame jika belum ada
		content = Instance.new("ScrollingFrame")
		content.Name                = "Content"
		content.Size                = UDim2.new(1, -4, 1, -54)
		content.Position            = UDim2.new(0, 2, 0, 52)
		content.BackgroundTransparency = 1
		content.BorderSizePixel     = 0
		content.ScrollBarThickness  = 4
		content.ScrollBarImageColor3 = C.accent
		content.Parent              = shopPanel
	end

	-- Hapus "Coming Soon" label jika ada
	for _, c in ipairs(shopPanel:GetDescendants()) do
		if c:IsA("TextLabel") and c.Text:find("Coming Soon") then
			c:Destroy()
		end
	end

	-- Layout
	local layout = Instance.new("UIListLayout")
	layout.Padding    = UDim.new(0, 8)
	layout.Parent     = content

	local pad = Instance.new("UIPadding")
	pad.PaddingTop    = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft   = UDim.new(0, 8)
	pad.PaddingRight  = UDim.new(0, 8)
	pad.Parent        = content

	-- Buat card untuk setiap item
	for _, item in ipairs(SHOP_ITEMS) do
		local card = Instance.new("Frame")
		card.Size               = UDim2.new(1, 0, 0, 105)
		card.BackgroundColor3   = C.bg2
		card.BorderSizePixel    = 0
		card.Parent             = content
		corner(card, 10)
		stroke(card, item.color, 1)

		-- Icon bulat (kiri)
		local iconBg = Instance.new("Frame")
		iconBg.Size               = UDim2.new(0, 68, 0, 68)
		iconBg.Position           = UDim2.new(0, 12, 0, 8)
		iconBg.BackgroundColor3   = C.bg
		iconBg.BorderSizePixel    = 0
		iconBg.Parent             = card
		corner(iconBg, 36)  -- lingkaran penuh
		stroke(iconBg, item.color, 1.5)

		local icon = Instance.new("ImageLabel")
		icon.Size               = UDim2.new(0, 52, 0, 52)
		icon.Position           = UDim2.new(0.5, -26, 0.5, -26)
		icon.BackgroundTransparency = 1
		icon.Image              = item.icon
		icon.ScaleType          = Enum.ScaleType.Fit
		icon.Parent             = iconBg

		-- Harga di bawah icon lingkaran (di dalam iconBg parent=card, posisi absolut)
		local priceTag = Instance.new("TextLabel")
		priceTag.Size               = UDim2.new(0, 72, 0, 18)
		-- Posisi tepat di bawah iconBg
		priceTag.Position           = UDim2.new(0, 12, 1, -22)
		priceTag.BackgroundColor3   = Color3.fromRGB(0, 0, 0)
		priceTag.BackgroundTransparency = 0.3
		priceTag.BorderSizePixel    = 0
		priceTag.Text               = item.robux and item.robux > 0 and ("💎 " .. item.robux .. " R$") or "💎 GP"
		priceTag.TextSize           = 10
		priceTag.Font               = Enum.Font.GothamBold
		priceTag.TextColor3         = item.color
		priceTag.TextXAlignment     = Enum.TextXAlignment.Center
		priceTag.TextScaled         = false
		priceTag.ZIndex             = 3
		priceTag.Parent             = card
		Instance.new("UICorner", priceTag).CornerRadius = UDim.new(0, 4)

		-- Info (kanan icon)
		local infoFrame = Instance.new("Frame")
		infoFrame.Size               = UDim2.new(1, -96, 1, -10)
		infoFrame.Position           = UDim2.new(0, 92, 0, 5)
		infoFrame.BackgroundTransparency = 1
		infoFrame.Parent             = card

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size               = UDim2.new(1, 0, 0, 22)
		nameLabel.Position           = UDim2.new(0, 0, 0, 2)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text               = item.name
		nameLabel.TextSize           = 15
		nameLabel.Font               = Enum.Font.GothamBold
		nameLabel.TextColor3         = item.color
		nameLabel.TextXAlignment     = Enum.TextXAlignment.Left
		nameLabel.Parent             = infoFrame

		local descLabel = Instance.new("TextLabel")
		descLabel.Size               = UDim2.new(1, -4, 0, 42)
		descLabel.Position           = UDim2.new(0, 0, 0, 25)
		descLabel.BackgroundTransparency = 1
		descLabel.Text               = item.desc
		descLabel.TextSize           = 11
		descLabel.Font               = Enum.Font.Gotham
		descLabel.TextColor3         = C.gray
		descLabel.TextXAlignment     = Enum.TextXAlignment.Left
		descLabel.TextWrapped        = true
		descLabel.Parent             = infoFrame

		-- Tombol Beli
		local buyBtn = Instance.new("TextButton")
		buyBtn.Size               = UDim2.new(0, 76, 0, 26)
		buyBtn.Position           = UDim2.new(0, 0, 1, -28)
		buyBtn.BackgroundColor3   = item.color
		buyBtn.BorderSizePixel    = 0
		buyBtn.Text               = "🛒 Beli"
		buyBtn.TextSize           = 12
		buyBtn.Font               = Enum.Font.GothamBold
		buyBtn.TextColor3         = Color3.new(0, 0, 0)
		buyBtn.Parent             = infoFrame
		corner(buyBtn, 6)

	-- [P53] tombol gift
	local giftBtn2 = Instance.new("TextButton")
	giftBtn2.Name             = "GiftBtn"
	giftBtn2.Size             = UDim2.new(0, 76, 0, 26)
	giftBtn2.Position         = UDim2.new(0, 82, 1, -28)
	giftBtn2.BackgroundColor3 = Color3.fromRGB(255, 120, 200)
	giftBtn2.BorderSizePixel  = 0
	giftBtn2.Text             = "🎁 Gift"
	giftBtn2.TextSize         = 12
	giftBtn2.Font             = Enum.Font.GothamBold
	giftBtn2.TextColor3       = Color3.new(0, 0, 0)
	giftBtn2.Parent           = infoFrame
	corner(giftBtn2, 6)
	giftBtn2.MouseButton1Click:Connect(function()
		if _G.ZayinBukaGift then _G.ZayinBukaGift(item) end
	end)

		buyBtn.MouseButton1Click:Connect(function()
			if item.id == 0 then
				buyBtn.Text = "Soon!"
				task.delay(1.5, function() buyBtn.Text = "🛒 Beli" end)
				return
			end
			if item.type == "gamepass" then
				MarketplaceService:PromptGamePassPurchase(player, item.id)
			else
				MarketplaceService:PromptProductPurchase(player, item.id)
			end
		end)

		-- Tombol Gift
		local giftBtn = Instance.new("TextButton")
		giftBtn.Size               = UDim2.new(0, 70, 0, 26)
		giftBtn.Position           = UDim2.new(0, 86, 1, -32)
		giftBtn.BackgroundColor3   = C.bg
		giftBtn.BorderSizePixel    = 0
		giftBtn.Text               = "🎁 Gift"
		giftBtn.TextSize           = 12
		giftBtn.Font               = Enum.Font.GothamBold
		giftBtn.TextColor3         = C.white
		giftBtn.Parent             = infoFrame
		giftBtn.Visible            = false -- [PATCH] gift dinonaktifkan (desain lama tidak bisa jalan di Roblox)
		corner(giftBtn, 6)
		stroke(giftBtn, item.color, 1)

		giftBtn.MouseButton1Click:Connect(function()
			showGiftDialog(item)
		end)

		-- Hover effect
		card.MouseEnter:Connect(function()
			TweenService:Create(card, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(25, 32, 55)
			}):Play()
		end)
		card.MouseLeave:Connect(function()
			TweenService:Create(card, TweenInfo.new(0.15), {
				BackgroundColor3 = C.bg2
			}):Play()
		end)
	end

	-- Update canvas size
	content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
	end)

	print("[ZayinMenuShop] ShopPanel berhasil diisi!")
end

-- ============================================================
-- INIT — tunggu ZayinMenuBaru dan cari ShopPanel
-- ============================================================
task.spawn(function()
	local menu = playerGui:WaitForChild("ZayinMenuBaru", 15)
	if not menu then warn("[ZayinMenuShop] ZayinMenuBaru tidak ditemukan!"); return end

	-- Cari ShopPanel — frame dengan TextLabel "🛒  Shop" di header
	local shopPanel = nil
	for _, c in ipairs(menu:GetChildren()) do
		if c:IsA("Frame") then
			for _, desc in ipairs(c:GetDescendants()) do
				if desc:IsA("TextLabel") and (desc.Text:find("Shop") or desc.Text:find("🛒")) 
					and not desc.Text:find("Gift") then
					-- Pastikan bukan MenuPanel
					if c.Name ~= "MenuPanel" and c ~= menu then
						shopPanel = c
						break
					end
				end
			end
		end
		if shopPanel then break end
	end

	if shopPanel then
		print("[ZayinMenuShop] ShopPanel ditemukan:", shopPanel:GetFullName())
		-- Sejajarkan Y ShopPanel dengan MenuPanel
		local menuPanel = menu:FindFirstChild("MenuPanel")
		if menuPanel then
			task.wait(0.1)  -- tunggu posisi final
			local mPos = menuPanel.AbsolutePosition
			shopPanel.Position = UDim2.new(0, shopPanel.AbsolutePosition.X, 0, mPos.Y)
		end
		buildShopPanel(shopPanel)
	else
		warn("[ZayinMenuShop] ShopPanel tidak ditemukan! Pastikan ada frame Shop di ZayinMenuBaru")
	end
end)

print("[ZayinMenuShop] Ready!")

-- [P53] panel gift: pilih pemain penerima
task.spawn(function()
	local Players = game:GetService("Players")
	local RS = game:GetService("ReplicatedStorage")
	local UIS = game:GetService("UserInputService")
	local TS = game:GetService("TweenService")
	local plr = Players.LocalPlayer
	local gui = plr:WaitForChild("PlayerGui")

	local DF = RS:WaitForChild("DonationSystem", 20)
	local GiftIntentRE = DF and DF:WaitForChild("GiftIntent", 20)
	local GiftNotifRE  = DF and DF:WaitForChild("GiftNotif", 20)
	local SDC = require(RS:WaitForChild("ZayinConfig"):WaitForChild("ShopDonationConfig"))

	-- peta nama item -> kunci gift
	local PETA = { ["CoiL VIP"] = "CoilVIP", ["Boombox"] = "Boombox", ["Bundle VIP"] = "BundleVIP" }

	_G.ZayinBukaGift = function(item)
		local kunci = PETA[item.name]
		if not kunci then return end
		local g = SDC.GiftProducts and SDC.GiftProducts[kunci]
		if not g then return end

		local old = gui:FindFirstChild("ZayinGiftPanel")
		if old then old:Destroy() end

		local M2 = UIS.TouchEnabled and not UIS.KeyboardEnabled
		local vp = workspace.CurrentCamera.ViewportSize
		local W = math.clamp(vp.X * (M2 and 0.82 or 0.24), 260, 340)
		local H = M2 and 320 or 380

		local sg = Instance.new("ScreenGui")
		sg.Name = "ZayinGiftPanel"; sg.ResetOnSpawn = false
		sg.IgnoreGuiInset = true; sg.DisplayOrder = 60; sg.Parent = gui

		local bg = Instance.new("TextButton")
		bg.Size = UDim2.fromScale(1,1); bg.BackgroundColor3 = Color3.new(0,0,0)
		bg.BackgroundTransparency = 0.5; bg.Text = ""; bg.BorderSizePixel = 0
		bg.ZIndex = 60; bg.Parent = sg

		local p = Instance.new("Frame")
		p.Size = UDim2.fromOffset(W, H)
		p.AnchorPoint = Vector2.new(0.5, 0.5)
		p.Position = UDim2.new(0.5, 0, 0.5, 0)
		p.BackgroundColor3 = Color3.fromRGB(12, 15, 22)
		p.BorderSizePixel = 0; p.ZIndex = 61; p.Parent = sg
		Instance.new("UICorner", p).CornerRadius = UDim.new(0, 14)
		local st = Instance.new("UIStroke", p)
		st.Color = Color3.fromRGB(255, 130, 205); st.Thickness = 2

		local hdr = Instance.new("TextLabel")
		hdr.Size = UDim2.new(1, -20, 0, M2 and 32 or 38)
		hdr.Position = UDim2.new(0, 12, 0, 10)
		hdr.BackgroundTransparency = 1
		hdr.Text = "🎁 Gift " .. g.name .. "  (" .. g.robux .. " R$)"
		hdr.TextColor3 = Color3.fromRGB(255, 150, 215)
		hdr.Font = Enum.Font.GothamBold
		hdr.TextSize = M2 and 14 or 16
		hdr.TextXAlignment = Enum.TextXAlignment.Left
		hdr.ZIndex = 62; hdr.Parent = p

		local tutup = Instance.new("TextButton")
		tutup.Size = UDim2.fromOffset(M2 and 48 or 54, M2 and 22 or 26)
		tutup.AnchorPoint = Vector2.new(1, 0)
		tutup.Position = UDim2.new(1, -10, 0, 12)
		tutup.BackgroundColor3 = Color3.fromRGB(40, 12, 12)
		tutup.Text = "Tutup"; tutup.TextColor3 = Color3.fromRGB(255, 90, 90)
		tutup.Font = Enum.Font.GothamBold; tutup.TextSize = M2 and 10 or 11
		tutup.BorderSizePixel = 0; tutup.ZIndex = 63; tutup.Parent = p
		Instance.new("UICorner", tutup).CornerRadius = UDim.new(0, 8)

		local info = Instance.new("TextLabel")
		info.Size = UDim2.new(1, -24, 0, M2 and 16 or 18)
		info.Position = UDim2.new(0, 12, 0, M2 and 46 or 54)
		info.BackgroundTransparency = 1
		info.Text = "Pilih pemain yang ingin diberi hadiah:"
		info.TextColor3 = Color3.fromRGB(150, 160, 175)
		info.Font = Enum.Font.Gotham; info.TextSize = M2 and 11 or 12
		info.TextXAlignment = Enum.TextXAlignment.Left
		info.ZIndex = 62; info.Parent = p

		local sf = Instance.new("ScrollingFrame")
		sf.Size = UDim2.new(1, -20, 1, -(M2 and 78 or 90))
		sf.Position = UDim2.new(0, 10, 0, M2 and 68 or 78)
		sf.BackgroundTransparency = 1; sf.BorderSizePixel = 0
		sf.ScrollBarThickness = 3
		sf.ScrollBarImageColor3 = Color3.fromRGB(255, 130, 205)
		sf.CanvasSize = UDim2.new(0,0,0,0)
		sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
		sf.ZIndex = 62; sf.Parent = p
		local ll = Instance.new("UIListLayout", sf)
		ll.Padding = UDim.new(0, 6); ll.SortOrder = Enum.SortOrder.LayoutOrder

		local function tutupPanel()
			TS:Create(p, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
			TS:Create(bg, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
			task.delay(0.16, function() sg:Destroy() end)
		end
		tutup.MouseButton1Click:Connect(tutupPanel)
		bg.MouseButton1Click:Connect(tutupPanel)

		-- daftar pemain (kecuali diri sendiri)
		local ada = 0
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= plr then
				ada += 1
				local row = Instance.new("TextButton")
				row.Size = UDim2.new(1, -6, 0, M2 and 44 or 50)
				row.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
				row.BorderSizePixel = 0; row.Text = ""
				row.AutoButtonColor = false
				row.ZIndex = 63; row.Parent = sf
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
				local rs2 = Instance.new("UIStroke", row)
				rs2.Color = Color3.fromRGB(60, 70, 90); rs2.Thickness = 1

				local avSz = M2 and 32 or 36
				local av = Instance.new("ImageLabel")
				av.Size = UDim2.fromOffset(avSz, avSz)
				av.Position = UDim2.new(0, 8, 0.5, -avSz/2)
				av.BackgroundColor3 = Color3.fromRGB(30, 34, 44)
				av.BorderSizePixel = 0
				av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. other.UserId .. "&w=150&h=150"
				av.ZIndex = 64; av.Parent = row
				Instance.new("UICorner", av).CornerRadius = UDim.new(1, 0)

				local nm = Instance.new("TextLabel")
				nm.Size = UDim2.new(1, -(avSz + 20), 1, 0)
				nm.Position = UDim2.new(0, avSz + 14, 0, 0)
				nm.BackgroundTransparency = 1
				nm.Text = other.DisplayName
				nm.TextColor3 = Color3.fromRGB(235, 242, 255)
				nm.Font = Enum.Font.GothamBold
				nm.TextSize = M2 and 13 or 14
				nm.TextXAlignment = Enum.TextXAlignment.Left
				nm.TextTruncate = Enum.TextTruncate.AtEnd
				nm.ZIndex = 64; nm.Parent = row

				row.MouseEnter:Connect(function() row.BackgroundColor3 = Color3.fromRGB(32, 24, 40) end)
				row.MouseLeave:Connect(function() row.BackgroundColor3 = Color3.fromRGB(20, 24, 34) end)
				-- [P59] cek punya: tandai kalau sudah memiliki item ini
				local sudahPunya = false
				task.spawn(function()
					local rf = DF and DF:FindFirstChild("CekKepemilikan")
					if not rf then return end
					local ok, punya = pcall(function() return rf:InvokeServer(other.UserId) end)
					if not (ok and type(punya) == "table") then return end
					if punya[kunci] then
						sudahPunya = true
						rs2.Color = Color3.fromRGB(60, 200, 120)
						row.BackgroundColor3 = Color3.fromRGB(14, 26, 20)
						nm.TextColor3 = Color3.fromRGB(150, 165, 180)
						local tanda = Instance.new("TextLabel")
						tanda.Name = "SudahPunya"
						tanda.Size = UDim2.fromOffset(70, 20)
						tanda.AnchorPoint = Vector2.new(1, 0.5)
						tanda.Position = UDim2.new(1, -10, 0.5, 0)
						tanda.BackgroundColor3 = Color3.fromRGB(16, 44, 30)
						tanda.BorderSizePixel = 0
                        tanda.Text = "✓ Punya"
						tanda.TextColor3 = Color3.fromRGB(70, 225, 140)
						tanda.Font = Enum.Font.GothamBold
						tanda.TextSize = M2 and 10 or 11
						tanda.ZIndex = 65
						tanda.Parent = row
						Instance.new("UICorner", tanda).CornerRadius = UDim.new(0, 8)
					end
				end)

				row.MouseButton1Click:Connect(function()
					if sudahPunya then
						-- beri tahu, jangan lanjut ke pembelian
						local lama = nm.Text
						nm.Text = other.DisplayName .. "  —  sudah punya item ini!"
						nm.TextColor3 = Color3.fromRGB(255, 190, 80)
						task.delay(2, function()
							if nm and nm.Parent then
								nm.Text = lama
								nm.TextColor3 = Color3.fromRGB(150, 165, 180)
							end
						end)
						return
					end
					GiftIntentRE:FireServer(other.UserId, kunci)
					tutupPanel()
				end)
			end
		end

		if ada == 0 then
			local kosong = Instance.new("TextLabel")
			kosong.Size = UDim2.new(1, 0, 0, 60)
			kosong.BackgroundTransparency = 1
			kosong.Text = "Tidak ada pemain lain di server"
			kosong.TextColor3 = Color3.fromRGB(140, 150, 165)
			kosong.Font = Enum.Font.Gotham; kosong.TextSize = M2 and 12 or 13
			kosong.ZIndex = 63; kosong.Parent = sf
		end
	end

	-- notif gift untuk semua pemain
	if GiftNotifRE then
		GiftNotifRE.OnClientEvent:Connect(function(d)
			local M2 = UIS.TouchEnabled and not UIS.KeyboardEnabled
			local vp = workspace.CurrentCamera.ViewportSize
			local old = gui:FindFirstChild("ZayinGiftNotif")
			if old then old:Destroy() end

			local W = math.clamp(vp.X * (M2 and 0.9 or 0.32), 300, 460)
			local H = M2 and 78 or 88

			local sg2 = Instance.new("ScreenGui")
			sg2.Name = "ZayinGiftNotif"; sg2.ResetOnSpawn = false
			sg2.IgnoreGuiInset = true; sg2.DisplayOrder = 78; sg2.Parent = gui

			local c = Instance.new("Frame")
			c.Size = UDim2.fromOffset(W, H)
			c.AnchorPoint = Vector2.new(0.5, 0)
			c.Position = UDim2.new(0.5, 0, 0, -H - 20)
			c.BackgroundColor3 = Color3.fromRGB(16, 12, 22)
			c.BackgroundTransparency = 0.5
			c.BorderSizePixel = 0; c.Parent = sg2
			Instance.new("UICorner", c).CornerRadius = UDim.new(0, 14)
			local cs2 = Instance.new("UIStroke", c)
			cs2.Color = Color3.fromRGB(255, 130, 205); cs2.Thickness = 2

			local avSz = M2 and 44 or 50
			local ring = Instance.new("Frame")
			ring.Size = UDim2.fromOffset(avSz, avSz)
			ring.Position = UDim2.new(0, 12, 0.5, -avSz/2)
			ring.BackgroundColor3 = Color3.fromRGB(255, 130, 205)
			ring.BorderSizePixel = 0; ring.Parent = c
			Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
			local av2 = Instance.new("ImageLabel")
			av2.Size = UDim2.new(1, -4, 1, -4)
			av2.Position = UDim2.new(0, 2, 0, 2)
			av2.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
			av2.BorderSizePixel = 0
			av2.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(d.pengirimId or 0) .. "&w=150&h=150"
			av2.Parent = ring
			Instance.new("UICorner", av2).CornerRadius = UDim.new(1, 0)

			local xT = avSz + 22
			local t1 = Instance.new("TextLabel")
			t1.Size = UDim2.new(1, -xT - 14, 0, M2 and 20 or 22)
			t1.Position = UDim2.new(0, xT, 0, M2 and 14 or 17)
			t1.BackgroundTransparency = 1
			t1.Text = "🎁 " .. tostring(d.pengirim) .. " memberi hadiah!"
			t1.TextColor3 = Color3.fromRGB(255, 160, 220)
			t1.Font = Enum.Font.GothamBold
			t1.TextSize = M2 and 15 or 17
			t1.TextXAlignment = Enum.TextXAlignment.Left
			t1.TextTruncate = Enum.TextTruncate.AtEnd
			t1.Parent = c

			local t2 = Instance.new("TextLabel")
			t2.Size = UDim2.new(1, -xT - 14, 0, M2 and 18 or 20)
			t2.Position = UDim2.new(0, xT, 0, M2 and 36 or 42)
			t2.BackgroundTransparency = 1
			t2.Text = tostring(d.item) .. " untuk " .. tostring(d.penerima)
			t2.TextColor3 = Color3.fromRGB(230, 235, 245)
			t2.Font = Enum.Font.GothamBold
			t2.TextSize = M2 and 13 or 15
			t2.TextXAlignment = Enum.TextXAlignment.Left
			t2.TextTruncate = Enum.TextTruncate.AtEnd
			t2.Parent = c

			TS:Create(c, TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{Position = UDim2.new(0.5, 0, 0, M2 and 62 or 76)}):Play()
			task.wait(5)
			TS:Create(c, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
				{Position = UDim2.new(0.5, 0, 0, -H - 20)}):Play()
			task.wait(0.32)
			sg2:Destroy()
		end)
	end
end)