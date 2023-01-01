
ENT.Base = "lvs_base_fighterplane"

ENT.PrintName = "Cessna 172"
ENT.Author = "Luna"
ENT.Information = "Small and Unarmed Civilian Airplane"
ENT.Category = "[LVS] - Planes"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/cessna.mdl"

ENT.AITEAM = 0

ENT.MaxVelocity = 1800
ENT.MaxPerfVelocity = 1500
ENT.MaxThrust = 700

ENT.TurnRatePitch = 1.5
ENT.TurnRateYaw = 1.3
ENT.TurnRateRoll = 1

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.MaxSlipAnglePitch = 8
ENT.MaxSlipAngleYaw = 4

ENT.MaxHealth = 250

ENT.FlyByAdvance = 1.3
ENT.FlyBySound = "lvs/vehicles/cessna/flyby.wav" 
ENT.DeathSound = "lvs/vehicles/generic/crash.wav"

function ENT:OnSetupDataTables()
	self:AddDT( "Bool", "LightsEnabled" )
end

function ENT:InitWeapons()
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/light.png")
	weapon.Ammo = -1
	weapon.Delay = 0
	weapon.HeatRateUp = 0
	weapon.HeatRateDown = 1
	weapon.StartAttack = function( ent )
		if not ent.SetLightsEnabled then return end

		if ent:GetAI() then return end

		ent:SetLightsEnabled( not ent:GetLightsEnabled() )
		ent:EmitSound( "items/flashlight1.wav", 75, 105 )
	end
	self:AddWeapon( weapon )
end

ENT.EngineSounds = {
	{
		sound = "^lvs/vehicles/cessna/rpm_1.wav",
		Pitch = 100,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 300,
		FadeIn = 0,
		FadeOut = 0.15,
		FadeSpeed = 1.5,
		UseDoppler = false,
	},
	{
		sound = "^lvs/vehicles/cessna/rpm_2.wav",
		Pitch = 50,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 320,
		FadeIn = 0.15,
		FadeOut = 0.25,
		FadeSpeed = 1.5,
		UseDoppler = true,
	},
	{
		sound = "^lvs/vehicles/cessna/rpm_3.wav",
		Pitch = 75,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 110,
		FadeIn = 0.25,
		FadeOut = 0.4,
		FadeSpeed = 1.5,
		UseDoppler = true,
	},
	{
		sound = "^lvs/vehicles/cessna/rpm_4.wav",
		Pitch = 50,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 60,
		FadeIn = 0.4,
		FadeOut = 1,
		FadeSpeed = 1.5,
		UseDoppler = true,
	},
}

