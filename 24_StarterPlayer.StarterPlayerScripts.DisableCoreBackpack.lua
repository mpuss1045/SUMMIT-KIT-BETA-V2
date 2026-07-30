-- DisableCoreBackpack (FIXED)
-- Fix: hapus while-true loop, cukup panggil sekali + retry singkat
task.spawn(function()
	for i = 1, 5 do
		pcall(function()
			game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		task.wait(0.5)
	end
end)