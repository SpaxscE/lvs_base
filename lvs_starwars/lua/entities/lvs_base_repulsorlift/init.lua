AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:ApproachTargetAngle( TargetAngle, OverridePitch, OverrideYaw, OverrideRoll, FreeMovement )
	local LocalAngles = self:WorldToLocalAngles( TargetAngle )

	local LocalAngPitch = LocalAngles.p
	local LocalAngYaw = LocalAngles.y

	local TargetForward = TargetAngle:Forward()
	local Forward = self:GetForward()

	local AngVel = self:GetPhysicsObject():GetAngleVelocity()

	local Pitch = math.Clamp( -LocalAngPitch / 8 , -1, 1 ) + math.Clamp(AngVel.y / 100,-0.25,0.25) / math.abs( LocalAngPitch )
	local Yaw = math.Clamp( -LocalAngYaw / 4 ,-1,1) + math.Clamp(AngVel.z / 100,-0.25,0.25) / math.abs( LocalAngYaw )

	if OverridePitch and OverridePitch ~= 0 then
		Pitch = OverridePitch
	end

	if OverrideYaw and OverrideYaw ~= 0 then
		Yaw = OverrideYaw
	end
	
	self:SetSteer( Vector( math.Clamp(Yaw,-1,1), -math.Clamp(Pitch,-1,1), 0) )
end

function ENT:CalcAero( phys, deltatime )
	local Steer = self:GetSteer()

	local Forward = self:GetForward()
	local Left = -self:GetRight()

	local Vel = self:GetVelocity()
	local VelForward = Vel:GetNormalized()

	local GravityPitch = 0
	local GravityYaw = 0

	-- crash bebehavior
	if self:IsDestroyed() then
		local WorldGravity = self:GetWorldGravity()
		local WorldUp = self:GetWorldUp()

		local Up = self:GetUp()

		Steer = phys:GetAngleVelocity() / 200

		local PitchPull = (math.deg( math.acos( math.Clamp( WorldUp:Dot( Up ) ,-1,1) ) ) - 90) /  90
		local YawPull = (math.deg( math.acos( math.Clamp( WorldUp:Dot( Left ) ,-1,1) ) ) - 90) /  90

		local GravMul = WorldGravity / 600

		GravityPitch = math.abs( PitchPull ) ^ 1.25 * self:Sign( PitchPull ) * GravMul
		GravityYaw = math.abs( YawPull ) ^ 1.25 * self:Sign( YawPull ) * GravMul

		if not phys:IsGravityEnabled() then
			phys:EnableGravity( true )
		end
	end

	local Pitch = math.Clamp(Steer.y - GravityPitch,-1,1) * self.TurnRatePitch * 4
	local Yaw = math.Clamp(-Steer.x + GravityYaw,-1,1) * self.TurnRateYaw * 4
	local Roll = math.Clamp(-self:GetAngles().r / 90 - phys:GetAngleVelocity().z * math.min(self:GetThrottle(),1) / 90,-1,1) * self.TurnRateRoll * 12

	local VelL = self:WorldToLocal( self:GetPos() + Vel )

	local MulZ = (math.max( math.deg( math.acos( math.Clamp( VelForward:Dot( Forward ) ,-1,1) ) ) - math.abs( Steer.y ), 0 ) / 90) * 0.3
	local MulY = (math.max( math.abs( math.deg( math.acos( math.Clamp( VelForward:Dot( Left ) ,-1,1) ) ) - 90 ) - math.abs( Steer.z ), 0 ) / 90) * 0.15

	local VtolMove = self:GetVtolMove()

	local Move = Vector( (VtolMove.x < 0) and -math.min(VelL.x * 0.15,0) or 0, -VelL.y * MulY, -VelL.z * MulZ ) + VtolMove

	return Move, Vector( Roll, Pitch, Yaw )
end
