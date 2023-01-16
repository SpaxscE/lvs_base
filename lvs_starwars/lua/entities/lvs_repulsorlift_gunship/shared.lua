
ENT.Base = "lvs_base_repulsorlift"

ENT.PrintName = "LAAT/i"
ENT.Author = "Luna"
ENT.Information = "Gunship/Troop Transport of the Galactic Republic"
ENT.Category = "[LVS] - Star Wars"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/laat.mdl"
ENT.GibModels = {
	"models/gibs/helicopter_brokenpiece_01.mdl",
	"models/gibs/helicopter_brokenpiece_02.mdl",
	"models/gibs/helicopter_brokenpiece_03.mdl",
	"models/combine_apc_destroyed_gib02.mdl",
	"models/combine_apc_destroyed_gib04.mdl",
	"models/combine_apc_destroyed_gib05.mdl",
	"models/props_c17/trappropeller_engine.mdl",
	"models/gibs/airboat_broken_engine.mdl",
}

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

ENT.AutomaticFrameAdvance = true

function ENT:OnSetupDataTables()
	self:AddDT( "Entity", "GunnerSeat" )
	self:AddDT( "Entity", "BTPodL" )
	self:AddDT( "Entity", "BTPodR" )

	self:AddDT( "Bool", "RearHatch" )

	self:AddDT( "Int", "DoorMode" )

	self:AddDT( "Bool", "WingTurretFire" )
	self:AddDT( "Vector", "WingTurretTarget" )

	self:AddDT( "Bool", "BTLFire" )
	self:AddDT( "Bool", "BTRFire" )

	self:AddDT( "Bool", "LightsActive" )
end

function ENT:InitWeapons()
	self:InitWeaponDriver()
	self:InitWeaponGunner()
	self:InitWeaponBTL()
	self:InitWeaponBTR()
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

function ENT:CalcMainActivity( ply )
	local Pod = ply:GetVehicle()

	if Pod == self:GetDriverSeat() or Pod == self:GetGunnerSeat() then return end

	if ply.m_bWasNoclipping then 
		ply.m_bWasNoclipping = nil 
		ply:AnimResetGestureSlot( GESTURE_SLOT_CUSTOM ) 

		if CLIENT then 
			ply:SetIK( true )
		end 
	end 

	if Pod == self:GetBTPodL() or Pod == self:GetBTPodR() then
		ply.CalcIdeal = ACT_STAND
		ply.CalcSeqOverride = ply:LookupSequence( "drive_jeep" )

		return ply.CalcIdeal, ply.CalcSeqOverride
	end

	ply.CalcIdeal = ACT_STAND
	ply.CalcSeqOverride = ply:LookupSequence( "idle_all_02" )

	if ply:GetAllowWeaponsInVehicle() and IsValid( ply:GetActiveWeapon() ) then

		local holdtype = ply:GetActiveWeapon():GetHoldType()

		if holdtype == "smg" then 
			holdtype = "smg1"
		end

		local seqid = ply:LookupSequence( "idle_" .. holdtype )

		if seqid ~= -1 then
			ply.CalcSeqOverride = seqid
		end
	end

	return ply.CalcIdeal, ply.CalcSeqOverride
end