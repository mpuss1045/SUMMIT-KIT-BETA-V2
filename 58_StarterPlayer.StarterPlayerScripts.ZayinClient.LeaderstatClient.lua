-- ================================================================
-- LeaderstatClient v2.0
-- Fix: refreshConn = task.spawn (thread) → tidak bisa :Disconnect() → CRASH
--      Solusi: pakai flag isOpen + task.spawn loop, bukan simpan thread
-- Fix: Tombol X → tombol "Tutup" 
-- UI:  Panel geser ke kanan (tidak tumpuk tombol top-right)
-- UI:  Responsive mobile & PC
-- ================================================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local StarterGui        = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui", 10)
local camera      = workspace.CurrentCamera

local M = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

-- ── Helpers ──────────────────────────────────────────────────
local function make(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props) do obj[k] = v end
	if parent then obj.Parent = parent end
	return obj
end
local function addCorner(r, parent)
	make("UICorner", { CornerRadius = UDim.new(0, r) }, parent)
end
local function addStroke(color, thick, transp, parent)
	return make("UIStroke", { Color = color, Thickness = thick, Transparency = transp }, parent)
end
local function addGradient(colors, rotation, parent)
	local kps = {}
	for i, c in ipairs(colors) do
		kps[i] = ColorSequenceKeypoint.new((i - 1) / (#colors - 1), c)
	end
	make("UIGradient", { Color = ColorSequence.new(kps), Rotation = rotation or 0 }, parent)
end
local function addTextStroke(parent)
	make("UIStroke", { Color = Color3.new(0,0,0), Thickness = 1.5, Transparency = 0.2 }, parent)
end

-- ── Warna ─────────────────────────────────────────────────────
local C = {
	bg     = Color3.fromRGB(6,   10,  20),
	bg2    = Color3.fromRGB(10,  15,  30),
	bg3    = Color3.fromRGB(15,  22,  42),
	cyan   = Color3.fromRGB(0,  210, 255),
	violet = Color3.fromRGB(160,  80, 255),
	white  = Color3.new(1, 1, 1),
	red    = Color3.fromRGB(220,  50,  50),
	rowbg  = Color3.fromRGB(8,   13,  26),
	selfbg = Color3.fromRGB(0,  140, 220),
	black  = Color3.new(0, 0, 0),
	gold   = Color3.fromRGB(255, 215,   0),
	silver = Color3.fromRGB(200, 215, 230),
	bronze = Color3.fromRGB(205, 127,  50),
}
local MEDAL = { C.gold, C.silver, C.bronze }
local EMOJI = { "🥇", "🥈", "🥉" }

-- ── Ukuran responsif ──────────────────────────────────────────
-- Konstanta tombol top-right (sama persis dengan ZayinMenuBaru)
local TR_SIZE  = M and 36 or 42
local TR_GAP   = M and 6  or 8
local TR_TOP   = M and 8  or 10
local TR_RIGHT = M and 8  or 12
-- Margin kanan panel = rata dengan tombol 👁️ (paling kanan, order=1)
local PANEL_MARGIN_RIGHT = TR_RIGHT
-- Y tepat di bawah tombol, jarak minimal
local PANEL_TOP = math.floor(TR_SIZE / 2)

local function getFrameSize()
	local vp = camera.ViewportSize
	local w, h
	if M then
		-- Mobile: lebar ~90% layar, cukup besar tapi ada margin kiri
		w = math.clamp(vp.X * 0.88, 220, vp.X - 16)
		h = math.clamp(vp.Y * 0.52, 240, 420)
	else
		-- PC: lebar ~22% viewport
		w = math.clamp(vp.X * 0.22, 260, 420)
		h = math.clamp(vp.Y * 0.52, 300, 560)
	end
	return math.floor(w), math.floor(h)
end

-- Pakai AnchorPoint (1,0) → posisi dari kanan, tidak pernah terpotong
local function getFrameAnchor()
	return Vector2.new(1, 0)
end

local function getFramePos(w, h)
	-- AnchorPoint (1,0): X=1 berarti ujung kanan panel di posisi ini
	-- Kita mau ujung kanan panel = vp.X - PANEL_MARGIN_RIGHT
	-- Dalam UDim2 dengan AnchorPoint(1,0): Position.X.Scale=1, Offset=-PANEL_MARGIN_RIGHT
	return UDim2.new(1, -PANEL_MARGIN_RIGHT, 0, PANEL_TOP)
end

-- ── ScreenGui ─────────────────────────────────────────────────
local ScreenGui = make("ScreenGui", {
	Name           = "CustomLeaderstatGui",
	ResetOnSpawn   = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder   = 99,
}, PlayerGui)

-- ── MainFrame ─────────────────────────────────────────────────
local W, H = getFrameSize()

local MainFrame = make("Frame", {
	Name                   = "MainFrame",
	Size                   = UDim2.fromOffset(W, H),
	AnchorPoint            = getFrameAnchor(),
	Position               = getFramePos(W, H),
	BackgroundColor3       = C.bg,
	BackgroundTransparency = 0.08,
	BorderSizePixel        = 0,
	Visible                = false,
	ZIndex                 = 2,
}, ScreenGui)
addCorner(14, MainFrame)
addStroke(C.cyan, 1.5, 0.25, MainFrame)
addGradient({
	Color3.fromRGB(0,18,40),
	Color3.fromRGB(8,12,28),
	Color3.fromRGB(22,5,45)
}, 140, MainFrame)

local topLine = make("Frame", {
	Size             = UDim2.new(1,-28,0,2),
	Position         = UDim2.new(0,14,0,38),
	BackgroundColor3 = C.cyan,
	BorderSizePixel  = 0,
	ZIndex           = 5,
}, MainFrame)
addGradient({ C.black, C.cyan, C.violet, C.black }, 0, topLine)

-- ── Header ────────────────────────────────────────────────────
local HDR_H = M and 42 or 38

local Header = make("Frame", {
	Size                   = UDim2.new(1, 0, 0, HDR_H),
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	ZIndex                 = 4,
}, MainFrame)

local TitleLbl = make("TextLabel", {
	Size                    = UDim2.new(1, -90, 1, 0),
	Position                = UDim2.new(0, 14, 0, 0),
	BackgroundTransparency  = 1,
	Text                    = "⛰  LEADERBOARD",
	Font                    = Enum.Font.GothamBold,
	TextSize                = M and 12 or 14,
	TextColor3              = C.cyan,
	TextXAlignment          = Enum.TextXAlignment.Left,
	ZIndex                  = 5,
}, Header)
addGradient({ C.cyan, C.violet, C.cyan }, 0, TitleLbl)

-- Tombol Tutup — style sama dengan Main Menu, font normal
local TutupBtn = make("TextButton", {
	Name                   = "TutupBtn",
	Size                   = UDim2.new(0, M and 52 or 58, 0, M and 22 or 26),
	AnchorPoint            = Vector2.new(1, 0.5),
	Position               = UDim2.new(1, -10, 0.5, 0),
	BackgroundColor3       = Color3.fromRGB(32, 10, 10),
	BackgroundTransparency = 0,
	BorderSizePixel        = 0,
	Text                   = "Tutup",
	Font                   = Enum.Font.Gotham,   -- normal, bukan Bold
	TextSize               = M and 9 or 11,
	TextColor3             = Color3.fromRGB(255, 75, 75),
	AutoButtonColor        = false,
	ZIndex                 = 6,
}, Header)
addCorner(12, TutupBtn)
addStroke(Color3.fromRGB(255, 75, 75), 1, 0, TutupBtn)

TutupBtn.MouseEnter:Connect(function()
	TweenService:Create(TutupBtn, TweenInfo.new(0.12),
		{ BackgroundColor3 = Color3.fromRGB(55, 14, 14) }):Play()
end)
TutupBtn.MouseLeave:Connect(function()
	TweenService:Create(TutupBtn, TweenInfo.new(0.12),
		{ BackgroundColor3 = Color3.fromRGB(32, 10, 10) }):Play()
end)

-- ── Guide Top Bar ─────────────────────────────────────────────
local TOPBAR_H = M and 22 or 24

local TopBar = make("Frame", {
	Size                   = UDim2.new(1, -16, 0, TOPBAR_H),
	Position               = UDim2.new(0, 8, 0, HDR_H + 4),
	BackgroundColor3       = C.bg2,
	BackgroundTransparency = 0.2,
	BorderSizePixel        = 0,
	ZIndex                 = 4,
}, MainFrame)
addCorner(6, TopBar)
addStroke(C.cyan, 0.8, 0.55, TopBar)

local COLS_SCALE = {
	{ text="NO",     x=0,    w=0.12 },
	{ text="PLAYER", x=0.12, w=0.26 },
	{ text="POSISI", x=0.38, w=0.20 },
	{ text="SUMMIT", x=0.58, w=0.20 },
	{ text="TIME",   x=0.78, w=0.22 },
}
for _, col in ipairs(COLS_SCALE) do
	make("TextLabel", {
		Size                   = UDim2.new(col.w, 0, 1, 0),
		Position               = UDim2.new(col.x, 0, 0, 0),
		BackgroundTransparency = 1,
		Text                   = col.text,
		Font                   = Enum.Font.GothamBold,
		TextSize               = M and 8 or 10,
		TextColor3             = C.cyan,
		TextXAlignment         = Enum.TextXAlignment.Center,
		ZIndex                 = 5,
	}, TopBar)
end

local hLine = make("Frame", {
	Size             = UDim2.new(1, 0, 0, 1),
	Position         = UDim2.new(0, 0, 1, -1),
	BackgroundColor3 = C.cyan,
	BorderSizePixel  = 0,
	ZIndex           = 6,
}, TopBar)
addGradient({ C.black, C.cyan, C.black }, 0, hLine)

-- ── ScrollFrame ───────────────────────────────────────────────
local SCROLL_Y = HDR_H + 4 + TOPBAR_H + 5

local ScrollFrame = make("ScrollingFrame", {
	Size                       = UDim2.new(1, -16, 1, -(SCROLL_Y + 8)),
	Position                   = UDim2.new(0, 8, 0, SCROLL_Y),
	BackgroundTransparency     = 1,
	BorderSizePixel            = 0,
	ScrollBarThickness         = M and 3 or 4,
	ScrollBarImageColor3       = C.cyan,
	ScrollBarImageTransparency = 0.35,
	CanvasSize                 = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize        = Enum.AutomaticSize.Y,
	ScrollingDirection         = Enum.ScrollingDirection.Y,
	ElasticBehavior            = Enum.ElasticBehavior.Never,
	ZIndex                     = 3,
}, MainFrame)

make("UIListLayout", {
	Padding             = UDim.new(0, M and 4 or 5),
	SortOrder           = Enum.SortOrder.LayoutOrder,
	FillDirection       = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
}, ScrollFrame)
make("UIPadding", {
	PaddingTop    = UDim.new(0, 4),
	PaddingBottom = UDim.new(0, 4),
	PaddingLeft   = UDim.new(0, 2),
	PaddingRight  = UDim.new(0, 2),
}, ScrollFrame)

-- ── Build Row ─────────────────────────────────────────────────
local ROW_H = M and 52 or 60

local function buildRow()
	local row = make("Frame", {
		Size             = UDim2.new(1, -4, 0, ROW_H),
		BackgroundColor3 = C.rowbg,
		BackgroundTransparency = 0.12,
		BorderSizePixel  = 0,
		ClipsDescendants = true,
		ZIndex           = 3,
	})
	addCorner(10, row)
	local rowStroke = addStroke(C.cyan, 1.2, 0.55, row)

	-- Avatar background
	local avatarBG = make("ImageLabel", {
		Name                = "AvatarBG",
		Size                = UDim2.new(0.26, 0, 1, 0),
		Position            = UDim2.new(0.14, 0, 0, 0),
		BackgroundTransparency = 1,
		ImageTransparency   = 0.25,
		ScaleType           = Enum.ScaleType.Crop,
		ZIndex              = 1,
	}, row)
	make("UIGradient", { Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})}, avatarBG)

	-- Avatar circle
	local avSize = M and 28 or 32
	local avatarThumb = make("ImageLabel", {
		Name             = "AvatarThumb",
		Size             = UDim2.fromOffset(avSize, avSize),
		Position         = UDim2.new(0.27, -avSize/2, 0, M and 3 or 4),
		BackgroundColor3 = C.bg3,
		BorderSizePixel  = 0,
		ZIndex           = 4,
	}, row)
	addCorner(100, avatarThumb)
	addStroke(C.cyan, 1.8, 0.1, avatarThumb)

	-- Nama player
	local nameVal = make("TextLabel", {
		Name             = "NameValue",
		Size             = UDim2.new(0.30, 0, 0, M and 11 or 13),
		Position         = UDim2.new(0.12, 0, 1, M and -22 or -26),
		BackgroundTransparency = 1,
		Text             = "Player",
		Font             = Enum.Font.GothamBold,
		TextSize         = M and 8 or 10,
		TextColor3       = C.cyan,
		TextScaled       = false,
		TextXAlignment   = Enum.TextXAlignment.Center,
		TextTruncate     = Enum.TextTruncate.AtEnd,
		ZIndex           = 5,
	}, row)
	addTextStroke(nameVal)

	-- NO
	local noVal = make("TextLabel", {
		Name           = "NoValue",
		Size           = UDim2.new(0.14, 0, 1, 0),
		BackgroundTransparency = 1,
		Text           = "#?",
		Font           = Enum.Font.GothamBold,
		TextColor3     = C.white,
		TextScaled     = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex         = 5,
	}, row)
	addTextStroke(noVal)
	make("UITextSizeConstraint", { MaxTextSize = M and 15 or 18, MinTextSize = 7 }, noVal)

	-- POSISI
	local posVal = make("TextLabel", {
		Name           = "PosisiValue",
		Size           = UDim2.new(0.22, 0, 1, 0),
		Position       = UDim2.new(0.40, 0, 0, 0),
		BackgroundTransparency = 1,
		Text           = "BC",
		Font           = Enum.Font.Gotham,
		TextColor3     = C.white,
		TextScaled     = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex         = 5,
	}, row)
	addTextStroke(posVal)
	make("UITextSizeConstraint", { MaxTextSize = M and 10 or 12, MinTextSize = 6 }, posVal)

	-- SUMMIT
	local sumVal = make("TextLabel", {
		Name           = "SummitValue",
		Size           = UDim2.new(0.19, 0, 1, 0),
		Position       = UDim2.new(0.62, 0, 0, 0),
		BackgroundTransparency = 1,
		Text           = "0",
		Font           = Enum.Font.GothamBold,
		TextColor3     = C.white,
		TextScaled     = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex         = 5,
	}, row)
	addTextStroke(sumVal)
	make("UITextSizeConstraint", { MaxTextSize = M and 14 or 18, MinTextSize = 7 }, sumVal)

	-- TIME
	local btVal = make("TextLabel", {
		Name           = "BestTimeValue",
		Size           = UDim2.new(0.19, 0, 1, 0),
		Position       = UDim2.new(0.81, 0, 0, 0),
		BackgroundTransparency = 1,
		Text           = "--:--",
		Font           = Enum.Font.Code,
		TextColor3     = C.white,
		TextScaled     = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex         = 5,
	}, row)
	addTextStroke(btVal)
	make("UITextSizeConstraint", { MaxTextSize = M and 10 or 13, MinTextSize = 6 }, btVal)

	-- Accent line bawah
	local accLine = make("Frame", {
		Name             = "AccentLine",
		Size             = UDim2.new(1, 0, 0, 2),
		Position         = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = C.cyan,
		BackgroundTransparency = 0.5,
		BorderSizePixel  = 0,
		ZIndex           = 6,
	}, row)
	addGradient({ C.black, C.cyan, C.violet, C.black }, 0, accLine)

	-- Self highlight
	local selfHL = make("Frame", {
		Name             = "SelfHL",
		Size             = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(0, 140, 220),
		BackgroundTransparency = 0.84,
		BorderSizePixel  = 0,
		Visible          = false,
		ZIndex           = 2,
	}, row)
	addCorner(10, selfHL)

	-- [P37] Role di bawah nickname
	local roleVal = make("TextLabel", {
		Name             = "RoleValue",
		Size             = UDim2.new(0.30, 0, 0, M and 9 or 11),
		Position         = UDim2.new(0.12, 0, 1, M and -11 or -13),
		BackgroundTransparency = 1,
		Text             = "",
		Font             = Enum.Font.GothamBold,
		TextSize         = M and 7 or 8,
		TextColor3       = Color3.fromRGB(160, 170, 185),
		TextXAlignment   = Enum.TextXAlignment.Center,
		TextTruncate     = Enum.TextTruncate.AtEnd,
		ZIndex           = 6,
	}, row)
	addTextStroke(roleVal)

	return row, rowStroke, accLine
end

-- ── State ─────────────────────────────────────────────────────
local isOpen    = false
local rowCache  = {}
local thumbCache = {}
-- FIX: refreshConn simpan sebagai boolean flag, bukan thread/connection
-- Loop update jalan selama isOpen = true
local refreshLoopRunning = false

local function Fmt(n)
	if type(n) ~= "number" then return tostring(n) end
	local s = tostring(math.floor(n)):reverse()
	s = s:gsub("(%d%d%d)", "%1,")
	return s:reverse():gsub("^,", "")
end

local function CollectData()
	local list = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		local ls  = plr:FindFirstChild("leaderstats")
		local sum = ls and ls:FindFirstChild("Summit")
		local cp  = ls and ls:FindFirstChild("Posisi")
		local bt  = ls and ls:FindFirstChild("BestTime")
		local don = ls and ls:FindFirstChild("Donation")
		table.insert(list, {
			displayName = plr.DisplayName,
			userId      = plr.UserId,
			roleId      = plr:GetAttribute("RoleId"),
			isVIP       = plr:GetAttribute("IsVIP") == true,
			donation    = don and don.Value or 0,
			summit      = sum and sum.Value or 0,
			cp          = cp  and cp.Value  or "Basecamp",
			bestTime    = bt  and bt.Value  or "--:--",
			isSelf      = (plr == LocalPlayer),
		})
	end
	table.sort(list, function(a, b) return a.summit > b.summit end)
	return list
end

local function LoadAvatar(userId, imgBG, imgThumb)
	if thumbCache[userId] then
		if imgBG    then imgBG.Image    = thumbCache[userId] end
		if imgThumb then imgThumb.Image = thumbCache[userId] end
		return
	end
	task.spawn(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(
				userId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size420x420
			)
		end)
		if ok and img then
			thumbCache[userId] = img
			if imgBG    and imgBG.Parent    then imgBG.Image    = img end
			if imgThumb and imgThumb.Parent then imgThumb.Image = img end
		end
	end)
end

local function UpdateRows()
	local data  = CollectData()
	local total = #data

	for i = 1, total do
		if not rowCache[i] then
			local row, sk, al = buildRow()
			row.Name        = "Row_" .. i
			row.LayoutOrder = i
			row.Visible     = true
			row.Parent      = ScrollFrame
			rowCache[i]     = { row = row, stroke = sk, accLine = al }
		end
	end

	for rank = 1, total do
		local e   = data[rank]
		local rc  = rowCache[rank]
		local row = rc.row
		row.Visible     = true
		row.LayoutOrder = rank

		local ab = row:FindFirstChild("AvatarBG")
		local at = row:FindFirstChild("AvatarThumb")
		if ab and at then LoadAvatar(e.userId, ab, at) end

		local noV = row:FindFirstChild("NoValue")
		if noV then noV.Text = EMOJI[rank] or ("#"..rank) end

		local nmV = row:FindFirstChild("NameValue")
		if nmV then nmV.Text = e.displayName end

		-- [P35] isi role
		local roleV = row:FindFirstChild("RoleValue")
		if roleV then
			local GCok, GC = pcall(function()
				return require(game:GetService("ReplicatedStorage").ZayinConfig.GameConfig)
			end)
			local peta = (GCok and GC and GC.LeaderstatRoles) or {}
			-- [P57] staff tetap rolenya; pemain biasa ber-VIP tampil "VIP"
			local conf = (e.roleId and peta[e.roleId])
				or (e.isVIP and peta.VIP)
				or peta.Default
			if conf then
				roleV.Text = conf.Text
				roleV.TextColor3 = conf.Color
			else
				roleV.Text = ""
			end
		end

		local posV = row:FindFirstChild("PosisiValue")
		if posV then
			local cp = tostring(e.cp or "")
				:gsub("Basecamp", "BC")
				:gsub("[Cc]heckpoint", "CP")
				:gsub("[Ss]ummit", "Sum")
			posV.Text = cp
		end

		local sumV = row:FindFirstChild("SummitValue")
		if sumV then sumV.Text = Fmt(e.summit) end

		local btV = row:FindFirstChild("BestTimeValue")
		if btV then btV.Text = e.bestTime end

		local sh = row:FindFirstChild("SelfHL")
		if sh then sh.Visible = e.isSelf end

		local sk = rc.stroke
		if sk then
			if e.isSelf then
				sk.Color = C.cyan; sk.Transparency = 0.05; sk.Thickness = 2
			elseif rank <= 3 then
				sk.Color = MEDAL[rank]; sk.Transparency = 0.2; sk.Thickness = 1.5
			else
				sk.Color = C.cyan; sk.Transparency = 0.6; sk.Thickness = 1.2
			end
		end

		local al = rc.accLine
		if al then
			local alg = al:FindFirstChildOfClass("UIGradient")
			if alg then
				local mid  = MEDAL[rank] or C.cyan
				local mid2 = rank == 1 and Color3.fromRGB(255,150,0) or C.violet
				alg.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0,   C.black),
					ColorSequenceKeypoint.new(0.3, mid),
					ColorSequenceKeypoint.new(0.7, mid2),
					ColorSequenceKeypoint.new(1,   C.black),
				})
			end
		end
	end

	for i = total + 1, #rowCache do
		if rowCache[i] then rowCache[i].row.Visible = false end
	end
end

_G.ZayinRefreshLeaderstat = UpdateRows -- [P36]

-- ── Open / Close ──────────────────────────────────────────────
local TWEEN_IN  = 0.25
local TWEEN_OUT = 0.18

local function CloseFrame()
	if not isOpen then return end
	isOpen = false

	local w, h = getFrameSize()
	TweenService:Create(MainFrame,
		TweenInfo.new(TWEEN_OUT, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
		{ Size = UDim2.fromOffset(w, 0), BackgroundTransparency = 1 }
	):Play()
	task.delay(TWEEN_OUT + 0.02, function()
		MainFrame.Visible = false
	end)
end

local function OpenFrame()
	if isOpen then return end
	local w, h = getFrameSize()
	-- Posisi tetap dari kanan via AnchorPoint(1,0)
	MainFrame.AnchorPoint            = getFrameAnchor()
	MainFrame.Position               = getFramePos(w, h)
	MainFrame.Size                   = UDim2.fromOffset(w, 0)
	MainFrame.BackgroundTransparency = 1
	MainFrame.Visible                = true
	UpdateRows()
	TweenService:Create(MainFrame,
		TweenInfo.new(TWEEN_IN, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(w, h), BackgroundTransparency = 0.08 }
	):Play()
	isOpen = true

	if not refreshLoopRunning then
		refreshLoopRunning = true
		task.spawn(function()
			while true do
				task.wait(3)
				if not isOpen then
					refreshLoopRunning = false
					break
				end
				UpdateRows()
			end
		end)
	end
end

local function ToggleFrame()
	if isOpen then CloseFrame() else OpenFrame() end
end

-- ── Tombol Tutup ──────────────────────────────────────────────
TutupBtn.MouseButton1Click:Connect(CloseFrame)

-- ── CloseAllUIs event ─────────────────────────────────────────
local closeEvent = ReplicatedStorage:FindFirstChild("CloseAllUIs")
if closeEvent then
	closeEvent.Event:Connect(function(source)
		if source ~= "Leaderstat" and isOpen then CloseFrame() end
	end)
end

-- ── Tab key (PC) ──────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Tab then
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		end)
		ToggleFrame()
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Tab then
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		end)
	end
end)

-- ── ToggleRequest attribute dari ZayinMenuBaru (tombol 🏆) ────
ScreenGui:GetAttributeChangedSignal("ToggleRequest"):Connect(function()
	ToggleFrame()
end)

-- ── Expose isOpen untuk ZayinMenuBaru sync ────────────────────
ScreenGui:SetAttribute("IsOpen", false)
-- Update attribute saat state berubah
local _origOpen  = OpenFrame
local _origClose = CloseFrame
OpenFrame = function()
	_origOpen()
	ScreenGui:SetAttribute("IsOpen", true)
end
CloseFrame = function()
	_origClose()
	ScreenGui:SetAttribute("IsOpen", false)
end
-- Re-bind
-- [PATCH] duplikat koneksi TutupBtn dihapus (koneksi pertama otomatis pakai versi wrap)

-- ── Realtime listener (Changed event) ─────────────────────────
local function ListenPlayer(plr)
	task.spawn(function()
		local ls = plr:WaitForChild("leaderstats", 15)
		if not ls then return end
		local function connectVal(name)
			local val = ls:WaitForChild(name, 10)
			if not val then return end
			val:GetPropertyChangedSignal("Value"):Connect(function()
				if isOpen then UpdateRows() end
			end)
		end
		connectVal("Posisi")   -- FIX: was "CP"
		connectVal("Summit")
		connectVal("BestTime") -- FIX: was "Best Time"
	end)
end

for _, plr in ipairs(Players:GetPlayers()) do ListenPlayer(plr) end
Players.PlayerAdded:Connect(ListenPlayer)

-- ── Cleanup thumbCache saat player keluar ─────────────────────
Players.PlayerRemoving:Connect(function(player)
	thumbCache[player.UserId] = nil
	if isOpen then task.defer(UpdateRows) end
end)

-- ── Resize responsif saat viewport berubah ───────────────────
camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if isOpen then
		local w, h = getFrameSize()
		MainFrame.AnchorPoint = getFrameAnchor()
		MainFrame.Position    = getFramePos(w, h)
		MainFrame.Size        = UDim2.fromOffset(w, h)
	end
end)

-- ── Native PlayerList selalu OFF ──────────────────────────────
task.spawn(function()
	-- Cukup sekali saat init, bukan loop
	for i = 1, 3 do
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		end)
		task.wait(1)
	end
end)

print("[LeaderstatClient v2.0] Ready! Mobile:", M)

-- [P9] pantau perubahan leaderstats: nilai awal sering tiba setelah UI dibangun
task.spawn(function()
	local plr = game:GetService("Players").LocalPlayer
	local ls  = plr:WaitForChild("leaderstats", 20)
	if not ls then return end
	for _, nama in ipairs({"Summit", "BestTime", "Posisi"}) do
		local v = ls:FindFirstChild(nama)
		if v then
			v.Changed:Connect(function()
				local f = _G.ZayinRefreshLeaderstat
				if type(f) == "function" then pcall(f) end
			end)
		end
	end
end)

-- [P35] online counter — update jumlah pemain di header LEADERBOARD
task.spawn(function()
	local Players = game:GetService("Players")
	local gui = LocalPlayer:WaitForChild("PlayerGui")
	local function cariHeader()
		for _, d in ipairs(gui:GetDescendants()) do
			if d:IsA("TextLabel") and d.Text:find("LEADERBOARD", 1, true) then
				return d
			end
		end
	end
	local header = cariHeader()
	for _ = 1, 20 do
		if header then break end
		task.wait(0.5); header = cariHeader()
	end
	if not header then return end
	local function refresh()
		header.Text = "⛰  LEADERBOARD   ·   PLAYER ONLINE " .. #Players:GetPlayers()
	end
	Players.PlayerAdded:Connect(refresh)
	Players.PlayerRemoving:Connect(function() task.wait(0.1); refresh() end)
	refresh()
end)

-- [P36] pantau role: RoleId sering ter-set OverheadServer SETELAH panel dibuka.
-- Pantau attribute tiap pemain, refresh baris saat role berubah.
task.spawn(function()
	local Players = game:GetService("Players")
	local function pantau(p)
		p:GetAttributeChangedSignal("RoleId"):Connect(function()
			-- panggil ulang pengisi baris kalau fungsinya global; kalau tidak, trigger via event kecil
			if type(_G.ZayinRefreshLeaderstat) == "function" then
				pcall(_G.ZayinRefreshLeaderstat)
			end
		end)
	end
	for _, p in ipairs(Players:GetPlayers()) do pantau(p) end
	Players.PlayerAdded:Connect(pantau)
end)