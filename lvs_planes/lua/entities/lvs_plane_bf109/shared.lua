
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
ENT.MaxThrust = 1250

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 1

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.MaxSlipAnglePitch = 20
ENT.MaxSlipAngleYaw = 10

ENT.MaxHealth = 1000

function ENT:InitWeapons()
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/mg.png")
	weapon.Ammo = 1000
	weapon.Delay = 0.1
	weapon.Attack = function( ent )
		ent.MirrorPrimary = not ent.MirrorPrimary

		local Mirror = ent.MirrorPrimary and -1 or 1

		local bullet = {}
		bullet.Src 	= ent:LocalToWorld( Vector(109.29,7.13 * Mirror,92.85) )
		bullet.Dir 	= ent:GetForward()
		bullet.Spread 	= Vector( 0.015,  0.015, 0 )
		bullet.TracerName = "lvs_tracer_white"
		bullet.Force	= 10
		bullet.HullSize 	= 50
		bullet.Damage	= 10
		bullet.Velocity = 30000
		bullet.Attacker 	= ent:GetDriver()
		bullet.Callback = function(att, tr, dmginfo) end
		ent:FireBullet( bullet )
	end
	weapon.StartAttack = function( ent )
		if not IsValid( ent.SoundEmitter1 ) then
			ent.SoundEmitter1 = ent:AddSoundEmitter( Vector(109.29,0,92.85), "lvs/weapons/mg_light_loop.wav", "lvs/weapons/mg_light_loop_interior.wav" )
			ent.SoundEmitter1:SetSoundLevel( 95 )
		end
	
		ent.SoundEmitter1:Play()
	end
	weapon.FinishAttack = function( ent )
		if IsValid( ent.SoundEmitter1 ) then
			ent.SoundEmitter1:Stop()
		end
	end
	weapon.OnSelect = function( ent ) ent:EmitSound("physics/metal/weapon_impact_soft3.wav") end
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	self:AddWeapon( weapon )



	local weapon = {}
	weapon.Icon = Material("lvs/weapons/hmg.png")
	weapon.Ammo = 300
	weapon.Delay = 0.14
	weapon.Attack = function( ent )
		ent.MirrorSecondary = not ent.MirrorSecondary

		local Mirror = ent.MirrorSecondary and -1 or 1

		local bullet = {}
		bullet.Src 	= ent:LocalToWorld( Vector(93.58,85.93 * Mirror,63.63) )
		bullet.Dir 	= ent:LocalToWorldAngles( Angle(0,-0.5 * Mirror,0) ):Forward()
		bullet.Spread 	= Vector( 0.04,  0.04, 0 )
		bullet.TracerName = "lvs_tracer_orange"
		bullet.Force	= 50
		bullet.HullSize 	= 15
		bullet.Damage	= 15
		bullet.SplashDamage = 85
		bullet.SplashDamageRadius = 50
		bullet.Velocity = 12000
		bullet.Attacker 	= ent:GetDriver()
		bullet.Callback = function(att, tr, dmginfo)
		end
		ent:FireBullet( bullet )
	end
	weapon.StartAttack = function( ent )
		if not IsValid( ent.SoundEmitter2 ) then
			ent.SoundEmitter2 = ent:AddSoundEmitter( Vector(109.29,0,92.85), "lvs/weapons/mg_heavy_loop.wav", "lvs/weapons/mg_heavy_loop.wav" )
			ent.SoundEmitter2:SetSoundLevel( 95 )
		end

		ent.SoundEmitter2:Play()
	end
	weapon.FinishAttack = function( ent )
		if IsValid( ent.SoundEmitter2 ) then
			ent.SoundEmitter2:Stop()
		end
		ent:EmitSound("lvs/weapons/mg_heavy_lastshot.wav", 95)
	end
	weapon.OnSelect = function( ent ) ent:EmitSound("physics/metal/weapon_impact_soft2.wav") end
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	self:AddWeapon( weapon )



	self:AddWeapon( LVS:GetWeaponPreset( "TURBO" ) )
end

ENT.FlyByAdvance = 0.5
ENT.FlyBySound = "lvs/vehicles/bf109/flyby.wav" 
ENT.DeathSound = "lvs/vehicles/generic/crash.wav"

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
