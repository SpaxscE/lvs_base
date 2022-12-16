AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_camera.lua" )
AddCSLuaFile( "cl_hud.lua" )
include("shared.lua")
include("sv_wheels.lua")
include("sv_landinggear.lua")
include("sv_components.lua")
include("sv_ai.lua")

function ENT:OnCreateAI()
	self:StartEngine()
	self.COL_GROUP_OLD = self:GetCollisionGroup()
	self:SetCollisionGroup( COLLISION_GROUP_INTERACTIVE_DEBRIS )
end

function ENT:OnRemoveAI()
	self:StopEngine()
	self:SetCollisionGroup( self.COL_GROUP_OLD or COLLISION_GROUP_NONE )
end

function ENT:ApproachTargetAngle( TargetAngle, OverridePitch, OverrideYaw, OverrideRoll, FreeMovement )
	local LocalAngles = self:WorldToLocalAngles( TargetAngle )

	local LocalAngPitch = LocalAngles.p
	local LocalAngYaw = LocalAngles.y
	local LocalAngRoll = LocalAngles.r

	local TargetForward = TargetAngle:Forward()
	local Forward = self:GetForward()

	local AngDiff = math.deg( math.acos( math.Clamp( Forward:Dot( TargetForward ) ,-1,1) ) )

	local WingFinFadeOut = math.max( (90 - AngDiff ) / 90, 0 )
	local RudderFadeOut = math.min( math.max( (120 - AngDiff ) / 120, 0 ) * 3, 1 )

	local Pitch = math.Clamp( -LocalAngPitch / 20 , -1, 1 )
	local Yaw = math.Clamp( -LocalAngYaw / 8 ,-1,1) * RudderFadeOut
	local Roll = math.Clamp( (-math.Clamp(LocalAngYaw * 2,-90,90) + LocalAngRoll * RudderFadeOut * 0.25) * WingFinFadeOut / 180 , -1 , 1 )

	if FreeMovement then
		Roll = math.Clamp( -LocalAngYaw * WingFinFadeOut / 180 , -1 , 1 )
	end

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
	local Steer = self:GetSteer()

	local Stability, InvStability, ForwardVelocity = self:GetStability()

	local Forward = self:GetForward()
	local Left = -self:GetRight()
	local Up = self:GetUp()

	local Vel = self:GetVelocity()
	local VelForward = Vel:GetNormalized()

	local PitchPull = math.max( (math.deg( math.acos( math.Clamp( WorldUp:Dot( Up ) ,-1,1) ) ) - 90) /  90, 0 )
	local YawPull = (math.deg( math.acos( math.Clamp( WorldUp:Dot( Left ) ,-1,1) ) ) - 90) /  90

	local GravMul = (WorldGravity / 600) * 0.25

	--[[ if destroyed simulate crash using this:
	if Entity(1):KeyDown( IN_ATTACK ) then
		Steer = phys:GetAngleVelocity() / 200

		PitchPull = (math.deg( math.acos( math.Clamp( WorldUp:Dot( Up ) ,-1,1) ) ) - 90) /  90

		GravMul = WorldGravity / 600
	end
	]]

	local GravityPitch = math.abs( PitchPull ) ^ 1.25 * self:Sign( PitchPull ) * GravMul
	local GravityYaw = math.abs( YawPull ) ^ 1.25 * self:Sign( YawPull ) * GravMul

	local StallMul = math.min( -math.min(Vel.z + 150,0) / 100, 15 )

	local StallPitch = 0
	local StallYaw = 0

	if StallMul > 0 then
		if InvStability < 1 then
			StallPitch = PitchPull* GravMul * StallMul
			StallYaw = YawPull * GravMul * StallMul
		else
			local StallPitchDir = self:Sign( math.deg( math.acos( math.Clamp( -VelForward:Dot( Up ) ,-1,1) ) ) - 90 )
			local StallYawDir =  self:Sign( math.deg( math.acos( math.Clamp( -VelForward:Dot( Left ) ,-1,1) ) ) - 90 )

			local StallPitchPull = ((90 - math.abs( math.deg( math.acos( math.Clamp( -WorldUp:Dot( Up ) ,-1,1) ) ) - 90 )) / 90) * StallPitchDir
			local StallYawPull =  ((90 - math.abs( math.deg( math.acos( math.Clamp( -WorldUp:Dot( Left ) ,-1,1) ) ) - 90 )) / 90) * StallYawDir * 0.5

			StallPitch = StallPitchPull * GravMul * StallMul
			StallYaw = StallYawPull * GravMul * StallMul
		end
	end

	local Pitch = math.Clamp(Steer.y - GravityPitch,-1,1) * self.TurnRatePitch * 3 * Stability - StallPitch * InvStability
	local Yaw = math.Clamp(Steer.z * 4 + GravityYaw,-1,1) * self.TurnRateYaw * Stability + StallYaw * InvStability
	local Roll = math.Clamp(Steer.x * 1.5,-1,1) * self.TurnRateRoll * 12 * Stability

	self:HandleLandingGear( deltatime )
	self:SetWheelSteer( Steer.z * 45 )

	local VelL = self:WorldToLocal( self:GetPos() + Vel )

	local MulZ = (math.max( math.deg( math.acos( math.Clamp( VelForward:Dot( Forward ) ,-1,1) ) ) - self.MaxSlipAnglePitch * math.abs( Steer.y ), 0 ) / 90) * 0.3
	local MulY = (math.max( math.abs( math.deg( math.acos( math.Clamp( VelForward:Dot( Left ) ,-1,1) ) ) - 90 ) - self.MaxSlipAngleYaw * math.abs( Steer.z ), 0 ) / 90) * 0.15

	local Lift = -math.min( (math.deg( math.acos( math.Clamp( WorldUp:Dot( Up ) ,-1,1) ) ) - 90) / 180,0) * (WorldGravity / (1 / deltatime))

	return Vector(0, -VelL.y * MulY, Lift - VelL.z * MulZ ) * Stability,  Vector( Roll, Pitch, Yaw )
end

function ENT:PhysicsSimulate( phys, deltatime )
	local Aero, Torque = self:CalcAero( phys, deltatime )

	phys:Wake()

	local Thrust = math.max( self:GetThrustStrenght(), 0 ) * self.MaxThrust * phys:GetMass()

	local ForceLinear = (Aero * 10000 * self.ForceLinearMultiplier + Vector(Thrust,0,0)) * deltatime
	local ForceAngle = (Torque * 25 * self.ForceAngleMultiplier - phys:GetAngleVelocity() * 1.5 * self.ForceAngleDampingMultiplier) * deltatime * 250

	return ForceAngle, ForceLinear, SIM_LOCAL_ACCELERATION
end
