AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:OnSpawn( PObj )
	self:SetBodygroup( 14, 1 ) 
	self:SetBodygroup( 13, 1 ) 

	PObj:SetMass( 5000 )

	self:AddDriverSeat( Vector(32,0,67.5), Angle(0,-90,0) )

	self:AddPassengerSeat( Vector(32,200,67.5), Angle(0,-90,0) )

	self:AddPassengerSeat( Vector(32,-200,67.5), Angle(0,-90,0) )
end

function ENT:ApproachTargetAngle( TargetAngle, OverridePitch, OverrideYaw, OverrideRoll )
	local LocalAngles = self:WorldToLocalAngles( TargetAngle )

	local LocalAngPitch = LocalAngles.p
	local LocalAngYaw = LocalAngles.y
	local LocalAngRoll = LocalAngles.r

	local TargetForward = TargetAngle:Forward()
	local Forward = self:GetForward()

	local AngDiff = math.deg( math.acos( math.Clamp( Forward:Dot( TargetForward ) ,-1,1) ) )

	local WingFinFadeOut = math.max( (90 - AngDiff ) / 90, 0 )
	local RudderFadeOut = math.max( (60 - AngDiff ) / 60, 0 )

	local Pitch = math.Clamp( -LocalAngPitch / 22 , -1, 1 )
	local Yaw = math.Clamp( -LocalAngYaw / 10 ,-1,1) * RudderFadeOut
	local Roll = math.Clamp( (-LocalAngYaw + LocalAngRoll * RudderFadeOut) * WingFinFadeOut / 180 , -1 , 1 )

	if OverridePitch and OverridePitch ~= 0 then
		Pitch = OverridePitch
	end

	if OverrideYaw and OverrideYaw ~= 0 then
		Yaw = OverrideYaw
	end
	
	if OverrideRoll and OverrideRoll ~= 0 then
		Roll = OverrideRoll
	end

	self:SetSteer( Vector( Roll, -Pitch, -Yaw) )
end

function ENT:CalcAero( phys, deltatime )
	local WorldGravity = self:GetWorldGravity()
	local WorldUp = self:GetWorldUp()

	local Stability, InvStability, ForwardVelocity = self:GetStability()

	local Forward = self:GetForward()
	local Left = -self:GetRight()
	local Up = self:GetUp()

	local Vel = self:GetVelocity()
	local VelForward = Vel:GetNormalized()

	local PitchPull = math.max( (math.deg( math.acos( math.Clamp( WorldUp:Dot( Up ) ,-1,1) ) ) - 90) /  90, 0 )
	local YawPull = (math.deg( math.acos( math.Clamp( WorldUp:Dot( Left ) ,-1,1) ) ) - 90) /  90

	local StallPitchPull = (math.deg( math.acos( math.Clamp( -VelForward:Dot( Up ) ,-1,1) ) ) - 90) / 90
	local StallYawPull = (math.deg( math.acos( math.Clamp( -VelForward:Dot( Left ) ,-1,1) ) ) - 90) /  90

	local GravMul = WorldGravity / 600
	local GravityPitch = math.abs( PitchPull ) ^ 1.25 * self:Sign( PitchPull ) * GravMul * 0.25
	local GravityYaw = math.abs( YawPull ) ^ 1.25 * self:Sign( YawPull ) * GravMul * 0.25

	local StallMul = math.min( -math.min(Vel.z,0) / 1000, 1 ) * 10

	local StallPitch = math.abs( PitchPull ) * self:Sign( PitchPull ) * GravMul * StallMul
	local StallYaw = math.abs( YawPull ) * self:Sign( YawPull ) * GravMul * StallMul

	local Steer = self:GetSteer()
	local Pitch = math.Clamp(Steer.y - GravityPitch,-1,1) * self.TurnRatePitch * 3 * Stability - StallPitch * InvStability
	local Yaw = math.Clamp(Steer.z * 4 + GravityYaw,-1,1) * self.TurnRateYaw * 0.75 * Stability + StallYaw * InvStability
	local Roll = math.Clamp( self:Sign( Steer.x ) * (math.abs( Steer.x ) ^ 1.5) * 22,-1,1) * self.TurnRateRoll * 12 * Stability

	local VelL = self:WorldToLocal( self:GetPos() + Vel )

	local MulZ = (math.max( math.deg( math.acos( math.Clamp( VelForward:Dot( Forward ) ,-1,1) ) ) - self.MaxSlipAnglePitch * math.abs( Steer.y ), 0 ) / 90) * 0.3
	local MulY = (math.max( math.abs( math.deg( math.acos( math.Clamp( VelForward:Dot( Left ) ,-1,1) ) ) - 90 ) - self.MaxSlipAngleYaw * math.abs( Steer.z ), 0 ) / 90) * 0.15

	local Lift = -math.min( (math.deg( math.acos( math.Clamp( WorldUp:Dot( Up ) ,-1,1) ) ) - 90) / 180,0) * (WorldGravity / (1 / deltatime))

	return Vector(0, -VelL.y * MulY, Lift - VelL.z * MulZ ) * Stability,  Vector( Roll, Pitch, Yaw )
end

function ENT:PhysicsSimulate( phys, deltatime )
	local Aero, Torque = self:CalcAero( phys, deltatime )

	phys:Wake()

	local ForwardVelocity = self:WorldToLocal( self:GetPos() + self:GetVelocity() ).x
	local TargetVelocity = self.MaxVelocity * self:GetThrottle()

	local Thrust = Vector(math.max(TargetVelocity - ForwardVelocity,0),0,0) * self.MaxThrust

	local ForceLinear = (Aero * 10000 * self.ForceLinearMultiplier + Thrust) * deltatime
	local ForceAngle = (Torque * 25 * self.ForceAngleMultiplier - phys:GetAngleVelocity() * 1.5 * self.ForceAngleDampingMultiplier) * deltatime * 250

	return ForceAngle, ForceLinear, SIM_LOCAL_ACCELERATION
end
