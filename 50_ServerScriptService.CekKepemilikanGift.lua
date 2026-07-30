-- CekKepemilikanGift — beri tahu client item apa saja yang sudah dimiliki pemain
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local DF = RS:FindFirstChild("DonationSystem")
if not DF then
	DF = Instance.new("Folder"); DF.Name = "DonationSystem"; DF.Parent = RS
end

local rf = DF:FindFirstChild("CekKepemilikan")
if not rf then
	rf = Instance.new("RemoteFunction")
	rf.Name = "CekKepemilikan"
	rf.Parent = DF
end

local function punyaTool(player, namaTool)
	local bp = player:FindFirstChildOfClass("Backpack")
	if bp and bp:FindFirstChild(namaTool) then return true end
	local ch = player.Character
	if ch and ch:FindFirstChild(namaTool) then return true end
	return false
end

rf.OnServerInvoke = function(_, targetUserId)
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target then return {} end
	local punyaCoil = punyaTool(target, "CoiL VIP")
	local punyaBoom = punyaTool(target, "BoomBox")
	local punyaVIP  = target:GetAttribute("IsVIP") == true
	return {
		CoilVIP   = punyaCoil,
		Boombox   = punyaBoom,
		BundleVIP = (punyaCoil and punyaBoom and punyaVIP),
	}
end