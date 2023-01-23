
ENT.Base = "lvs_base_helicopter"

ENT.PrintName = "Combine Gunship"
ENT.Author = "Luna"
ENT.Information = "Combine Synth Gunship from Half Life 2 + Episodes"
ENT.Category = "[LVS] - Helicopters"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/combine_gunship.mdl"
ENT.GibModels = {
	"models/gibs/gunship_gibs_engine.mdl",
	"models/gibs/gunship_gibs_eye.mdl",
	"models/gibs/gunship_gibs_headsection.mdl",
	"models/gibs/gunship_gibs_midsection.mdl",
	"models/gibs/gunship_gibs_nosegun.mdl",
	"models/gibs/gunship_gibs_sensorarray.mdl",
	"models/gibs/gunship_gibs_tailsection.mdl",
	"models/gibs/gunship_gibs_wing.mdl",
}

ENT.AITEAM = 1

ENT.MaxHealth = 1600

ENT.MaxVelocity = 2150

ENT.ThrustUp = 1
ENT.ThrustDown = 0.8
ENT.ThrustRate = 1

ENT.ThrottleRateUp = 0.2
ENT.ThrottleRateDown = 0.2

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 1

ENT.ForceLinearDampingMultiplier = 1.5

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.EngineSounds = {
	{
		sound = "^npc/attack_helicopter/aheli_rotor_loop1.wav",
		--sound_int = "lvs/vehicles/helicopter/loop_interior.wav",
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
	self:AddDT( "Entity", "Body" )
end

