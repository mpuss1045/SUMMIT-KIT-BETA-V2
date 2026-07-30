-- GiftGrantStore — simpan hak hasil gift agar permanen lintas sesi
local Players = game:GetService("Players")
local DSS     = game:GetService("DataStoreService")
local SS      = game:GetService("ServerStorage")
local RS      = game:GetService("ReplicatedStorage")

local store = DSS:GetDataStore("ZayinGiftGrants_v1")

-- BindableFunction supaya DonationService bisa mencatat gift
local catat = SS:FindFirstChild("CatatGift")
if not catat then
	catat = Instance.new("BindableEvent")
	catat.Name = "CatatGift"
	catat.Parent = SS
end

local function kunciDS(userId) return "gift_" .. tostring(userId) end

local function bacaHak(userId)
	local ok, data = pcall(function() return store:GetAsync(kunciDS(userId)) end)
	if ok and type(data) == "table" then return data end
	return {}
end

local function beriTool(player, namaTool)
	local VT = SS:FindFirstChild("VIPTools")
	local tpl = VT and VT:FindFirstChild(namaTool)
	if not tpl then return end
	local bp = player:FindFirstChildOfClass("Backpack")
	if bp and not bp:FindFirstChild(namaTool) then
		tpl:Clone().Parent = bp
	end
end

local function terapkanHak(player)
	local hak = bacaHak(player.UserId)
	if hak.vip then player:SetAttribute("IsVIP", true) end
	for namaTool, punya in pairs(hak.tools or {}) do
		if punya then beriTool(player, namaTool) end
	end
end

-- catat gift baru (dipanggil DonationService)
catat.Event:Connect(function(targetUserId, daftarTool, vip)
	local ok = pcall(function()
		store:UpdateAsync(kunciDS(targetUserId), function(old)
			old = (type(old) == "table") and old or {}
			old.tools = old.tools or {}
			for _, t in ipairs(daftarTool or {}) do old.tools[t] = true end
			if vip then old.vip = true end
			return old
		end)
	end)
	if not ok then warn("[GiftGrantStore] gagal simpan untuk", targetUserId) end
end)

local function pasang(p)
	task.spawn(function()
		terapkanHak(p)
	end)
	p.CharacterAdded:Connect(function()
		task.wait(1.5) -- setelah GamepassService selesai
		terapkanHak(p)
	end)
end

Players.PlayerAdded:Connect(pasang)
for _, p in ipairs(Players:GetPlayers()) do pasang(p) end