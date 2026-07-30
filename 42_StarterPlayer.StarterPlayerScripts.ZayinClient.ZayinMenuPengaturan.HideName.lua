-- HideName UPDATED
-- Tambahan: toggle _G.ZayinHideOverhead agar ZayinOverheadClient ikut hide
-- Lokasi: StarterPlayer/StarterPlayerScripts/ZayinClient/ZayinMenuPengaturan/HideName

local HideName = {}
local Players = game:GetService("Players")

function HideName.Toggle(hide)
	-- Set global flag untuk ZayinOverheadClient
	_G.ZayinHideOverhead = hide

	-- Sembunyikan BillboardGui overhead ZayinSystem
	for _, p in pairs(Players:GetPlayers()) do
		if p.Character then
			local head = p.Character:FindFirstChild("Head")
			if head then
				local overhead = head:FindFirstChild("ZayinOverhead")
				if overhead then overhead.Enabled = not hide end
			end
		end
	end

	-- Sembunyikan BillboardGui nama bawaan Roblox
	for _, p in pairs(Players:GetPlayers()) do
		if p.Character then
			local head = p.Character:FindFirstChild("Head")
			if head then
				for _, gui in pairs(head:GetChildren()) do
					if gui:IsA("BillboardGui") and gui.Name ~= "ZayinOverhead" then
						gui.Enabled = not hide
					end
				end
			end
		end
	end

	-- API overhead lama jika masih ada
	if _G.OverheadTitleAPI and _G.OverheadTitleAPI.setHideTitle then
		_G.OverheadTitleAPI.setHideTitle(hide)
	end
end

return HideName