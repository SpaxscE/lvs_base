
ENT.Base = "lvs_base_wheeldrive"

ENT.PrintName = "[LVS] Wheeldrive Bike"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS] - Cars"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

ENT.MaxVelocity = 1250
ENT.MaxVelocityReverse = 100

ENT.EngineCurve = 0.4
ENT.EngineTorque = 250

ENT.TransGears = 4
ENT.TransGearsReverse = 1

ENT.PhysicsMass = 250
ENT.PhysicsWeightScale = 0.5
ENT.PhysicsInertia = Vector(400,400,200)

ENT.ForceAngleMultiplier = 0.5

ENT.PhysicsPitchInvertForceMul = 1

ENT.PhysicsDampingSpeed = 500
ENT.PhysicsDampingForward = true
ENT.PhysicsDampingReverse = false

ENT.PhysicsRollMul = 1
ENT.PhysicsDampingRollMul = 1
ENT.PhysicsWheelGyroMul = 1
ENT.PhysicsWheelGyroSpeed = 400

ENT.WheelPhysicsMass = 250
ENT.WheelPhysicsInertia = Vector(5,4,5)

ENT.WheelSideForce = 800
ENT.WheelDownForce = 1000

ENT.KickStarter = true
ENT.KickStarterSound = "lvs/vehicles/bmw_r75/moped_crank.wav"
ENT.KickStarterMinAttempts = 2
ENT.KickStarterMaxAttempts = 4
ENT.KickStarterAttemptsInSeconds = 5
ENT.KickStarterMinDelay = 0.5

ENT.FastSteerAngleClamp = 15

function ENT:ShouldPutFootDown()
	return self:GetNWHandBrake() or self:GetVelocity():Length() < 20
end

function ENT:CalcMainActivity( ply )
	if ply ~= self:GetDriver() then return self:CalcMainActivityPassenger( ply ) end

	if ply.m_bWasNoclipping then 
		ply.m_bWasNoclipping = nil 
		ply:AnimResetGestureSlot( GESTURE_SLOT_CUSTOM ) 
		
		if CLIENT then 
			ply:SetIK( true )
		end 
	end 

	ply.CalcIdeal = ACT_STAND
	ply.CalcSeqOverride = ply:LookupSequence( "drive_airboat" )

	return ply.CalcIdeal, ply.CalcSeqOverride
end

function ENT:GetWheelUp()
	return self:GetUp() * math.Clamp( 1 + math.abs( self:GetSteer() / 10 ), 1, 1.5 )
end

function ENT:GetVehicleType()
	return "bike"
end

function ENT:GravGunPickupAllowed( ply )
	return false
end
