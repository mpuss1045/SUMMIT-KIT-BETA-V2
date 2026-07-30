-- SapuPatungDobel — buang patung kembar (nama sama) tiap beberapa detik
task.spawn(function()
	while true do
		task.wait(5)
		local terlihat = {}
		local dihapus = 0
		for _, v in ipairs(workspace:GetChildren()) do
			if v:IsA("Model") and (v:GetAttribute("ZayinPatung") or v.Name:find("PatungChar_", 1, true) or v.Name:find("DonationStatue", 1, true)) then
				local kunci = v.Name
				if terlihat[kunci] then
					-- sudah ada patung dengan nama sama -> buang yang ini
					v:Destroy()
					dihapus += 1
				else
					terlihat[kunci] = v
				end
			end
		end
		if dihapus > 0 then
			print("[SapuPatung] " .. dihapus .. " patung kembar dibuang")
		end
	end
end)