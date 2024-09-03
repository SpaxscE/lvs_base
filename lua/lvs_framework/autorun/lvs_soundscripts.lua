
sound.Add( {
	name = "LVS.ION_CANNON_FIRE",
	channel = CHAN_STATIC,
	volume = 1,
	level = 120,
	pitch = {98, 102},
	sound = {
		"^lvs/tournament/weapons/laserrifle/ion_cannon_shot1.wav",
		"^lvs/tournament/weapons/laserrifle/ion_cannon_shot2.wav",
		"^lvs/tournament/weapons/laserrifle/ion_cannon_shot3.wav",
	}
} )

sound.Add( {
	name = "LVS.Physics.Scrape",
	channel = CHAN_STATIC,
	level = 80,
	sound = "lvs/physics/scrape_loop.wav"
} )

sound.Add( {
	name = "LVS.Physics.Wind",
	channel = CHAN_STATIC,
	level = 140,
	sound = "lvs/physics/wind_loop.wav",
} )

sound.Add( {
	name = "LVS.Physics.Water",
	channel = CHAN_STATIC,
	level = 140,
	sound = "lvs/physics/water_loop.wav",
} )

sound.Add( {
	name = "LVS.DYNAMIC_EXPLOSION",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 130,
	pitch = {90, 110},
	sound = "^lvs/explosion_dist.wav"
} )

sound.Add( {
	name = "LVS.MISSILE_EXPLOSION",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 130,
	pitch = {90, 120},
	sound = {
		"ambient/levels/streetwar/city_battle17.wav",
		"ambient/levels/streetwar/city_battle18.wav",
		"ambient/levels/streetwar/city_battle19.wav",
	}
} )

sound.Add( {
	name = "LVS.BOMB_EXPLOSION_DYNAMIC",
	channel = CHAN_STATIC,
	volume = 1,
	level = 135,
	pitch = {90, 110},
	sound = {
		"^lvs/explosions/dyn1.wav",
		"^lvs/explosions/dyn2.wav",
		"^lvs/explosions/dyn3.wav",
		"^lvs/explosions/dyn4.wav",
	}
} )

sound.Add( {
	name = "LVS.BOMB_EXPLOSION",
	channel = CHAN_STATIC,
	volume = 1,
	level = 75,
	pitch = {90, 110},
	sound = {
		"lvs/explosions/close1.wav",
		"lvs/explosions/close2.wav",
		"lvs/explosions/close3.wav",
		"lvs/explosions/close4.wav",
	}
} )

sound.Add( {
	name = "LVS.BULLET_EXPLOSION_DYNAMIC",
	channel = CHAN_STATIC,
	volume = 1,
	level = 135,
	pitch = {90, 110},
	sound = {
		"^lvs/explosions/med_dyn1.wav",
		"^lvs/explosions/med_dyn2.wav",
		"^lvs/explosions/med_dyn3.wav",
		"^lvs/explosions/med_dyn4.wav",
	}
} )

sound.Add( {
	name = "LVS.BULLET_EXPLOSION",
	channel = CHAN_STATIC,
	volume = 1,
	level = 75,
	pitch = {90, 110},
	sound = {
		"lvs/explosions/med_close1.wav",
		"lvs/explosions/med_close2.wav",
		"lvs/explosions/med_close3.wav",
		"lvs/explosions/med_close4.wav",
	}
} )


sound.Add( {
	name = "LVS.EXPLOSION",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 115,
	pitch = {95, 115},
	sound = "lvs/explosion.wav"
} )

if CLIENT then
	local SoundList = {}

	hook.Add( "EntityEmitSound", "!!!lvs_fps_rape_fixer", function( t )
		if not t.Entity.LVS and not t.Entity._LVS then return end

		local SoundFile = t.SoundName

		if SoundList[ SoundFile ] == true then
			return true

		elseif SoundList[ SoundFile ] == false then
			return false

		else
			local File = string.Replace( SoundFile, "^", "" )

			local Exists = file.Exists( "sound/"..File , "GAME" )

			SoundList[ SoundFile ] = Exists

			if not Exists then
				print("[LVS] '"..SoundFile.."' not found. Soundfile will not be played and is filtered for this game session to avoid fps issues.")
			end
		end
	end )
end
