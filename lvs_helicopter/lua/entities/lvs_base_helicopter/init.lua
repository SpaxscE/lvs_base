AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_camera.lua" )
AddCSLuaFile( "sh_camera_eyetrace.lua" )
AddCSLuaFile( "cl_hud.lua" )
AddCSLuaFile( "cl_flyby.lua" )
include("shared.lua")
include("sv_ai.lua")
include("sv_engine.lua")
include("sh_camera_eyetrace.lua")

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

	if self:GetAI() then self:SetAIAimVector( LocalAngles:Forward() ) end

	local LocalAngPitch = LocalAngles.p
	local LocalAngYaw = LocalAngles.y
	local LocalAngRoll = LocalAngles.r

	local TargetForward = TargetAngle:Forward()
	local Forward = self:GetForward()

	local AngDiff = math.deg( math.acos( math.Clamp( Forward:Dot( TargetForward ) ,-1,1) ) )

	local WingFinFadeOut = math.max( (90 - AngDiff ) / 90, 0 )
	local RudderFadeOut = math.min( math.max( (120 - AngDiff ) / 120, 0 ) * 3, 1 )

	local AngVel = self:GetPhysicsObject():GetAngleVelocity()

	local Pitch = math.Clamp( -LocalAngPitch / 20 , -1, 1 )
	local Yaw = math.Clamp( -LocalAngYaw / 4,-1,1) * RudderFadeOut
	local Roll = math.Clamp( (-math.Clamp(LocalAngYaw * 8,-90,90) + LocalAngRoll * RudderFadeOut * 0.75) * WingFinFadeOut / 180 , -1 , 1 )

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

	self:SetSteer( Vector( math.Clamp(Roll * 1.25,-1,1), math.Clamp(-Pitch * 1.25,-1,1), -Yaw) )
end

function ENT:CalcAero( phys, deltatime )
	local WorldGravity = self:GetWorldGravity()
	local WorldUp = Vector(0,0,1)
	local Steer = self:GetSteer()

	local Forward = self:GetForward()
	local Left = -self:GetRight()
	local Up = self:GetUp()

	local Vel = self:GetVelocity()
	local VelForward = Vel:GetNormalized()

	--[[
	-- crash bebehavior
	if self:IsDestroyed() then
		Steer = phys:GetAngleVelocity() / 200

		PitchPull = (math.deg( math.acos( math.Clamp( WorldUp:Dot( Up ) ,-1,1) ) ) - 90) /  90

		GravMul = WorldGravity / 600
	end
	]]

	local YawPull = (math.deg( math.acos( math.Clamp( WorldUp:Dot( Left ) ,-1,1) ) ) - 90) /  90
	local SpeedTurn = math.abs( YawPull ) ^ 1.25 * self:Sign( YawPull ) * math.min( self:GetVelocity():Length() / 1000, 1 )

	local Pitch = math.Clamp(Steer.y,-1,1) * self.TurnRatePitch * 3
	local Yaw = math.Clamp(Steer.z + SpeedTurn,-1,1) * self.TurnRateYaw * 3
	local Roll = math.Clamp(Steer.x,-1,1) * self.TurnRateRoll * 12

	local ThrustRatio = math.Clamp( self.ThrustRatio, 0, 1 )
	local InvThrustRatio = 1 - ThrustRatio

	-- * 10000 * self.ForceLinearMultiplier

	local LocalGravity = self:WorldToLocal( self:GetPos() + WorldUp * WorldGravity )

	local Lift = LocalGravity * ThrustRatio
	local Move = LocalGravity * InvThrustRatio

	local Force = (Lift + Move) * self:GetThrottle()

	return Force, Vector( Roll, Pitch, Yaw )
end

function ENT:OnSkyCollide( data, PhysObj )

	local NewVelocity = self:VectorSubtractNormal( data.HitNormal, data.OurOldVelocity ) - data.HitNormal * 400

	PhysObj:SetVelocityInstantaneous( NewVelocity )
	PhysObj:SetAngleVelocityInstantaneous( data.OurOldAngularVelocity )

	return true
end

function ENT:PhysicsSimulate( phys, deltatime )
	local Aero, Torque = self:CalcAero( phys, deltatime )

	phys:Wake()

	local ForceLinear = Aero
	local ForceAngle = (Torque * 25 * self.ForceAngleMultiplier - phys:GetAngleVelocity() * 1.5 * self.ForceAngleDampingMultiplier) * deltatime * 250

	return ForceAngle, ForceLinear, SIM_LOCAL_ACCELERATION
end
