--[[
  BOOMBOX SERVER v3
  - Auto-next saat lagu selesai via polling (tidak pakai Ended)
  - Broadcast posisi lagu ke client setiap 1 detik
  - Staff tanpa batas (cek via STAFF_LIST, bisa tambah bebas)
  - Seek dihapus (tidak diperlukan)
]]

local Players            = game:GetService("Players")
local DataStoreService   = game:GetService("DataStoreService")
local ServerStorage      = game:GetService("ServerStorage")

-- ── BindableEvents dibuat PERTAMA agar server lain bisa langsung pakai ──
-- Event untuk sync activeSounds dari holster
local syncBE = ServerStorage:FindFirstChild("BoomboxSyncFromHolster")
if not syncBE then
	syncBE = Instance.new("BindableEvent")
	syncBE.Name = "BoomboxSyncFromHolster"
	syncBE.Parent = ServerStorage
end

-- Event untuk pause/resume Equipped handler saat ganti avatar
local pauseEquippedBE = ServerStorage:FindFirstChild("BoomboxPauseEquipped")
if not pauseEquippedBE then
	pauseEquippedBE = Instance.new("BindableEvent")
	pauseEquippedBE.Name = "BoomboxPauseEquipped"
	pauseEquippedBE.Parent = ServerStorage
end

-- Flag: jangan proses Tool.Equipped saat ganti avatar
local equippedPaused = {}  -- {[player] = true}
local Tool         = script.Parent
local Remote       = Tool:WaitForChild("Remote", 10)
local SharedRemote = Tool:WaitForChild("SharedRemote", 10)
local SharedFunc   = Tool:WaitForChild("SharedFunction", 10)
local Handle       = Tool:WaitForChild("Handle", 10)

local SOUND_MAX_DISTANCE = 80
local SOUND_MIN_DISTANCE = 5
local SOUND_EMITTER_SIZE = 10

-- ── STAFF LIST — tambah nama bebas di sini ────────────────
-- Tambah username Roblox sebagai string, atau UserId sebagai angka
local STAFF_LIST = {
	"iTzme_yunnitaa",
	"clairdelune152",
	"kayz_zx",
	"Arzhellaa",
	-- tambah player lain di sini:
	-- "NamaPlayer",
	-- 123456789,  -- atau pakai UserId
}

local function isStaff(player)
	-- [P65] izin dari GameConfig.BoomboxAdminRoles
	local rid = player:GetAttribute("RoleId")
	if type(rid) == "string" and rid ~= "" then
		local ZC = game:GetService("ReplicatedStorage"):FindFirstChild("ZayinConfig")
		local GCm = ZC and ZC:FindFirstChild("GameConfig")
		if GCm then
			local ok, cfg = pcall(require, GCm)
			if ok and cfg and cfg.BoomboxAdminRoles then
				return cfg.BoomboxAdminRoles[rid] == true
			end
		end
	end
	-- fallback daftar lama
	for _, v in ipairs(STAFF_LIST) do
		if type(v)=="number" and v==player.UserId then return true end
		if type(v)=="string" and v==player.Name  then return true end
	end
	return false
end

local activeSounds       = {}
local playerSoundObjects = {}
local playerHolsters     = {}
local playerPollingConns = {}  -- polling per player

local PlaylistStore  = DataStoreService:GetDataStore("BoomboxSharedPlaylist_v1")
local STORE_KEY      = "GlobalPlaylist"
local MAX_SONGS      = 200
local SharedPlaylist = {}

local function loadPlaylist()
	local ok,data=pcall(function() return PlaylistStore:GetAsync(STORE_KEY) end)
	if ok and type(data)=="table" then SharedPlaylist=data else SharedPlaylist={} end
end

local function savePlaylist()
	pcall(function() PlaylistStore:SetAsync(STORE_KEY, SharedPlaylist) end)
end

local function broadcastPlaylistUpdate()
	for _,p in ipairs(Players:GetPlayers()) do
		SharedRemote:FireClient(p,"PlaylistUpdated",SharedPlaylist)
	end
end

local function applySoundSettings(sound)
	sound.RollOffMode        = Enum.RollOffMode.Linear
	sound.RollOffMaxDistance = SOUND_MAX_DISTANCE
	sound.RollOffMinDistance = SOUND_MIN_DISTANCE
	sound.EmitterSize        = SOUND_EMITTER_SIZE
end

local function applyEQPreset(sound, eq)
	for _,obj in pairs(sound:GetChildren()) do
		if obj:IsA("EqualizerSoundEffect") or obj:IsA("ReverbSoundEffect")
			or obj:IsA("PitchShiftSoundEffect") then obj:Destroy() end
	end
	local e=Instance.new("EqualizerSoundEffect"); e.Name="BoomboxEQ"
	if     eq=="Bass"      then e.LowGain=8;  e.MidGain=-2; e.HighGain=-4
	elseif eq=="Jazz"      then e.LowGain=2;  e.MidGain=5;  e.HighGain=3
	elseif eq=="Pop"       then e.LowGain=3;  e.MidGain=0;  e.HighGain=5
	elseif eq=="Rock"      then e.LowGain=6;  e.MidGain=-3; e.HighGain=6
	elseif eq=="Classical" then e.LowGain=-2; e.MidGain=3;  e.HighGain=4
	elseif eq=="Lofi"      then e.LowGain=4;  e.MidGain=-5; e.HighGain=-8
		local rv=Instance.new("ReverbSoundEffect"); rv.WetLevel=0.3; rv.DecayTime=1.5; rv.Parent=sound
	else e.LowGain=0; e.MidGain=0; e.HighGain=0 end
	e.Parent=sound
	sound:SetAttribute("EQName", eq or "Flat")  -- [FIX] simpan nama preset supaya snapshot bisa baca
end

-- ── STOP POLLING ─────────────────────────────────────────
local function stopPolling(player)
	if playerPollingConns[player] then
		playerPollingConns[player]:Disconnect()
		playerPollingConns[player]=nil
	end
end

-- ── DETEKSI LAGU SELESAI ─────────────────────────────────
-- Pakai task.spawn + loop sederhana, tanpa Heartbeat
-- Cek setiap detik: apakah sound masih IsPlaying?
-- Jika berhenti DAN durasi sudah lewat = lagu selesai
-- [P71] flag jeda: pause tidak boleh dianggap lagu selesai
local sedangJeda = {}

local function startPolling(player, sound)
	stopPolling(player)

	-- Simpan "token" untuk cancel
	local cancelled = false
	playerPollingConns[player] = {
		Disconnect = function() cancelled = true end,
		Connected  = true,
	}

	task.spawn(function()
		-- Tunggu sound load (TimeLength > 0)
		local waited = 0
		while sound and sound.Parent and sound.TimeLength <= 0 do
			task.wait(0.5)
			waited += 0.5
			if waited > 10 then return end  -- timeout
		end

		if cancelled or activeSounds[player] ~= sound then return end

		local dur = sound.TimeLength
		-- Tunggu lebih dari 90% durasi baru mulai cek
		local remaining = dur - sound.TimePosition
		local safeWait = math.max(remaining * 0.85, 1)

		-- Broadcast posisi setiap 1 detik selama lagu berjalan
		task.spawn(function()
			while not cancelled and sound and sound.Parent and (sound.IsPlaying or sedangJeda[player]) do
				task.wait(1)
				if not cancelled and sound and sound.Parent then
					Remote:FireClient(player,"SongPosition",
						sound.TimePosition, sound.TimeLength)
				end
			end
		end)

		task.wait(safeWait)

		-- Setelah wait, cek setiap 0.5 detik
		while not cancelled and sound and sound.Parent do
			if activeSounds[player] ~= sound then return end
			if sedangJeda[player] then
				-- [P71] sedang dijeda: tunggu, jangan anggap selesai
				task.wait(0.5)
				continue
			end
			if not sound.IsPlaying then
				-- Berhenti → lagu selesai
				task.wait(0.3)  -- kecil delay biar tidak false positive
				if cancelled or activeSounds[player] ~= sound then return end
				if sound.IsPlaying then
					-- Ternyata lanjut lagi, tunggu lagi
					task.wait(1)
					continue
				end
				-- Benar-benar selesai
				stopPolling(player)
				-- JANGAN hapus sound atau holster — biarkan boombox tetap di punggung
				-- Sound sudah berhenti sendiri (IsPlaying=false)
				-- activeSounds tetap ada agar holster tidak hilang
				Remote:FireClient(player, "SongEnded")
				Remote:FireClient(player, "MusicStatus", false)
				return
			end
			task.wait(0.5)
		end
	end)
end

-- ── PLAY SONG ─────────────────────────────────────────────
local function playSong(player, songId, volume, eqPreset)
	sedangJeda[player] = nil -- [P71] lagu baru = tidak dijeda
	-- [PATCH B5] validasi input dari client
	if songId ~= nil and (type(songId) ~= "number" or songId <= 0 or songId % 1 ~= 0) then return end
	if volume ~= nil and type(volume) ~= "number" then volume = nil end
	if eqPreset ~= nil and type(eqPreset) ~= "string" then eqPreset = nil end
	local character=player.Character; if not character then return end

	stopPolling(player)

	local handle
	local tool=character:FindFirstChild(Tool.Name)
	if tool then handle=tool:FindFirstChild("Handle")
	else handle=character:FindFirstChild("Holster") end
	if not handle then return end

	local oldSound=handle:FindFirstChild("BoomboxSound")
	if oldSound then oldSound:Stop(); oldSound:Destroy() end

	if songId then
		local sound=Instance.new("Sound")
		sound.Name    = "BoomboxSound"
		sound.SoundId = "rbxassetid://"..tostring(songId)
		sound.Volume  = volume or 0.5
		sound.Looped  = false

		applySoundSettings(sound)
		applyEQPreset(sound, eqPreset or "Flat")
		sound.Parent=handle
		sound:Play()

		activeSounds[player]       = sound
		playerSoundObjects[player] = handle

		Remote:FireClient(player, "MusicStatus", true)
		startPolling(player, sound)
	else
		activeSounds[player]       = nil
		playerSoundObjects[player] = nil
		Remote:FireClient(player, "MusicStatus", false)
	end
end

local function setVolume(player, volume)
	local s=activeSounds[player]
	if s and s.Parent then s.Volume=math.clamp(volume,0,1) end
end

local function setLooping(player, looped)
	local s=activeSounds[player]
	if s and s.Parent then s.Looped=looped end
end

local function updateEQ(player, eqPreset)
	local s=activeSounds[player]
	if not s or not s.Parent then return end
	applyEQPreset(s, eqPreset)
end

local function checkMusicStatus(player)
	local s=activeSounds[player]
	if s and s.Parent and s.IsPlaying then return true end
	activeSounds[player]=nil; playerSoundObjects[player]=nil; return false
end

-- ── HOLSTER ───────────────────────────────────────────────
local function createServerHolster(player)
	local character=player.Character; if not character then return nil end
	if playerHolsters[player] then playerHolsters[player]:Destroy(); playerHolsters[player]=nil end
	local old=character:FindFirstChild("Holster"); if old then old:Destroy() end
	local holster=Handle:Clone()
	for _,obj in pairs(holster:GetChildren()) do if obj:IsA("Sound") then obj:Destroy() end end
	holster.Name="Holster"; holster.CanCollide=false; holster.Massless=true; holster.Parent=character
	local torso=character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if torso then
		local w=Instance.new("Weld"); w.Name="HolsterWeld"; w.Part0=torso; w.Part1=holster
		w.C0=CFrame.new(0.8,-0.5,0)*CFrame.Angles(0,0,math.rad(90))+Vector3.new(-1,1,1)
		w.Parent=holster
	end
	playerHolsters[player]=holster; return holster
end

local function removeServerHolster(player)
	if playerHolsters[player] then playerHolsters[player]:Destroy(); playerHolsters[player]=nil end
	local ch=player.Character
	if ch then local h=ch:FindFirstChild("Holster"); if h then h:Destroy() end end
end

local function copySound(srcSound, dstParent, player)
	-- Copy sound ke parent baru dan restart polling
	local timePos  = srcSound.TimePosition
	local soundId  = srcSound.SoundId
	local volume   = srcSound.Volume
	local isPlay   = srcSound.IsPlaying
	local looped   = srcSound.Looped
	local eqName   = srcSound:GetAttribute("EQName")  -- [FIX] bawa nama preset EQ
	local eqData   = {}
	local eq       = srcSound:FindFirstChild("BoomboxEQ")
	if eq then eqData={LowGain=eq.LowGain,MidGain=eq.MidGain,HighGain=eq.HighGain} end
	local hasReverb= srcSound:FindFirstChildOfClass("ReverbSoundEffect")~=nil
	srcSound:Destroy()

	local newSound=Instance.new("Sound")
	newSound.Name="BoomboxSound"; newSound.SoundId=soundId
	newSound.Volume=volume; newSound.Looped=looped
	newSound.Parent=dstParent
	applySoundSettings(newSound)
	if eqName ~= nil then newSound:SetAttribute("EQName", eqName) end  -- [FIX] pertahankan EQName lintas transfer

	if eqData.LowGain~=nil then
		local e=Instance.new("EqualizerSoundEffect")
		e.Name="BoomboxEQ"; e.LowGain=eqData.LowGain
		e.MidGain=eqData.MidGain; e.HighGain=eqData.HighGain; e.Parent=newSound
	end
	if hasReverb then
		local rv=Instance.new("ReverbSoundEffect")
		rv.WetLevel=0.3; rv.DecayTime=1.5; rv.Parent=newSound
	end

	activeSounds[player]       = newSound
	playerSoundObjects[player] = dstParent

	if isPlay then
		newSound:Play()
		task.wait(0.05)
		pcall(function() newSound.TimePosition = timePos end)
		startPolling(player, newSound)
	end
	return newSound
end

local function transferSoundToBackholder(player)
	local sound=activeSounds[player]; if not sound then return end
	local character=player.Character; if not character then return end
	local holster=createServerHolster(player); if not holster then return end
	task.wait(0.1)
	local tool=character:FindFirstChild(Tool.Name)
	if tool then
		local h=tool:FindFirstChild("Handle")
		if h then for _,obj in pairs(h:GetChildren()) do if obj:IsA("Sound") then obj:Destroy() end end end
	end
	stopPolling(player)
	copySound(sound, holster, player)
end

local function transferSoundToHandle(player)
	local sound=activeSounds[player]; if not sound then return end
	local character=player.Character; if not character then return end
	local tool=character:FindFirstChild(Tool.Name); if not tool then return end
	local handle=tool:FindFirstChild("Handle"); if not handle then return end
	if sound.Parent~=handle then
		stopPolling(player)
		copySound(sound, handle, player)
	end
	removeServerHolster(player) -- [FIX] hapus holster SETELAH sound dipindah
end

-- ── REMOTE HANDLERS ───────────────────────────────────────
-- [PATCH B5] rate limit per pemain per aksi
local _actCD = {}
local function _tooFast(player, key, gap)
	local now = os.clock()
	local k = tostring(player.UserId) .. key
	if _actCD[k] and now - _actCD[k] < gap then return true end
	_actCD[k] = now
	return false
end

SharedFunc.OnServerInvoke = function(player, action, ...)
	local args={...}
	if action=="GetPlaylist" then return SharedPlaylist
	elseif action=="AddSong" then
		if _tooFast(player, "add", 5) then return false end
		local id,name,addedBy=args[1],args[2],args[3]
		if type(id)~="number" or id<=0 then return false end
		if type(name)~="string" or name=="" then name="ID: "..id end
		for _,s in ipairs(SharedPlaylist) do if s.ID==id then return false end end
		if #SharedPlaylist>=MAX_SONGS then return false end
		table.insert(SharedPlaylist,{
			Name=name:sub(1,60),ID=id,
			AddedBy=(addedBy or player.Name):sub(1,30),
			Favorite=false,
		})
		savePlaylist(); broadcastPlaylistUpdate(); return true
	elseif action=="RemoveSong" then
		-- [P65] jaga RemoveSong: hanya admin
		if not isStaff(player) then return false end
		local id=args[1]
		for i,s in ipairs(SharedPlaylist) do
			if s.ID==id then
				table.remove(SharedPlaylist,i)
				savePlaylist(); broadcastPlaylistUpdate(); return true
			end
		end
		return false
	end
	return false
end

Remote.OnServerEvent:Connect(function(player, action, ...)
	local args={...}
	-- [P70] pause/resume: jeda tanpa menghapus posisi lagu
	if action == "PauseSong" then
		local snd = activeSounds[player]
		if snd and snd.Parent then
			snd:Pause()
			sedangJeda[player] = true
			Remote:FireClient(player, "MusicStatus", false)
		end
		return
	elseif action == "ResumeSong" then
		local snd = activeSounds[player]
		if snd and snd.Parent then
			sedangJeda[player] = nil
			if snd.TimePosition > 0 then snd:Resume() else snd:Play() end
			Remote:FireClient(player, "MusicStatus", true)
		else
			-- [FIX] tak ada sound untuk di-resume (mis. sudah stop) → beri tahu client supaya play biasa
			Remote:FireClient(player, "ResumeFailed")
		end
		return
	end
	-- [PATCH B5] rate limit
	if action == "PlaySong"  and _tooFast(player, "play", 1)    then return end
	if action == "SeekSong"  and _tooFast(player, "seek", 0.3)  then return end
	if action == "UpdateEQ"  and _tooFast(player, "eq",   0.5)  then return end
	if action == "SetVolume" and _tooFast(player, "vol",  0.1)  then return end
	if     action=="RequestMusicStatus" then Remote:FireClient(player,"MusicStatus",checkMusicStatus(player))
	elseif action=="PlaySong"           then playSong(player,args[1],args[2],args[3])
	elseif action=="SetVolume"          then setVolume(player,args[1])
	elseif action=="SetLooping"         then setLooping(player,args[1])
	elseif action=="UpdateEQ"           then updateEQ(player,args[1])
	elseif action=="SeekSong"           then
		local pct=args[1]
		if type(pct)=="number" then
			local sound=activeSounds[player]
			if sound and sound.Parent and sound.TimeLength>0 then
				local newPos=math.clamp(pct*sound.TimeLength, 0, sound.TimeLength-0.5)
				sound:Pause()
				sound.TimePosition=newPos
				sound:Resume()
				-- Kirim posisi baru ke client
				Remote:FireClient(player,"SongPosition",newPos,sound.TimeLength)
				-- FIX: restart polling agar deteksi lagu selesai akurat setelah seek
				startPolling(player, sound)
			end
		end
	elseif action=="Activate"           then Remote:FireClient(player,"ChooseSong")
	elseif action=="TransferToBackholder" then transferSoundToBackholder(player)
	elseif action=="TransferToHandle"   then transferSoundToHandle(player)
	end
end)

Tool.Equipped:Connect(function()
	local player=Players:GetPlayerFromCharacter(Tool.Parent); if not player then return end
	-- Jangan proses saat ganti avatar (sistem avatar lama set flag ini)
	if equippedPaused[player] then
		return
	end
	task.wait(0.1); transferSoundToHandle(player) -- [FIX] removeServerHolster dihapus; transferSoundToHandle sudah bersihkan holster setelah sound aman dipindah
end)
Tool.Unequipped:Connect(function()
	local player=Players:GetPlayerFromCharacter(Tool.Parent); if not player then return end
	-- Jangan proses saat ganti avatar
	if equippedPaused[player] then
		return
	end
	task.wait(0.2); transferSoundToBackholder(player)
end)

local function cleanupPlayer(player)
	stopPolling(player)
	if activeSounds[player] then activeSounds[player]:Stop(); activeSounds[player]:Destroy(); activeSounds[player]=nil end
	playerSoundObjects[player]=nil
	playerHolsters[player]=nil
	equippedPaused[player]=nil; sedangJeda[player]=nil  -- cleanup flag ganti avatar
	local uidp = tostring(player.UserId)
	for k in pairs(_actCD) do if k:sub(1, #uidp) == uidp then _actCD[k] = nil end end
	removeServerHolster(player)
end

-- [PATCH P4] jembatan avatar: AvatarService minta save/restore lewat BindableEvent
local snapBE = ServerStorage:FindFirstChild("BoomboxSnapshot")
if not snapBE then
	snapBE = Instance.new("BindableEvent")
	snapBE.Name = "BoomboxSnapshot"
	snapBE.Parent = ServerStorage
end

-- [PATCH P4] snapshot musik: simpan sebelum karakter hilang, pulihkan setelah lahir
local musicSnapshot = {} -- [userId] = {songId, timePos, volume, eq}

local function ambilSnapshot(player)
	-- [FIX] jangan timpa snapshot lama dengan yang kosong
	local s = activeSounds[player]
	-- [FIX4] kalau tak ada sound aktif (mis. restore respawn belum kelar saat ganti avatar),
	-- fallback ambil dari snapshot 'terakhir' milik BoomboxRespawnFix
	if not (s and s.Parent and s.SoundId ~= "") then
		if musicSnapshot[player.UserId] then return end -- snapshot internal masih ada, biarkan
		local bf = game:GetService("ServerStorage"):FindFirstChild("GetTerakhirSnapshot")
		if bf then
			local data = bf:Invoke(player.UserId)
			if data and data.songId and data.songId > 0 then
				musicSnapshot[player.UserId] = {
					songId  = data.songId,
					timePos = data.timePos or 0,
					volume  = data.volume or 0.5,
					eq      = data.eq or "Flat",
					playing = true,
				}
			end
		end
		return
	end
	local eqName = "Flat"
	local eq = s:FindFirstChild("BoomboxEQ")
	if eq then eqName = tostring(s:GetAttribute("EQName") or "Flat") end
	musicSnapshot[player.UserId] = {
		songId  = tonumber(s.SoundId:match("%d+") or "0") or 0,
		timePos = s.TimePosition,
		volume  = s.Volume,
		eq      = eqName,
		playing = s.IsPlaying,
	}
end

local function pulihkanSnapshot(player, snapIn)
	local snap = snapIn or musicSnapshot[player.UserId]
	if not (snap and snap.songId and snap.songId > 0 and snap.playing) then return end
	-- [FIX] snapshot TIDAK dihapus di sini — hanya setelah restore sukses
	task.wait(1.2) -- [P9] jeda dikembalikan
	local char = player.Character
	for _ = 1, 20 do
		if char and char.Parent and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) then break end
		task.wait(0.2)
		char = player.Character
	end
	if not char or not char.Parent then warn("[Boombox] restore batal: karakter belum siap") return end
	local holster = createServerHolster(player)
	if not holster then return end
	local sound = Instance.new("Sound")
	sound.Name    = "BoomboxSound"
	sound.SoundId = "rbxassetid://" .. tostring(snap.songId)
	sound.Volume  = snap.volume or 0.5
	sound.Looped  = false
	applySoundSettings(sound)
	applyEQPreset(sound, snap.eq or "Flat")
	sound.Parent = holster
	sound:Play()
	task.wait(0.08)
	pcall(function() sound.TimePosition = snap.timePos or 0 end)
	activeSounds[player]       = sound
	playerSoundObjects[player] = holster
	startPolling(player, sound)
	musicSnapshot[player.UserId] = nil -- [FIX] baru dihapus setelah sukses
	Remote:FireClient(player, "MusicStatus", true)
	Remote:FireClient(player, "RestoredSong", snap.songId, sound.Volume, snap.eq or "Flat") -- [FIX] kirim nama EQ ke client
end

-- [FIX] pemicu restore dipindah ke ServerScriptService.BoomboxRespawnFix

-- [PATCH P5] pemicu dari luar tool: saat respawn, tool ini ikut hancur
-- sehingga Humanoid.Died tidak sempat jalan. Player.CharacterRemoving aman
-- karena terpasang pada objek Player yang tetap hidup.
local function pasangRemoving(p)
	p.CharacterRemoving:Connect(function()
		ambilSnapshot(p)
	end)
end
Players.PlayerAdded:Connect(pasangRemoving)
for _, p in ipairs(Players:GetPlayers()) do pasangRemoving(p) end

-- [PATCH P4] handler jembatan
snapBE.Event:Connect(function(player, aksi, dataLuar)
	if aksi == "save" then
		ambilSnapshot(player)
		local s = activeSounds[player]
		if s and s.Parent then s:Stop(); s:Destroy() end
		activeSounds[player] = nil
		removeServerHolster(player)
	elseif aksi == "restore" then
		task.spawn(pulihkanSnapshot, player)
	elseif aksi == "restoreWith" then
		task.spawn(function() pulihkanSnapshot(player, dataLuar) end)
	end
end)

Players.PlayerRemoving:Connect(function(p)
	musicSnapshot[p.UserId] = nil
	cleanupPlayer(p)
end)
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function(ch)
		ch:WaitForChild("Humanoid", 10).Died:Connect(function()
			-- [PATCH P4] ambil snapshot sebelum cleanup
			ambilSnapshot(p)
			cleanupPlayer(p)
		end)
	end)
end)
game:BindToClose(function() savePlaylist() end)

-- [PATCH] listener restore-avatar dihapus (sistem AvatarChanger sudah tidak ada)

loadPlaylist()

-- ── Handler pause/resume Equipped dari sistem avatar lama ──
pauseEquippedBE.Event:Connect(function(player, pause)
	if pause then
		equippedPaused[player] = true
	else
		equippedPaused[player] = nil
	end
end)

-- ── Handler sync dari sistem avatar lama ──
syncBE.Event:Connect(function(player)
	if not player or not player.Character then return end
	local holster = player.Character:FindFirstChild("Holster")
	if not holster then return end
	local sound = holster:FindFirstChild("BoomboxSound")
	if not sound then return end
	stopPolling(player)
	activeSounds[player]       = sound
	playerSoundObjects[player] = holster
	if sound.IsPlaying then
		startPolling(player, sound)
	end
	Remote:FireClient(player, "MusicStatus", sound.IsPlaying)
end)