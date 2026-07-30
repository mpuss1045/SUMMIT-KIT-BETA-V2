-- ============================================================
--  Sync.lua  |  Sinkronisasi animasi  |  v2.0
--  Fix: filter klik di atas UI (tidak trigger sync)
--  Fix: tidak import RunService yang tidak dipakai
--  Optimasi: raycast params dibuat sekali
-- ============================================================

local Sync = {}

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Priority yang dianggap emote/dance
local EMOTE_PRIORITIES = {
	[Enum.AnimationPriority.Action]  = true,
	[Enum.AnimationPriority.Action2] = true,
	[Enum.AnimationPriority.Action3] = true,
	[Enum.AnimationPriority.Action4] = true,
}

-- Raycast params dibuat sekali, diupdate karakter saat diperlukan
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function updateRayFilter()
	if player.Character then
		rayParams.FilterDescendantsInstances = {player.Character}
	end
end

-- Cari track emote/dance aktif dari karakter target
local function getEmoteTrack(char)
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return nil end

	local tracks = animator:GetPlayingAnimationTracks()

	-- Prioritaskan Action priority
	for _, track in ipairs(tracks) do
		if track.IsPlaying and track.Animation
			and EMOTE_PRIORITIES[track.Priority] then
			return track
		end
	end

	-- Fallback: ID besar kemungkinan emote custom
	for _, track in ipairs(tracks) do
		if track.IsPlaying and track.Animation then
			local numId = tonumber(
				(track.Animation.AnimationId or ""):match("%d+") or "0"
			) or 0
			if numId > 1_000_000 then
				return track
			end
		end
	end

	return nil
end

-- Cari karakter dari target instance
local function charFromInstance(inst)
	if not inst then return nil end
	local p = inst.Parent
	if p and p:FindFirstChildOfClass("Humanoid") then return p end
	if p and p.Parent and p.Parent:FindFirstChildOfClass("Humanoid") then return p.Parent end
	return nil
end

-- Cek apakah input sedang di atas elemen GUI
local function isOverGui()
	-- Cek via UIS GetGuiObjectsAtPosition di PlayerGui
	local uis = game:GetService("UserInputService")
	local loc = uis:GetMouseLocation()
	local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then return false end
	local ok, objs = pcall(function() return pg:GetGuiObjectsAtPosition(loc.X, loc.Y) end)
	return ok and #objs > 0
end

function Sync.Init(promptCallback)
	if not promptCallback then return end

	-- PC: mouse click
	local mouse = player:GetMouse()
	-- [P76] klik dimatikan (dipicu dari PlayerInfoPanel)
mouse.Button1Down:Connect(function()
	if true then return end
		-- FIX: jangan trigger jika klik di atas UI
		if isOverGui() then return end

		local char = charFromInstance(mouse.Target)
		if not char then return end

		local targetPlayer = Players:GetPlayerFromCharacter(char)
		if not targetPlayer or targetPlayer == player then return end

		local track = getEmoteTrack(char)
		if not track or not track.Animation then return end
		local animId = track.Animation.AnimationId
		if not animId or animId == "" then return end

		promptCallback(targetPlayer.Name, animId, track.TimePosition, track.Speed)
	end)

	-- Mobile: touch tap di dunia
	UserInputService.TouchTapInWorld:Connect(function(pos, processedByUI)
	if true then return end
		-- processedByUI sudah handle kalau tap di GUI
		if processedByUI then return end

		updateRayFilter()
		local unitRay = camera:ScreenPointToRay(pos.X, pos.Y)
		local result  = workspace:Raycast(unitRay.Origin, unitRay.Direction * 150, rayParams)
		if not result then return end

		local char = charFromInstance(result.Instance)
		if not char then return end

		local targetPlayer = Players:GetPlayerFromCharacter(char)
		if not targetPlayer or targetPlayer == player then return end

		local track = getEmoteTrack(char)
		if not track or not track.Animation then return end
		local animId = track.Animation.AnimationId
		if not animId or animId == "" then return end

		promptCallback(targetPlayer.Name, animId, track.TimePosition, track.Speed)
	end)

	-- Update filter saat respawn
	player.CharacterAdded:Connect(function()
		task.wait(0.1)
		updateRayFilter()
	end)
	updateRayFilter()
end

return Sync