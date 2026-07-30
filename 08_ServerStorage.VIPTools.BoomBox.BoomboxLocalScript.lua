--[[
  BOOMBOX CUSTOM EDITION — LOCAL SCRIPT v6
  Fix: Shuffle btn, drag panel, volume di bawah play,
       Loop kiri / Shuffle kanan play, EQ tab terpisah dengan lampu
]]

local Players              = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService     = game:GetService("UserInputService")
local RunService           = game:GetService("RunService")
local MarketplaceService   = game:GetService("MarketplaceService")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")

local Tool         = script.Parent
local Remote       = Tool:WaitForChild("Remote", 10)
local SharedRemote = Tool:WaitForChild("SharedRemote", 10)
local SharedFunc   = Tool:WaitForChild("SharedFunction", 10)

local BOOMBOX_TITLE = "Boombox"
local ACTION_NAME   = "BoomboxActivate"

local RANKS = {
	{name="iTzme_yunnitaa", rank="👑 Owner",    col=Color3.fromRGB(255,200,50)},
	{name="clairdelune152", rank="⚡ Developer", col=Color3.fromRGB(0,220,255)},
	{name="kayz_zx",        rank="🛡 Admin",     col=Color3.fromRGB(255,80,160)},
	{name="Arzhellaa",      rank="🛡 Admin",     col=Color3.fromRGB(255,80,160)},
}
local STAFF_NAMES = {}
for _,v in ipairs(RANKS) do STAFF_NAMES[v.name]=true end

local EQ_PRESETS = {
	{name="Normal",    icon="◎", low=0,   mid=0,   high=0,   col=Color3.fromRGB(0,220,255)},
	{name="Bass",      icon="🔊", low=10,  mid=-2,  high=-4,  col=Color3.fromRGB(255,160,30)},
	{name="Jazz",      icon="🎷", low=3,   mid=4,   high=2,   col=Color3.fromRGB(255,200,60)},
	{name="Pop",       icon="🎤", low=-2,  mid=5,   high=4,   col=Color3.fromRGB(255,80,160)},
	{name="Rock",      icon="🎸", low=6,   mid=-3,  high=6,   col=Color3.fromRGB(255,65,80)},
	{name="Classical", icon="🎻", low=-2,  mid=3,   high=4,   col=Color3.fromRGB(140,80,255)},
	{name="Lofi",      icon="📻", low=4,   mid=-5,  high=-8,  col=Color3.fromRGB(0,200,180)},
}
local currentEQIdx = 1  -- index ke EQ_PRESETS
-- [FIX] fungsi refresh tampilan EQ dari luar openGui (diisi ulang tiap openGui)
local _refreshEQDisplay = nil
local function setEQByName(nm)
	for i,p in ipairs(EQ_PRESETS) do
		if p.name == nm then currentEQIdx = i break end
	end
	if _refreshEQDisplay then _refreshEQDisplay() end
end

local Player   = Players.LocalPlayer
local Mouse    = Player:GetMouse()
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local M = isMobile

-- Bridge events
local SongEndedEvent = Instance.new("BindableEvent")

local SongPosEvent   = Instance.new("BindableEvent")

-- State
local isMusicPlaying = false
local hasMovedToBack = false
local currentSongId  = nil
local currentSongIdx = 1
local currentVolume  = 0.5
local isLooping      = false
local isShuffle      = false
local SharedPlaylist = {}
local AddHistory     = {}

-- Favorit persistent
local _favLoadRE, _favSaveRE
local LocalFavorites = {}

local function ensureFavRemotes()
	if _favLoadRE and _favSaveRE then return true end
	local folder = ReplicatedStorage:FindFirstChild("BoomboxFavRemotes")
	if not folder then return false end
	_favLoadRE = folder:FindFirstChild("LoadBoomboxFav")
	_favSaveRE = folder:FindFirstChild("SaveBoomboxFav")
	return _favLoadRE ~= nil and _favSaveRE ~= nil
end
local function loadFavorites()
	if not ensureFavRemotes() then return end
	local ok,data = pcall(function() return _favLoadRE:InvokeServer() end)
	if ok and type(data)=="table" then
		LocalFavorites={}
		for _,id in ipairs(data) do LocalFavorites[id]=true end
	end
end
local function saveFavorites()
	if not ensureFavRemotes() then return end
	local list={}
	for id in pairs(LocalFavorites) do table.insert(list,id) end
	pcall(function() _favSaveRE:FireServer(list) end)
end
local function isFavorite(id) return LocalFavorites[id]==true end
local function toggleFavorite(id)
	if LocalFavorites[id] then LocalFavorites[id]=nil
	else LocalFavorites[id]=true end
	saveFavorites()
	return LocalFavorites[id]==true
end

-- Connection registry
local _conns={}
local function trackConn(c) table.insert(_conns,c);return c end
local function cleanConns()
	for _,c in ipairs(_conns) do if c and c.Connected then c:Disconnect() end end
	_conns={}
end

local function getRankInfo(name)
	-- [P67] role dari GameConfig: cari via Username (jalan walau pemain offline)
	local ok, GC = pcall(function()
		return require(game:GetService("ReplicatedStorage"):WaitForChild("ZayinConfig",5):WaitForChild("GameConfig",5))
	end)

	if ok and GC then
		-- 1) cari RoleId dari daftar Roles berdasarkan Username
		local rid = nil
		if GC.Roles then
			for _, roleData in ipairs(GC.Roles) do
				for _, u in ipairs(roleData.Users or {}) do
					if u.Username == name then rid = roleData.RoleId break end
				end
				if rid then break end
			end
		end

		-- 2) kalau pemain sedang online, attribute lebih akurat
		local target = game:GetService("Players"):FindFirstChild(name)
		if target then
			local ridAttr = target:GetAttribute("RoleId")
			if type(ridAttr) == "string" and ridAttr ~= "" then rid = ridAttr end
		end

		if rid then
			local conf = GC.LeaderstatRoles and GC.LeaderstatRoles[rid]
			if conf then return conf.Text, conf.Color end
			local ov = GC.Overhead and GC.Overhead[rid]
			if ov then return ov.DisplayText, ov.Color end
			return rid, Color3.fromRGB(200, 210, 225)
		end

		-- 3) tanpa role: cek VIP (hanya bisa untuk pemain online)
		if target and target:GetAttribute("IsVIP") == true then
			local vipConf = GC.LeaderstatRoles and GC.LeaderstatRoles.VIP
			if vipConf then return vipConf.Text, vipConf.Color end
			return "VIP", Color3.fromRGB(255, 215, 0)
		end
	end

	return "Player", Color3.fromRGB(150, 160, 175)
end
-- [P65] isStaff dari RoleId + GameConfig (bukan daftar nama hardcode)
local function isStaff()
	local rid = Player:GetAttribute("RoleId")
	if type(rid) ~= "string" or rid == "" then return false end
	local ok, GC = pcall(function()
		return require(game:GetService("ReplicatedStorage"):WaitForChild("ZayinConfig",5):WaitForChild("GameConfig",5))
	end)
	if ok and GC and GC.BoomboxAdminRoles then
		return GC.BoomboxAdminRoles[rid] == true
	end
	return STAFF_NAMES[Player.Name] ~= nil
end

local function fetchSongName(id)
	local ok,info=pcall(function() return MarketplaceService:GetProductInfo(id,Enum.InfoType.Asset) end)
	if ok and info and info.Name and info.Name~="" then return info.Name end
	return nil
end

local function refreshSharedPlaylist()
	local ok,data=pcall(function() return SharedFunc:InvokeServer("GetPlaylist") end)
	if ok and data then SharedPlaylist=data end
end
local function addToSharedPlaylist(id,name)
	local ok,res=pcall(function() return SharedFunc:InvokeServer("AddSong",id,name,Player.Name) end)
	if ok then return res end
end
local function removeFromSharedPlaylist(id)
	if not isStaff() then return false end
	local ok,res=pcall(function() return SharedFunc:InvokeServer("RemoveSong",id) end)
	return ok and res
end
local function getPlaylistSorted()
	local fav,norm={},{}
	for _,s in ipairs(SharedPlaylist) do
		if isFavorite(s.ID) then table.insert(fav,s) else table.insert(norm,s) end
	end
	for _,s in ipairs(norm) do table.insert(fav,s) end
	return fav
end

local function updateHistory(addedBy,songName)
	for _,h in ipairs(AddHistory) do
		if h.playerName==addedBy then h.count+=1;h.lastSong=songName;return end
	end
	local rank,col=getRankInfo(addedBy)
	table.insert(AddHistory,{playerName=addedBy,rank=rank,rankCol=col,count=1,lastSong=songName})
	table.sort(AddHistory,function(a,b)
		local wa=STAFF_NAMES[a.playerName] and 1 or 0
		local wb=STAFF_NAMES[b.playerName] and 1 or 0
		if wa~=wb then return wa>wb end
		return a.count>b.count
	end)
end
local function rebuildHistory()
	AddHistory={}
	for _,s in ipairs(SharedPlaylist) do
		if s.AddedBy then updateHistory(s.AddedBy,s.Name) end
	end
end

-- [P68] stopCurrentSong (kode mati) dihapus

-- Stop total: hentikan musik DAN hapus holster (STOP manual oleh user)
local function stopAndClearHolster()
	Remote:FireServer("PlaySong",nil)
	isMusicPlaying=false; hasMovedToBack=false; currentSongId=nil
	local Ch=Player.Character
	if Ch and Ch:FindFirstChild("Holster") then Ch.Holster:Destroy() end
end

local function playSong(id,name)
	-- Kirim PlaySong ke server — server akan stop sound lama & play baru
	currentSongId=id
	Remote:FireServer("PlaySong",id,currentVolume,EQ_PRESETS[currentEQIdx].name)
	isMusicPlaying=true
	-- JANGAN set hasMovedToBack=true di sini
	-- hasMovedToBack diset true hanya saat TransferToBackholder berhasil (di Unequipped)
end
local function getNextIdx()
	local s=getPlaylistSorted(); if #s==0 then return 1 end
	if isShuffle then
		if #s==1 then return 1 end
		local idx
		local tries=0
		repeat
			idx=math.random(1,#s)
			tries+=1
		until idx~=currentSongIdx or tries>10
		return idx
	end
	return (currentSongIdx%#s)+1
end
local function playNextSong()
	local s=getPlaylistSorted(); if #s==0 then return end
	currentSongIdx=getNextIdx()
	local song=s[currentSongIdx]; if not song then return end
	playSong(song.ID,song.Name); return song
end

-- ═══════════════════════════════════════════════════════════
--  GUI HELPERS
-- ═══════════════════════════════════════════════════════════
local guiRoot,vizBars,vizConn,seekConn=nil,{},nil,nil
local VIZ_COUNT=14

local C={
	bg0=Color3.fromRGB(10,13,20),    bg1=Color3.fromRGB(14,17,26),
	bg2=Color3.fromRGB(20,24,34),   bg3=Color3.fromRGB(26,31,42),
	bg4=Color3.fromRGB(34,40,54),
	cyan=Color3.fromRGB(0,220,255),  teal=Color3.fromRGB(0,200,180),
	gold=Color3.fromRGB(255,200,60), amber=Color3.fromRGB(255,160,30),
	green=Color3.fromRGB(40,220,120),red=Color3.fromRGB(255,65,80),
	pink=Color3.fromRGB(255,80,160), purple=Color3.fromRGB(140,80,255),
	blue=Color3.fromRGB(59,130,246), white=Color3.fromRGB(255,255,255),
	textA=Color3.fromRGB(220,245,255),textB=Color3.fromRGB(120,180,210),
	textC=Color3.fromRGB(70,120,155),border=Color3.fromRGB(45,55,72),
}

local function make(cls,props,parent)
	local i=Instance.new(cls)
	for k,v in pairs(props or {}) do i[k]=v end
	if parent then i.Parent=parent end; return i
end
local function corner(p,r2) make("UICorner",{CornerRadius=UDim.new(0,r2 or 8)},p) end
local function stroke(p,col,t)
	local s=make("UIStroke",{Color=col or C.border,Thickness=t or 1},p)
	s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; return s
end
local function grad(p,colors,rot)
	local kps={}
	for i,pair in ipairs(colors) do kps[i]=ColorSequenceKeypoint.new(pair[1],pair[2]) end
	make("UIGradient",{Color=ColorSequence.new(kps),Rotation=rot or 0},p)
end
local function pad(p,t,b,l,r2)
	make("UIPadding",{PaddingTop=UDim.new(0,t or 0),PaddingBottom=UDim.new(0,b or 0),
		PaddingLeft=UDim.new(0,l or 0),PaddingRight=UDim.new(0,r2 or 0)},p)
end
local function ts(p,mx,mn) make("UITextSizeConstraint",{MaxTextSize=mx or 14,MinTextSize=mn or 6},p) end
local function r(pc,mob) return M and mob or pc end

-- Drag
local function makeDraggable(panel,handle)
	if not panel or not handle then return end
	local dragging,dragStart,startPos=false,nil,nil
	handle.InputBegan:Connect(function(inp)
		if inp.UserInputType~=Enum.UserInputType.MouseButton1
			and inp.UserInputType~=Enum.UserInputType.Touch then return end
		dragging=true; dragStart=inp.Position; startPos=panel.Position
		inp.Changed:Connect(function()
			if inp.UserInputState==Enum.UserInputState.End then dragging=false end
		end)
	end)
	UserInputService.InputChanged:Connect(function(inp)
		-- [P69] guard input: handler dari panel lama tidak ikut bekerja
		if not guiRoot or not guiRoot.Parent then return end
		if not dragging then return end
		if inp.UserInputType~=Enum.UserInputType.MouseMovement
			and inp.UserInputType~=Enum.UserInputType.Touch then return end
		local delta=inp.Position-dragStart
		local vp=workspace.CurrentCamera.ViewportSize
		local pw,ph=panel.AbsoluteSize.X,panel.AbsoluteSize.Y
		local ax=panel.AbsolutePosition.X-startPos.X.Offset
		local ay=panel.AbsolutePosition.Y-startPos.Y.Offset
		local mnX,mxX=-ax,vp.X-pw-ax
		local mnY,mxY=-ay,vp.Y-ph-ay
		if mnX>mxX then mnX,mxX=mxX,mnX end
		if mnY>mxY then mnY,mxY=mxY,mnY end
		panel.Position=UDim2.new(
			startPos.X.Scale,math.clamp(startPos.X.Offset+delta.X,mnX,mxX),
			startPos.Y.Scale,math.clamp(startPos.Y.Offset+delta.Y,mnY,mxY))
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if not guiRoot or not guiRoot.Parent then return end
		if inp.UserInputType==Enum.UserInputType.MouseButton1
			or inp.UserInputType==Enum.UserInputType.Touch then
			dragging=false
		end
	end)
end

-- Visualizer
local function createViz(parent,w)
	local f=make("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),BorderSizePixel=0},parent)
	vizBars={}
	local gap=2
	local bw=math.max(3,math.floor((w-(VIZ_COUNT-1)*gap)/VIZ_COUNT))
	for i=1,VIZ_COUNT do
		local bar=make("Frame",{BackgroundColor3=Color3.fromHSV((i/VIZ_COUNT)*0.55,0.9,1),
			BorderSizePixel=0,Size=UDim2.new(0,bw,0,4),
			Position=UDim2.new(0,(i-1)*(bw+gap),1,-4)},f)
		corner(bar,2); table.insert(vizBars,bar)
	end
end
local function startViz()
	if vizConn then vizConn:Disconnect() end
	local t,tH,cH=0,{},{}
	for i=1,VIZ_COUNT do tH[i]=4;cH[i]=4 end
	vizConn=RunService.Heartbeat:Connect(function(dt)
		-- [P68] guard visualizer: berhenti kalau GUI sudah tidak ada
		if not guiRoot or not guiRoot.Parent then
			if vizConn then vizConn:Disconnect(); vizConn=nil end
			return
		end
		t=t+dt
		for i=1,VIZ_COUNT do
			local w2=math.sin(t*4+i*0.45)*0.5+0.5
			tH[i]=isMusicPlaying and (5+math.clamp(w2+math.sin(t*7+i*1.1)*0.3,0,1)*34) or 3
		end
		for i,bar in ipairs(vizBars) do
			if not bar or not bar.Parent then continue end
			cH[i]=cH[i]+(tH[i]-cH[i])*dt*(isMusicPlaying and 14 or 6)
			local maxH=math.max(2,(bar.Parent.AbsoluteSize.Y or 30)-2)
			local h=math.clamp(math.floor(cH[i]),2,maxH)
			bar.Size=UDim2.new(0,bar.Size.X.Offset,0,h)
			bar.Position=UDim2.new(0,bar.Position.X.Offset,1,-h)
			local hue=((i/VIZ_COUNT)*0.55+(h/maxH)*0.08)%1
			bar.BackgroundColor3=Color3.fromHSV(hue,
				isMusicPlaying and 0.88 or 0.35,
				isMusicPlaying and (0.7+h/maxH*0.3) or 0.4)
		end
	end)
end
local function stopViz()
	if vizConn then vizConn:Disconnect();vizConn=nil end; vizBars={}
end

local function closeGui()
	_refreshEQDisplay = nil -- [FIX] lepas callback saat GUI ditutup
	stopViz()
	if seekConn then seekConn:Disconnect();seekConn=nil end
	cleanConns()
	if guiRoot then
		if typeof(guiRoot)=="Instance" and guiRoot.Parent then
			pcall(function() guiRoot:Destroy() end)
		end
		guiRoot=nil
	end
end

local function fmtTime(s)
	s=math.max(s or 0,0)
	return string.format("%02d:%02d",math.floor(s/60),math.floor(s%60))
end

-- ── Playlist rows ──────────────────────────────────────────
-- [P68] buildPlaylistRows (kode mati) dihapus

-- ── History rows ──────────────────────────────────────────
-- [P68] buildHistoryRows (kode mati) dihapus

-- ═══════════════════════════════════════════════════════════
--  OPEN GUI
-- ═══════════════════════════════════════════════════════════
local function openGui()
	closeGui()
	refreshSharedPlaylist(); rebuildHistory()
	task.spawn(loadFavorites)

	local sg=make("ScreenGui",{Name="BoomboxGui",ResetOnSpawn=false,
		ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset=true,DisplayOrder=20})
	guiRoot=sg

	local vp=workspace.CurrentCamera.ViewportSize
	local FW=r(370, math.min(math.floor(vp.X*0.90),340))
	local FH=r(430, math.min(math.floor(vp.Y*0.78),450))

	local panel=make("Frame",{Name="Panel",Size=UDim2.new(0,FW,0,FH),
		AnchorPoint=Vector2.new(0.5,0.5),
		Position=UDim2.new(0.5,0,0.5,M and -20 or 0),
		BackgroundColor3=C.bg1,BackgroundTransparency=0.15,BorderSizePixel=0},sg)
	corner(panel,14); stroke(panel,C.border,1)

	if M then
		local us=make("UIScale",{},panel)
		us.Scale=math.clamp(vp.X/400,0.72,1.0)
	end

	-- Accent bar atas
	local acBar=make("Frame",{Size=UDim2.new(1,0,0,3),
		BackgroundColor3=C.cyan,BorderSizePixel=0},panel)
	-- [P62] gradasi pelangi dihapus (tampilan lebih bersih)

	-- ── HEADER ────────────────────────────────────────────────
	local HDR_H=r(38,34)
	local hdr=make("Frame",{Size=UDim2.new(1,0,0,HDR_H),
		Position=UDim2.new(0,0,0,3),BackgroundColor3=C.bg2,BackgroundTransparency=0.1,BorderSizePixel=0},panel)
	make("UICorner",{CornerRadius=UDim.new(0,14)},hdr)
	makeDraggable(panel,hdr)

	local iconBox=make("Frame",{Size=UDim2.new(0,r(28,26),0,r(28,26)),
		AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,8,0.5,0),
		BackgroundColor3=C.bg3,BorderSizePixel=0},hdr)
	corner(iconBox,8); stroke(iconBox,C.gold,1.2)
	local il=make("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
		Text="♪",TextScaled=true,Font=Enum.Font.GothamBold,TextColor3=C.gold},iconBox)
	ts(il,16)

	make("TextLabel",{Size=UDim2.new(1,-r(120,110),0,HDR_H),
		Position=UDim2.new(0,r(44,40),0,0),BackgroundTransparency=1,
		Text=BOOMBOX_TITLE,TextColor3=C.textA,Font=Enum.Font.GothamBold,
		TextSize=r(15,13),TextXAlignment=Enum.TextXAlignment.Left},hdr)

	local CLOSE_W=r(46,42)
	local closeBtn=make("TextButton",{Size=UDim2.new(0,CLOSE_W,0,r(22,20)),
		AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-6,0.5,0),
		BackgroundColor3=Color3.fromRGB(50,14,20),
		Text="CLOSE",TextColor3=C.red,TextSize=r(10,9),
		Font=Enum.Font.GothamBold,BorderSizePixel=0},hdr)
	corner(closeBtn,8); stroke(closeBtn,C.red,1.2,0.3)
	closeBtn.MouseEnter:Connect(function() closeBtn.BackgroundColor3=Color3.fromRGB(80,18,28) end)
	closeBtn.MouseLeave:Connect(function() closeBtn.BackgroundColor3=Color3.fromRGB(50,14,20) end)
	closeBtn.MouseButton1Click:Connect(closeGui)

	-- ── VISUALIZER ────────────────────────────────────────────
	local VIZ_H=r(24,20)
	local vizSec=make("Frame",{Size=UDim2.new(1,0,0,VIZ_H),
		Position=UDim2.new(0,0,0,3+HDR_H),
		BackgroundColor3=C.bg2,BorderSizePixel=0,ClipsDescendants=true},panel)
	pad(vizSec,2,2,8,8)
	createViz(vizSec,FW-16); startViz()

	-- ── NOW PLAYING + SEEK ────────────────────────────────────
	local NOW_Y=3+HDR_H+VIZ_H
	local NOW_H=r(40,34)
	local nowBar=make("Frame",{Size=UDim2.new(1,0,0,NOW_H),
		Position=UDim2.new(0,0,0,NOW_Y),
		BackgroundColor3=C.bg2,BackgroundTransparency=0.1,BorderSizePixel=0},panel)
	pad(nowBar,4,4,10,10)

	local nowLbl=make("TextLabel",{Size=UDim2.new(1,-r(95,80),0,r(16,14)),
		BackgroundTransparency=1,
		Text=isMusicPlaying and "▶ Sedang memutar..." or "⏸ Tidak ada musik",
		TextColor3=isMusicPlaying and C.green or C.textB,
		Font=Enum.Font.GothamSemibold,TextSize=r(12,11),
		TextXAlignment=Enum.TextXAlignment.Left,
		TextTruncate=Enum.TextTruncate.AtEnd},nowBar)
	ts(nowLbl,r(13,11))

	local timeLbl=make("TextLabel",{Size=UDim2.new(0,r(88,76),0,r(13,11)),
		AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),
		BackgroundTransparency=1,Text="00:00 / 00:00",
		TextColor3=C.textB,Font=Enum.Font.Gotham,
		TextSize=r(10,9),TextXAlignment=Enum.TextXAlignment.Right},nowBar)
	ts(timeLbl,r(11,9))

	local SEEK_H=r(5,4)
	local seekBG=make("Frame",{Size=UDim2.new(1,0,0,SEEK_H),
		Position=UDim2.new(0,0,1,-SEEK_H),
		BackgroundColor3=C.bg3,BorderSizePixel=0},nowBar)
	corner(seekBG,3); stroke(seekBG,C.border,1)

	local seekFill=make("Frame",{Size=UDim2.new(0,0,1,0),
		BackgroundColor3=C.cyan,BorderSizePixel=0},seekBG)
	corner(seekFill,3); grad(seekFill,{{0,C.teal},{1,C.cyan}},0)
	make("Frame",{Size=UDim2.new(0,r(11,12),0,r(11,12)),
		AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),
		BackgroundColor3=C.white,BorderSizePixel=0},seekFill)

	-- Seek interaction
	local seekHit=make("TextButton",{Size=UDim2.new(1,0,0,r(20,28)),
		AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,0,0.5,0),
		BackgroundTransparency=1,Text="",BorderSizePixel=0},seekBG)
	local seekDragging=false; local seekPct=0
	seekHit.InputBegan:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1
			or inp.UserInputType==Enum.UserInputType.Touch then
			seekDragging=true
			local pct=math.clamp((inp.Position.X-seekBG.AbsolutePosition.X)
				/math.max(seekBG.AbsoluteSize.X,1),0,1)
			seekPct=pct; seekFill.Size=UDim2.new(pct,0,1,0)
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		-- [P69] guard input: handler dari panel lama tidak ikut bekerja
		if not guiRoot or not guiRoot.Parent then return end
		if not seekDragging then return end
		if inp.UserInputType==Enum.UserInputType.MouseMovement
			or inp.UserInputType==Enum.UserInputType.Touch then
			local pct=math.clamp((inp.Position.X-seekBG.AbsolutePosition.X)
				/math.max(seekBG.AbsoluteSize.X,1),0,1)
			seekPct=pct; seekFill.Size=UDim2.new(pct,0,1,0)
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if not guiRoot or not guiRoot.Parent then return end
		if inp.UserInputType==Enum.UserInputType.MouseButton1
			or inp.UserInputType==Enum.UserInputType.Touch then
			if seekDragging then seekDragging=false; Remote:FireServer("SeekSong",seekPct) end
		end
	end)

		trackConn(SongPosEvent.Event:Connect(function(pos,dur,pct)
		if seekDragging then return end
		if seekFill then seekFill.Size=UDim2.new(pct,0,1,0) end
		if timeLbl then timeLbl.Text=fmtTime(pos).." / "..fmtTime(dur) end
	end))

	-- ── TAB BAR — 6 tab ───────────────────────────────────────
	local TAB_Y=NOW_Y+NOW_H+3
	local TAB_H=r(28,24)
	local tabBar=make("Frame",{Size=UDim2.new(1,-16,0,TAB_H),
		Position=UDim2.new(0,8,0,TAB_Y),
		BackgroundColor3=C.bg3,BorderSizePixel=0},panel)
	corner(tabBar,9); stroke(tabBar,C.border,1)
	make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
		SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2)},tabBar)
	pad(tabBar,2,2,2,2)

	-- 6 Tab: Beranda | Playlist | Favorit | History | EQ | Tambah
	local TAB_DEFS={
		{name="Beranda",  label="▶ Beranda",  order=1, col=C.cyan},
		{name="Playlist", label="≡ Playlist",  order=2, col=C.teal},
		{name="Favorit",  label="★ Favorit",   order=3, col=C.gold},
		{name="History",  label="⏱ History",   order=4, col=C.amber},
		{name="EQ",       label="≋ EQ",         order=5, col=C.purple},
		{name="Tambah",   label="+ Tambah",     order=6, col=C.green},
	}
	local tabBtns={}
	local function setTab(name)
		for nm,btn in pairs(tabBtns) do
			local act=(nm==name)
			btn.TextColor3=act and C.textA or C.textB
			btn.BackgroundColor3=act and C.bg0 or C.bg4
			btn.BackgroundTransparency=act and 0 or 0.55
			local ind=btn:FindFirstChild("Ind")
			if ind then ind.Visible=act end
		end
	end
	for _,def in ipairs(TAB_DEFS) do
		local btn=make("TextButton",{Name=def.name,LayoutOrder=def.order,
			Size=UDim2.new(1/#TAB_DEFS,-2,1,0),BackgroundColor3=C.bg4,
			BackgroundTransparency=0.3,Text=def.label,TextColor3=C.textB,
			Font=Enum.Font.GothamBold,TextScaled=true,BorderSizePixel=0},tabBar)
		corner(btn,r(8,6)); ts(btn,r(10,8))
		make("Frame",{Name="Ind",Size=UDim2.new(1,0,0,2),
			Position=UDim2.new(0,0,1,-2),BackgroundColor3=def.col,
			BorderSizePixel=0,Visible=false},btn)
		tabBtns[def.name]=btn
	end

	local BODY_Y=TAB_Y+TAB_H+4
	local BODY_H=FH-BODY_Y-4
	local btxt=r(12,10)

	-- Helper buat scroll panel
	local function makePanel(name,col)
		local f=make("Frame",{Name=name,
			Size=UDim2.new(1,-16,0,BODY_H),
			Position=UDim2.new(0,8,0,BODY_Y),
			BackgroundTransparency=1,Visible=false},panel)
		return f
	end
	local function makeScroll(parent,col)
		local s=make("ScrollingFrame",{
			Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,
			ScrollBarThickness=r(3,2),ScrollBarImageColor3=col or C.cyan,
			CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},parent)
		make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4)},s)
		pad(s,2,2,0,4)
		return s
	end

	-- ─────────────────────────────────────────────────────────
	-- TAB 1: BERANDA — UIListLayout vertikal agar tidak overlap
	-- ─────────────────────────────────────────────────────────
	local berandaPanel=makePanel("PanelBeranda",C.cyan)

	-- Gunakan ScrollingFrame agar semua elemen tampil bersih
	local berandaScroll=make("ScrollingFrame",{
		Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,
		ScrollBarThickness=r(3,2),ScrollBarImageColor3=C.cyan,
		CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},berandaPanel)
	local berandaList=make("UIListLayout",{
		SortOrder=Enum.SortOrder.LayoutOrder,
		Padding=UDim.new(0,r(5,4))},berandaScroll)
	pad(berandaScroll,r(4,3),r(4,3),0,r(4,3))

	-- 1. Info lagu
	local infoH=r(42,36)
	local infoFrame=make("Frame",{LayoutOrder=1,Size=UDim2.new(1,0,0,infoH),
		BackgroundColor3=C.bg3,BorderSizePixel=0},berandaScroll)
	corner(infoFrame,r(10,9)); stroke(infoFrame,C.border,1)
	local bigSongLbl=make("TextLabel",{
		Size=UDim2.new(1,-r(36,30),0,infoH*0.6),
		Position=UDim2.new(0,r(10,8),0,r(6,5)),
		BackgroundTransparency=1,
		Text=isMusicPlaying and "Sedang memutar..." or "— tidak ada musik —",
		TextColor3=C.textA,Font=Enum.Font.GothamBold,
		TextSize=r(12,11),TextXAlignment=Enum.TextXAlignment.Left,
		TextTruncate=Enum.TextTruncate.AtEnd},infoFrame)
	ts(bigSongLbl,r(13,11))
	-- Sub-info: "oleh player"
	local subSongLbl=make("TextLabel",{
		Size=UDim2.new(1,-r(36,30),0,infoH*0.35),
		Position=UDim2.new(0,r(10,8),0,infoH*0.6),
		BackgroundTransparency=1,Text="",
		TextColor3=C.textC,Font=Enum.Font.Gotham,
		TextScaled=true,TextXAlignment=Enum.TextXAlignment.Left,
		TextTruncate=Enum.TextTruncate.AtEnd},infoFrame)
	ts(subSongLbl,r(10,9))
	local starBtn2=make("TextButton",{
		Size=UDim2.new(0,r(28,24),0,r(28,24)),
		AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-r(6,5),0.5,0),
		BackgroundTransparency=1,Text="☆",TextColor3=C.textC,
		TextSize=r(16,14),Font=Enum.Font.GothamBold,BorderSizePixel=0},infoFrame)

	-- 2. Baris tombol kontrol HORIZONTAL — UIListLayout agar rata otomatis
	local BS=r(34,28)   -- tombol kecil
	local BL=r(44,38)   -- tombol besar (play)
	local LH=r(10,8)    -- label height
	local BTN_TOTAL_H=BS+LH+r(5,3)  -- tinggi 1 kolom tombol

	local ctrlRow=make("Frame",{LayoutOrder=2,
		Size=UDim2.new(1,0,0,BTN_TOTAL_H+r(10,8)),
		BackgroundColor3=C.bg3,BorderSizePixel=0},berandaScroll)
	corner(ctrlRow,r(10,9))

	-- UIListLayout horizontal di dalam ctrlRow
	local ctrlList=make("UIListLayout",{
		FillDirection=Enum.FillDirection.Horizontal,
		VerticalAlignment=Enum.VerticalAlignment.Center,
		HorizontalAlignment=Enum.HorizontalAlignment.Center,
		Padding=UDim.new(0,r(8,5))},ctrlRow)

	-- Fungsi buat tombol dalam list horizontal
	local function makeHBtn(icon,label,col,sz)
		sz=sz or BS
		local col2=col or C.bg4
		local grp=make("Frame",{Size=UDim2.new(0,sz,0,BTN_TOTAL_H),
			BackgroundTransparency=1},ctrlRow)
		local btn=make("TextButton",{Size=UDim2.new(1,0,0,sz),
			BackgroundColor3=col2,BorderSizePixel=0,Text=icon,
			TextColor3=col2==C.bg4 and C.textB or C.white,
			TextSize=r(13,11),Font=Enum.Font.GothamBold},grp)
		corner(btn,r(10,9)); stroke(btn,col2==C.bg4 and C.border or col2,1.2)
		make("TextLabel",{Size=UDim2.new(1,0,0,LH),
			Position=UDim2.new(0,0,0,sz+r(3,2)),
			BackgroundTransparency=1,Text=label,TextColor3=C.textC,
			Font=Enum.Font.Gotham,TextScaled=true,
			TextXAlignment=Enum.TextXAlignment.Center},grp)
		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3=col2==C.bg4 and C.bg2 or col2:Lerp(C.white,0.1)
		end)
		btn.MouseLeave:Connect(function() btn.BackgroundColor3=col2 end)
		return btn
	end

	local prevBtn=makeHBtn("◀◀","Prev",C.bg4)
	local loopBtn=makeHBtn("🔁","Loop",C.bg4)

	-- Play/Pause dalam 1 grup (bertumpuk)
	local ppGrp=make("Frame",{Size=UDim2.new(0,BL,0,BTN_TOTAL_H),
		BackgroundTransparency=1},ctrlRow)
	local playBtnM=make("TextButton",{Size=UDim2.new(1,0,0,BL),
		BackgroundColor3=C.cyan,BorderSizePixel=0,Text="▶",
		TextColor3=C.white,TextSize=r(17,15),Font=Enum.Font.GothamBold},ppGrp)
	corner(playBtnM,r(11,10)); stroke(playBtnM,C.cyan,1.5)
	playBtnM.MouseEnter:Connect(function() playBtnM.BackgroundColor3=C.cyan:Lerp(C.white,0.12) end)
	playBtnM.MouseLeave:Connect(function() playBtnM.BackgroundColor3=C.cyan end)
	local pauseBtnM=make("TextButton",{Size=UDim2.new(1,0,0,BL),
		BackgroundColor3=C.cyan,BorderSizePixel=0,Text="⏸",
		TextColor3=C.white,TextSize=r(17,15),Font=Enum.Font.GothamBold,Visible=false},ppGrp)
	corner(pauseBtnM,r(11,10)); stroke(pauseBtnM,C.cyan,1.5)
	pauseBtnM.MouseEnter:Connect(function() pauseBtnM.BackgroundColor3=C.cyan:Lerp(C.white,0.12) end)
	pauseBtnM.MouseLeave:Connect(function() pauseBtnM.BackgroundColor3=C.cyan end)
	make("TextLabel",{Size=UDim2.new(1,0,0,LH),
		Position=UDim2.new(0,0,0,BL+r(3,2)),
		BackgroundTransparency=1,Text="Play",TextColor3=C.textC,
		Font=Enum.Font.Gotham,TextScaled=true,
		TextXAlignment=Enum.TextXAlignment.Center},ppGrp)

	local shuffleBtn=makeHBtn("🔀","Shuffle",C.bg4)
	local nextBtn=makeHBtn("▶▶","Next",C.bg4)

	-- 3. Volume row
	local VOL_H=r(28,24)
	local volRow=make("Frame",{LayoutOrder=3,Size=UDim2.new(1,0,0,VOL_H),
		BackgroundColor3=C.bg3,BorderSizePixel=0},berandaScroll)
	corner(volRow,r(9,8)); stroke(volRow,C.border,1)
	make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
		VerticalAlignment=Enum.VerticalAlignment.Center,
		HorizontalAlignment=Enum.HorizontalAlignment.Center,
		Padding=UDim.new(0,r(6,4))},volRow)

	local BV=r(22,18)

	-- Tombol mute (klik icon speaker)
	local muteBtn=make("TextButton",{LayoutOrder=1,Size=UDim2.new(0,r(22,18),0,r(22,18)),
		BackgroundTransparency=1,Text="🔊",TextScaled=true,
		Font=Enum.Font.Gotham,TextColor3=C.textB,BorderSizePixel=0},volRow)
	ts(muteBtn,14)

	local vMin=make("TextButton",{LayoutOrder=2,Size=UDim2.new(0,BV,0,BV),
		BackgroundColor3=C.bg4,BorderSizePixel=0,Text="−",TextColor3=C.cyan,
		Font=Enum.Font.GothamBold,TextScaled=true},volRow)
	corner(vMin,r(8,7)); stroke(vMin,C.border,1); ts(vMin,13)
	vMin.MouseEnter:Connect(function() vMin.BackgroundColor3=C.bg2 end)
	vMin.MouseLeave:Connect(function() vMin.BackgroundColor3=C.bg4 end)
	local vLbl=make("TextLabel",{LayoutOrder=3,Size=UDim2.new(0,r(38,32),1,0),
		BackgroundTransparency=1,Text=math.floor(currentVolume*100).."%",
		TextColor3=C.textA,Font=Enum.Font.GothamBold,
		TextScaled=true,TextXAlignment=Enum.TextXAlignment.Center},volRow)
	ts(vLbl,r(11,10))
	local vPlus=make("TextButton",{LayoutOrder=4,Size=UDim2.new(0,BV,0,BV),
		BackgroundColor3=C.bg4,BorderSizePixel=0,Text="+",TextColor3=C.cyan,
		Font=Enum.Font.GothamBold,TextScaled=true},volRow)
	corner(vPlus,r(8,7)); stroke(vPlus,C.border,1); ts(vPlus,13)
	vPlus.MouseEnter:Connect(function() vPlus.BackgroundColor3=C.bg2 end)
	vPlus.MouseLeave:Connect(function() vPlus.BackgroundColor3=C.bg4 end)

	-- 4. Mode info bar
	local modInfoH=r(20,17)
	local modInfoBar=make("Frame",{LayoutOrder=4,Size=UDim2.new(1,0,0,modInfoH),
		BackgroundColor3=C.bg3,BorderSizePixel=0},berandaScroll)
	corner(modInfoBar,r(8,7))
	local modeLbl=make("TextLabel",{Size=UDim2.new(0.34,0,1,0),Position=UDim2.new(0,r(6,5),0,0),
		BackgroundTransparency=1,Text="▶ Normal",TextColor3=C.textB,
		Font=Enum.Font.GothamMedium,TextScaled=true,
		TextXAlignment=Enum.TextXAlignment.Left},modInfoBar)
	ts(modeLbl,r(9,8))
	local eqInfoLbl=make("TextLabel",{Size=UDim2.new(0.34,0,1,0),
		AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,0),
		BackgroundTransparency=1,Text="EQ: Normal",TextColor3=C.amber,
		Font=Enum.Font.GothamMedium,TextScaled=true,
		TextXAlignment=Enum.TextXAlignment.Center},modInfoBar)
	ts(eqInfoLbl,r(9,8))
	local shuffInfoLbl=make("TextLabel",{Size=UDim2.new(0.34,0,1,0),
		AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-r(6,5),0,0),
		BackgroundTransparency=1,Text="Shuffle: OFF",TextColor3=C.textB,
		Font=Enum.Font.GothamMedium,TextScaled=true,
		TextXAlignment=Enum.TextXAlignment.Right},modInfoBar)
	ts(shuffInfoLbl,r(9,8))

	-- ─────────────────────────────────────────────────────────
	-- TAB 2: PLAYLIST — daftar semua lagu
	-- ─────────────────────────────────────────────────────────
	local playlistPanel=makePanel("PanelPlaylist",C.teal)
	local plHdr=make("Frame",{Size=UDim2.new(1,0,0,r(26,22)),
		BackgroundColor3=C.bg3,BorderSizePixel=0},playlistPanel)
	corner(plHdr,r(8,7))
	make("TextLabel",{Size=UDim2.new(0.6,0,1,0),Position=UDim2.new(0,8,0,0),
		BackgroundTransparency=1,Text="🌐 Shared Playlist",
		TextColor3=C.cyan,Font=Enum.Font.GothamBold,
		TextSize=r(13,12),TextXAlignment=Enum.TextXAlignment.Left},plHdr)
	local cntLbl=make("TextLabel",{Size=UDim2.new(0.4,-26,1,0),
		Position=UDim2.new(0.6,0,0,0),BackgroundTransparency=1,
		Text=#SharedPlaylist.." lagu",TextColor3=C.textB,
		Font=Enum.Font.Gotham,TextSize=r(11,10),
		TextXAlignment=Enum.TextXAlignment.Right},plHdr)
	local refBtn=make("TextButton",{Size=UDim2.new(0,r(20,16),0,r(20,16)),
		AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-2,0.5,0),
		BackgroundColor3=C.bg4,BorderSizePixel=0,Text="↺",
		TextColor3=C.cyan,Font=Enum.Font.GothamBold,TextScaled=true},plHdr)
	corner(refBtn,5); ts(refBtn,12)

	local plListFrame=make("Frame",{
		Size=UDim2.new(1,0,1,-r(30,26)),
		Position=UDim2.new(0,0,0,r(30,26)),
		BackgroundTransparency=1},playlistPanel)
	local songScroll=make("ScrollingFrame",{
		Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,
		ScrollBarThickness=r(3,2),ScrollBarImageColor3=C.cyan,
		CanvasSize=UDim2.new(0,0,0,0)},plListFrame)
	make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,r(4,3))},songScroll)
	pad(songScroll,r(4,3),r(4,3),0,r(4,3))

	-- ─────────────────────────────────────────────────────────
	-- TAB 3: FAVORIT
	-- ─────────────────────────────────────────────────────────
	local favPanel=makePanel("PanelFavorit",C.gold)
	local favHdr=make("Frame",{Size=UDim2.new(1,0,0,r(26,22)),
		BackgroundColor3=C.bg3,BorderSizePixel=0},favPanel)
	corner(favHdr,7)
	make("TextLabel",{Size=UDim2.new(0.65,0,1,0),Position=UDim2.new(0,8,0,0),
		BackgroundTransparency=1,Text="⭐ Lagu Favorit",
		TextColor3=C.gold,Font=Enum.Font.GothamBold,
		TextSize=r(13,12),TextXAlignment=Enum.TextXAlignment.Left},favHdr)
	local favCntLbl=make("TextLabel",{Size=UDim2.new(0.35,0,1,0),
		Position=UDim2.new(0.65,0,0,0),BackgroundTransparency=1,
		Text="0 lagu",TextColor3=C.textB,Font=Enum.Font.Gotham,
		TextSize=r(11,10),TextXAlignment=Enum.TextXAlignment.Right},favHdr)
	local favScroll=make("ScrollingFrame",{
		Size=UDim2.new(1,0,1,-r(30,26)),
		Position=UDim2.new(0,0,0,r(30,26)),
		BackgroundTransparency=1,BorderSizePixel=0,
		ScrollBarThickness=r(3,2),ScrollBarImageColor3=C.gold,
		CanvasSize=UDim2.new(0,0,0,0)},favPanel)
	make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,r(4,3))},favScroll)
	pad(favScroll,r(4,3),r(4,3),0,r(4,3))

	-- ─────────────────────────────────────────────────────────
	-- TAB 4: HISTORY
	-- ─────────────────────────────────────────────────────────
	local histPanel=makePanel("PanelHistory",C.amber)
	local histHdr=make("Frame",{Size=UDim2.new(1,0,0,r(26,22)),
		BackgroundColor3=C.bg3,BorderSizePixel=0},histPanel)
	corner(histHdr,7)
	make("TextLabel",{Size=UDim2.new(1,-8,1,0),Position=UDim2.new(0,8,0,0),
		BackgroundTransparency=1,Text="📋 Riwayat Penambah Lagu",
		TextColor3=C.amber,Font=Enum.Font.GothamBold,
		TextSize=r(13,12),TextXAlignment=Enum.TextXAlignment.Left},histHdr)
	local histScroll=make("ScrollingFrame",{
		Size=UDim2.new(1,0,1,-r(30,26)),
		Position=UDim2.new(0,0,0,r(30,26)),
		BackgroundTransparency=1,BorderSizePixel=0,
		ScrollBarThickness=r(3,2),ScrollBarImageColor3=C.amber,
		CanvasSize=UDim2.new(0,0,0,0)},histPanel)
	make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4)},histScroll)
	pad(histScroll,2,2,0,2)

	-- ─────────────────────────────────────────────────────────
	-- TAB 5: EQ — Grid 2 kolom, tidak numpuk
	-- ─────────────────────────────────────────────────────────
	local eqPanel=makePanel("PanelEQ",C.purple)
	local eqHdr=make("Frame",{Size=UDim2.new(1,0,0,r(26,22)),
		BackgroundColor3=C.bg3,BorderSizePixel=0},eqPanel)
	corner(eqHdr,7)
	make("TextLabel",{Size=UDim2.new(1,-8,1,0),Position=UDim2.new(0,8,0,0),
		BackgroundTransparency=1,Text="🎚 Equalizer Preset",
		TextColor3=C.purple,Font=Enum.Font.GothamBold,
		TextSize=r(13,12),TextXAlignment=Enum.TextXAlignment.Left},eqHdr)

	-- Scroll untuk EQ agar tidak numpuk
	local eqBodyScroll=make("ScrollingFrame",{
		Size=UDim2.new(1,0,1,-r(30,26)),
		Position=UDim2.new(0,0,0,r(30,26)),
		BackgroundTransparency=1,BorderSizePixel=0,
		ScrollBarThickness=r(3,2),ScrollBarImageColor3=C.purple,
		CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},eqPanel)

	make("TextLabel",{LayoutOrder=1,Size=UDim2.new(1,0,0,r(16,13)),
		BackgroundTransparency=1,
		Text="Klik preset untuk mengaktifkan — lampu menyala saat aktif",
		TextColor3=C.textC,Font=Enum.Font.Gotham,
		TextSize=r(10,9),TextXAlignment=Enum.TextXAlignment.Left,
		Parent=eqBodyScroll})

	-- Grid EQ 2 kolom — tinggi tiap cell lebih kecil
	local EQ_CELL_H=r(46,42)
	local eqGrid=make("Frame",{LayoutOrder=2,
		Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,
		AutomaticSize=Enum.AutomaticSize.Y,Parent=eqBodyScroll})
	make("UIListLayout", {
		FillDirection=Enum.FillDirection.Vertical,
		SortOrder=Enum.SortOrder.LayoutOrder,
		Padding=UDim.new(0,r(5,4))},eqGrid)

	local eqBtnRefs={}
	-- [FIX] hubungkan refresh EQ global ke tampilan aktif
	local function _syncEQUI()
		if eqInfoLbl then eqInfoLbl.Text = "EQ: "..EQ_PRESETS[currentEQIdx].name end
	end
	local function updateEQButtons()
		for idx2,ref in pairs(eqBtnRefs) do
			local act=(idx2==currentEQIdx)
			local col2=EQ_PRESETS[idx2].col
			ref.btn.BackgroundColor3=act and col2:Lerp(C.bg0,0.5) or C.bg3
			ref.dot.BackgroundColor3=act and col2 or C.bg4
			ref.nameLbl.TextColor3=act and col2 or C.textA
			for _,ch in ipairs(ref.btn:GetChildren()) do
				if ch:IsA("UIStroke") then
					ch.Color=act and col2 or C.border
					ch.Thickness=act and 2 or 1
				end
			end
		end
	end

	local descs={Normal="Seimbang",Bass="Berat & dalam",Jazz="Hangat & melodis",
		Pop="Vokal terang",Rock="Energik & keras",Classical="Lembut & jernih",Lofi="Retro & dreamy"}
	for i,preset in ipairs(EQ_PRESETS) do
		local act=(i==currentEQIdx)
		local col2=preset.col
		local eqBtn=make("TextButton",{LayoutOrder=i,
			Size=UDim2.new(1,-4,0,EQ_CELL_H),
			BackgroundColor3=act and col2:Lerp(C.bg0,0.5) or C.bg3,
			BorderSizePixel=0,Text=""},eqGrid)
		corner(eqBtn,12); stroke(eqBtn,act and col2 or C.border,act and 2 or 1)

		-- [P64] lampu dot di kanan tengah
		local dot=make("Frame",{Size=UDim2.new(0,r(10,8),0,r(10,8)),
			AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-10,0.5,0),
			BackgroundColor3=act and col2 or C.bg4,BorderSizePixel=0},eqBtn)
		corner(dot,r(6,5))

		-- [P64] ikon di kiri
		make("TextLabel",{Size=UDim2.new(0,r(34,30),1,0),
			Position=UDim2.new(0,r(8,6),0,0),
			BackgroundTransparency=1,Text=preset.icon,
			TextSize=r(18,16),Font=Enum.Font.Gotham},eqBtn)

		-- Nama preset
		local nameLbl=make("TextLabel",{
			Size=UDim2.new(1,-r(90,80),0,r(15,13)),
			Position=UDim2.new(0,r(48,42),0,r(7,6)),
			BackgroundTransparency=1,Text=preset.name,
			TextColor3=act and col2 or C.textA,
			Font=Enum.Font.GothamBold,TextSize=r(13,12),
			TextXAlignment=Enum.TextXAlignment.Left},eqBtn)

		-- Deskripsi kecil
		make("TextLabel",{Size=UDim2.new(1,-r(90,80),0,r(12,10)),
			Position=UDim2.new(0,r(48,42),0,r(24,21)),
			BackgroundTransparency=1,Text=descs[preset.name] or "",
			TextColor3=C.textC,Font=Enum.Font.Gotham,
			TextSize=r(10,9),TextXAlignment=Enum.TextXAlignment.Left},eqBtn)

		eqBtnRefs[i]={btn=eqBtn,dot=dot,nameLbl=nameLbl}

		local ci=i
		eqBtn.MouseButton1Click:Connect(function()
			currentEQIdx=ci
			Remote:FireServer("UpdateEQ",EQ_PRESETS[ci].name)
			eqInfoLbl.Text="EQ: "..EQ_PRESETS[ci].name
			updateEQButtons()
		end)
		eqBtn.MouseEnter:Connect(function()
			if ci~=currentEQIdx then eqBtn.BackgroundColor3=C.bg4 end
		end)
		eqBtn.MouseLeave:Connect(function()
			if ci~=currentEQIdx then eqBtn.BackgroundColor3=C.bg3 end
		end)
	end

	-- ─────────────────────────────────────────────────────────
	-- TAB 6: TAMBAH LAGU
	-- ─────────────────────────────────────────────────────────
	local tambahPanel=makePanel("PanelTambah",C.green)
	local tamHdr=make("Frame",{Size=UDim2.new(1,0,0,r(26,22)),
		BackgroundColor3=C.bg3,BorderSizePixel=0},tambahPanel)
	corner(tamHdr,7)
	make("TextLabel",{Size=UDim2.new(1,-8,1,0),Position=UDim2.new(0,8,0,0),
		BackgroundTransparency=1,Text="➕ Tambah Lagu ke Playlist",
		TextColor3=C.green,Font=Enum.Font.GothamBold,
		TextSize=r(13,12),TextXAlignment=Enum.TextXAlignment.Left},tamHdr)

	local tamBody=make("ScrollingFrame",{
		Size=UDim2.new(1,0,1,-r(30,26)),
		Position=UDim2.new(0,0,0,r(30,26)),
		BackgroundTransparency=1,BorderSizePixel=0,
		ScrollBarThickness=r(3,2),ScrollBarImageColor3=C.green,
		CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},tambahPanel)
	make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6)},tamBody)
	pad(tamBody,4,4,0,4)

	local statLbl=make("TextLabel",{LayoutOrder=1,
		Size=UDim2.new(1,0,0,r(16,13)),BackgroundTransparency=1,
		Text="",TextColor3=C.green,Font=Enum.Font.Gotham,
		TextSize=r(10,9),TextXAlignment=Enum.TextXAlignment.Center},tamBody)

	local function makeInput(ph,lo)
		local f=make("Frame",{LayoutOrder=lo,Size=UDim2.new(1,0,0,r(32,28)),
			BackgroundColor3=C.bg3,BorderSizePixel=0},tamBody)
		corner(f,8); stroke(f,C.border,1)
		local tb=make("TextBox",{Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,5,0,0),
			BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=btxt,
			TextColor3=C.textA,PlaceholderText=ph,PlaceholderColor3=C.textC,
			Text="",ClearTextOnFocus=false},f)
		return tb
	end
	local idIn=makeInput("ID Music (angka) — contoh: 1234567890",2)
	local nmIn=makeInput("Nama Lagu (opsional, auto-fetch jika kosong)",3)

	make("TextLabel",{LayoutOrder=4,Size=UDim2.new(1,0,0,r(14,12)),
		BackgroundTransparency=1,
		Text="ℹ ID = angka dari URL: roblox.com/library/[ID]/nama-lagu",
		TextColor3=C.textC,Font=Enum.Font.Gotham,
		TextSize=r(9,8),TextXAlignment=Enum.TextXAlignment.Left},tamBody)

	local btnRow=make("Frame",{LayoutOrder=5,Size=UDim2.new(1,0,0,r(32,28)),
		BackgroundTransparency=1},tamBody)
	make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
		Padding=UDim.new(0,4)},btnRow)
	local addBtn=make("TextButton",{Size=UDim2.new(0.5,-2,1,0),
		BackgroundColor3=C.teal,BorderSizePixel=0,
		Text="+ TAMBAH KE PLAYLIST",TextColor3=C.white,
		TextSize=r(10,9),Font=Enum.Font.GothamBold},btnRow)
	corner(addBtn,r(10,9))
	local cpBtn=make("TextButton",{Size=UDim2.new(0.5,-2,1,0),
		BackgroundColor3=C.green,BorderSizePixel=0,
		Text="▶ PLAY LANGSUNG",TextColor3=C.white,
		TextSize=r(10,9),Font=Enum.Font.GothamBold},btnRow)
	corner(cpBtn,r(10,9))

	make("TextLabel",{LayoutOrder=6,Size=UDim2.new(1,0,0,r(14,12)),
		BackgroundTransparency=1,
		Text=isStaff() and "⚡ Staff — bisa hapus lagu siapapun"
			or "ℹ Lagu tersimpan untuk semua player",
		TextColor3=isStaff() and C.gold or C.textC,
		Font=Enum.Font.Gotham,TextSize=r(9,8),
		TextXAlignment=Enum.TextXAlignment.Center},tamBody)

	-- ─── LOGIKA SEMUA TOMBOL ─────────────────────────────────

	-- Helper fungsi onPlay/onStop
	local function onPlay()
		playBtnM.Visible=false; pauseBtnM.Visible=true
		bigSongLbl.Text=currentSongId and "Sedang memutar..." or "— tidak ada musik —"
	end
	local function onStop()
		playBtnM.Visible=true; pauseBtnM.Visible=false
	end

	-- Playlist rows builder
	local function buildRows(scroll,favOnly)
		for _,c in ipairs(scroll:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end
		local list=getPlaylistSorted()
		local filtered={}
		for _,s in ipairs(list) do
			if not favOnly or isFavorite(s.ID) then table.insert(filtered,s) end
		end
		if not favOnly then
			cntLbl.Text=#SharedPlaylist.." lagu"
		else
			favCntLbl.Text=#filtered.." lagu"
		end
		local rowH=r(34,28)
		for i,song in ipairs(filtered) do
			local isPlay=(currentSongId==song.ID)
			local isFav=isFavorite(song.ID)
			local row=make("Frame",{Size=UDim2.new(1,-4,0,rowH),
				BackgroundColor3=isPlay and C.bg4 or C.bg3,BorderSizePixel=0},scroll)
			corner(row,r(8,7))
			if isPlay then stroke(row,C.cyan,1) end
			local nW=r(22,18)
			local nL=make("TextLabel",{Size=UDim2.new(0,nW,1,0),Position=UDim2.new(0,3,0,0),
				BackgroundTransparency=1,Text=isPlay and "▶" or "♪",
				TextColor3=isPlay and C.cyan or C.teal,
				Font=Enum.Font.GothamBold,TextScaled=true},row)
			ts(nL,r(12,11))
			local dW=isStaff() and r(20,17) or 0
			local sW=r(22,18)
			local sBtn=make("TextButton",{BackgroundTransparency=1,
				Size=UDim2.new(1,-(nW+sW+dW+6),1,0),
				Position=UDim2.new(0,nW+4,0,0),
				Font=Enum.Font.GothamSemibold,TextSize=r(11,10),
				TextColor3=isPlay and C.cyan or (isFav and C.gold or C.textA),
				Text=song.Name,TextXAlignment=Enum.TextXAlignment.Left,
				TextTruncate=Enum.TextTruncate.AtEnd},row)
			local starB=make("TextButton",{BackgroundTransparency=1,
				Size=UDim2.new(0,sW,1,0),Position=UDim2.new(1,-(sW+dW),0,0),
				Font=Enum.Font.GothamBold,TextScaled=true,
				TextColor3=isFav and C.gold or C.textC,Text=isFav and "★" or "☆"},row)
			ts(starB,r(12,11))
			if isStaff() then
				local dBtn=make("TextButton",{BackgroundTransparency=1,
					Size=UDim2.new(0,dW,1,0),Position=UDim2.new(1,-dW,0,0),
					Font=Enum.Font.GothamBold,TextSize=r(11,10),
					TextColor3=C.red,Text="🗑"},row)
				dBtn.MouseButton1Click:Connect(function()
					if currentSongId==song.ID then
						stopAndClearHolster()
						if nowLbl then nowLbl.Text="⏸ Tidak ada musik";nowLbl.TextColor3=C.textB end
						onStop()
					end
					removeFromSharedPlaylist(song.ID); refreshSharedPlaylist(); rebuildHistory()
					buildRows(scroll,favOnly)
				end)
			end
			row.MouseEnter:Connect(function()
				if currentSongId~=song.ID then row.BackgroundColor3=C.bg4 end
			end)
			row.MouseLeave:Connect(function()
				if currentSongId~=song.ID then row.BackgroundColor3=C.bg3 end
			end)
			sBtn.MouseButton1Click:Connect(function()
				playSong(song.ID,song.Name); currentSongIdx=i
				nowLbl.Text="▶ "..song.Name; nowLbl.TextColor3=C.green
				bigSongLbl.Text=song.Name
				if isFavorite(song.ID) then
					starBtn2.Text="★"; starBtn2.TextColor3=C.gold
				else
					starBtn2.Text="☆"; starBtn2.TextColor3=C.textC
				end
				onPlay(); buildRows(scroll,favOnly)
			end)
			starB.MouseButton1Click:Connect(function()
				toggleFavorite(song.ID); buildRows(scroll,favOnly)
				if currentSongId==song.ID then
					local fav2=isFavorite(song.ID)
					starBtn2.Text=fav2 and "★" or "☆"
					starBtn2.TextColor3=fav2 and C.gold or C.textC
				end
			end)
		end
		scroll.CanvasSize=UDim2.new(0,0,0,#filtered*(rowH+3)+8)
	end

	-- History builder
	local function buildHistory()
		for _,c in ipairs(histScroll:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end
		local rowH=r(42,35)
		if #AddHistory==0 then
			make("TextLabel",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,
				Text="Belum ada riwayat",TextColor3=C.textC,
				Font=Enum.Font.Gotham,TextSize=r(11,10),
				TextXAlignment=Enum.TextXAlignment.Center,Parent=histScroll})
			return
		end
		for i,h in ipairs(AddHistory) do
			local row=make("Frame",{Size=UDim2.new(1,-4,0,rowH),
				BackgroundColor3=C.bg3,BorderSizePixel=0,Parent=histScroll})
			corner(row,10); stroke(row,C.border,1)
			make("TextLabel",{Size=UDim2.new(0,r(20,16),1,0),Position=UDim2.new(0,5,0,0),
				BackgroundTransparency=1,Text=tostring(i)..".",TextColor3=C.textC,
				Font=Enum.Font.GothamBold,TextSize=r(10,9),
				TextXAlignment=Enum.TextXAlignment.Center},row)
			make("TextLabel",{Size=UDim2.new(1,-r(110,90),0,rowH*0.52),
				Position=UDim2.new(0,r(26,21),0,3),BackgroundTransparency=1,
				Text=h.playerName,TextColor3=h.rankCol,Font=Enum.Font.GothamBold,
				TextSize=r(11,10),TextXAlignment=Enum.TextXAlignment.Left,
				TextTruncate=Enum.TextTruncate.AtEnd},row)
			make("TextLabel",{Size=UDim2.new(1,-r(110,90),0,rowH*0.38),
				Position=UDim2.new(0,r(26,21),0,rowH*0.52),BackgroundTransparency=1,
				Text=h.rank,TextColor3=h.rankCol,Font=Enum.Font.Gotham,
				TextSize=r(9,8),TextXAlignment=Enum.TextXAlignment.Left},row)
			local badge=make("Frame",{Size=UDim2.new(0,r(42,35),0,r(18,16)),
				AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-5,0.5,0),
				BackgroundColor3=C.bg4,BorderSizePixel=0},row)
			corner(badge,7); stroke(badge,h.rankCol,1)
			make("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
				Text=h.count.." 🎵",TextColor3=h.rankCol,Font=Enum.Font.GothamBold,
				TextSize=r(9,8),TextXAlignment=Enum.TextXAlignment.Center},badge)
		end
		histScroll.CanvasSize=UDim2.new(0,0,0,#AddHistory*(rowH+4)+8)
	end

	-- Build awal
	buildRows(songScroll,false)
	buildHistory()

	-- Refresh
	refBtn.MouseButton1Click:Connect(function()
		refreshSharedPlaylist(); rebuildHistory()
		buildRows(songScroll,false); buildHistory()
	end)
	trackConn(SharedRemote.OnClientEvent:Connect(function(ev)
		if ev=="PlaylistUpdated" then
			refreshSharedPlaylist(); rebuildHistory()
			buildRows(songScroll,false); buildHistory()
		end
	end))

	-- Loop/Shuffle UI
	local function updateLoopUI()
		local on=isLooping
		loopBtn.TextColor3=on and C.cyan or C.textB
		loopBtn.BackgroundColor3=on and Color3.fromRGB(0,40,60) or C.bg4
		for _,ch in ipairs(loopBtn:GetChildren()) do
			if ch:IsA("UIStroke") then ch.Color=on and C.cyan or C.border end
		end
		modeLbl.Text=on and "🔁 Loop" or "▶ Normal"
		modeLbl.TextColor3=on and C.cyan or C.textB
	end
	local function updateShuffleUI()
		local on=isShuffle
		shuffleBtn.TextColor3=on and C.pink or C.textB
		shuffleBtn.BackgroundColor3=on and Color3.fromRGB(60,10,40) or C.bg4
		for _,ch in ipairs(shuffleBtn:GetChildren()) do
			if ch:IsA("UIStroke") then ch.Color=on and C.pink or C.border end
		end
		shuffInfoLbl.Text=on and "Shuffle: ON" or "Shuffle: OFF"
		shuffInfoLbl.TextColor3=on and C.pink or C.textB
	end
	updateLoopUI(); updateShuffleUI()

	-- Tombol handlers
	prevBtn.MouseButton1Click:Connect(function()
		local s=getPlaylistSorted(); if #s==0 then return end
		currentSongIdx=currentSongIdx-1; if currentSongIdx<1 then currentSongIdx=#s end
		local song=s[currentSongIdx]; playSong(song.ID,song.Name)
		nowLbl.Text="▶ "..song.Name; nowLbl.TextColor3=C.green
		bigSongLbl.Text=song.Name; onPlay()
		buildRows(songScroll,false)
	end)
	nextBtn.MouseButton1Click:Connect(function()
		local nxt=playNextSong()
		if nxt then
			nowLbl.Text="▶ "..nxt.Name; nowLbl.TextColor3=C.green
			bigSongLbl.Text=nxt.Name; onPlay()
			buildRows(songScroll,false)
		end
	end)
	playBtnM.MouseButton1Click:Connect(function()
		-- [P70] lanjutkan lagu yang sedang dijeda
		if currentSongId then
			Remote:FireServer("ResumeSong"); isMusicPlaying=true
			onPlay()
			return
		end
		local s=getPlaylistSorted()
		if #s==0 then
			-- [FIX] playlist client kosong (mis. setelah stop+respawn) → refresh dulu
			refreshSharedPlaylist(); s=getPlaylistSorted()
			buildRows(songScroll,false)
		end
		if #s==0 then return end
		local song=s[currentSongIdx] or s[1]
		playSong(song.ID,song.Name)
		nowLbl.Text="▶ "..song.Name; nowLbl.TextColor3=C.green
		bigSongLbl.Text=song.Name; onPlay(); buildRows(songScroll,false)
	end)
	pauseBtnM.MouseButton1Click:Connect(function()
		-- [P70] jeda (posisi lagu dipertahankan)
		Remote:FireServer("PauseSong"); isMusicPlaying=false
		nowLbl.Text="⏸ Dijeda"; nowLbl.TextColor3=C.textB; onStop()
	end)
	loopBtn.MouseButton1Click:Connect(function()
		isLooping=not isLooping
		Remote:FireServer("SetLooping",isLooping); updateLoopUI()
	end)
	shuffleBtn.MouseButton1Click:Connect(function()
		isShuffle=not isShuffle; updateShuffleUI()
	end)
	-- State mute
	local isMuted = false
	local premuteVolume = currentVolume

	local function updateMuteUI()
		if isMuted then
			muteBtn.Text = "🔇"
			muteBtn.TextColor3 = C.red
			vLbl.Text = "MUTE"
			vLbl.TextColor3 = C.red
		else
			muteBtn.Text = "🔊"
			muteBtn.TextColor3 = C.textB
			vLbl.Text = math.floor(currentVolume*100).."%"
			vLbl.TextColor3 = C.textA
		end
	end

	muteBtn.MouseButton1Click:Connect(function()
		isMuted = not isMuted
		if isMuted then
			premuteVolume = currentVolume
			Remote:FireServer("SetVolume", 0)
		else
			Remote:FireServer("SetVolume", premuteVolume)
			currentVolume = premuteVolume
		end
		updateMuteUI()
	end)

	vMin.MouseButton1Click:Connect(function()
		if isMuted then isMuted=false end
		currentVolume=math.clamp(currentVolume-0.1,0,1)
		premuteVolume=currentVolume
		vLbl.Text=math.floor(currentVolume*100).."%"
		vLbl.TextColor3=C.textA
		muteBtn.Text="🔊"; muteBtn.TextColor3=C.textB
		Remote:FireServer("SetVolume",currentVolume)
	end)
	vPlus.MouseButton1Click:Connect(function()
		if isMuted then isMuted=false end
		currentVolume=math.clamp(currentVolume+0.1,0,1)
		premuteVolume=currentVolume
		vLbl.Text=math.floor(currentVolume*100).."%"
		vLbl.TextColor3=C.textA
		muteBtn.Text="🔊"; muteBtn.TextColor3=C.textB
		Remote:FireServer("SetVolume",currentVolume)
	end)

	-- Bintang di beranda
	starBtn2.MouseButton1Click:Connect(function()
		if not currentSongId then return end
		local fav2=toggleFavorite(currentSongId)
		starBtn2.Text=fav2 and "★" or "☆"
		starBtn2.TextColor3=fav2 and C.gold or C.textC
		buildRows(songScroll,false)
	end)

	-- Tambah lagu
	idIn.FocusLost:Connect(function()
		local sid=tonumber(idIn.Text); if not sid then return end
		statLbl.Text="⏳ Mengambil nama..."; statLbl.TextColor3=C.gold
		task.spawn(function()
			local n=fetchSongName(sid)
			if n then
				if nmIn.Text=="" then nmIn.Text=n end
				statLbl.Text="✅ "..n; statLbl.TextColor3=C.green
			else statLbl.Text="⚠ Isi nama manual"; statLbl.TextColor3=C.amber end
		end)
	end)
	addBtn.MouseButton1Click:Connect(function()
		local sid=tonumber(idIn.Text)
		if not sid then statLbl.Text="⚠ ID tidak valid";statLbl.TextColor3=C.red;return end
		for _,s in ipairs(SharedPlaylist) do
			if s.ID==sid then statLbl.Text="⚠ Lagu sudah ada";statLbl.TextColor3=C.amber;return end
		end
		local sname=(nmIn.Text~="" and nmIn.Text) or ("Lagu #"..(#SharedPlaylist+1))
		statLbl.Text="⏳ Menyimpan..."; statLbl.TextColor3=C.gold
		task.spawn(function()
			local res=addToSharedPlaylist(sid,sname)
			if res then
				statLbl.Text="✅ "..sname; statLbl.TextColor3=C.green
				idIn.Text=""; nmIn.Text=""
				refreshSharedPlaylist(); rebuildHistory()
				buildRows(songScroll,false); buildHistory()
			else statLbl.Text="❌ Gagal";statLbl.TextColor3=C.red end
		end)
	end)
	cpBtn.MouseButton1Click:Connect(function()
		local sid=tonumber(idIn.Text)
		if not sid then statLbl.Text="⚠ ID tidak valid";statLbl.TextColor3=C.red;return end
		local dn=(nmIn.Text~="" and nmIn.Text) or ("ID: "..sid)
		playSong(sid,dn)
		nowLbl.Text="▶ "..dn; nowLbl.TextColor3=C.green
		bigSongLbl.Text=dn; onPlay()
		statLbl.Text="▶ Memutar: "..dn; statLbl.TextColor3=C.green
	end)

	-- Tab switching
	local panels2={
		Beranda=berandaPanel, Playlist=playlistPanel,
		Favorit=favPanel, History=histPanel,
		EQ=eqPanel, Tambah=tambahPanel,
	}
	local function switchTab(name)
		for nm,p in pairs(panels2) do p.Visible=(nm==name) end
		setTab(name)
		if name=="Favorit" then
			task.spawn(function()
				task.wait(0.2)
				buildRows(favScroll,true)
			end)
		elseif name=="History" then
			buildHistory()
		end
	end
	for nm,btn in pairs(tabBtns) do
		btn.MouseButton1Click:Connect(function() switchTab(nm) end)
	end

	-- [FIX] pasang callback refresh EQ supaya restore saat GUI terbuka langsung update tampilan
	_refreshEQDisplay = function()
		pcall(function() updateEQButtons() end)
		pcall(_syncEQUI)
	end
	switchTab("Beranda"); setTab("Beranda")
	sg.Parent=Player.PlayerGui
end


-- ── Mobile Button ──────────────────────────────────────────
local mobileGui,mbHueConn=nil,nil
local function createMobileBtn()
	local old=Player.PlayerGui:FindFirstChild("BoomboxMobileBtn")
	if old then old:Destroy() end
	if mbHueConn then mbHueConn:Disconnect() end
	local sg=make("ScreenGui",{Name="BoomboxMobileBtn",ResetOnSpawn=false,
		ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=true,DisplayOrder=10})
	-- Posisi: kanan bawah, di atas hotbar
	local vp2=workspace.CurrentCamera.ViewportSize
	local btnSize=56
	local btn=make("TextButton",{
		BackgroundColor3=Color3.fromRGB(10,30,48),
		BorderSizePixel=0,
		Size=UDim2.new(0,btnSize,0,btnSize),
		-- AnchorPoint kanan bawah, di atas hotbar ~120px dari bawah
		AnchorPoint=Vector2.new(1,1),
		Position=UDim2.new(1,-12,1,-160),
		Font=Enum.Font.GothamBold,
		TextSize=8,TextColor3=C.cyan,
		Text="🎵"},sg)
	corner(btn,14)
	-- Stroke cyan tebal
	local btnStroke=stroke(btn,C.cyan,2)
	-- Label "Boombox" di dalam tombol (bawah icon)
	make("TextLabel",{
		Size=UDim2.new(1,0,0,14),
		AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,-2),
		BackgroundTransparency=1,
		Text="Boombox",TextColor3=C.cyan,
		Font=Enum.Font.GothamBold,TextSize=9,
		TextXAlignment=Enum.TextXAlignment.Center},btn)

	-- Gradient background
	grad(btn,{{0,Color3.fromRGB(0,40,70)},{1,Color3.fromRGB(0,20,40)}},90)

	-- Animasi: pulse cyan
	local hue=0.55  -- fixed cyan, tidak rainbow
	local pulse=0
	mbHueConn=RunService.Heartbeat:Connect(function(dt)
		if btn and btn.Parent then
			pulse=(pulse+dt*2)%math.pi
			local glow=math.abs(math.sin(pulse))
			btnStroke.Color=Color3.fromRGB(
				math.floor(0+glow*20),
				math.floor(180+glow*40),
				math.floor(200+glow*55))
			btnStroke.Thickness=1.5+glow*1
		else mbHueConn:Disconnect();mbHueConn=nil end
	end)
	btn.MouseButton1Click:Connect(function() Remote:FireServer("Activate",Mouse.Hit.p) end)
	sg.Parent=Player.PlayerGui; mobileGui=sg
end
local function removeMobileBtn()
	if mbHueConn then mbHueConn:Disconnect();mbHueConn=nil end
	if mobileGui then mobileGui:Destroy();mobileGui=nil end
end

-- ── Tool Events ────────────────────────────────────────────
local function onAction(_,state,_)
	if state==Enum.UserInputState.Begin then Remote:FireServer("Activate",Mouse.Hit.p) end
	return Enum.ContextActionResult.Sink
end

Tool.Equipped:Connect(function(mouse)
	-- Reset flag dulu
	hasMovedToBack=false
	-- Transfer sound dari holster ke handle (server yang handle)
	Remote:FireServer("TransferToHandle")
	Remote:FireServer("RequestMusicStatus")
	if M then createMobileBtn()
	else
		ContextActionService:BindAction(ACTION_NAME,onAction,false,Enum.UserInputType.MouseButton1)
		if mouse then
			trackConn(mouse.Button1Down:Connect(function()
				onAction(nil,Enum.UserInputState.Begin,nil)
			end))
		end
	end
end)

Tool.Unequipped:Connect(function()
	ContextActionService:UnbindAction(ACTION_NAME)
	if M then removeMobileBtn() end
	closeGui()
	task.wait(0.15)
	if isMusicPlaying then
		-- Selalu transfer ke punggung saat tool dilepas
		hasMovedToBack=true
		Remote:FireServer("TransferToBackholder")
	else
		hasMovedToBack=false
	end
end)

Remote.OnClientEvent:Connect(function(func,...)
	if func=="ChooseSong" then
		-- [P70] jangan reset tab kalau panel sudah terbuka
		if not (guiRoot and guiRoot.Parent) then openGui() end
	elseif func=="MusicStatus" then
		local status=...
		isMusicPlaying=status
		-- [P72] currentSongId DIPERTAHANKAN saat pause supaya bisa dilanjutkan
	elseif func=="ResumeFailed" then
		-- [FIX] server tak bisa resume (musik sudah stop) → mainkan lagu dari playlist
		local s=getPlaylistSorted()
		if #s==0 then refreshSharedPlaylist(); s=getPlaylistSorted() end
		if #s>0 then
			local song=s[currentSongIdx] or s[1]
			currentSongId=song.ID
			playSong(song.ID,song.Name)
		else
			currentSongId=nil; isMusicPlaying=false
		end
	elseif func=="SongEnded" then
		SongEndedEvent:Fire()
	elseif func=="SongPosition" then
		local pos,dur = ...
		if type(pos)=="number" and type(dur)=="number" and dur>0 then
			local pct=math.clamp(pos/dur,0,1)
			SongPosEvent:Fire(pos,dur,pct)
		end
	end
end)

-- [handler BoomboxRestored dipindah ke bawah]

Player.CharacterAdded:Connect(function(char)
	char:WaitForChild("Humanoid", 10).Died:Connect(function()
		if char:FindFirstChild("Holster") then char.Holster:Destroy() end
		isMusicPlaying=false; hasMovedToBack=false; currentSongId=nil
		stopViz()
		if seekConn then seekConn:Disconnect();seekConn=nil end
		if M then removeMobileBtn() end
		cleanConns()
	end)
end)

task.spawn(function() task.wait(2); ensureFavRemotes() end)

-- [PATCH P4] restore dari server: server menyimpan & memulihkan musik sendiri.
-- Client hanya menyesuaikan tampilan saat menerima sinyal RestoredSong.
Remote.OnClientEvent:Connect(function(func, ...)
	if func == "RestoredSong" then
		local sid, vol, eqName = ...
		currentSongId  = sid
		currentVolume  = vol or currentVolume
		isMusicPlaying = true
		hasMovedToBack = true
		if type(eqName) == "string" then setEQByName(eqName) end -- [FIX] sinkron tampilan EQ
	end
end)


-- FIX: Listener global SongEnded, tetap aktif walau GUI ditutup
SongEndedEvent.Event:Connect(function()
	if isLooping then
		local sorted = getPlaylistSorted()
		local song = sorted[currentSongIdx]
		if song then
			playSong(song.ID, song.Name)
		end
	else
		playNextSong()
	end
end)