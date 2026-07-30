-- ============================================================
-- OverheadClient (LocalScript)
-- Lokasi: StarterPlayer > StarterPlayerScripts > ZayinClient > OverheadClient
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local GuiService        = game:GetService("GuiService")
local RunService        = game:GetService("RunService")

local player = Players.LocalPlayer

-- === Remotes ===
local ZayinRemotes    = ReplicatedStorage:WaitForChild("ZayinRemotes", 15)
local RefreshOverhead = ZayinRemotes:WaitForChild("RefreshOverhead", 15)
local SendDeviceType  = ZayinRemotes:WaitForChild("SendDeviceType",  15)

-- ============================================================
-- ICON ASSET IDs
-- ============================================================
local DEVICE_ICONS = {
	PC      = "rbxassetid://83197222357616",
	Mobile  = "rbxassetid://140008946259457",
	Tablet  = "rbxassetid://140008946259457",
	Console = "rbxassetid://72306073822302",
	VR      = "rbxassetid://72306073822302",
}



-- ============================================================
-- DEVICE DETECTION
-- ============================================================
local function getDeviceType()
	if UserInputService.VREnabled then return "VR" end
	if GuiService:IsTenFootInterface() then return "Console" end
	if UserInputService.TouchEnabled and UserInputService.KeyboardEnabled then return "Tablet" end
	if UserInputService.TouchEnabled then return "Mobile" end
	return "PC"
end

local myDevice = getDeviceType()
task.delay(1, function()
	SendDeviceType:FireServer(myDevice)
end)

-- ============================================================
-- VIP ANIMASI GOLD
-- ============================================================
local vipConns = {}
local VIP_COLORS = {
	Color3.fromRGB(255, 215,   0),
	Color3.fromRGB(255, 255, 120),
	Color3.fromRGB(255, 180,   0),
	Color3.fromRGB(255, 140,   0),
}

local function stopVipAnim(uid)
	if vipConns[uid] then vipConns[uid]:Disconnect(); vipConns[uid] = nil end
end

local function startVipAnim(label, uid)
	stopVipAnim(uid)
	local t = 0
	vipConns[uid] = RunService.Heartbeat:Connect(function(dt)
		if not label or not label.Parent then stopVipAnim(uid); return end
		t += dt * 2
		local i1 = math.floor(t) % #VIP_COLORS + 1
		local i2 = (math.floor(t) + 1) % #VIP_COLORS + 1
		label.TextColor3 = VIP_COLORS[i1]:Lerp(VIP_COLORS[i2], t % 1)
	end)
end

-- ============================================================
-- DEVICE ICON SIZE — ikuti TextBounds nama secara realtime
-- ============================================================
local deviceIconConns = {}

local function stopDeviceWatch(uid)
	if deviceIconConns[uid] then
		deviceIconConns[uid]:Disconnect()
		deviceIconConns[uid] = nil
	end
end

local function startDeviceWatch(dl, nm, uid)
	stopDeviceWatch(uid)
	deviceIconConns[uid] = RunService.Heartbeat:Connect(function()
		if not dl or not dl.Parent or not nm or not nm.Parent then
			stopDeviceWatch(uid)
			return
		end
		local textH = nm.TextBounds.Y
		if textH and textH > 8 then
			-- 1.4x ukuran text agar icon lebih besar dan seimbang
			local size = math.clamp(math.floor(textH * 1.4), 16, 48)
			if math.abs(dl.AbsoluteSize.X - size) > 1 then
				dl.Size = UDim2.new(0, size, 0, size)
			end
		end
	end)
end

-- ============================================================
-- ROLE RGB ANIMASI (kelap kelip rainbow)
-- ============================================================
local roleAnimConns = {}

local function stopRoleAnim(uid)
	if roleAnimConns[uid] then
		roleAnimConns[uid]:Disconnect()
		roleAnimConns[uid] = nil
	end
end

local function startRoleAnim(label, uid)
	stopRoleAnim(uid)
	local t = 0
	roleAnimConns[uid] = RunService.Heartbeat:Connect(function(dt)
		if not label or not label.Parent then stopRoleAnim(uid); return end
		t += dt * 1.5
		-- Rainbow HSV cycle
		local h = t % 1
		local r, g, b
		local i = math.floor(h * 6)
		local f = h * 6 - i
		local q = 1 - f
		if     i % 6 == 0 then r, g, b = 1, f, 0
		elseif i % 6 == 1 then r, g, b = q, 1, 0
		elseif i % 6 == 2 then r, g, b = 0, 1, f
		elseif i % 6 == 3 then r, g, b = 0, q, 1
		elseif i % 6 == 4 then r, g, b = f, 0, 1
		elseif i % 6 == 5 then r, g, b = 1, 0, q
		end
		label.TextColor3 = Color3.new(r, g, b)
	end)
end

-- ============================================================
-- ROLE WARNA
-- ============================================================
local ROLE_COLORS = {
	Owner     = Color3.fromRGB(255,  60,  60),
	Developer = Color3.fromRGB(255,  60,  60),
	Admin     = Color3.fromRGB(255, 165,   0),
	Mod       = Color3.fromRGB( 80, 180, 255),
	Staff     = Color3.fromRGB(120, 255, 120),
}
local function getRoleColor(role)
	return ROLE_COLORS[role] or Color3.fromRGB(220, 220, 220)
end


-- ============================================================
-- SETUP BADGE ROW (frame di atas nama)
-- ============================================================

-- ============================================================
-- APPLY OVERHEAD — dipanggil setelah attribute sudah ready
-- ============================================================
local function applyOverhead(p)
	local char = p.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end
	local overhead = head:FindFirstChild("OverheadGui")
	if not overhead then return end

	-- Baca attribute
	local role       = p:GetAttribute("Role") or ""      -- display text (pakai emoji)
	local isVIP      = p:GetAttribute("IsVIP") == true

	-- Pastikan main UIListLayout Vertical
	local mainLayout = overhead:FindFirstChildOfClass("UIListLayout")
	if mainLayout then
		mainLayout.FillDirection       = Enum.FillDirection.Vertical
		mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		mainLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	end



	-- ── CANVAS (baris nama + device) ─────────────────────────
	local canvas = overhead:FindFirstChild("Canvas")
	if canvas then
		-- Pastikan Canvas Horizontal
		local cLayout = canvas:FindFirstChildOfClass("UIListLayout")
		if cLayout then
			cLayout.FillDirection       = Enum.FillDirection.Horizontal
			cLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
			cLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			cLayout.Padding             = UDim.new(0, 4)
			cLayout.SortOrder           = Enum.SortOrder.LayoutOrder
		end

		-- Device icon (kiri nama) — ukuran mengikuti tinggi Canvas
		local dl = canvas:FindFirstChild("Device")
		if dl then
			dl.LayoutOrder = 0
			dl.ScaleType   = Enum.ScaleType.Fit

			-- Ambil tinggi Canvas sebagai referensi ukuran icon
			-- Pakai Scale Y = 1 agar tinggi = tinggi Canvas, lebar auto (AspectRatio)
			-- Pastikan aspect ratio 1:1 agar tidak gepeng
			local arc = dl:FindFirstChildOfClass("UIAspectRatioConstraint")
			if not arc then
				arc = Instance.new("UIAspectRatioConstraint")
				arc.AspectRatio  = 1
				arc.DominantAxis = Enum.DominantAxis.Height
				arc.Parent = dl
			end

			local nm = canvas:FindFirstChild("DisplayName")
			local deviceType = p:GetAttribute("DeviceType") or ""
			local icon = DEVICE_ICONS[deviceType]
			if icon and deviceType ~= "" then
				dl.Image   = icon
				dl.Visible = true
				startDeviceWatch(dl, nm, p.UserId)
			elseif p == player then
				dl.Image   = DEVICE_ICONS[myDevice] or ""
				dl.Visible = dl.Image ~= ""
				if dl.Visible then startDeviceWatch(dl, nm, p.UserId) end
			else
				dl.Visible = false
				stopDeviceWatch(p.UserId)
			end
		end

		-- DisplayName
		local nm = canvas:FindFirstChild("DisplayName")
		if nm then nm.LayoutOrder = 1 end

		-- VIP (kanan nama)
		local vl = canvas:FindFirstChild("VIP")
		if vl then
			vl.LayoutOrder = 2
			if vl.Visible then startVipAnim(vl, p.UserId)
			else stopVipAnim(p.UserId) end
		end

		canvas.LayoutOrder = 2
	end

	-- ── LAYOUT ORDER (atas → bawah) ────────────────────────
	-- 0 = Role (Owner/Admin/dll) paling atas
	-- 2 = Canvas (Device icon | Nama | VIP)
	-- 3 = TitleSummit (🔥 EXPERT)
	-- 4 = TotalSummit (🗻 328x Summit) dekat kepala

	-- ── ROLE (paling atas) ───────────────────────────────────
	local rl = overhead:FindFirstChild("Role")
	if rl then
		rl.LayoutOrder = 0
		if rl.Visible and role ~= "" then
			startRoleAnim(rl, p.UserId)
		else
			stopRoleAnim(p.UserId)
		end
	end


	-- ── CANVAS (nama, layout order 2) ───────────────────────
	if canvas then canvas.LayoutOrder = 2 end

	-- ── TITLE SUMMIT ─────────────────────────────────────────
	local tl = overhead:FindFirstChild("TitleSummit")
	if tl then tl.LayoutOrder = 3 end

	-- ── TOTAL SUMMIT (paling bawah/dekat kepala) ─────────────
	local sl = overhead:FindFirstChild("TotalSummit")
	if sl then sl.LayoutOrder = 4 end
end

-- ============================================================
-- WAIT FOR ATTRIBUTES THEN APPLY
-- Masalah utama: attribute diset server, butuh waktu replikasi ke client
-- Polling sampai attribute Role atau kondisi lain sudah terbaca
-- ============================================================
local function waitAttrAndApply(p, maxWait)
	maxWait = maxWait or 15
	local elapsed = 0

	-- Tunggu overhead muncul dulu
	while elapsed < maxWait do
		if not p.Parent then return end
		local char     = p.Character
		local head     = char and char:FindFirstChild("Head")
		local overhead = head and head:FindFirstChild("OverheadGui")
		if overhead then break end
		task.wait(0.3)
		elapsed += 0.3
	end

	if not p.Parent then return end

	-- Apply pertama kali
	applyOverhead(p)

	-- Apply lagi setelah 0.5s (tunggu DeviceType dari server)
	task.delay(0.5, function()
		if p.Parent then applyOverhead(p) end
	end)

	-- Apply lagi setelah 2s (tunggu Role/IsVerified replikasi)
	task.delay(2, function()
		if p.Parent then applyOverhead(p) end
	end)

	-- Apply lagi setelah 5s (backup final)
	task.delay(5, function()
		if p.Parent then applyOverhead(p) end
	end)
end

-- ============================================================
-- DEBOUNCE
-- ============================================================
local pending = {}
local function scheduleApply(p)
	local uid = p.UserId
	if pending[uid] then return end
	pending[uid] = true
	task.delay(0.2, function()
		pending[uid] = nil
		if p.Parent then applyOverhead(p) end
	end)
end

-- ============================================================
-- SETUP PER PLAYER
-- ============================================================
local function setupPlayer(p)
	-- Respawn
	p.CharacterAdded:Connect(function()
		-- Delay 1.5s beri waktu server rebuild overhead (terutama saat ganti/reset avatar)
		task.delay(1.5, function()
			if p.Parent then
				task.spawn(waitAttrAndApply, p, 12)
			end
		end)
	end)

	-- Sudah spawn
	if p.Character then
		task.spawn(waitAttrAndApply, p, 10)
	end

	-- Watch attribute — apply ulang saat berubah
	for _, attr in ipairs({ "IsVIP", "Role", "RoleId", "DeviceType" }) do
		p:GetAttributeChangedSignal(attr):Connect(function()
			scheduleApply(p)
		end)
	end

	-- Watch summit
	task.spawn(function()
		local ls = p:WaitForChild("leaderstats", 20)
		if not ls then return end
		local sv = ls:WaitForChild("Summit", 20)
		if not sv then return end
		sv.Changed:Connect(function() scheduleApply(p) end)
	end)
end

-- ============================================================
-- RefreshOverhead dari server → apply ulang
-- ============================================================
RefreshOverhead.OnClientEvent:Connect(function(p)
	if not p then return end
	applyOverhead(p)
	task.delay(0.2, function() if p.Parent then applyOverhead(p) end end)
	task.delay(0.8, function() if p.Parent then applyOverhead(p) end end)
end)

-- ============================================================
-- INIT
-- ============================================================
Players.PlayerAdded:Connect(setupPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, p)
end

Players.PlayerRemoving:Connect(function(p)
	stopVipAnim(p.UserId)
	stopRoleAnim(p.UserId)
	stopDeviceWatch(p.UserId)
	pending[p.UserId] = nil
end)

print("[OverheadClient] Ready! Device: " .. myDevice)