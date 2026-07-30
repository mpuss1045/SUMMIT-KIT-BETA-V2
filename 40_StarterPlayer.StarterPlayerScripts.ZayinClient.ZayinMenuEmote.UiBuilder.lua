-- UiBuilder Emote v4.0 | Clean rebuild | Campuran style
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
	gold = Color3.fromRGB(255,200,60),
	pink = Color3.fromRGB(255,60,160),
	yelo = Color3.fromRGB(255,200,50),
	green= Color3.fromRGB(40,230,140),
	red  = Color3.fromRGB(255,70,90),
	redbg= Color3.fromRGB(35,10,10),
	textA= Color3.fromRGB(220,230,240),
	textB= Color3.fromRGB(120,140,160),
	textC= Color3.fromRGB(70,90,110),
	white= Color3.fromRGB(255,255,255),
}

local function make(cls,props,parent)
	local i=Instance.new(cls)
	for k,v in pairs(props or {}) do i[k]=v end
	if parent then i.Parent=parent end
	return i
end
local function corner(p,r) make("UICorner",{CornerRadius=UDim.new(0,r or 8)},p) end
local function stroke(p,col,t)
	local s=make("UIStroke",{Color=col,Thickness=t or 1},p)
	s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; return s
end
local function ts(p,mx) make("UITextSizeConstraint",{MaxTextSize=mx,MinTextSize=6},p) end
local function pad(p,t,b,l,r)
	make("UIPadding",{PaddingTop=UDim.new(0,t or 0),PaddingBottom=UDim.new(0,b or 0),
		PaddingLeft=UDim.new(0,l or 0),PaddingRight=UDim.new(0,r or 0)},p)
end

-- Sync Prompt
local _prompt,_yesC,_noC=nil,nil,nil
function UiBuilder.CreateSyncPrompt(parentGui)
	if _prompt then return end
	local sg=make("ScreenGui",{Name="SyncPromptGui",ResetOnSpawn=false,
		ZIndexBehavior=Enum.ZIndexBehavior.Sibling},parentGui)
	local bd=make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(0,0,0),
		BackgroundTransparency=0.5,BorderSizePixel=0,ZIndex=9,Visible=false},sg)
	_prompt=make("Frame",{Name="PromptFrame",
		Size=UDim2.new(0,rs(280,300),0,rs(140,155)),
		Position=UDim2.new(0.5,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),
		BackgroundColor3=C.bg1,BorderSizePixel=0,Visible=false,ZIndex=10},sg)
	corner(_prompt,12); stroke(_prompt,C.cyan,1.5)
	local title=make("TextLabel",{Name="Title",
		Size=UDim2.new(1,-24,0,rs(36,40)),Position=UDim2.new(0,12,0,rs(10,12)),
		BackgroundTransparency=1,TextColor3=C.textA,TextWrapped=true,TextScaled=false,
		TextSize=rs(13,14),Font=Enum.Font.GothamBold,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11},_prompt)
	make("TextLabel",{Size=UDim2.new(1,-24,0,rs(14,16)),
		Position=UDim2.new(0,12,0,rs(50,56)),BackgroundTransparency=1,
		TextColor3=C.textB,Text="Animasi akan disinkronkan",TextSize=rs(10,11),
		Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11},_prompt)
	local BH=rs(32,38)
	local btnY=make("TextButton",{Name="BtnYes",
		Size=UDim2.new(0.5,-14,0,BH),Position=UDim2.new(0,12,1,-BH-10),
		BackgroundColor3=C.green,BorderSizePixel=0,Text="✓  SYNC",
		TextColor3=Color3.fromRGB(0,20,10),Font=Enum.Font.GothamBold,
		TextSize=rs(11,12),ZIndex=11},_prompt)
	corner(btnY,8)
	local btnN=make("TextButton",{Name="BtnNo",
		Size=UDim2.new(0.5,-14,0,BH),Position=UDim2.new(0.5,2,1,-BH-10),
		BackgroundColor3=C.redbg,BorderSizePixel=0,Text="✕  BATAL",
		TextColor3=C.red,Font=Enum.Font.GothamBold,TextSize=rs(11,12),ZIndex=11},_prompt)
	corner(btnN,8); stroke(btnN,C.red,1)
	_prompt:GetPropertyChangedSignal("Visible"):Connect(function() bd.Visible=_prompt.Visible end)
end

function UiBuilder.ShowSyncPrompt(targetName,onYes)
	if not _prompt then return end
	local t=_prompt:FindFirstChild("Title")
	if t then t.Text='Sync dengan "'..targetName..'"?' end
	_prompt.Visible=true
	if _yesC then _yesC:Disconnect() end
	if _noC  then _noC:Disconnect()  end
	_yesC=_prompt.BtnYes.MouseButton1Click:Connect(function()
		_prompt.Visible=false; if onYes then onYes() end
	end)
	_noC=_prompt.BtnNo.MouseButton1Click:Connect(function()
		_prompt.Visible=false
	end)
end

-- Build Emote Panel
function UiBuilder.BuildEmotePanel(targetFrame)
	if targetFrame:FindFirstChild("OuterGlass") then return targetFrame end
	targetFrame.BackgroundTransparency=1

	-- Ukuran
	local SPD_H  = rs(36,38)
	local TAB_H  = rs(30,32)
	local CELL_H = rs(26,28)
	local ROWS   = 6
	local SCROLL_H = CELL_H*ROWS + rs(12,14)
	local STOP_H = rs(36,38)
	local GAP    = rs(4,5)
	local PH     = SPD_H + GAP + TAB_H + GAP + SCROLL_H + GAP + STOP_H + GAP*2

	targetFrame.Size = UDim2.new(1,0,0,PH)

	-- Outer container (tidak ClipsDescendants agar stop tidak terpotong)
	local outer=make("Frame",{Name="OuterGlass",
		Size=UDim2.new(1,0,0,PH),
		BackgroundColor3=C.bg1,BorderSizePixel=0,
		ClipsDescendants=false},targetFrame)
	corner(outer,12)

	local y = GAP

	-- 1. Speed control bar
	local sf=make("Frame",{Name="SliderFrame",
		Size=UDim2.new(1,-rs(12,14),0,SPD_H),
		Position=UDim2.new(0,rs(6,7),0,y),
		BackgroundColor3=C.bg2,BorderSizePixel=0},outer)
	corner(sf,10)

	local SPD_LW=rs(70,74)
	make("TextLabel",{Size=UDim2.new(0,SPD_LW,1,0),Position=UDim2.new(0,rs(8,10),0,0),
		BackgroundTransparency=1,Text="Kecepatan",TextColor3=C.textB,
		Font=Enum.Font.GothamBold,TextSize=rs(11,12),
		TextXAlignment=Enum.TextXAlignment.Left},sf)

	local BW=rs(24,26); local VW=rs(40,44); local RW=rs(46,50); local G=rs(3,4)
	local gX=SPD_LW+rs(12,14)

	local btnMinus=make("TextButton",{Name="BtnMinus",
		Size=UDim2.new(0,BW,0,BW),AnchorPoint=Vector2.new(0,0.5),
		Position=UDim2.new(0,gX,0.5,0),
		BackgroundColor3=C.bg4,BorderSizePixel=0,
		Text="−",TextColor3=C.cyan,Font=Enum.Font.GothamBold,TextSize=rs(14,16)},sf)
	corner(btnMinus,6)
	btnMinus.MouseEnter:Connect(function() btnMinus.BackgroundColor3=C.bg3 end)
	btnMinus.MouseLeave:Connect(function() btnMinus.BackgroundColor3=C.bg4 end)

	make("TextLabel",{Name="Value",
		Size=UDim2.new(0,VW,1,0),Position=UDim2.new(0,gX+BW+G,0,0),
		BackgroundTransparency=1,Text="1.0x",TextColor3=C.textA,
		Font=Enum.Font.GothamBold,TextSize=rs(13,14),
		TextXAlignment=Enum.TextXAlignment.Center},sf)

	local btnPlus=make("TextButton",{Name="BtnPlus",
		Size=UDim2.new(0,BW,0,BW),AnchorPoint=Vector2.new(0,0.5),
		Position=UDim2.new(0,gX+BW+G+VW+G,0.5,0),
		BackgroundColor3=C.bg4,BorderSizePixel=0,
		Text="+",TextColor3=C.cyan,Font=Enum.Font.GothamBold,TextSize=rs(14,16)},sf)
	corner(btnPlus,6)
	btnPlus.MouseEnter:Connect(function() btnPlus.BackgroundColor3=C.bg3 end)
	btnPlus.MouseLeave:Connect(function() btnPlus.BackgroundColor3=C.bg4 end)

	local resetBtn=make("TextButton",{Name="ResetSpeedBtn",
		Size=UDim2.new(0,RW,0,rs(24,26)),AnchorPoint=Vector2.new(1,0.5),
		Position=UDim2.new(1,-rs(6,8),0.5,0),
		BackgroundColor3=Color3.fromRGB(35,8,8),BorderSizePixel=0,
		Text="RESET",TextColor3=C.red,Font=Enum.Font.GothamBold,TextSize=rs(10,11)},sf)
	corner(resetBtn,6); stroke(resetBtn,C.red,1); ts(resetBtn,rs(10,11))
	resetBtn.MouseEnter:Connect(function() resetBtn.BackgroundColor3=Color3.fromRGB(55,12,12) end)
	resetBtn.MouseLeave:Connect(function() resetBtn.BackgroundColor3=Color3.fromRGB(35,8,8) end)

	y = y + SPD_H + GAP

	-- 2. Tab bar
	local TAB_DEFS={
		{name="DanceButton",  label="💃 DANCE", col=C.pink},
		{name="EmoteButton",  label="😎 EMOTE", col=C.yelo},
		{name="FavoriteButton",label="⭐ FAV",  col=C.cyan},
	}
	local tabBar=make("Frame",{Name="TopBar",
		Size=UDim2.new(1,-rs(12,14),0,TAB_H),
		Position=UDim2.new(0,rs(6,7),0,y),
		BackgroundColor3=C.bg2,BorderSizePixel=0},outer)
	corner(tabBar,10)
	make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
		SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,rs(3,4))},tabBar)
	pad(tabBar,rs(3,4),rs(3,4),rs(3,4),rs(3,4))

	for i,d in ipairs(TAB_DEFS) do
		local btn=make("TextButton",{Name=d.name,LayoutOrder=i,
			Size=UDim2.new(0.333,-rs(2.5,3),1,0),
			BackgroundColor3=C.bg4,BackgroundTransparency=0.3,
			Text=d.label,TextColor3=C.textB,
			Font=Enum.Font.GothamBold,TextSize=rs(9,10),
			BorderSizePixel=0},tabBar)
		corner(btn,7); ts(btn,rs(9,10))
		btn.MouseEnter:Connect(function()
			if btn.BackgroundColor3~=d.col then btn.BackgroundTransparency=0.1 end
		end)
		btn.MouseLeave:Connect(function()
			if btn.BackgroundColor3~=d.col then btn.BackgroundTransparency=0.3 end
		end)
	end

	y = y + TAB_H + GAP

	-- 3. Scroll area
	local scrollWrap=make("Frame",{
		Size=UDim2.new(1,-rs(12,14),0,SCROLL_H),
		Position=UDim2.new(0,rs(6,7),0,y),
		BackgroundColor3=C.bg2,BorderSizePixel=0},outer)
	corner(scrollWrap,10)

	local scroll=make("ScrollingFrame",{Name="ScrollingFrame",
		Size=UDim2.new(1,-2,1,-2),Position=UDim2.new(0,1,0,1),
		BackgroundTransparency=1,BorderSizePixel=0,
		ScrollBarThickness=rs(3,4),ScrollBarImageColor3=C.cyan,
		CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
		ScrollingDirection=Enum.ScrollingDirection.Y},scrollWrap)

	make("UIGridLayout",{SortOrder=Enum.SortOrder.LayoutOrder,
		CellPadding=UDim2.new(0,rs(4,5),0,rs(3,4)),
		CellSize=UDim2.new(0.5,-rs(4,5),0,CELL_H)},scroll)
	pad(scroll,rs(3,4),rs(3,4),rs(3,4),rs(3,4))

	-- Template button
	local tmpl=make("TextButton",{Name="Button",
		BackgroundColor3=C.bg3,BackgroundTransparency=0,
		Text="  Template",TextXAlignment=Enum.TextXAlignment.Left,
		TextColor3=C.textA,Font=Enum.Font.GothamMedium,
		TextSize=rs(10,11),Visible=false,BorderSizePixel=0},scroll)
	corner(tmpl,7); ts(tmpl,rs(10,11))
	make("TextLabel",{Name="FavIcon",Active=true,
		Size=UDim2.new(0,rs(18,20),1,0),
		AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-rs(3,4),0,0),
		BackgroundTransparency=1,Text="☆",TextColor3=C.textC,
		Font=Enum.Font.GothamBold,TextSize=rs(12,13)},tmpl)

	y = y + SCROLL_H + GAP

	-- 4. Stop button
	local stopArea=make("Frame",{
		Size=UDim2.new(1,-rs(12,14),0,STOP_H),
		Position=UDim2.new(0,rs(6,7),0,y),
		BackgroundColor3=Color3.fromRGB(0,35,50),BorderSizePixel=0},outer)
	corner(stopArea,10)

	local stopBtn=make("TextButton",{Name="StopButton",
		Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
		Text="⏹  STOP ANIMASI",TextColor3=C.cyan,
		Font=Enum.Font.GothamBold,TextSize=rs(11,12),BorderSizePixel=0},stopArea)
	ts(stopBtn,rs(11,12))
	stopBtn.MouseEnter:Connect(function() stopArea.BackgroundColor3=Color3.fromRGB(0,50,70) end)
	stopBtn.MouseLeave:Connect(function() stopArea.BackgroundColor3=Color3.fromRGB(0,35,50) end)

	return targetFrame
end

return UiBuilder