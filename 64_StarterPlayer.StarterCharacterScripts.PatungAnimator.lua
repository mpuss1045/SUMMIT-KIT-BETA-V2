-- PatungAnimator FIXED
-- Fix: hapus while-loop scan tiap 10 detik (boros CPU semua client)
-- Fix: animatedPatung dibersihkan saat model destroy
-- Optim: gunakan ChildAdded + scan sekali saat init

local DANCE_ANIM_ID = "rbxassetid://507770239"
local animatedPatung = {}

local function animatePatung(model)
	if animatedPatung[model] then return end
	if not model:GetAttribute("ZayinPatung") then return end

	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator", hum)
	end

	animatedPatung[model] = true

	task.spawn(function()
		task.wait(0.5)
		if not model.Parent then
			animatedPatung[model] = nil
			return
		end
		local anim = Instance.new("Animation")
		anim.AnimationId = DANCE_ANIM_ID
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if ok and track then
			track.Looped   = true
			track.Priority = Enum.AnimationPriority.Action4
			track:Play()
		else
			animatedPatung[model] = nil
		end
	end)

	-- Cleanup saat model destroy
	model.Destroying:Connect(function()
		animatedPatung[model] = nil
	end)
end

-- Scan sekali saat init (delay 5 detik agar workspace siap)
task.spawn(function()
	task.wait(5)
	for _, v in pairs(workspace:GetChildren()) do
		if v:GetAttribute("ZayinPatung") then
			task.spawn(animatePatung, v)
		end
	end
end)

-- Deteksi patung baru via ChildAdded (tidak perlu while loop)
workspace.ChildAdded:Connect(function(child)
	if child:GetAttribute("ZayinPatung") then
		task.delay(2, function()
			if child.Parent then animatePatung(child) end
		end)
	end
	-- Handle attribute yang di-set setelah child masuk
	child:GetAttributeChangedSignal("ZayinPatung"):Connect(function()
		if child:GetAttribute("ZayinPatung") then
			animatePatung(child)
		end
	end)
end)

workspace.ChildRemoved:Connect(function(child)
	animatedPatung[child] = nil
end)

print("[PatungAnimator FIXED] Ready!")