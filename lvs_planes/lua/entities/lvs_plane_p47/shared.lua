
ENT.Base = "lvs_base_fighterplane"

ENT.PrintName = "P-47D"
ENT.Author = "Luna"
ENT.Information = "American World War 2 Fighterplane"
ENT.Category = "[LVS] - Planes"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/p47.mdl"

ENT.AITEAM = 2

ENT.MaxVelocity = 2600
ENT.MaxPerfVelocity = 2000
ENT.MaxThrust = 1000

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 0.8

ENT.ThrottleRateUp = 0.4
ENT.ThrottleRateDown = 0.2

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.MaxSlipAnglePitch = 20
ENT.MaxSlipAngleYaw = 10

ENT.MaxHealth = 650

ENT.MISSILE_MDL = "models/blu/p47_missile.mdl"
ENT.MISSILE_POSITIONS = {
	[1] = Vector(92.16,-194.69,62.98),
	[2] = Vector(92.16,194.69,62.98),
	[3] = Vector(92.63,-178.76,61.32),
	[4] = Vector(92.63,178.76,61.32),
	[5] = Vector(93.54,-163.72,59.4),
	[6] = Vector(93.54,163.72,59.4),
	[7] = Vector(93.96,-132.84,55.58),
	[8] = Vector(93.96,132.84,55.58),
	[9] = Vector(94,-118.52,53.9),
	[10] = Vector(94,118.52,53.9),
}

function ENT:InitWeapons()
	self.PosTPMG= {
		Vector(109.15,102.95,54.79), Vector(109.15,-102.95,54.79),
		Vector(98.27,-113.97,54.65),Vector(98.27,113.97,54.65),
		Vector(103.38,108.19,54.65),Vector(103.38,-108.19,54.65),
		Vector(113.46,-97.47,54.72),Vector(113.46,97.47,54.72),
	}
	self.DirTPMG= { 0.6, -0.6, -0.6, 0.6, 0.6, -0.6, -0.6, 0.6 }
	self:AddWeapon( LVS:GetWeaponPreset( "TABLE_POINT_MG" ) )

	local weapon = {}
	weapon.Icon = Material("lvs/weapons/missile.png")
	weapon.UseableByAI = false
	weapon.Ammo = 10
	weapon.Delay = 0.1
	weapon.HeatRateUp = 3
	weapon.HeatRateDown = 0.05
	weapon.Attack = function( ent )
		if not ent.MISSILE_ENTITIES then return end

		local Missile = ent.MISSILE_ENTITIES[ ent:GetAmmo() ]

		if not IsValid( Missile ) then return end

		Missile:SetNoDraw( true )

		local projectile = ents.Create( "lvs_missile" )
		projectile:SetPos( Missile:GetPos() )
		projectile:SetAngles( Missile:GetAngles() )
		projectile:Spawn()
		projectile:Activate()
		projectile:SetAttacker( ent:GetDriver() )
		projectile:SetEntityFilter( ent:GetCrosshairFilterEnts() )
		projectile:SetSpeed( ent:GetVelocity():Length() + 4000 )
		projectile:SetDamage( 250 )
		projectile:Enable()

		ent:TakeAmmo()
	end
	self:AddWeapon( weapon )

	self:AddWeapon( LVS:GetWeaponPreset( "TURBO" ) )
end

ENT.FlyByAdvance = 0.5
ENT.FlyBySound = "lvs/vehicles/spitfire/flyby.wav" 
ENT.DeathSound = "lvs/vehicles/generic/crash.wav"

ENT.EngineSounds = {
	{
		sound = "lvs/vehicles/bf109/engine_compressor.wav",
		sound_int = "",
		Pitch = 40,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 40,
		FadeIn = 0.35,
		FadeOut = 1,
		FadeSpeed = 5,
		UseDoppler = true,
		VolumeMin = 0,
		VolumeMax = 0.25,
		SoundLevel = 120,
	},
	{
		sound = "^lvs/vehicles/spitfire/dist.wav",
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
		sound = "lvs/vehicles/spitfire/engine_low.wav",
		sound_int = "lvs/vehicles/spitfire/engine_low_int.wav",
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
		sound = "lvs/vehicles/spitfire/engine_high.wav",
		sound_int = "lvs/vehicles/spitfire/engine_high_int.wav",
		Pitch = 50,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 60,
		FadeIn = 0.15,
		FadeOut = 1,
		FadeSpeed = 1,
		UseDoppler = true,
	},
}
