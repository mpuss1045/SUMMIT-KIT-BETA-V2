local players = game:GetService("Players")
local runservice = game:GetService("RunService")
local player = players.LocalPlayer

local air_turn_speed = 16
local air_friction    = 10
local snap_strength   = 0.95
local boost_duration  = 0.12
local boost_force     = 0.6
local boost_extra     = 1
local deadzone        = 0.05

local character, humanoid, root
local air_velocity = Vector3.zero
local boost_timer  = 0

-- ✅ Simpan koneksi agar bisa di-Disconnect
local stateChangedConn = nil
local renderSteppedConn = nil

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function get_move_direction()
	if not humanoid then return Vector3.zero end
	local dir = flat(humanoid.MoveDirection)
	if dir.Magnitude < deadzone then return Vector3.zero end
	return dir.Unit
end

local function clamp_horizontal(v, walkspeed)
	local max_speed = walkspeed + boost_extra
	if v.Magnitude > max_speed then
		return v.Unit * max_speed
	end
	return v
end

local function is_airborne()
	if not humanoid then return false end
	local state = humanoid:GetState()
	return state == Enum.HumanoidStateType.Jumping
		or state == Enum.HumanoidStateType.Freefall
end

local function apply_velocity(v)
	local current = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(v.X, current.Y, v.Z)
end

local function setup_character(char)
	-- ✅ Disconnect koneksi lama sebelum buat yang baru
	if stateChangedConn then
		stateChangedConn:Disconnect()
		stateChangedConn = nil
	end

	character    = char
	humanoid     = char:WaitForChild("Humanoid", 10)
	root         = char:WaitForChild("HumanoidRootPart", 10)
	boost_timer  = 0
	air_velocity = Vector3.zero

	-- ✅ Simpan koneksi StateChanged
	stateChangedConn = humanoid.StateChanged:Connect(function(_, state)
		if state == Enum.HumanoidStateType.Jumping then
			local move_dir = get_move_direction()
			local walkspeed = humanoid.WalkSpeed
			if move_dir.Magnitude > deadzone then
				air_velocity = move_dir * (walkspeed + boost_extra)
				boost_timer  = boost_duration
				apply_velocity(air_velocity)
			end
		end
	end)

	-- ✅ Bersihkan saat karakter dihapus
	char.Destroying:Connect(function()
		if stateChangedConn then
			stateChangedConn:Disconnect()
			stateChangedConn = nil
		end
		character = nil
		humanoid  = nil
		root      = nil
	end)
end

-- ✅ Simpan RenderStepped connection
renderSteppedConn = runservice.RenderStepped:Connect(function(dt)
	if not character or not humanoid or not root then return end

	local walkspeed = humanoid.WalkSpeed
	local move_dir  = get_move_direction()
	local velocity  = root.AssemblyLinearVelocity
	local horizontal = flat(velocity)

	if not is_airborne() then
		air_velocity = horizontal
		boost_timer  = 0
		return
	end

	if move_dir.Magnitude > deadzone then
		local target      = move_dir * (walkspeed + boost_extra)
		local alpha       = math.clamp(air_turn_speed * dt, 0, 1)
		local snap_target = air_velocity:Lerp(target, snap_strength)
		air_velocity      = air_velocity:Lerp(snap_target, alpha)
	else
		local alpha = math.clamp(air_friction * dt, 0, 1)
		air_velocity = air_velocity:Lerp(Vector3.zero, alpha)
	end

	if boost_timer > 0 and move_dir.Magnitude > deadzone then
		local boost  = move_dir * (walkspeed + boost_extra) * boost_force
		air_velocity += boost * dt * 10
		boost_timer  -= dt
	end

	air_velocity = clamp_horizontal(air_velocity, walkspeed)
	apply_velocity(air_velocity)
end)

-- ✅ Simpan CharacterAdded connection
local characterAddedConn = player.CharacterAdded:Connect(setup_character)

if player.Character then
	setup_character(player.Character)
end