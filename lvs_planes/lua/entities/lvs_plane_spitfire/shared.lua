
ENT.Base = "lvs_base_fighterplane"

ENT.PrintName = "Spitfire"
ENT.Author = "Luna"
ENT.Information = "British World War 2 Fighterplane"
ENT.Category = "[LVS] - Planes"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/spitfire.mdl"

ENT.AITEAM = 2

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

ENT.MaxHealth = 650

function ENT:InitWeapons()
	self.PosTPMG= { Vector(100,150,65), Vector(100,-150,65), Vector(136.19,-74.97,53.7), Vector(136.19,74.97,53.7), Vector(105,100,58), Vector(105,-100,58), }
	self.DirTPMG= { 0.5, -0.5, -0.5, 0.5, 0.4, -0.4 }
	self:AddWeapon( LVS:GetWeaponPreset( "TABLE_POINT_MG" ) )

	self.PosHMG = Vector(136.19,74.97,53.7)
	self.DirHMG = 0.5
	self:AddWeapon( LVS:GetWeaponPreset( "HMG" ) )
end

ENT.FlyByAdvance = 0.5
ENT.FlyBySound = "lvs/vehicles/spitfire/flyby.wav" 
ENT.DeathSound = "lvs/vehicles/generic/crash.wav"

ENT.EngineSounds = {
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
