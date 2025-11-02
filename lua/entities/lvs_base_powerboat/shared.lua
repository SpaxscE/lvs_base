
ENT.Base = "lvs_base_wheeldrive"

ENT.PrintName = "[LVS] Base Boat"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

ENT.MaxHealth = 600
ENT.MaxHealthEngine = 50
ENT.MaxHealthFuelTank = 10

ENT.EngineIdleRPM = 1000
ENT.EngineMaxRPM = 6000

ENT.EngineSplash = false
ENT.EngineSplashStartSize = 50
ENT.EngineSplashEndSize = 200
ENT.EngineSplashVelocity = 500
ENT.EngineSplashVelocityRandomAdd = 200
ENT.EngineSplashThrowAngle = 0

ENT.DeleteOnExplode = true

ENT.lvsAllowEngineTool = false
ENT.lvsShowInSpawner = false

ENT.AllowSuperCharger = false
ENT.AllowTurbo = false

ENT.FloatHeight = 0
ENT.FloatForce = 20
ENT.FloatWaveFrequency = 5
ENT.FloatExponent = 2
ENT.FloatWaveIntensity = 1

ENT.FloatThrottleIntensity = 1

ENT.TurnRate = 5
ENT.TurnForceYaw = 600
ENT.TurnForceRoll = 400

ENT.MaxThrust = 1000

ENT.MaxVelocity = 1000
ENT.MaxVelocityReverse = 350

ENT.MinVelocityAutoBrake = 200

ENT.ForceLinearMultiplier = 1
ENT.ForceAngleMultiplier = 1

function ENT:GetVehicleType()
	return "boat"
end

function ENT:UpdateAnimation( ply, velocity, maxseqgroundspeed )
	ply:SetPlaybackRate( 1 )

	if CLIENT then
		if ply == self:GetDriver() then
			ply:SetPoseParameter( "vehicle_steer", -self:GetSteer() )
			ply:InvalidateBoneCache()
		end

		GAMEMODE:GrabEarAnimation( ply )
		GAMEMODE:MouthMoveAnimation( ply )
	end

	return false
end

function ENT:GetThrust()
	return self:GetThrustStrenght() * self.MaxThrust
end

function ENT:GetThrustStrenght()
	local EntTable = self:GetTable()

	local VelL = self:WorldToLocal( self:GetPos() + self:GetVelocity() )

	local DesiredVelocity = EntTable.MaxVelocity * self:GetThrottle() - EntTable.MaxVelocityReverse * self:GetBrake()

	if DesiredVelocity == 0 and math.abs( VelL.x ) > EntTable.MinVelocityAutoBrake then
		return 0
	end

	return math.Clamp((DesiredVelocity - VelL.x) / EntTable.MaxVelocity,-1,1) 
end

function ENT:GetGear()
	return -1
end

function ENT:IsManualTransmission()
	return false
end
