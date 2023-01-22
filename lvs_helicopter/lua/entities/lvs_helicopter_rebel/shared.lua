
ENT.Base = "lvs_base_helicopter"

ENT.PrintName = "Rebel Helicopter"
ENT.Author = "Luna"
ENT.Information = "Transport Helicopter as seen in Half Life 2 Episode 2"
ENT.Category = "[LVS] - Helicopters"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/helicopter.mdl"
ENT.GibModels = {
	"models/gibs/helicopter_brokenpiece_01.mdl",
	"models/gibs/helicopter_brokenpiece_02.mdl",
	"models/gibs/helicopter_brokenpiece_03.mdl",
	"models/gibs/helicopter_brokenpiece_06_body.mdl",
	"models/gibs/helicopter_brokenpiece_04_cockpit.mdl",
	"models/gibs/helicopter_brokenpiece_05_tailfan.mdl",
}

ENT.AITEAM = 2

ENT.MaxHealth = 3000

ENT.MaxVelocity = 1500

ENT.ThrustUp = 1
ENT.ThrustDown = 0.8
ENT.ThrustRate = 1

ENT.ThrottleRateUp = 0.2
ENT.ThrottleRateDown = 0.2

ENT.TurnRatePitch = 0.75
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 0.75

ENT.ForceLinearDampingMultiplier = 1.5

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.FlyByAdvance = 0.7
ENT.FlyBySound = "lvs/vehicles/helicopter/flyby.wav" 

ENT.EngineSounds = {
	{
		sound = "^lvs/vehicles/helicopter/loop_near.wav",
		sound_int = "lvs/vehicles/helicopter/loop_interior.wav",
		Pitch = 0,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 100,
		Volume = 1,
		VolumeMin = 0,
		VolumeMax = 1,
		SoundLevel = 125,
		UseDoppler = true,
	},
	{
		sound = "^lvs/vehicles/helicopter/loop_dist.wav",
		sound_int = "",
		Pitch = 0,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 100,
		Volume = 1,
		VolumeMin = 0,
		VolumeMax = 1,
		SoundLevel = 125,
		UseDoppler = true,
	},
}

function ENT:OnSetupDataTables()
	self:AddDT( "Entity", "GunnerSeat" )
end
