
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

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.MaxSlipAnglePitch = 24
ENT.MaxSlipAngleYaw = 12

ENT.MaxHealth = 1000

function ENT:InitWeapons()
	self.PosTPMG= {
		Vector(109.15,102.95,54.79), Vector(109.15,-102.95,54.79),
		Vector(98.27,-113.97,54.65),Vector(98.27,113.97,54.65),
		Vector(103.38,108.19,54.65),Vector(103.38,-108.19,54.65),
		Vector(113.46,-97.47,54.72),Vector(113.46,97.47,54.72),
	}
	self.DirTPMG= { 0.6, -0.6, -0.6, 0.6, 0.6, -0.6, -0.6, 0.6 }
	self:AddWeapon( LVS:GetWeaponPreset( "TABLE_POINT_MG" ) )

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
