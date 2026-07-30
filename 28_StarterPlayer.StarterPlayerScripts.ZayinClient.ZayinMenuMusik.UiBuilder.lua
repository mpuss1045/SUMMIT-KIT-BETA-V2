-- UiBuilder Musik v4.0 | Clean rebuild | Style sama dengan Emote
local UiBuilder = {}
local UIS = game:GetService("UserInputService")
local M = UIS.TouchEnabled and not UIS.KeyboardEnabled
local function rs(pc,mob) return M and mob or pc end

local C = {
	bg0  = Color3.fromRGB(8,10,14),
	bg1  = Color3.fromRGB(12,14,18),
	bg2  = Color3.fromRGB(16,18,24),
	bg3  = Color3.fromRGB(22,24,32),
	bg4  = Color3.fromRGB(28,30,40),
	cyan = Color3.fromRGB(0,210,200),
	cynd = Color3.fromRGB(0,150,145),
	teal = Color3.fromRGB(0,190,180),
	gold = Color3.fromRGB(255,200,60),
	amber= Color3.fromRGB(255,165,30),
	pink = Color3.fromRGB(255,60,160),
	green= Color3.fromRGB(40,230,140),
	red  = Color3.fromRGB(255,70,90),
	redbg= Color3.fromRGB(35,10,10),
	white= Color3.fromRGB(255,255,255),
	textA= Color3.fromRGB(220,230,240),
	textB= Color3.fromRGB(120,140,160),
	textC= Color3.fromRGB(70,90,110),
	border=Color3.fromRGB(30,35,45),
}

local function make(cls,props,parent)
	local i=Instance.new(cls)
	for k,v in pairs(props or {}) do i[k]=v end
	if parent then i.Parent=parent end
	return i
end
local function corner(p,r) make("UICorner",{CornerRadius=UDim.new(0,r or 8)},p) end
local function ts(p,mx) make("UITextSizeConstraint",{MaxTextSize=mx,MinTextSize=6},p) end
local function pad(p,t,b,l,r)
	make("UIPadding",{PaddingTop=UDim.new(0,t or 0),PaddingBottom=UDim.new(0,b or 0),
		PaddingLeft=UDim.new(0,l or 0),PaddingRight=UDim.new(0,r or 0)},p)
end
local function hover(btn,on,off)
	btn.MouseEnter:Connect(function() btn.BackgroundColor3=on end)
	btn.MouseLeave:Connect(function() btn.BackgroundColor3=off end)
end

-- Build lama (tidak dipakai tapi dipertahankan agar tidak error)
function UiBuilder.Build(parent) return {Colors=C} end

function UiBuilder.BuildEmbedded(contentFrame)
	local ui={}; ui.Colors=C

	-- Ukuran (sama dengan Emote)
	local VIZ_H  = rs(44,48)
	local INFO_H = rs(32,34)
	local TAB_H  = rs(30,32)
	local ROW_H  = rs(30,32)
	local ROWS   = 4  -- playlist rows visible
	local VOL_H  = rs(30,32)
	local CTRL_H = rs(36,38)
	local EQ_ROW = rs(26,28)
	local GAP    = rs(4,5)

	-- Container langsung ke content
	local wrapper=make("Frame",{Name="MusicWrapper",
		Size=UDim2.new(1,0,0,0),
		AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundColor3=C.bg1,BorderSizePixel=0,
		ClipsDescendants=false},contentFrame)
	corner(wrapper,12)
	ui.Panel=wrapper

	local function section(y,w,h,bg)
		local f=make("Frame",{
			Size=UDim2.new(1,-rs(12,14),0,h),
			Position=UDim2.new(0,rs(6,7),0,y),
			BackgroundColor3=bg or C.bg2,BorderSizePixel=0},wrapper)
		corner(f,10); return f
	end

	local y=GAP

	-- Badge count (kecil di atas kanan)
	local badge=make("TextLabel",{Name="CountBadge",
		Size=UDim2.new(0,rs(54,58),0,rs(18,20)),
		AnchorPoint=Vector2.new(1,0),
		Position=UDim2.new(1,-rs(6,7),0,GAP),
		BackgroundColor3=C.bg3,Text="0 lagu",
		TextColor3=C.gold,TextSize=rs(9,10),
		Font=Enum.Font.GothamBold,BorderSizePixel=0},wrapper)
	corner(badge,10)
	ui.UpdateCount=function(n) badge.Text=tostring(n).." lagu" end

	-- 1. TAB BAR
	local TAB_DEFS={
		{name="PlayerTab",   label="▶ PLAY",  order=1,col=C.cyan},
		{name="PlaylistTab", label="≡ LIST",  order=2,col=C.teal},
		{name="FavoritTab",  label="★ FAV",   order=3,col=C.gold},
		{name="EQTab",       label="≋ EQ",    order=4,col=C.amber},
	}
	local tabBar=section(y,nil,TAB_H)
	make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
		SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,rs(3,4))},tabBar)
	pad(tabBar,rs(3,4),rs(3,4),rs(3,4),rs(3,4))

	local tbns={}
	for _,d in ipairs(TAB_DEFS) do
		local b=make("TextButton",{Name=d.name,LayoutOrder=d.order,
			Size=UDim2.new(0.25,-rs(2.5,3),1,0),
			BackgroundColor3=C.bg4,BackgroundTransparency=0.3,
			Text=d.label,TextColor3=C.textB,
			Font=Enum.Font.GothamBold,TextSize=rs(9,10),BorderSizePixel=0},tabBar)
		corner(b,7); ts(b,rs(9,10))
		make("Frame",{Name="Indicator",Size=UDim2.new(1,0,0,2),
			Position=UDim2.new(0,0,1,-2),BackgroundColor3=d.col,
			BorderSizePixel=0,Visible=false},b)
		b.MouseEnter:Connect(function()
			if b.BackgroundColor3~=d.col then b.BackgroundTransparency=0.1 end
		end)
		b.MouseLeave:Connect(function()
			if b.BackgroundColor3~=d.col then b.BackgroundTransparency=0.3 end
		end)
		tbns[d.name]=b
	end
	ui.PlayerTabBtn=tbns["PlayerTab"]; ui.PlaylistTabBtn=tbns["PlaylistTab"]
	ui.FavoritTabBtn=tbns["FavoritTab"]; ui.EQTabBtn=tbns["EQTab"]
	y=y+TAB_H+GAP

	-- 2. PLAYER CONTAINER
	local CY=y
	local pc=make("Frame",{Name="PlayerContainer",
		Size=UDim2.new(1,-rs(12,14),0,0),
		Position=UDim2.new(0,rs(6,7),0,CY),
		AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1,Visible=true},wrapper)
	ui.PlayerContainer=pc

	local py=0

	-- Visualizer
	local viz=make("Frame",{Name="VisualizerFrame",
		Size=UDim2.new(1,0,0,VIZ_H),Position=UDim2.new(0,0,0,py),
		BackgroundColor3=C.bg2,BorderSizePixel=0},pc)
	corner(viz,10); ui.VisualizerFrame=viz; py=py+VIZ_H+GAP

	-- Song info row
	local infoRow=make("Frame",{Size=UDim2.new(1,0,0,INFO_H),
		Position=UDim2.new(0,0,0,py),BackgroundColor3=C.bg2,BorderSizePixel=0},pc)
	corner(infoRow,10)

	local sn=make("TextLabel",{Name="NameLagu",
		Size=UDim2.new(1,-rs(60,65),1,0),Position=UDim2.new(0,rs(8,10),0,0),
		BackgroundTransparency=1,Text="— pilih lagu —",
		TextColor3=C.textA,Font=Enum.Font.GothamBold,
		TextSize=rs(12,13),TextXAlignment=Enum.TextXAlignment.Left,
		TextTruncate=Enum.TextTruncate.AtEnd},infoRow)
	ts(sn,rs(12,13)); ui.NameLagu=sn

	local starBtn=make("TextButton",{Name="StarIcon",
		Size=UDim2.new(0,rs(24,26),0,rs(24,26)),
		AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-rs(32,36),0.5,0),
		BackgroundTransparency=1,Text="☆",TextColor3=C.textB,
		TextSize=rs(16,18),Font=Enum.Font.Gotham,BorderSizePixel=0},infoRow)
	ui.StarIcon=starBtn

	local detikLbl=make("TextLabel",{Name="DetikLagu",
		Size=UDim2.new(0,rs(70,76),1,0),
		AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-rs(4,5),0,0),
		BackgroundTransparency=1,Text="00:00",
		TextColor3=C.textB,Font=Enum.Font.Gotham,
		TextSize=rs(9,10),TextXAlignment=Enum.TextXAlignment.Right},infoRow)
	ts(detikLbl,rs(9,10)); ui.DetikLagu=detikLbl
	py=py+INFO_H+GAP

	-- Seek bar
	local sBG=make("Frame",{Name="SeekBG",
		Size=UDim2.new(1,0,0,rs(5,6)),Position=UDim2.new(0,0,0,py),
		BackgroundColor3=C.bg3,BorderSizePixel=0},pc)
	corner(sBG,3); ui.SeekBG=sBG
	local sHB=make("TextButton",{Name="SeekHitbox",
		Size=UDim2.new(1,0,0,rs(18,20)),AnchorPoint=Vector2.new(0,0.5),
		Position=UDim2.new(0,0,0.5,0),BackgroundTransparency=1,
		Text="",BorderSizePixel=0},sBG)
	local sf=make("Frame",{Name="SeekFill",Size=UDim2.new(0,0,1,0),
		BackgroundColor3=C.cyan,BorderSizePixel=0},sBG)
	corner(sf,3); ui.SeekFill=sf
	local seekDragging=false
	local function applySeek(px)
		local mn=sBG.AbsolutePosition.X
		local pct=math.clamp((px-mn)/math.max(sBG.AbsoluteSize.X,1),0,1)
		sf.Size=UDim2.new(pct,0,1,0); sBG:SetAttribute("SeekPercent",pct)
	end
	sHB.InputBegan:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
			seekDragging=true; applySeek(inp.Position.X) end
	end)
	game:GetService("UserInputService").InputChanged:Connect(function(inp)
		if not seekDragging then return end
		if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then
			applySeek(inp.Position.X) end
	end)
	game:GetService("UserInputService").InputEnded:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
			seekDragging=false end
	end)
	py=py+rs(5,6)+rs(12,14)  -- gap lebih besar

	-- Controls
	local BH=rs(30,32); local LH=rs(9,10); local ColH=BH+LH+rs(2,3)
	local ctrlF=make("Frame",{Size=UDim2.new(1,0,0,ColH),
		Position=UDim2.new(0,0,0,py),BackgroundTransparency=1},pc)
	make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
		HorizontalAlignment=Enum.HorizontalAlignment.Center,
		VerticalAlignment=Enum.VerticalAlignment.Center,
		Padding=UDim.new(0,rs(5,6))},ctrlF)

	local SS=rs(30,32); local SL=rs(36,40); local SM=rs(26,28)
	local function mkCtrl(nm,ic,lb,w,hi)
		local col=make("Frame",{Size=UDim2.new(0,w,0,ColH),BackgroundTransparency=1},ctrlF)
		local b=make("TextButton",{Name=nm,Size=UDim2.new(1,0,0,BH),
			BackgroundColor3=C.bg2,BorderSizePixel=0,Text=ic,
			TextColor3=hi and C.cyan or C.textB,TextSize=rs(12,13),
			Font=Enum.Font.GothamBold},col)
		corner(b,8)
		hover(b,C.bg3,C.bg2)
		local l=make("TextLabel",{Size=UDim2.new(1,0,0,LH),
			Position=UDim2.new(0,0,0,BH+rs(2,3)),BackgroundTransparency=1,
			Text=lb,TextColor3=C.textC,Font=Enum.Font.Gotham,
			TextSize=rs(8,9),TextXAlignment=Enum.TextXAlignment.Center},col)
		ts(l,rs(8,9)); return b
	end

	local modeBtn=mkCtrl("ModeButton","➡","Mode",SM,false)
	local prevBtn=mkCtrl("PrevButton","◀◀","Prev",SS,false)

	local ppc=make("Frame",{Size=UDim2.new(0,SL,0,ColH),BackgroundTransparency=1},ctrlF)
	local playBtn=make("TextButton",{Name="PlayButton",Size=UDim2.new(1,0,0,BH),
		BackgroundColor3=Color3.fromRGB(0,50,48),BorderSizePixel=0,Text="▶",
		TextColor3=C.cyan,TextSize=rs(13,14),Font=Enum.Font.GothamBold,Visible=true},ppc)
	corner(playBtn,8); hover(playBtn,Color3.fromRGB(0,70,66),Color3.fromRGB(0,50,48))
	local pauseBtn=make("TextButton",{Name="PauseButton",Size=UDim2.new(1,0,0,BH),
		BackgroundColor3=Color3.fromRGB(0,50,48),BorderSizePixel=0,Text="⏸",
		TextColor3=C.cyan,TextSize=rs(13,14),Font=Enum.Font.GothamBold,Visible=false},ppc)
	corner(pauseBtn,8); hover(pauseBtn,Color3.fromRGB(0,70,66),Color3.fromRGB(0,50,48))
	make("TextLabel",{Size=UDim2.new(1,0,0,LH),Position=UDim2.new(0,0,0,BH+rs(2,3)),
		BackgroundTransparency=1,Text="Play/Pause",TextColor3=C.textC,
		Font=Enum.Font.Gotham,TextSize=rs(8,9),
		TextXAlignment=Enum.TextXAlignment.Center},ppc)

	local nextBtn=mkCtrl("NextButton","▶▶","Next",SS,true)
	local shuffleBtn=mkCtrl("ShuffleButton","🔀","Shuffle",SM,false)
	py=py+ColH+GAP

	-- Volume bar
	local vf=make("Frame",{Size=UDim2.new(1,0,0,VOL_H),
		Position=UDim2.new(0,0,0,py),BackgroundColor3=C.bg2,BorderSizePixel=0},pc)
	corner(vf,10)
	make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
		VerticalAlignment=Enum.VerticalAlignment.Center,
		HorizontalAlignment=Enum.HorizontalAlignment.Center,
		Padding=UDim.new(0,rs(4,5))},vf)

	local volMuteBtn=make("TextButton",{Name="VolMuteBtn",
		Size=UDim2.new(0,rs(20,22),0,rs(20,22)),LayoutOrder=1,
		BackgroundTransparency=1,BorderSizePixel=0,
		Text="🔊",TextSize=rs(14,16),Font=Enum.Font.Gotham,TextColor3=C.textB},vf)

	local BV=rs(20,22)
	local vmb=make("TextButton",{Name="VolMinBtn",LayoutOrder=2,Size=UDim2.new(0,BV,0,BV),BackgroundColor3=Color3.fromRGB(0,40,38),BorderSizePixel=0,
		Text="−",TextColor3=C.cyan,Font=Enum.Font.GothamBold,TextSize=rs(13,14)},vf)
	corner(vmb,6); ts(vmb,rs(13,14))
	hover(vmb,C.bg3,C.bg4)

	local vlb=make("TextLabel",{Name="VolLabel",LayoutOrder=3,
		Size=UDim2.new(0,rs(36,40),1,0),BackgroundTransparency=1,
		Text="80%",TextColor3=C.textA,Font=Enum.Font.GothamBold,
		TextSize=rs(11,12),TextXAlignment=Enum.TextXAlignment.Center},vf)
	ts(vlb,rs(11,12))

	local vpb=make("TextButton",{Name="VolPlusBtn",LayoutOrder=4,Size=UDim2.new(0,BV,0,BV),BackgroundColor3=Color3.fromRGB(0,40,38),BorderSizePixel=0,
		Text="+",TextColor3=C.cyan,Font=Enum.Font.GothamBold,TextSize=rs(13,14)},vf)
	corner(vpb,6); ts(vpb,rs(13,14))
	hover(vpb,C.bg3,C.bg4)
	py=py+VOL_H+GAP

	-- Info bar (Mode + EQ + Shuffle)
	local ib=make("Frame",{Size=UDim2.new(1,0,0,rs(22,24)),
		Position=UDim2.new(0,0,0,py),BackgroundColor3=C.bg2,BorderSizePixel=0},pc)
	corner(ib,8)
	local ml=make("TextLabel",{Name="ModeLabel",Size=UDim2.new(0.33,0,1,0),
		Position=UDim2.new(0,rs(4,5),0,0),BackgroundTransparency=1,Text="▶ Normal",
		TextColor3=C.textB,Font=Enum.Font.GothamMedium,
		TextSize=rs(9,10),TextXAlignment=Enum.TextXAlignment.Left},ib); ts(ml,rs(9,10))
	local el=make("TextLabel",{Name="EQInfoLabel",Size=UDim2.new(0.34,0,1,0),
		Position=UDim2.new(0.33,0,0,0),BackgroundTransparency=1,Text="EQ: Normal",
		TextColor3=C.amber,Font=Enum.Font.GothamMedium,
		TextSize=rs(9,10),TextXAlignment=Enum.TextXAlignment.Center},ib); ts(el,rs(9,10))
	local sl2=make("TextLabel",{Name="ShuffleLabel",Size=UDim2.new(0.33,-rs(4,5),1,0),
		Position=UDim2.new(0.67,0,0,0),BackgroundTransparency=1,Text="Shuffle: OFF",
		TextColor3=C.textB,Font=Enum.Font.GothamMedium,
		TextSize=rs(9,10),TextXAlignment=Enum.TextXAlignment.Right},ib); ts(sl2,rs(9,10))

	-- Set pc total height
	local pcH=py+rs(22,24)+GAP
	pc.Size=UDim2.new(1,-rs(12,14),0,pcH)
	pc.AutomaticSize=Enum.AutomaticSize.None

	-- 3. PLAYLIST CONTAINER
	local plistC=make("Frame",{Name="PlaylistContainer",
		Size=UDim2.new(1,-rs(12,14),0,ROW_H*9+rs(16,18)),
		Position=UDim2.new(0,rs(6,7),0,CY),
		BackgroundTransparency=1,Visible=false},wrapper)
	local plistS=make("ScrollingFrame",{Name="PlaylistScroll",
		Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,
		ScrollBarThickness=rs(3,4),ScrollBarImageColor3=C.cyan,
		CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},plistC)
	make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,rs(3,4))},plistS)
	pad(plistS,rs(3,4),rs(3,4),rs(3,4),rs(3,4))

	-- 4. FAVORIT CONTAINER
	local favC=make("Frame",{Name="FavoritContainer",
		Size=UDim2.new(1,-rs(12,14),0,ROW_H*9+rs(16,18)),
		Position=UDim2.new(0,rs(6,7),0,CY),
		BackgroundTransparency=1,Visible=false},wrapper)
	local favEmptyLbl=make("TextLabel",{Name="EmptyLabel",
		Size=UDim2.new(1,0,0,50),Position=UDim2.new(0,0,0.3,0),
		BackgroundTransparency=1,Text="★ Belum ada favorit",
		TextColor3=C.textB,TextSize=11,Font=Enum.Font.GothamMedium,
		TextXAlignment=Enum.TextXAlignment.Center,TextWrapped=true,Visible=true},favC)
	local favS=make("ScrollingFrame",{Name="FavoritScroll",
		Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,
		ScrollBarThickness=rs(3,4),ScrollBarImageColor3=C.gold,
		CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
		Visible=false},favC)
	make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,rs(3,4))},favS)
	pad(favS,rs(3,4),rs(3,4),rs(3,4),rs(3,4))

	-- 5. EQ CONTAINER
	local eqC=make("Frame",{Name="EQContainer",
		Size=UDim2.new(1,-rs(12,14),0,ROW_H*8+rs(16,18)),
		Position=UDim2.new(0,rs(6,7),0,CY),
		BackgroundTransparency=1,Visible=false},wrapper)
	make("TextLabel",{Size=UDim2.new(1,0,0,rs(16,18)),Position=UDim2.new(0,0,0,rs(2,3)),
		BackgroundTransparency=1,Text="≋ EQUALIZER",TextColor3=C.amber,
		Font=Enum.Font.GothamBold,TextSize=rs(11,12),
		TextXAlignment=Enum.TextXAlignment.Left},eqC)

	local EQP={{name="Normal",icon="◎",col=C.cyan,desc="Seimbang"},
		{name="Bass",icon="🔊",col=C.amber,desc="Bass berat"},
		{name="Jazz",icon="🎷",col=C.gold,desc="Hangat"},
		{name="Pop",icon="🎤",col=C.pink,desc="Vokal"},
		{name="Electronic",icon="⚡",col=C.teal,desc="Energik"}}
	local ERH=rs(26,28); local eqBtns={}
	for i,d in ipairs(EQP) do
		local ry=rs(22,24)+(i-1)*(ERH+rs(3,4))
		local row=make("Frame",{Size=UDim2.new(1,0,0,ERH),
			Position=UDim2.new(0,0,0,ry),
			BackgroundColor3=C.bg2,BorderSizePixel=0},eqC)
		corner(row,8)
		make("TextLabel",{Size=UDim2.new(0,rs(18,20),1,0),Position=UDim2.new(0,rs(4,5),0,0),
			BackgroundTransparency=1,Text=d.icon,TextSize=rs(13,14),Font=Enum.Font.Gotham},row)
		make("TextLabel",{Size=UDim2.new(1,-rs(65,72),1,0),Position=UDim2.new(0,rs(26,28),0,0),
			BackgroundTransparency=1,Text=d.name.." - "..d.desc,TextColor3=d.col,
			Font=Enum.Font.GothamBold,TextSize=rs(11,12),
			TextXAlignment=Enum.TextXAlignment.Left},row)
		local sb2=make("TextButton",{Name="EQBtn_"..d.name,
			Size=UDim2.new(0,rs(42,46),0,rs(18,20)),
			AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-rs(3,4),0.5,0),
			BackgroundColor3=C.bg4,BorderSizePixel=0,Text="PILIH",TextColor3=d.col,
			Font=Enum.Font.GothamBold,TextSize=rs(9,10)},row)
		corner(sb2,6); ts(sb2,rs(9,10))
		hover(sb2,C.bg3,C.bg4)
		eqBtns[d.name]={row=row,btn=sb2,col=d.col}
	end

	-- Assign semua refs
	ui.PlayButton=playBtn; ui.PauseButton=pauseBtn
	ui.NextButton=nextBtn; ui.PrevButton=prevBtn
	ui.ModeButton=modeBtn; ui.ModeLabel=ml
	ui.ShuffleButton=shuffleBtn; ui.ShuffleLabel=sl2
	ui.EQInfoLabel=el; ui.LoopButton=modeBtn; ui.RepeatButton=modeBtn
	ui.CloseButton=nil
	ui.VolumeBar=vf; ui.VolMinBtn=vmb; ui.VolPlusBtn=vpb
	ui.VolLabel=vlb; ui.VolumeSlider=vlb; ui.VolMuteBtn=volMuteBtn
	ui.PlaylistContainer=plistC; ui.FavoritContainer=favC
	ui.EQContainer=eqC; ui.FavoritScroll=favS
	ui.FavoritEmptyLabel=favEmptyLbl; ui.PlaylistScroll=plistS
	ui.EQButtons=eqBtns; ui.SeekBG=sBG; ui.SeekFill=sf
	ui.UIScale=make("UIScale",{Scale=1},wrapper)

	return ui
end

return UiBuilder