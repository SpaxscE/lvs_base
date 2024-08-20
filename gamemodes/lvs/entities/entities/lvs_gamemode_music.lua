AddCSLuaFile()

ENT.Type            = "anim"

list.Set( "lvsDynamicSongs", "Song1", {
	segments = 5,
	duration = 213,
	stages = 7,
	songs = {
		warmup = {
			[1] = {"guitar1"},
			[2] = {"guitar2"},
			[3] = {"karamba"},
			[4] = {"synth"},
			[5] = {"voices"},
		},
		lowaction = {
			[1] = {"bass"},
			[2] = {"bass","drum1"},
			[3] = {"bass","drum1","guitar1"},
			[4] = {"bass","drum1","guitar1","synth"},
			[5] = {"bass","drum1","guitar1","synth","guitar2"},
			[6] = {"bass","drum1","guitar1","synth","karamba","guitar2"},
			[7] = {"bass","drum1","guitar1","synth","karamba","guitar2","voices"},
		},
		highaction = {
			[1] = {"bass"},
			[2] = {"bass","drum2"},
			[3] = {"bass","drum2","guitar2"},
			[4] = {"bass","drum2","guitar2","synth"},
			[5] = {"bass","drum2","guitar2","synth","karamba"},
			[6] = {"bass","drum2","guitar2","synth","karamba","guitar1"},
			[7] = {"bass","drum2","guitar2","synth","karamba","guitar1","voices"},
		},
	},
	instruments = {
		bass = "lvs/tournament/music/song1/bass.ogg",
		drum1 = "lvs/tournament/music/song1/drum1.ogg",
		drum2 = "lvs/tournament/music/song1/drum2.ogg",
		guitar1 = "lvs/tournament/music/song1/guitar1.ogg",
		guitar2 = "lvs/tournament/music/song1/guitar2.ogg",
		synth = "lvs/tournament/music/song1/synth.ogg",
		karamba = "lvs/tournament/music/song1/karamba.ogg",
		voices = "lvs/tournament/music/song1/voices.ogg",
	},
})

list.Set( "lvsDynamicSongs", "Song2", {
	segments = 20,
	duration = 224.5,
	stages = 7,
	songs = {
		warmup = {
			[1] = {"guitar1"},
			[2] = {"guitar2"},
			[3] = {"karamba"},
			[4] = {"synth"},
			[5] = {"voices"},
		},
		lowaction = {
			[1] = {"bass"},
			[2] = {"bass","drum1"},
			[3] = {"bass","drum1","guitar1"},
			[4] = {"bass","drum1","guitar1","synth"},
			[5] = {"bass","drum1","guitar1","synth","guitar2"},
			[6] = {"bass","drum1","guitar1","synth","karamba","guitar2"},
			[7] = {"bass","drum1","guitar1","synth","karamba","guitar2","voices"},
		},
		highaction = {
			[1] = {"bass"},
			[2] = {"bass","drum2"},
			[3] = {"bass","drum2","guitar2"},
			[4] = {"bass","drum2","guitar2","synth"},
			[5] = {"bass","drum2","guitar2","synth","karamba"},
			[6] = {"bass","drum2","guitar2","synth","karamba","guitar1"},
			[7] = {"bass","drum2","guitar2","synth","karamba","guitar1","voices"},
		},
	},
	instruments = {
		bass = "lvs/tournament/music/song2/bass.ogg",
		drum1 = "lvs/tournament/music/song2/drum1.ogg",
		drum2 = "lvs/tournament/music/song2/drum2.ogg",
		guitar1 = "lvs/tournament/music/song2/guitar1.ogg",
		guitar2 = "lvs/tournament/music/song2/guitar2.ogg",
		synth = "lvs/tournament/music/song2/synth.ogg",
		karamba = "lvs/tournament/music/song2/karamba.ogg",
		voices = "lvs/tournament/music/song2/voices.ogg",
	},
})

function ENT:SetupDataTables()
	self:NetworkVar( "Bool",0, "Active" )
	self:NetworkVar( "String",0, "Song" )

	if SERVER then
		local _, SongName = table.Random( list.Get( "lvsDynamicSongs" ) )

		self:SetSong( SongName )
	end
end

if SERVER then
	local MusicHandler

	hook.Add( "LVS.OnGameStateChanged", "lvs_music_hook", function( oldstate, newstate )
		if not IsValid( MusicHandler ) then return end

		MusicHandler:SetActive( newstate >= GAMESTATE_START and newstate <= GAMESTATE_MAIN )
	end )

	function ENT:Initialize()
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false )

		MusicHandler = self
	end

	function ENT:Think()
		return false
	end

	function ENT:OnRemove()
		MusicHandler = nil
	end

	function ENT:UpdateTransmitState() 
		return TRANSMIT_ALWAYS
	end

else
	function ENT:Initialize()
	end

	local cVarVolume = CreateClientConVar( "lvs_volume_music", 0.1, true, false)
	local volume = cVarVolume and cVarVolume:GetFloat() or 0.1

	cvars.AddChangeCallback( "lvs_volume_music", function( convar, oldValue, newValue ) 
		if newValue == oldValue then return end

		volume = math.Clamp( tonumber( newValue ), 0, 1 )

		for _, ent in pairs( ents.FindByClass( "lvs_gamemode_music" ) ) do
			if volume <= 0 then continue end

			if not ent:GetActive() then continue end

			ent:ModSong()
		end
	end)

	function ENT:GetSongType()
		if GAMEMODE:GetGameState() <= GAMESTATE_START then return "warmup" end

		local GoalPos = GAMEMODE:GetGoalPos()

		local me = LocalPlayer()
		local myPos = me:GetPos()
		local myTeam = me:lvsGetAITeam()

		local DistToGoal = (GoalPos - myPos):Length()

		local ClosestEnemy = 9999999

		for _, ply in pairs( player.GetAll() ) do
			if ply:Team() == TEAM_SPECTATOR or myTeam == ply:lvsGetAITeam() then continue end

			local Pos = ply:GetPos()

			local distToGoal = (GoalPos - Pos):Length()
			local distToMe = (myPos - Pos):Length()

			if distToMe < ClosestEnemy then
				ClosestEnemy = distToMe
			end
		end

		if ClosestEnemy < 4000 and DistToGoal < 6000 then return "highaction" end

		return "lowaction"
	end

	function ENT:GetIntensity()
		local SongData = list.Get( "lvsDynamicSongs" )[ self:GetSong() ]

		if GAMEMODE:GetGameState() <= GAMESTATE_START then
			if not self._RandomWarmupVariant then
				self._RandomWarmupVariant = math.random( 1, #SongData.songs.warmup )
			end

			return self._RandomWarmupVariant
		end

		local Team1, Team2 = GAMEMODE:GetGameProgression()

		local Intensity = 1 + math.Round( math.min( Team1 + Team2, 1 ) * (SongData.stages - 1), 0 )

		return Intensity
	end

	function ENT:GetInstruments()
		if not self.Instruments then
			self.Instruments = {}

			for id, filepath in pairs( list.Get( "lvsDynamicSongs" )[ self:GetSong() ].instruments ) do
				self.Instruments[ id ] = { soundFile = filepath }
			end

		end

		return self.Instruments
	end

	function ENT:ModSong( Restarted )
		local NewSongType = self:GetSongType()
		local NewIntensity = self:GetIntensity()

		local ShouldRestart = false
	
		if self._oldIntensity ~= NewIntensity then
			self._oldIntensity = NewIntensity

			ShouldRestart = true
		end
	
		if self._oldSongType ~= NewSongType then
			self._oldSongType = NewSongType

			ShouldRestart = true
		end

		if not Restarted and ShouldRestart then
			self:ResetSong()
		end

		local availableSongs = list.Get( "lvsDynamicSongs" )[ self:GetSong() ].songs[ NewSongType ]
		local pickedSong = availableSongs[ NewIntensity ]

		local instruments = self:GetInstruments() 

		for id, data in pairs( instruments) do
			if not data.snd then continue end

			if table.HasValue( pickedSong, id ) then
				data.snd:PlayEx( volume, 100 )
			else
				data.snd:Stop()

				instruments[ id ].snd = nil
			end
		end

		return not Restarted and ShouldRestart
	end

	function ENT:ResetSong()
		local ply = LocalPlayer()

		local instruments = self:GetInstruments() 

		for id, data in pairs( instruments) do
			if data.snd then
				instruments[ id ].snd:Stop()
				instruments[ id ].snd = nil
			end

			local snd = CreateSound( ply, data.soundFile )
			snd:SetSoundLevel( 0 )

			instruments[ id ].snd = snd
		end
	end

	function ENT:SetProgression( new )
		self.curProgression = new
	end

	function ENT:GetProgression()
		return (self.curProgression or 0)
	end

	function ENT:StopSong()
		if not self._IsPlaying then return end

		self._IsPlaying = nil
		self.InternalThink = nil

		local instruments = self:GetInstruments() 
	
		for id, data in pairs( instruments ) do
			if not data.snd then continue end

			data.snd:ChangeVolume( 0, 1 )
		end

		timer.Simple( 0.99, function()
			if not IsValid( self ) then return end

			for id, data in pairs( instruments ) do
				if not data.snd then continue end

				instruments[ id ].snd:Stop()
				instruments[ id ].snd = nil
			end
		end )

		self:SetProgression( 0 )
	end

	function ENT:Think()
		if not self:GetActive() or volume <= 0 then

			self:StopSong()

			return
		end

		self._IsPlaying = true

		local T = CurTime()

		if (self.InternalThink or 0) > T then return end

		local SongData = list.Get( "lvsDynamicSongs" )[ self:GetSong() ]

		local progress = SongData.duration / SongData.segments

		self.InternalThink = T + progress

		local curProgression = self:GetProgression()
	
		if curProgression >= SongData.duration then
			curProgression = 0
		end

		local Restarted = false

		if curProgression == 0 then
			self:ResetSong()

			Restarted = true
		end

		local ForceRestarted = self:ModSong( Restarted )

		if ForceRestarted then
			self:SetProgression( 0 )

			return
		end

		self:SetProgression( curProgression + progress )
	end

	function ENT:OnRemove()
	end

	function ENT:Draw()
	end
end
