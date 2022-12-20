
ENT.Base = "lvs_base_fighterplane"

ENT.PrintName = "BF 109"
ENT.Author = "Luna"
ENT.Information = "German World War 2 Fighterplane"
ENT.Category = "[LVS]"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/bf109.mdl"

ENT.AITEAM = 1

ENT.MaxVelocity = 2500
ENT.MaxPerfVelocity = 1800
ENT.MaxThrust = 25

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 1

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.MaxSlipAnglePitch = 20
ENT.MaxSlipAngleYaw = 10

ENT.MaxHealth = 1000

ENT.WEAPONS = {
	[1] = {
		Icon = Material("lvs_weapons/hmg.png"),
		Ammo = 300,
		Delay = 0.1,
		Attack = function( ent )
			ent.MirrorPrimary = not ent.MirrorPrimary

			local Mirror = ent.MirrorPrimary and -1 or 1

			ent:EmitSound("^test_dist.wav",105,105 + math.cos( CurTime() ) * 10 + math.Rand(-5,5),1,CHAN_WEAPON)

			local bullet = {}
			bullet.Num 	= 1
			bullet.Src 	= ent:LocalToWorld( Vector(109.29,7.13 * Mirror,92.85) )
			bullet.Dir 	= ent:GetForward()
			bullet.Spread 	= Vector( 0.015,  0.015, 0 )
			bullet.TracerName = "lvs_bullet_base"
			bullet.Force	= 10
			bullet.HullSize 	= 25
			bullet.Damage	= 50
			bullet.Velocity = 18000
			bullet.Attacker 	= ent:GetDriver()
			bullet.Callback = function(att, tr, dmginfo)
			end

			ent:FireBullet( bullet )
		end,

		StartAttack = function( ent ) end,
		FinishAttack = function( ent ) end,
		OnSelect = function( ent ) end,
		OnDeselect = function( ent ) end,
		OnThink = function( ent, active ) end,
	},
	[2] = {
		Icon = Material("lvs_weapons/mg.png"),
		Ammo = 300,
		Delay = 0.15,
		Attack = function( ent )
			ent.MirrorSecondary = not ent.MirrorSecondary

			local Mirror = ent.MirrorSecondary and -1 or 1

			ent:EmitSound("^test_dist.wav",105,105 + math.cos( CurTime() ) * 10 + math.Rand(-5,5),1,CHAN_WEAPON)

			local bullet = {}
			bullet.Num 	= 1
			bullet.Src 	= ent:LocalToWorld( Vector(93.58,85.93 * Mirror,63.63) )
			bullet.Dir 	= ent:LocalToWorldAngles( Angle(0,-0.5 * Mirror,0) ):Forward()
			bullet.Spread 	= Vector( 0.015,  0.015, 0 )
			bullet.TracerName = "lvs_bullet_base"
			bullet.Force	= 10
			bullet.HullSize 	= 25
			bullet.Damage	= 50
			bullet.Velocity = 18000
			bullet.Attacker 	= ent:GetDriver()
			bullet.Callback = function(att, tr, dmginfo)
				dmginfo:SetDamageType(DMG_AIRBOAT)
			end

			ent:FireBullet( bullet )
		end,
		StartAttack = function( ent ) end,
		FinishAttack = function( ent ) end,
		OnSelect = function( ent ) end,
		OnDeselect = function( ent ) end,
		OnThink = function( ent, active ) end,
	}
}

ENT.EngineSounds = {
	{
		sound = "^lvs/vehicles/bf109/dist.wav",
		sound_int = "",
		Pitch = 80,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 40,
		FadeIn = 0.35,
		FadeOut = 1,
		FadeSpeed = 1.5,
		UseDoppler = true,
		VolumeMin = 0,
		VolumeMax = 1,
		SoundLevel = 110,
	},
	{
		sound = "lvs/vehicles/bf109/engine_compressor.wav",
		sound_int = "",
		Pitch = 50,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 60,
		FadeIn = 0.35,
		FadeOut = 1,
		FadeSpeed = 5,
		UseDoppler = true,
		VolumeMin = 0,
		VolumeMax = 0.25,
		SoundLevel = 120,
	},
	{
		sound = "lvs/vehicles/bf109/engine_low.wav",
		Pitch = 80,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 300,
		FadeIn = 0,
		FadeOut = 0.15,
		FadeSpeed = 1.5,
		UseDoppler = false,
	},
	{
		sound = "lvs/vehicles/bf109/engine_mid.wav",
		Pitch = 80,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 80,
		FadeIn = 0.15,
		FadeOut = 0.35,
		FadeSpeed = 1.5,
		UseDoppler = true,
	},
	{
		sound = "lvs/vehicles/bf109/engine_high.wav",
		sound_int = "lvs/vehicles/bf109/engine_high_int.wav",
		Pitch = 50,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 60,
		FadeIn = 0.35,
		FadeOut = 1,
		FadeSpeed = 1,
		UseDoppler = true,
	},
}
