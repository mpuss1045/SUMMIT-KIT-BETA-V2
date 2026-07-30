-- AvatarController | LocalScript | v2.0
-- Embed ke AvatarPanel ZayinMenuBaru
-- Fitur: Boy/Girl tab, grid avatar, apply avatar

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)
local M         = UIS.TouchEnabled and not UIS.KeyboardEnabled
local function rs(pc,mob) return M and mob or pc end

-- Data avatar
local Boys = {
	{name="Boy 1",id=8891157967},{name="Boy 2",id=8015593450},
	{name="Boy 3",id=7843828496},{name="Boy 4",id=8352609716},
	{name="Boy 5",id=8968308984},{name="Boy 6",id=4832303740},
	{name="Boy 7",id=9046030552},{name="Boy 8",id=9000844254},
	{name="Boy 9",id=8592887007},{name="Boy 10",id=9093398365},
	{name="Boy 11",id=8935328065},{name="Boy 12",id=8891975253},
}
local Girls = {
	{name="Girl 1",id=7867614019},{name="Girl 2",id=7867615010},
	{name="Girl 3",id=7867616935},{name="Girl 4",id=8071401677},
	{name="Girl 5",id=8071402124},{name="Girl 6",id=8071403762},
	{name="Girl 7",id=8071408433},{name="Girl 8",id=8071406272},
	{name="Girl 9",id=8071405532},{name="Girl 10",id=7867618823},
}

-- Warna (sama dengan Emote/Musik)
local C = {
	bg1  = Color3.fromRGB(12,14,18),
	bg2  = Color3.fromRGB(16,18,24),
	bg3  = Color3.fromRGB(22,24,32),
	bg4  = Color3.fromRGB(28,30,40),
	cyan = Color3.fromRGB(0,210,200),
	gold = Color3.fromRGB(255,200,60),
	pink = Color3.fromRGB(255,60,160),
	blue = Color3.fromRGB(60,140,255),
	green= Color3.fromRGB(40,230,140),
	red  = Color3.fromRGB(255,70,90),
	redbg= Color3.fromRGB(35,10,10),
	textA= Color3.fromRGB(220,230,240),
	textB= Color3.fromRGB(120,140,160),
	textC= Color3.fromRGB(70,90,110),
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

local currentMode = "Boy"
local selectedId  = nil
local activeBtn   = nil

local function applyAvatar(id)
	local avatarFolder = game:GetService("ReplicatedStorage")
		:WaitForChild("ZayinRemotes"):WaitForChild("Avatar")
	local remote = avatarFolder:FindFirstChild("Change")
	if remote then pcall(function() remote:FireServer(id) end) end
end


local function initialize()
	local sg = playerGui:WaitForChild("ZayinMenuBaru", 15)
	if not sg then warn("[AvatarController] ZayinMenuBaru tidak ditemukan!"); return end

	local avatarP = sg:WaitForChild("AvatarPanel", 10)
	if not avatarP then warn("[AvatarController] AvatarPanel tidak ditemukan!"); return end

	local content = avatarP:WaitForChild("Content", 5)
	if not content then warn("[AvatarController] Content tidak ditemukan!"); return end

	-- Bersihkan placeholder
	for _,c in pairs(content:GetChildren()) do
		if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
	end

	-- Ukuran
	local TAB_H  = rs(30,32)
	local CELL_W = rs(76,80)
	local CELL_H = rs(84,88)
	local GAP    = rs(4,5)
	local INFO_H = rs(34,36)
	local BTN_H  = rs(32,34)
	local SCROLL_H = rs(200,220)
	local SEARCH_H = rs(32,34)
	local RESET_H  = rs(32,34)
	local PH = TAB_H+GAP+SEARCH_H+GAP+SCROLL_H+GAP+INFO_H+GAP+BTN_H+GAP+RESET_H+GAP*2

	-- Wrapper
	local wrapper=make("Frame",{Name="AvatarUI",
		Size=UDim2.new(1,0,0,PH),
		BackgroundColor3=C.bg1,BorderSizePixel=0,
		ClipsDescendants=false},content)
	corner(wrapper,12)

	local y=GAP

	-- 1. Tab bar (Boy / Girl)
	local tabBar=make("Frame",{
		Size=UDim2.new(1,-rs(12,14),0,TAB_H),
		Position=UDim2.new(0,rs(6,7),0,y),
		BackgroundColor3=C.bg2,BorderSizePixel=0},wrapper)
	corner(tabBar,10)
	make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
		SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,rs(3,4))},tabBar)
	pad(tabBar,rs(3,4),rs(3,4),rs(3,4),rs(3,4))

	local boyTabBtn=make("TextButton",{Name="BoyTab",LayoutOrder=1,
		Size=UDim2.new(0.5,-rs(2,3),1,0),
		BackgroundColor3=C.blue,BackgroundTransparency=0,
		Text="👦 BOY",TextColor3=C.textA,
		Font=Enum.Font.GothamBold,TextSize=rs(10,11),BorderSizePixel=0},tabBar)
	corner(boyTabBtn,7); ts(boyTabBtn,rs(10,11))

	local girlTabBtn=make("TextButton",{Name="GirlTab",LayoutOrder=2,
		Size=UDim2.new(0.5,-rs(2,3),1,0),
		BackgroundColor3=C.bg4,BackgroundTransparency=0.3,
		Text="👧 GIRL",TextColor3=C.textB,
		Font=Enum.Font.GothamBold,TextSize=rs(10,11),BorderSizePixel=0},tabBar)
	corner(girlTabBtn,7); ts(girlTabBtn,rs(10,11))

	y=y+TAB_H+GAP
	-- Search bar
	local searchBar=make("Frame",{
		Size=UDim2.new(1,-rs(12,14),0,SEARCH_H),
		Position=UDim2.new(0,rs(6,7),0,y),
		BackgroundColor3=C.bg2,BorderSizePixel=0},wrapper)
	corner(searchBar,10)
	local searchIcon=make("TextLabel",{Size=UDim2.new(0,rs(24,26),1,0),
		Position=UDim2.new(0,rs(6,8),0,0),BackgroundTransparency=1,
		Text="🔍",TextSize=rs(13,14),Font=Enum.Font.Gotham,TextColor3=C.textB},searchBar)
	local searchBox=make("TextBox",{Name="SearchBox",
		Size=UDim2.new(1,-rs(32,36),1,-rs(8,10)),
		Position=UDim2.new(0,rs(30,34),0,rs(4,5)),
		BackgroundTransparency=1,BorderSizePixel=0,
		Text="",PlaceholderText="Cari username...",
		PlaceholderColor3=C.textC,TextColor3=C.textA,
		Font=Enum.Font.GothamMedium,TextSize=rs(11,12),
		ClearTextOnFocus=false},searchBar)
	ts(searchBox,rs(11,12))
	y=y+SEARCH_H+GAP


	-- 2. Scroll grid avatar
	local scrollWrap=make("Frame",{
		Size=UDim2.new(1,-rs(12,14),0,SCROLL_H),
		Position=UDim2.new(0,rs(6,7),0,y),
		BackgroundColor3=C.bg2,BorderSizePixel=0},wrapper)
	corner(scrollWrap,10)

	local scroll=make("ScrollingFrame",{Name="AvatarScroll",
		Size=UDim2.new(1,-2,1,-2),Position=UDim2.new(0,1,0,1),
		BackgroundTransparency=1,BorderSizePixel=0,
		ScrollBarThickness=rs(3,4),ScrollBarImageColor3=C.cyan,
		CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},scrollWrap)

	make("UIGridLayout",{
		CellSize=UDim2.new(0,CELL_W,0,CELL_H),
		CellPadding=UDim2.new(0,rs(6,8),0,rs(6,8)),
		HorizontalAlignment=Enum.HorizontalAlignment.Center,
		SortOrder=Enum.SortOrder.LayoutOrder},scroll)
	pad(scroll,rs(6,8),rs(6,8),rs(4,6),rs(4,6))

	y=y+SCROLL_H+GAP

	-- 3. Info selected
	local infoBar=make("Frame",{
		Size=UDim2.new(1,-rs(12,14),0,INFO_H),
		Position=UDim2.new(0,rs(6,7),0,y),
		BackgroundColor3=C.bg2,BorderSizePixel=0},wrapper)
	corner(infoBar,10)

	local selectedLbl=make("TextLabel",{Name="SelectedLabel",
		Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
		Text="Pilih avatar...",TextColor3=C.textB,
		Font=Enum.Font.GothamBold,TextSize=rs(11,12),
		TextXAlignment=Enum.TextXAlignment.Center},infoBar)
	ts(selectedLbl,rs(11,12))
	y=y+INFO_H+GAP

	-- 4. Apply button
	local applyBtn=make("TextButton",{
		Size=UDim2.new(1,-rs(12,14),0,BTN_H),
		Position=UDim2.new(0,rs(6,7),0,y),
		BackgroundColor3=Color3.fromRGB(0,50,48),BorderSizePixel=0,
		Text="TERAPKAN AVATAR",TextColor3=C.cyan,
		Font=Enum.Font.GothamBold,TextSize=rs(11,12)},wrapper)
	corner(applyBtn,10); ts(applyBtn,rs(11,12))
	applyBtn.MouseEnter:Connect(function() applyBtn.BackgroundColor3=Color3.fromRGB(0,70,66) end)
	applyBtn.MouseLeave:Connect(function() applyBtn.BackgroundColor3=Color3.fromRGB(0,50,48) end)
	y=y+BTN_H+GAP

	-- 5. Reset button
	local resetBtn=make("TextButton",{
		Size=UDim2.new(1,-rs(12,14),0,RESET_H),
		Position=UDim2.new(0,rs(6,7),0,y),
		BackgroundColor3=C.redbg,BorderSizePixel=0,
		Text="RESET AVATAR",TextColor3=C.red,
		Font=Enum.Font.GothamBold,TextSize=rs(11,12)},wrapper)
	corner(resetBtn,10); ts(resetBtn,rs(11,12))
	resetBtn.MouseEnter:Connect(function() resetBtn.BackgroundColor3=Color3.fromRGB(55,12,12) end)
	resetBtn.MouseLeave:Connect(function() resetBtn.BackgroundColor3=C.redbg end)


	
	-- Fungsi build grid
	-- Cache thumbnail agar tidak panggil API berulang
local thumbnailCache = {}
local function getCachedThumbnail(userId)
	if thumbnailCache[userId] then return thumbnailCache[userId] end
	local ok, url = pcall(function()
		return game:GetService('Players'):GetUserThumbnailAsync(
			userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
	end)
	local result = (ok and url) or ''
	if result ~= '' then thumbnailCache[userId] = result end
	return result
end

local function buildGrid(list)
		-- Bersihkan
		for _,c in pairs(scroll:GetChildren()) do
			if c:IsA("TextButton") or c:IsA("ImageButton") then c:Destroy() end
		end
		activeBtn = nil

		for i,item in ipairs(list) do
			local cell=make("TextButton",{
				Name="Avatar_"..i,
				BackgroundColor3=C.bg3,BorderSizePixel=0,
				Text="",AutoButtonColor=false,LayoutOrder=i},scroll)
			corner(cell,10)
			do local st=Instance.new("UIStroke"); st.Color=Color3.fromRGB(0,100,95); st.Thickness=1; st.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; st.Parent=cell end

			-- Thumbnail
			local img=make("ImageLabel",{
				Size=UDim2.new(1,-rs(6,8),0.75,0),
				Position=UDim2.new(0,rs(3,4),0,rs(4,6)),
				BackgroundTransparency=1,BorderSizePixel=0,
				Image=getCachedThumbnail(item.id),
				ScaleType=Enum.ScaleType.Fit},cell)

			-- Nama
			local nameLbl=make("TextLabel",{
				Size=UDim2.new(1,0,0.25,0),
				Position=UDim2.new(0,0,0.75,0),
				BackgroundTransparency=1,Text=item.name,
				TextColor3=C.textB,Font=Enum.Font.GothamMedium,
				TextSize=rs(8,9),TextXAlignment=Enum.TextXAlignment.Center,
				TextTruncate=Enum.TextTruncate.AtEnd},cell)
			ts(nameLbl,rs(8,9))

			-- Klik
			cell.MouseButton1Click:Connect(function()
				-- Reset active
				if activeBtn then
					activeBtn.BackgroundColor3=C.bg3
					local cs=activeBtn:FindFirstChildOfClass("UIStroke")
					if cs then cs:Destroy() end
				end
				-- Set active
				activeBtn=cell
				selectedId=item.id
				cell.BackgroundColor3=Color3.fromRGB(0,40,38)
				local s=make("UIStroke",{Color=C.cyan,Thickness=1.5},cell)
				s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
				selectedLbl.Text="✓ "..item.name
				selectedLbl.TextColor3=C.cyan
			end)

			-- Hover
			cell.MouseEnter:Connect(function()
				if activeBtn~=cell then cell.BackgroundColor3=C.bg4 end
			end)
			cell.MouseLeave:Connect(function()
				if activeBtn~=cell then cell.BackgroundColor3=C.bg3 end
			end)
		end
	end

	-- Reset handler
	resetBtn.MouseButton1Click:Connect(function()
		local avatarF=game:GetService("ReplicatedStorage")
			:WaitForChild("ZayinRemotes"):WaitForChild("Avatar")
		local remote=avatarF:FindFirstChild("Reset")
		if remote then pcall(function() remote:FireServer() end) end
		selectedLbl.Text="✓ Avatar direset!"; selectedLbl.TextColor3=C.green
	end)























	-- Search by username Roblox
	local curList=Boys
	searchBox.FocusLost:Connect(function(enterPressed)
		local username=searchBox.Text:match("^%s*(.-)%s*$")
		if username=="" then buildGrid(curList); return end
		selectedLbl.Text="🔍 Mencari..."; selectedLbl.TextColor3=C.gold
		local ok,userId=pcall(function()
			return game:GetService("Players"):GetUserIdFromNameAsync(username)
		end)
		if not ok or not userId then
			selectedLbl.Text="⚠ User tidak ditemukan"; selectedLbl.TextColor3=C.red; return
		end
		buildGrid({{name=username,id=userId}})
		selectedLbl.Text="Preview: "..username; selectedLbl.TextColor3=C.cyan
	end)
	-- Tab switch
	local function switchTab(mode)
		currentMode=mode
		if mode=="Boy" then
			boyTabBtn.BackgroundColor3=C.blue; boyTabBtn.BackgroundTransparency=0; boyTabBtn.TextColor3=C.textA
			girlTabBtn.BackgroundColor3=C.bg4; girlTabBtn.BackgroundTransparency=0.3; girlTabBtn.TextColor3=C.textB
			buildGrid(Boys); curList=Boys
		else
			girlTabBtn.BackgroundColor3=C.pink; girlTabBtn.BackgroundTransparency=0; girlTabBtn.TextColor3=C.textA
			boyTabBtn.BackgroundColor3=C.bg4; boyTabBtn.BackgroundTransparency=0.3; boyTabBtn.TextColor3=C.textB
			buildGrid(Girls); curList=Girls
		end
		selectedId=nil; activeBtn=nil
		selectedLbl.Text="Pilih avatar..."; selectedLbl.TextColor3=C.textB
	end

	boyTabBtn.MouseButton1Click:Connect(function() switchTab("Boy") end)
	girlTabBtn.MouseButton1Click:Connect(function() switchTab("Girl") end)

	-- Apply
	applyBtn.MouseButton1Click:Connect(function()
		if not selectedId then
			selectedLbl.Text="⚠ Pilih avatar dulu!"; selectedLbl.TextColor3=C.gold
			return
		end
		applyBtn.Text="⏳ Menerapkan..."; applyBtn.TextColor3=C.gold
		applyAvatar(selectedId)
		task.delay(1.5, function()
			applyBtn.Text="TERAPKAN AVATAR"; applyBtn.TextColor3=C.cyan
			selectedLbl.Text="✓ Avatar diterapkan!"; selectedLbl.TextColor3=C.green
		end)
	end)

	-- Init tab awal
	switchTab("Boy")
	print("[AvatarController v2.0] Ready!")
end

task.spawn(function()
	task.wait(2)
	local ok,err=pcall(initialize)
	if not ok then warn("[AvatarController ERROR]:", err) end
end)