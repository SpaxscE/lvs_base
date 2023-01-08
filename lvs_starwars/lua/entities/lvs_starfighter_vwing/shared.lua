
ENT.Base = "lvs_base_starfighter"

ENT.PrintName = "V-Wing"
ENT.Author = "Luna"
ENT.Information = "Starfighter of the Galactic Republic"
ENT.Category = "[LVS] - Star Wars"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/vwing.mdl"

ENT.AITEAM = 2

ENT.MaxVelocity = 2150
ENT.MaxThrust = 2150

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 1

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.MaxHealth = 300
ENT.MaxShield = 100

function ENT:InitWeapons()
	self:AddWeapon( LVS:GetWeaponPreset( "TURBO" ) )
end

ENT.FlyByAdvance = 0.5
ENT.FlyBySound = "lvs/vehicles/vwing/flyby.wav" 
ENT.DeathSound = "lvs/vehicles/generic_starfighter/crash.wav"

ENT.EngineSounds = {
	{
		sound = "lvs/vehicles/vwing/loop.wav",
		sound_int = "lvs/vehicles/vwing/loop_interior.wav",
		Pitch = 80,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 40,
		FadeIn = 0,
		FadeOut = 1,
		FadeSpeed = 1.5,
		UseDoppler = true,
	},
}