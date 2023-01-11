
ENT.Base = "lvs_base_repulsorlift"

ENT.PrintName = "LAAT/i"
ENT.Author = "Luna"
ENT.Information = "Gunship/Troop Transport of the Galactic Republic"
ENT.Category = "[LVS] - Star Wars"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/laat.mdl"

ENT.AITEAM = 2

ENT.MaxVelocity = 2400
ENT.MaxThrust = 2400

ENT.MaxPitch = 60

ENT.ThrustVtol = 50
ENT.ThrustRateVtol = 2

ENT.TurnRatePitch = 0.7
ENT.TurnRateYaw = 0.7
ENT.TurnRateRoll = 0.7

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.MaxHealth = 4000

function ENT:InitWeapons()
end


sound.Add( {
	name = "LVS.LAAT.FLYBY",
	sound = {
		"lvs/vehicles/laat/flyby1.wav",
		"lvs/vehicles/laat/flyby2.wav",
		"lvs/vehicles/laat/flyby3.wav",
		"lvs/vehicles/laat/flyby4.wav",
		"lvs/vehicles/laat/flyby5.wav",
	}
} )

ENT.FlyByAdvance = 1
ENT.FlyBySound = "LVS.LAAT.FLYBY" 
ENT.DeathSound = "lvs/vehicles/generic_starfighter/crash.wav"

ENT.EngineSounds = {
	{
		sound = "lvs/vehicles/laat/loop.wav",
		Pitch = 80,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 40,
		FadeIn = 0,
		FadeOut = 1,
		FadeSpeed = 1.5,
		UseDoppler = true,
	},
	{
		sound = "^lvs/vehicles/laat/dist.wav",
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
}