-- ============================================================+
-- CarryPhysicsClient_FINAL.lua
-- Lokasi: StarterPlayer > StarterCharacterScripts
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local player      = Players.LocalPlayer
local CarryRemote = ReplicatedStorage:WaitForChild("CarryRemote", 30)
if not CarryRemote then return end

local isCarried       = false
local descAddedConn   = nil
local heartbeatConn   = nil

-- Cek setiap 12 frame (~5x/detik) — hemat CPU mobile
local INTERVAL  = 12
local tick       = 0

local function applyPart(p: BasePart)
	if p.CanCollide  then p.CanCollide = false end
	if not p.Massless then p.Massless  = true  end
	if p.CollisionGroup ~= "Carried" then
		pcall(function() p.CollisionGroup = "Carried" end)
	end
end
local function restorePart(p: BasePart)
	if p.CanCollide then p.CanCollide = false end
	if p.Massless   then p.Massless   = false end
	if p.CollisionGroup ~= "Players" then
		pcall(function() p.CollisionGroup = "Players" end)
	end
end
local function applyChar(char: Model)
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") then applyPart(d) end
	end
end
local function restoreChar(char: Model)
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") then restorePart(d) end
	end
end

local function startHeartbeat()
	if heartbeatConn then return end
	tick = 0
	heartbeatConn = RunService.Heartbeat:Connect(function()
		if not isCarried then
			heartbeatConn:Disconnect(); heartbeatConn = nil; return
		end
		tick += 1
		if tick < INTERVAL then return end
		tick = 0
		local char = player.Character; if not char then return end
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BasePart") then
				if d.CanCollide                  then d.CanCollide = false end
				if not d.Massless                then d.Massless   = true  end
				if d.CollisionGroup ~= "Carried" then
					pcall(function() d.CollisionGroup = "Carried" end)
				end
			end
		end
	end)
end
local function stopHeartbeat()
	if heartbeatConn then heartbeatConn:Disconnect(); heartbeatConn = nil end
end

local function bindDescAdded()
	if descAddedConn then descAddedConn:Disconnect() end
	local char = player.Character; if not char then return end
	descAddedConn = char.DescendantAdded:Connect(function(d)
		if not isCarried then return end
		if d:IsA("BasePart") then task.defer(function() applyPart(d) end) end
	end)
end

local function startCarried()
	isCarried = true
	local char = player.Character
	if char then applyChar(char); bindDescAdded() end
	startHeartbeat()
end
local function stopCarried()
	isCarried = false
	stopHeartbeat()
	if descAddedConn then descAddedConn:Disconnect(); descAddedConn = nil end
	task.delay(0.2, function()
		local char = player.Character; if char then restoreChar(char) end
	end)
end

CarryRemote.OnClientEvent:Connect(function(action, data)
	if action == "Start" and data and not data.youAreCarrier then
		startCarried()
	elseif action == "End" and data and not data.youAreCarrier then
		stopCarried()
	end
end)

player.CharacterAdded:Connect(function()
	isCarried = false
	stopHeartbeat()
	if descAddedConn then descAddedConn:Disconnect(); descAddedConn = nil end
end)