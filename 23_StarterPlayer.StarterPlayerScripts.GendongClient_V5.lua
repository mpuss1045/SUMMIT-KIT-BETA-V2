-- ============================================================
-- GendongClient_V6.lua
-- Lokasi: StarterGui > GendongGUI (LocalScript)
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)
local mouse     = player:GetMouse()
local camera    = workspace.CurrentCamera

-- ─── Remotes ─────────────────────────────────────────────────────────────────
local CarryRemote   = ReplicatedStorage:WaitForChild("CarryRemote", 15)
local SyncingFolder = ReplicatedStorage:FindFirstChild("Syncing")
	or ReplicatedStorage:WaitForChild("Syncing", 10)
local SyncEvent, UnSyncEvent
if SyncingFolder then
	SyncEvent   = SyncingFolder:FindFirstChild("Sync")   or SyncingFolder:WaitForChild("Sync",   8)
	UnSyncEvent = SyncingFolder:FindFirstChild("UnSync") or SyncingFolder:WaitForChild("UnSync", 8)
end

-- ─── Animation ID ────────────────────────────────────────────────────────────
local ANIM_SIT_R15   = 0
local ANIM_SIT_R6    = 0
local ANIM_CARRY_R15 = 0
local ANIM_CARRY_R6  = 0

-- ─── Platform ────────────────────────────────────────────────────────────────
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ─── Hapus GUI lama ──────────────────────────────────────────────────────────
for _, name in ipairs({"GendongUI_V2","GendongUI_V3","GendongUI_V4","GendongUI_V5","GendongUI_V6"}) do
	local old = playerGui:FindFirstChild(name)
	if old then old:Destroy() end
end
local gGui = script.Parent and script.Parent:IsA("ScreenGui") and script.Parent or nil
if gGui then
	for _, n in ipairs({"Frame2","Frame3"}) do
		local f = gGui:FindFirstChild(n); if f then f:Destroy() end
	end
end

-- ─── ScreenGui ───────────────────────────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "GendongUI_V6"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent         = playerGui

-- ─── Helper ──────────────────────────────────────────────────────────────────
local function make(class, props, parent)
	local obj = Instance.new(class)
	for k,v in pairs(props) do obj[k] = v end
	if parent then obj.Parent = parent end
	return obj
end
local function corner(r,p) make("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function stroke(c,t,p)
	local s = make("UIStroke",{Color=c,Thickness=t},p)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
end
local function pad(t,b,l,r,p)
	make("UIPadding",{
		PaddingTop=UDim.new(0,t),PaddingBottom=UDim.new(0,b),
		PaddingLeft=UDim.new(0,l),PaddingRight=UDim.new(0,r),
	},p)
end
local function tw(obj,info,props) TweenService:Create(obj,info,props):Play() end

local TF  = TweenInfo.new(0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
local TFB = TweenInfo.new(0.20,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
local TFI = TweenInfo.new(0.12,Enum.EasingStyle.Quad,Enum.EasingDirection.In)

-- Ukuran responsif
local function rs(pc, mob) return isMobile and mob or pc end

local C = {
	BG     = Color3.fromRGB(15,15,23),
	BG2    = Color3.fromRGB(22,22,34),
	SURF   = Color3.fromRGB(34,34,50),
	SURF2  = Color3.fromRGB(44,44,64),
	ACC    = Color3.fromRGB(99,102,241),
	ACC2   = Color3.fromRGB(139,92,246),
	GREEN  = Color3.fromRGB(34,197,94),
	RED    = Color3.fromRGB(239,68,68),
	YELLOW = Color3.fromRGB(234,179,8),
	ORANGE = Color3.fromRGB(249,115,22),
	BLUE   = Color3.fromRGB(59,130,246),
	TEXT   = Color3.fromRGB(235,235,255),
	MUTED  = Color3.fromRGB(130,130,165),
	WHITE  = Color3.fromRGB(255,255,255),
	BORDER = Color3.fromRGB(50,50,75),
}

-- ═══════════════════════════════════════════════════════
-- TRUSTED LIST — auto carry tanpa acc
-- ═══════════════════════════════════════════════════════
local trustedPlayers = {}  -- {[userId] = displayName}

local function isTrusted(uid)
	return trustedPlayers[uid] ~= nil
end

-- ═══════════════════════════════════════════════════════
-- MENU POPUP — tengah layar
-- ═══════════════════════════════════════════════════════
local Overlay = make("Frame",{
	Name="Overlay", Size=UDim2.new(1,0,1,0),
	BackgroundColor3=Color3.new(0,0,0),
	BackgroundTransparency=1, ZIndex=18, Visible=false,
},ScreenGui)

local MENU_W = rs(270,295)

local Menu = make("Frame",{
	Name="Menu",
	Size=UDim2.new(0,MENU_W,0,50),
	AnchorPoint=Vector2.new(0.5,0.5),
	Position=UDim2.new(0.5,0,0.5,0),
	BackgroundColor3=C.BG2, BorderSizePixel=0,
	ZIndex=19, Visible=false,
},ScreenGui)
corner(18,Menu); stroke(C.ACC,1.2,Menu)

-- Topbar menu
local TopBar = make("Frame",{
	Size=UDim2.new(1,0,0,rs(68,74)),
	BackgroundColor3=C.ACC, BorderSizePixel=0, ZIndex=20,
},Menu)
corner(18,TopBar)
make("Frame",{
	Size=UDim2.new(1,0,0.5,0),Position=UDim2.new(0,0,0.5,0),
	BackgroundColor3=C.ACC, BorderSizePixel=0, ZIndex=20,
},TopBar)

-- Avatar thumbnail (ImageLabel untuk foto profil Roblox)
local AvatarFrame = make("Frame",{
	Size=UDim2.new(0,rs(46,50),0,rs(46,50)),
	AnchorPoint=Vector2.new(0,0.5),
	Position=UDim2.new(0,12,0.5,0),
	BackgroundColor3=C.ACC2, BorderSizePixel=0, ZIndex=21,
},TopBar)
corner(rs(23,25),AvatarFrame)
stroke(Color3.fromRGB(255,255,255),1.5,AvatarFrame)

local AvatarImg = make("ImageLabel",{
	Size=UDim2.new(1,0,1,0),
	BackgroundTransparency=1,
	Image="",
	ZIndex=22,
},AvatarFrame)
corner(rs(23,25),AvatarImg)

-- Fallback teks inisial (muncul jika foto gagal load)
local AvatarFallback = make("TextLabel",{
	Size=UDim2.new(1,0,1,0),
	BackgroundTransparency=1,
	Text="?", TextColor3=C.WHITE,
	TextSize=rs(17,19), Font=Enum.Font.GothamBold, ZIndex=23,
},AvatarFrame)

local MenuName = make("TextLabel",{
	Size=UDim2.new(1,-rs(100,110),0,rs(20,22)),
	Position=UDim2.new(0,rs(66,70),0,rs(10,12)),
	BackgroundTransparency=1, Text="Player",
	TextColor3=C.WHITE, TextSize=rs(14,16),
	Font=Enum.Font.GothamBold,
	TextXAlignment=Enum.TextXAlignment.Left,
	TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=21,
},TopBar)

local MenuSub = make("TextLabel",{
	Size=UDim2.new(1,-rs(100,110),0,rs(14,16)),
	Position=UDim2.new(0,rs(66,70),0,rs(33,37)),
	BackgroundTransparency=1, Text="Pilih aksi",
	TextColor3=Color3.fromRGB(200,210,255),
	TextSize=rs(11,12), Font=Enum.Font.Gotham,
	TextXAlignment=Enum.TextXAlignment.Left, ZIndex=21,
},TopBar)

-- Tombol X tutup menu
local BtnCloseMenu = make("TextButton",{
	Size=UDim2.new(0,rs(28,32),0,rs(28,32)),
	AnchorPoint=Vector2.new(1,0.5),
	Position=UDim2.new(1,-8,0.5,0),
	BackgroundColor3=Color3.fromRGB(255,255,255),
	BackgroundTransparency=0.8,
	BorderSizePixel=0, Text="✕",
	TextColor3=C.WHITE, TextSize=rs(13,15),
	Font=Enum.Font.GothamBold, ZIndex=22,
},TopBar)
corner(rs(14,16),BtnCloseMenu)

-- Divider
make("Frame",{
	Size=UDim2.new(1,-24,0,1),
	Position=UDim2.new(0,12,0,rs(68,74)),
	BackgroundColor3=C.BORDER, BorderSizePixel=0, ZIndex=20,
},Menu)

-- Scroll area aksi
local BtnScroll = make("ScrollingFrame",{
	Size=UDim2.new(1,0,1,-rs(76,82)),
	Position=UDim2.new(0,0,0,rs(76,82)),
	BackgroundTransparency=1, BorderSizePixel=0,
	ScrollBarThickness=0, CanvasSize=UDim2.new(0,0,0,0),
	AutomaticCanvasSize=Enum.AutomaticSize.Y, ZIndex=20,
},Menu)
make("UIListLayout",{
	SortOrder=Enum.SortOrder.LayoutOrder,
	Padding=UDim.new(0,rs(5,7)),
},BtnScroll)
pad(rs(8,10),rs(10,12),rs(12,14),rs(12,14),BtnScroll)

local BTN_H = rs(42,48)

local ACTIONS = {
	{id="carry",     label="🤲  Gendong Player",    color=Color3.fromRGB(79,70,229),  order=1},
	{id="sync",      label="💃  Sync Dance / Emote", color=Color3.fromRGB(5,150,105),  order=2},
	{id="addfriend", label="➕  Tambah Teman",        color=Color3.fromRGB(37,99,235),  order=3},
	{id="stopcarry", label="🚫  Stop Carry",          color=Color3.fromRGB(185,28,28),  order=4},
	{id="stopsync",  label="⏹  Stop Sync Dance",     color=Color3.fromRGB(180,83,9),   order=5},
}

local aBtns = {}
for _, def in ipairs(ACTIONS) do
	local btn = make("TextButton",{
		Name=def.id,
		Size=UDim2.new(1,0,0,BTN_H),
		BackgroundColor3=def.color, BorderSizePixel=0,
		Text=def.label, TextColor3=C.WHITE,
		TextSize=rs(13,14), Font=Enum.Font.GothamSemibold,
		TextXAlignment=Enum.TextXAlignment.Left,
		LayoutOrder=def.order, ZIndex=21,
	},BtnScroll)
	corner(10,btn); pad(0,0,rs(12,14),0,btn)
	btn.MouseEnter:Connect(function()
		tw(btn,TF,{BackgroundColor3=def.color:Lerp(Color3.new(1,1,1),0.15)})
	end)
	btn.MouseLeave:Connect(function()
		tw(btn,TF,{BackgroundColor3=def.color})
	end)
	aBtns[def.id] = btn
end

-- ─── Trusted / Auto Carry Toggle di menu ──────────────────────────────────────
local TrustToggleFrame = make("Frame",{
	Size=UDim2.new(1,0,0,BTN_H),
	BackgroundColor3=C.SURF, BorderSizePixel=0,
	LayoutOrder=6, ZIndex=21,
},BtnScroll)
corner(10,TrustToggleFrame)

local TrustLabel = make("TextLabel",{
	Size=UDim2.new(1,-60,1,0), Position=UDim2.new(0,12,0,0),
	BackgroundTransparency=1,
	Text="⚡  Auto Carry (Percayai)",
	TextColor3=C.TEXT, TextSize=rs(12,13),
	Font=Enum.Font.GothamSemibold,
	TextXAlignment=Enum.TextXAlignment.Left, ZIndex=22,
},TrustToggleFrame)

local TrustToggleBtn = make("TextButton",{
	Size=UDim2.new(0,50,0,26),
	AnchorPoint=Vector2.new(1,0.5),
	Position=UDim2.new(1,-10,0.5,0),
	BackgroundColor3=C.SURF2, BorderSizePixel=0,
	Text="OFF", TextColor3=C.MUTED,
	TextSize=11, Font=Enum.Font.GothamBold, ZIndex=22,
},TrustToggleFrame)
corner(13,TrustToggleBtn)

-- ─── Daftar player yang sedang di-carry (hanya muncul saat carrier) ──────────
local CarriedListFrame = make("Frame",{
	Size=UDim2.new(1,0,0,0),
	BackgroundTransparency=1,
	BorderSizePixel=0,
	LayoutOrder=7, ZIndex=21,
	AutomaticSize=Enum.AutomaticSize.Y,
},BtnScroll)

local CarriedListLayout = make("UIListLayout",{
	SortOrder=Enum.SortOrder.LayoutOrder,
	Padding=UDim.new(0,4),
},CarriedListFrame)

local CarriedListTitle = make("TextLabel",{
	Size=UDim2.new(1,0,0,20),
	BackgroundTransparency=1,
	Text="Sedang digendong:",
	TextColor3=C.MUTED, TextSize=11,
	Font=Enum.Font.GothamBold,
	TextXAlignment=Enum.TextXAlignment.Left,
	LayoutOrder=0, ZIndex=22,
},CarriedListFrame)

-- ═══════════════════════════════════════════════════════
-- PROMPT PANEL — tengah layar dengan timer bar
-- ═══════════════════════════════════════════════════════
local PROMPT_W   = rs(310,300)
local PROMPT_TIMEOUT = 10

local PromptPanel = make("Frame",{
	Name="PromptPanel",
	Size=UDim2.new(0,PROMPT_W,0,rs(148,155)),
	AnchorPoint=Vector2.new(0.5,0.5),
	Position=UDim2.new(0.5,0,-0.4,0),
	BackgroundColor3=C.BG2, BorderSizePixel=0,
	ZIndex=22, Visible=false,
},ScreenGui)
corner(16,PromptPanel)
stroke(C.ACC,2,PromptPanel)
PromptPanel.BackgroundTransparency = 0.06

-- Header
local PHeader = make("Frame",{
	Size=UDim2.new(1,0,0,rs(44,48)),
	BackgroundTransparency=1, BorderSizePixel=0, ZIndex=23,
},PromptPanel)
-- [P79] garis aksen tipis pengganti header blok
make("Frame",{
	Size=UDim2.new(1,-36,0,3), Position=UDim2.new(0,18,0,0),
	BackgroundColor3=C.ACC, BorderSizePixel=0, ZIndex=24,
},PromptPanel)
-- [P79] blok header ungu dihapus

make("TextLabel",{
	Size=UDim2.new(1,-20,1,0), Position=UDim2.new(0,14,0,0),
	BackgroundTransparency=1, Text="Permintaan Gendong",
	TextColor3=C.ACC, TextSize=rs(13,15),
	Font=Enum.Font.GothamBold,
	TextXAlignment=Enum.TextXAlignment.Left, ZIndex=24,
},PHeader)

-- Pesan
local PromptLbl = make("TextLabel",{
	Size=UDim2.new(1,-24,0,rs(36,40)),
	Position=UDim2.new(0,12,0,rs(50,54)),
	BackgroundTransparency=1, Text="",
	TextColor3=C.TEXT, TextSize=rs(13,14),
	Font=Enum.Font.GothamSemibold, TextWrapped=true,
	TextXAlignment=Enum.TextXAlignment.Left, ZIndex=23,
},PromptPanel)

-- Timer bar BG
local TimerBG = make("Frame",{
	Size=UDim2.new(1,-24,0,5),
	Position=UDim2.new(0,12,0,rs(90,96)),
	BackgroundColor3=C.SURF, BorderSizePixel=0, ZIndex=23,
},PromptPanel)
corner(3,TimerBG)

local TimerFill = make("Frame",{
	Size=UDim2.new(1,0,1,0),
	BackgroundColor3=C.ACC, BorderSizePixel=0, ZIndex=24,
},TimerBG)
corner(3,TimerFill)

local TimerLbl = make("TextLabel",{
	Size=UDim2.new(0,30,0,rs(13,14)),
	AnchorPoint = Vector2.new(1, 0),
	Position=UDim2.new(1,-12,0,rs(77,82)),
	BackgroundTransparency=1, Text="10s",
	TextColor3=C.MUTED, TextSize=rs(11,12),
	Font=Enum.Font.GothamBold,
	TextXAlignment=Enum.TextXAlignment.Right, ZIndex=23,
},PromptPanel)

-- Tombol Setuju / Tolak — ukuran penuh bawah panel
local BTN_PROMPT_H = rs(38,44)
local BtnYes = make("TextButton",{
	Size=UDim2.new(0.5,-14,0,BTN_PROMPT_H),
	AnchorPoint=Vector2.new(0,1),
	Position=UDim2.new(0,12,1,-12),
	BackgroundColor3=C.ACC, BorderSizePixel=0,
	Text="✓  Setuju", TextColor3=C.WHITE,
	TextSize=rs(13,15), Font=Enum.Font.GothamBold, ZIndex=23,
},PromptPanel)
corner(12,BtnYes)

local BtnNo = make("TextButton",{
	Size=UDim2.new(0.5,-14,0,BTN_PROMPT_H),
	AnchorPoint=Vector2.new(1,1),
	Position=UDim2.new(1,-12,1,-12),
	BackgroundColor3=C.SURF, BorderSizePixel=0,
	Text="✕  Tolak", TextColor3=C.MUTED,
	TextSize=rs(13,15), Font=Enum.Font.GothamBold, ZIndex=23,
},PromptPanel)
corner(12,BtnNo)

-- ═══════════════════════════════════════════════════════
-- STATUS PANEL — kanan atas
-- ═══════════════════════════════════════════════════════
local STAT_W = rs(210,235)

local StatusPanel = make("Frame",{
	Name="StatusPanel",
	Size=UDim2.new(0,STAT_W,0,rs(58,64)),
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -rs(200,160), 0, 12),
	BackgroundColor3=C.BG2,
	BackgroundTransparency=0.05,
	BorderSizePixel=0, ZIndex=15, Visible=false,
},ScreenGui)
corner(14,StatusPanel)
stroke(C.BORDER,1,StatusPanel)

local StatusDot = make("Frame",{
	Size=UDim2.new(0,8,0,8), AnchorPoint=Vector2.new(0,0.5),
	Position=UDim2.new(0,12,0,rs(19,22)),
	BackgroundColor3=C.GREEN, BorderSizePixel=0, ZIndex=16,
},StatusPanel)
corner(4,StatusDot)

local StatusMain = make("TextLabel",{
	Size=UDim2.new(1,-rs(70,78),0,rs(18,20)),
	Position=UDim2.new(0,26,0,rs(9,11)),
	BackgroundTransparency=1, Text="",
	TextColor3=C.TEXT, TextSize=rs(12,13),
	Font=Enum.Font.GothamBold,
	TextXAlignment=Enum.TextXAlignment.Left,
	TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=16,
},StatusPanel)

local StatusSub = make("TextLabel",{
	Size=UDim2.new(1,-rs(70,78),0,rs(15,17)),
	Position=UDim2.new(0,26,0,rs(28,31)),
	BackgroundTransparency=1, Text="",
	TextColor3=C.MUTED, TextSize=rs(11,12),
	Font=Enum.Font.Gotham,
	TextXAlignment=Enum.TextXAlignment.Left,
	TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=16,
},StatusPanel)

local BtnPrev = make("TextButton",{
	Size=UDim2.new(0,rs(24,28),0,rs(24,28)),
	AnchorPoint=Vector2.new(1,0.5),
	Position=UDim2.new(1,-rs(54,60),0.5,0),
	BackgroundColor3=C.SURF, BorderSizePixel=0,
	Text="‹", TextColor3=C.TEXT, TextSize=rs(16,18),
	Font=Enum.Font.GothamBold, ZIndex=16, Visible=false,
},StatusPanel)
corner(8,BtnPrev)

local BtnNext = make("TextButton",{
	Size=UDim2.new(0,rs(24,28),0,rs(24,28)),
	AnchorPoint=Vector2.new(1,0.5),
	Position=UDim2.new(1,-rs(26,29),0.5,0),
	BackgroundColor3=C.SURF, BorderSizePixel=0,
	Text="›", TextColor3=C.TEXT, TextSize=rs(16,18),
	Font=Enum.Font.GothamBold, ZIndex=16, Visible=false,
},StatusPanel)
corner(8,BtnNext)

local BtnStop = make("TextButton",{
	Size=UDim2.new(0,rs(46,52),0,rs(28,34)),
	AnchorPoint=Vector2.new(1,0.5),
	Position=UDim2.new(1,-5,0.5,0),
	BackgroundColor3=C.RED, BorderSizePixel=0,
	Text="Stop", TextColor3=C.WHITE,
	TextSize=rs(11,12), Font=Enum.Font.GothamBold, ZIndex=16,
},StatusPanel)
corner(10,BtnStop)

-- ═══════════════════════════════════════════════════════
-- NOTIF KECIL
-- ═══════════════════════════════════════════════════════
local Notif = make("Frame",{
	Size=UDim2.new(0,rs(210,230),0,rs(36,40)),
	AnchorPoint=Vector2.new(0.5,0),
	Position=UDim2.new(0.5,0,-0.1,0),
	BackgroundColor3=C.SURF, BorderSizePixel=0,
	ZIndex=28, Visible=false,
},ScreenGui)
corner(rs(10,12),Notif)
stroke(C.BORDER,1,Notif)

local NotifLbl = make("TextLabel",{
	Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,10,0,0),
	BackgroundTransparency=1, Text="",
	TextColor3=C.TEXT, TextSize=rs(12,13),
	Font=Enum.Font.GothamSemibold,
	TextXAlignment=Enum.TextXAlignment.Left, ZIndex=29,
},Notif)

local notifThr = nil
local function showNotif(text)
	if notifThr then task.cancel(notifThr) end
	NotifLbl.Text = text
	Notif.Visible  = true
	Notif.Position = UDim2.new(0.5,0,-0.1,0)
	tw(Notif,TFB,{Position=UDim2.new(0.5,0,0,rs(58,65))})
	notifThr = task.delay(2.5,function()
		tw(Notif,TFI,{Position=UDim2.new(0.5,0,-0.1,0)})
		task.wait(0.13); Notif.Visible=false
	end)
end

-- ═══════════════════════════════════════════════════════
-- ANIMASI
-- ═══════════════════════════════════════════════════════
local sitTrack, carryTrack = nil, nil
local function getHum()
	local c = player.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function getAnimator()
	local h = getHum(); if not h then return end
	return h:FindFirstChildOfClass("Animator") or make("Animator",{},h)
end
local function isR15()
	local h = getHum()
	return h and h.RigType == Enum.HumanoidRigType.R15
end
local function loadAnim(id)
	if not id or id==0 then return nil end
	local a = getAnimator(); if not a then return nil end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://"..tostring(id)
	local ok,t = pcall(function() return a:LoadAnimation(anim) end)
	anim:Destroy(); return ok and t or nil
end
local function playSit()
	local h = getHum(); if not h then return end
	h.Sit = true
	local id = isR15() and ANIM_SIT_R15 or ANIM_SIT_R6
	if sitTrack then sitTrack:Stop(0.15); sitTrack=nil end
	local t = loadAnim(id)
	if t then t.Priority=Enum.AnimationPriority.Action; t.Looped=true; t:Play(0.2); sitTrack=t end
end
local function stopSit()
	if sitTrack then sitTrack:Stop(0.2); sitTrack=nil end
	local h = getHum(); if h then h.Sit=false end
end
local function playCarry()
	local id = isR15() and ANIM_CARRY_R15 or ANIM_CARRY_R6
	if carryTrack then carryTrack:Stop(0.1); carryTrack=nil end
	local t = loadAnim(id)
	if t then t.Priority=Enum.AnimationPriority.Action; t.Looped=true; t:Play(0.2); carryTrack=t end
end
local function stopCarry()
	if carryTrack then carryTrack:Stop(0.2); carryTrack=nil end
end

-- ═══════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════
local menuOpen           = false
local menuTargetId       = nil
local menuTargetName     = nil
local lastRequesterId    = nil
local isCarried          = false
local currentCarrierId   = nil
local currentCarrierName = nil
local isSyncing          = false
local jumpBlockConn      = nil
local carriedList        = {}
local carriedIndex       = 1
local timerThr           = nil

-- FIX MOBILE KEDIP: debounce input yang lebih ketat
local inputLock          = false
local lastInputTime      = 0
local INPUT_COOLDOWN     = 0.4

local function startBlockJump()
	if jumpBlockConn then jumpBlockConn:Disconnect() end
	jumpBlockConn = UserInputService.JumpRequest:Connect(function()
		local h = getHum(); if h then h.Jump=false end
	end)
end
local function stopBlockJump()
	if jumpBlockConn then jumpBlockConn:Disconnect(); jumpBlockConn=nil end
end

-- ═══════════════════════════════════════════════════════
-- TIMER BAR
-- ═══════════════════════════════════════════════════════
local function startTimer(dur, onExpire)
	if timerThr then task.cancel(timerThr) end
	TimerFill.Size = UDim2.new(1,0,1,0)
	TimerFill.BackgroundColor3 = C.ACC
	TimerLbl.Text  = tostring(dur).."s"
	timerThr = task.spawn(function()
		local elapsed, step = 0, 0.05
		while elapsed < dur do
			task.wait(step); elapsed += step
			local ratio = 1-(elapsed/dur)
			TimerFill.Size = UDim2.new(math.max(ratio,0),0,1,0)
			TimerLbl.Text  = tostring(math.ceil(dur-elapsed)).."s"
			if ratio < 0.25 then
				TimerFill.BackgroundColor3 = C.RED
			elseif ratio < 0.55 then
				TimerFill.BackgroundColor3 = C.YELLOW
			else
				TimerFill.BackgroundColor3 = C.ACC
			end
		end
		TimerFill.Size = UDim2.new(0,0,1,0)
		TimerLbl.Text  = "0s"
		if onExpire then onExpire() end
	end)
end
local function stopTimer()
	if timerThr then task.cancel(timerThr); timerThr=nil end
end

-- ═══════════════════════════════════════════════════════
-- AVATAR FOTO PROFIL
-- ═══════════════════════════════════════════════════════
local function loadAvatar(userId, name)
	-- Set inisial dulu sebagai fallback
	AvatarFallback.Text = (name or "?"):sub(1,2):upper()
	AvatarImg.Image = ""
	-- Load thumbnail Roblox
	local ok, imgUrl = pcall(function()
		return game:GetService("Players"):GetUserThumbnailAsync(
			userId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size100x100
		)
	end)
	if ok and imgUrl then
		AvatarImg.Image = imgUrl
		AvatarFallback.Visible = false
	else
		AvatarFallback.Visible = true
	end
end

-- ═══════════════════════════════════════════════════════
-- UPDATE DAFTAR DIGENDONG DI MENU
-- ═══════════════════════════════════════════════════════
local function refreshCarriedListInMenu()
	-- Hapus item lama (kecuali title)
	for _, ch in ipairs(CarriedListFrame:GetChildren()) do
		if ch:IsA("TextButton") then ch:Destroy() end
	end

	if #carriedList == 0 then
		CarriedListTitle.Visible = false
		CarriedListFrame.Visible = false
		return
	end

	CarriedListTitle.Visible = true
	CarriedListFrame.Visible = true

	for i, item in ipairs(carriedList) do
		local row = make("TextButton",{
			Size=UDim2.new(1,0,0,rs(34,38)),
			BackgroundColor3=C.SURF, BorderSizePixel=0,
			Text="👤  "..item.name,
			TextColor3=C.TEXT, TextSize=rs(12,13),
			Font=Enum.Font.GothamSemibold,
			TextXAlignment=Enum.TextXAlignment.Left,
			LayoutOrder=i, ZIndex=22,
		},CarriedListFrame)
		corner(8,row); pad(0,0,12,0,row)

		-- Klik baris → stop carry player itu
		row.MouseButton1Click:Connect(function()
			CarryRemote:FireServer("Stop",{targetId=item.id})
			showNotif("🚫 Stop carry "..item.name)
		end)
	end
end

-- ═══════════════════════════════════════════════════════
-- MENU BUKA/TUTUP
-- ═══════════════════════════════════════════════════════
local function closeMenu()
	if not menuOpen then return end
	tw(Overlay,TFI,{BackgroundTransparency=1})
	tw(Menu,TFI,{Size=UDim2.new(0,MENU_W,0,0),BackgroundTransparency=1})
	task.delay(0.13,function()
		Overlay.Visible=false; Menu.Visible=false
		menuOpen=false; menuTargetId=nil; menuTargetName=nil
	end)
end

local function openMenu(targetId, targetName)
	-- FIX MOBILE KEDIP: cegah buka ulang terlalu cepat
	if menuOpen then closeMenu(); return end
	menuTargetId=targetId; menuTargetName=targetName; menuOpen=true

	MenuName.Text = targetName or "Player"
	MenuSub.Text  = "Pilih aksi"
	loadAvatar(targetId, targetName)

	local iAmCarryingThis = false
	for _,it in ipairs(carriedList) do
		if it.id == targetId then iAmCarryingThis=true; break end
	end

	local trusted = isTrusted(targetId)
	aBtns["carry"].Visible     = not isCarried and not iAmCarryingThis
	aBtns["stopcarry"].Visible = iAmCarryingThis
	aBtns["sync"].Visible      = true
	aBtns["stopsync"].Visible  = isSyncing
	aBtns["addfriend"].Visible = true

	-- Trust toggle
	TrustToggleBtn.Text = trusted and "ON" or "OFF"
	TrustToggleBtn.BackgroundColor3 = trusted and C.GREEN or C.SURF2
	TrustToggleBtn.TextColor3       = trusted and C.WHITE or C.MUTED
	TrustToggleFrame.Visible = not isCarried -- hanya muncul jika bisa carry

	-- Daftar yang digendong
	refreshCarriedListInMenu()

	-- Hitung tinggi menu
	local vis = 0
	for _,b in pairs(aBtns) do if b.Visible then vis+=1 end end
	if TrustToggleFrame.Visible then vis+=1 end
	local extraH = CarriedListFrame.Visible
		and (#carriedList*(rs(34,38)+4)+24) or 0
	local menuH = rs(76,82) + vis*(BTN_H+rs(5,7)) + rs(18,22) + extraH

	Menu.Size = UDim2.new(0,MENU_W,0,0)
	Menu.BackgroundTransparency   = 1
	Overlay.BackgroundTransparency= 1
	-- [P78] menu lama dimatikan (aksi lewat PlayerInfoPanel)
	-- Overlay.Visible=true; Menu.Visible=true
	tw(Overlay,TF,{BackgroundTransparency=0.55})
	tw(Menu,TFB,{Size=UDim2.new(0,MENU_W,0,menuH),BackgroundTransparency=0})
end

-- ═══════════════════════════════════════════════════════
-- PROMPT BUKA/TUTUP
-- ═══════════════════════════════════════════════════════
local function showPrompt()
	PromptPanel.Visible  = true
	PromptPanel.Position = UDim2.new(0.5,0,-0.4,0)
	tw(PromptPanel,TFB,{Position=UDim2.new(0.5,0,0.5,0)})
	startTimer(PROMPT_TIMEOUT, function()
		tw(PromptPanel,TFI,{Position=UDim2.new(0.5,0,-0.4,0)})
		task.delay(0.13,function() PromptPanel.Visible=false end)
	end)
end
local function hidePrompt()
	stopTimer()
	tw(PromptPanel,TFI,{Position=UDim2.new(0.5,0,-0.4,0)})
	task.delay(0.13,function() PromptPanel.Visible=false end)
end

-- ═══════════════════════════════════════════════════════
-- STATUS UPDATE
-- ═══════════════════════════════════════════════════════
local function updateStatus()
	local count = #carriedList
	if isCarried then
		StatusDot.BackgroundColor3 = C.YELLOW
		StatusMain.Text = "Sedang digendong"
		StatusSub.Text  = "oleh "..(currentCarrierName or "Player")
		BtnPrev.Visible = false
		BtnNext.Visible = false
		StatusPanel.Visible = true
	elseif count > 0 then
		carriedIndex = math.clamp(carriedIndex,1,count)
		local item = carriedList[carriedIndex]
		StatusDot.BackgroundColor3 = C.GREEN
		StatusMain.Text = ("Menggendong (%d/%d)"):format(carriedIndex,count)
		StatusSub.Text  = item and item.name or "Player"
		BtnPrev.Visible = count > 1
		BtnNext.Visible = count > 1
		StatusPanel.Visible = true
	else
		StatusPanel.Visible = false
	end
end

-- ═══════════════════════════════════════════════════════
-- CARRIED LIST
-- ═══════════════════════════════════════════════════════
local function addCarried(id, name)
	for _,it in ipairs(carriedList) do
		if it.id == id then it.name=name; updateStatus(); return end
	end
	table.insert(carriedList,{id=id,name=name})
	carriedIndex=#carriedList; updateStatus()
end
local function removeCarried(id)
	for i,it in ipairs(carriedList) do
		if it.id==id then table.remove(carriedList,i); break end
	end
	carriedIndex=math.max(1,math.min(carriedIndex,#carriedList))
	updateStatus()
	if #carriedList==0 then stopCarry() end
end
local function setCarriedSnapshot(list)
	carriedList={}
	for _,it in ipairs(list or {}) do
		table.insert(carriedList,{id=it.id,name=it.name})
	end
	carriedIndex=math.clamp(carriedIndex,1,math.max(1,#carriedList))
	updateStatus()
	if #carriedList==0 then stopCarry() end
end

-- ═══════════════════════════════════════════════════════
-- FIX MOBILE: Cari player terdekat di layar
-- ═══════════════════════════════════════════════════════
local function getPlayerScreenPos(p)
	local char = p.Character; if not char then return end
	local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
	local pos, onScreen = camera:WorldToScreenPoint(hrp.Position + Vector3.new(0,1,0))
	if onScreen then return Vector2.new(pos.X,pos.Y) end
end

local function castToPlayer(sx,sy)
	local ray    = camera:ScreenPointToRay(sx,sy)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local myChar = player.Character
	if myChar then params.FilterDescendantsInstances={myChar} end
	local res = workspace:Raycast(ray.Origin,ray.Direction*100,params)
	if res then
		local hitChar = res.Instance:FindFirstAncestorOfClass("Model")
		if hitChar then
			local hp = Players:GetPlayerFromCharacter(hitChar)
			if hp and hp~=player then return hp end
		end
	end
	-- Fallback mobile: cari yang paling dekat di layar
	if isMobile then
		local best, bestD = nil, 90
		for _, p2 in ipairs(Players:GetPlayers()) do
			if p2 == player then continue end
			local sp = getPlayerScreenPos(p2)
			if sp then
				local d = (sp - Vector2.new(sx,sy)).Magnitude
				if d < bestD then best=p2; bestD=d end
			end
		end
		return best
	end
end

-- ═══════════════════════════════════════════════════════
-- INPUT — FIX MOBILE KEDIP
-- Penyebab kedip: TouchStarted + Button1Down keduanya
-- fire sekaligus di mobile. Pakai satu jalur saja.
-- ═══════════════════════════════════════════════════════
local function handleInput(sx, sy)
	-- Cegah double fire
	if inputLock then return end
	local now = tick()
	if (now - lastInputTime) < INPUT_COOLDOWN then return end
	inputLock = true; lastInputTime = now

	if menuOpen then
		closeMenu()
		task.delay(INPUT_COOLDOWN, function() inputLock=false end)
		return
	end

	local hp = castToPlayer(sx,sy)
	if hp then
		openMenu(hp.UserId, hp.DisplayName)
	end

	task.delay(INPUT_COOLDOWN, function() inputLock=false end)
end

-- PC
if not isMobile then
	-- [P76] klik dimatikan (dipicu dari PlayerInfoPanel)
mouse.Button1Down:Connect(function()
	if true then return end
		handleInput(mouse.X, mouse.Y)
	end)
end

-- Mobile — hanya TouchStarted, tidak pakai Button1Down
if isMobile then
	UserInputService.TouchStarted:Connect(function(input, processed)
		if processed then return end
		local pos = input.Position
		handleInput(pos.X, pos.Y)
	end)
end

-- ═══════════════════════════════════════════════════════
-- TOMBOL MENU
-- ═══════════════════════════════════════════════════════
aBtns["carry"].MouseButton1Click:Connect(function()
	if not menuTargetId then return end
	CarryRemote:FireServer("Request",{targetId=menuTargetId})
	showNotif("🤲 Request carry → "..( menuTargetName or "Player"))
	closeMenu()
end)

aBtns["sync"].MouseButton1Click:Connect(function()
	if not menuTargetId or not SyncEvent then return end
	local t = Players:GetPlayerByUserId(menuTargetId)
	if t then
		SyncEvent:FireServer(t); isSyncing=true
		showNotif("💃 Sync dance → "..(menuTargetName or "Player"))
	end
	closeMenu()
end)

aBtns["addfriend"].MouseButton1Click:Connect(function()
	if not menuTargetId then return end
	showNotif("➕ Membuka profil "..(menuTargetName or "Player"))
	game:GetService("GuiService"):OpenBrowserWindow(
		"https://www.roblox.com/users/"..tostring(menuTargetId).."/profile")
	closeMenu()
end)

aBtns["stopcarry"].MouseButton1Click:Connect(function()
	if menuTargetId then
		CarryRemote:FireServer("Stop",{targetId=menuTargetId})
	end
	closeMenu()
end)

aBtns["stopsync"].MouseButton1Click:Connect(function()
	if UnSyncEvent then UnSyncEvent:FireServer() end
	isSyncing=false
	showNotif("⏹ Sync dance dihentikan")
	closeMenu()
end)

-- Trust toggle
TrustToggleBtn.MouseButton1Click:Connect(function()
	if not menuTargetId then return end
	if isTrusted(menuTargetId) then
		trustedPlayers[menuTargetId] = nil
		TrustToggleBtn.Text = "OFF"
		TrustToggleBtn.BackgroundColor3 = C.SURF2
		TrustToggleBtn.TextColor3       = C.MUTED
		showNotif("🔓 "..(menuTargetName or "Player").." dihapus dari percaya")
	else
		trustedPlayers[menuTargetId] = menuTargetName
		TrustToggleBtn.Text = "ON"
		TrustToggleBtn.BackgroundColor3 = C.GREEN
		TrustToggleBtn.TextColor3       = C.WHITE
		showNotif("⚡ "..(menuTargetName or "Player").." dipercaya — auto carry!")
	end
end)

BtnCloseMenu.MouseButton1Click:Connect(closeMenu)
Overlay.InputBegan:Connect(function(inp)
	if inp.UserInputType==Enum.UserInputType.MouseButton1
		or inp.UserInputType==Enum.UserInputType.Touch then
		closeMenu()
	end
end)

-- ═══════════════════════════════════════════════════════
-- TOMBOL STATUS
-- ═══════════════════════════════════════════════════════
BtnStop.MouseButton1Click:Connect(function()
	if isCarried then
		CarryRemote:FireServer("Stop",{})
	else
		local item = carriedList[carriedIndex]
		if item then CarryRemote:FireServer("Stop",{targetId=item.id}) end
	end
end)
BtnPrev.MouseButton1Click:Connect(function()
	if #carriedList==0 then return end
	carriedIndex=carriedIndex-1
	if carriedIndex<1 then carriedIndex=#carriedList end
	updateStatus()
end)
BtnNext.MouseButton1Click:Connect(function()
	if #carriedList==0 then return end
	carriedIndex=(carriedIndex%#carriedList)+1
	updateStatus()
end)

-- ═══════════════════════════════════════════════════════
-- TOMBOL PROMPT
-- ═══════════════════════════════════════════════════════
BtnYes.MouseButton1Click:Connect(function()
	if not lastRequesterId then return end
	CarryRemote:FireServer("Response",{requesterId=lastRequesterId,accept=true})
	hidePrompt()
end)
BtnNo.MouseButton1Click:Connect(function()
	if not lastRequesterId then return end
	CarryRemote:FireServer("Response",{requesterId=lastRequesterId,accept=false})
	hidePrompt()
	showNotif("✕ Permintaan ditolak")
end)

-- ═══════════════════════════════════════════════════════
-- CARRY REMOTE EVENTS
-- ═══════════════════════════════════════════════════════
CarryRemote.OnClientEvent:Connect(function(action,data)
	if action == "Prompt" then
		-- Cek trusted player — auto acc tanpa prompt
		if data and isTrusted(data.fromId) then
			CarryRemote:FireServer("Response",{requesterId=data.fromId,accept=true})
			showNotif("⚡ Auto carry dari "..(data.fromName or "Player"))
			return
		end
		lastRequesterId = data.fromId
		PromptLbl.Text  = (data.fromName or "Seseorang").." ingin menggendong kamu."
		showPrompt()

	elseif action == "Start" then
		if data and data.youAreCarrier then
			addCarried(data.targetId,data.targetName)
			playCarry()
			showNotif("🤲 Menggendong "..(data.targetName or "Player"))
		elseif data and data.carrierId then
			isCarried=true
			currentCarrierId=data.carrierId
			currentCarrierName=data.carrierName
			startBlockJump(); playSit(); stopCarry()
			updateStatus()
			showNotif("Digendong oleh "..(data.carrierName or "Player"))
		end

	elseif action == "End" then
		if data and data.youAreCarrier then
			if data.removedId then removeCarried(data.removedId) end
			if #carriedList==0 then stopCarry() end
		else
			isCarried=false; currentCarrierId=nil; currentCarrierName=nil
			stopBlockJump(); stopSit(); updateStatus()
		end
		hidePrompt()

	elseif action == "CarrierList" then
		if data and data.list then setCarriedSnapshot(data.list) end

	elseif action=="TooFar" then
		showNotif("📍 Terlalu jauh — dekati dulu")
	elseif action=="Busy" then
		showNotif("⚠️ Player tidak tersedia")
	elseif action=="Declined" then
		showNotif("✕ Carry ditolak")
		hidePrompt()
	elseif action=="RequestExpired" then
		showNotif("⏰ Request kadaluarsa")
		hidePrompt()
	elseif action=="PromptExpire" or action=="PromptClose" then
		hidePrompt()
	end
end)

-- ═══════════════════════════════════════════════════════
-- RESPAWN
-- ═══════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════
-- RESPAWN
-- ═══════════════════════════════════════════════════════

-- [PATCH] guard AvatarChanger dihapus (sistem sudah tidak ada)

player.CharacterAdded:Connect(function()

	stopBlockJump(); stopSit(); stopCarry(); stopTimer()
	isCarried=false; currentCarrierId=nil; currentCarrierName=nil
	isSyncing=false; menuOpen=false; menuTargetId=nil; menuTargetName=nil
	lastRequesterId=nil; carriedList={}; carriedIndex=1
	inputLock=false
	if Menu.Visible    then Menu.Visible=false    end
	if Overlay.Visible then Overlay.Visible=false end
	hidePrompt(); updateStatus()
	task.wait(0.8)
	local h = getHum()
	if h then h.Sit=false; h.PlatformStand=false end
end)