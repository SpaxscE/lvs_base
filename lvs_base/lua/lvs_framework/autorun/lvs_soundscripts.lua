
sound.Add( {
	name = "LVS.Physics.Scrape",
	channel = CHAN_STATIC,
	level = 80,
	sound = "lvs/physics/scrape_loop.wav"
} )

sound.Add( {
	name = "LVS.Physics.Impact",
	channel = CHAN_STATIC,
	level = 75,
	sound = {
		"lvs/physics/impact_soft1.wav",
		"lvs/physics/impact_soft2.wav",
		"lvs/physics/impact_soft3.wav",
		"lvs/physics/impact_soft4.wav",
		"lvs/physics/impact_soft5.wav",
	}
} )

sound.Add( {
	name = "LVS.Physics.Crash",
	channel = CHAN_STATIC,
	level = 75,
	sound = "lvs/physics/impact_hard.wav",
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
	name = "LVS.EXPLOSION",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 115,
	pitch = {95, 115},
	sound = "lvs/explosion.wav"
} )
