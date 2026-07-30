-- ============================================================
-- ChatTagClient (LocalScript)
-- Lokasi: StarterPlayer > StarterPlayerScripts > ZayinClient > ChatTagClient
-- ============================================================

local Players           = game:GetService("Players")
local TextChatService   = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player     = Players.LocalPlayer

-- Load GameConfig sekali saat script start
local GameConfig = require(
	ReplicatedStorage:WaitForChild("ZayinConfig", 10)
		:WaitForChild("GameConfig", 10)
)

-- Config dari GameConfig
local ROLE_TAGS = GameConfig.ChatTag
local NAME_COLORS = GameConfig.ChatNameColor

-- ============================================================
-- HELPER
-- ============================================================
local function colorToHex(c)
	return string.format("%02X%02X%02X",
		math.floor(c.R * 255),
		math.floor(c.G * 255),
		math.floor(c.B * 255)
	)
end

-- Build prefix tag untuk player tertentu
local function buildPrefix(sender)
	local roleId = sender:GetAttribute("RoleId")
	local isVIP  = sender:GetAttribute("IsVIP") == true

	local tags = {}

	-- Role tag
	if roleId and ROLE_TAGS[roleId] then
		local t   = ROLE_TAGS[roleId]
		local hex = colorToHex(t.Color)
		table.insert(tags, string.format('<b><font color="#%s">[%s]</font></b>', hex, t.Text))
	end

	-- VIP tag (selalu tampil jika VIP, meskipun sudah ada role)
	if isVIP then
		local vip = ROLE_TAGS.VIP
		if vip then
			local hex = colorToHex(vip.Color)
			table.insert(tags, string.format('<b><font color="#%s">[%s]</font></b>', hex, vip.Text))
		end
	end

	return table.concat(tags, " ")
end

-- Build nama berwarna
local function buildName(sender)
	local roleId = sender:GetAttribute("RoleId")
	local isVIP  = sender:GetAttribute("IsVIP") == true

	local nameColorObj = (roleId and NAME_COLORS[roleId])
		or (isVIP and NAME_COLORS.VIP)

	if nameColorObj then
		local hex = colorToHex(nameColorObj)
		return string.format('<b><font color="#%s">%s</font></b> :', hex, sender.DisplayName)
	end

	return nil
end

-- ============================================================
-- OnIncomingMessage
-- ============================================================
TextChatService.OnIncomingMessage = function(message)
	local props = Instance.new("TextChatMessageProperties")

	local textSource = message.TextSource
	if not textSource then return props end

	local sender = Players:GetPlayerByUserId(textSource.UserId)
	if not sender then return props end

	local tagPrefix = buildPrefix(sender)
	local coloredName = buildName(sender)

	if tagPrefix ~= "" and coloredName then
		props.PrefixText = tagPrefix .. " " .. coloredName
	elseif tagPrefix ~= "" then
		props.PrefixText = tagPrefix .. " " .. message.PrefixText
	elseif coloredName then
		props.PrefixText = coloredName
	end

	return props
end

print("[ChatTagClient] Ready!")