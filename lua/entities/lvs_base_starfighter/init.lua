AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_camera.lua" )
AddCSLuaFile( "sh_camera_eyetrace.lua" )
AddCSLuaFile( "cl_hud.lua" )
AddCSLuaFile( "cl_flyby.lua" )
AddCSLuaFile( "cl_deathsound.lua" )
include("shared.lua")
include("sv_ai.lua")
include("sv_mouseaim.lua")
include("sv_components.lua")
include("sv_vehiclespecific.lua")
include("sh_camera_eyetrace.lua")

DEFINE_BASECLASS( "lvs_base" )

function ENT:OnDriverChanged( Old, New, VehicleIsActive )

	if not VehicleIsActive and self:GetThrottle() == 0 then
		self:SetSteer( vector_origin )
		self:SetVtolMove( vector_origin )
	end

	self:OnPassengerChanged( Old, New, 1 )
end

function ENT:StartEngine()
	if self:GetEngineActive() or not self:IsEngineStartAllowed() then return end

	self:GetPhysicsObject():EnableGravity( false )

	BaseClass.StartEngine( self )
end

function ENT:StopEngine()
	if not self:GetEngineActive() then return end

	self:GetPhysicsObject():EnableGravity( true )

	BaseClass.StopEngine( self )
end

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

	local SmoothPitch = math.Clamp( math.Clamp(AngVel.y / 100,-0.25,0.25) / math.abs( LocalAngPitch ), -1, 1 )
	local SmoothYaw = math.Clamp( math.Clamp(AngVel.z / 100,-0.25,0.25) / math.abs( LocalAngYaw ), -1, 1 )

	local Pitch = math.Clamp( -LocalAngPitch / 10 + SmoothPitch, -1, 1 )
	local Yaw = math.Clamp( -LocalAngYaw / 2 + SmoothYaw,-1,1) * RudderFadeOut
	local Roll = math.Clamp( (-math.Clamp(LocalAngYaw * 16 * self:GetThrottle(),-90,90) + LocalAngRoll * RudderFadeOut * 0.75) * WingFinFadeOut / 180 , -1 , 1 )

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

function ENT:CalcAero( phys, deltatime, EntTable )
	if not EntTable then
		EntTable = self:GetTable()
	end

	-- mouse aim needs to run at high speed.
	if self:GetAI() then
		if EntTable._lvsAITargetAng then
			self:ApproachTargetAngle( EntTable._lvsAITargetAng )
		end
	else
		local ply = self:GetDriver()
		if IsValid( ply ) and ply:lvsMouseAim() then
			self:PlayerMouseAim( ply )
		end
	end

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

	local Pitch = math.Clamp(Steer.y - GravityPitch,-1,1) * EntTable.TurnRatePitch * 3
	local Yaw = math.Clamp(Steer.z * 4 + GravityYaw,-1,1) * EntTable.TurnRateYaw
	local Roll = math.Clamp(Steer.x * 1.5,-1,1) * EntTable.TurnRateRoll * 12

	local VelL = self:WorldToLocal( self:GetPos() + Vel )

	local MulZ = (math.max( math.deg( math.acos( math.Clamp( VelForward:Dot( Forward ) ,-1,1) ) ) - math.abs( Steer.y ), 0 ) / 90) * 0.3
	local MulY = (math.max( math.abs( math.deg( math.acos( math.Clamp( VelForward:Dot( Left ) ,-1,1) ) ) - 90 ) - math.abs( Steer.z ), 0 ) / 90) * 0.15

	local VtolMove = self:GetVtolMove()

	local Move = Vector( (VtolMove.x < 0) and -math.min(VelL.x * 0.15,0) or 0, -VelL.y * MulY, -VelL.z * MulZ ) + VtolMove

	return Move, Vector( Roll, Pitch, Yaw )
end

function ENT:OnSkyCollide( data, PhysObj )
	local NewVelocity = self:VectorSubtractNormal( data.HitNormal, data.OurOldVelocity ) - data.HitNormal * math.Clamp(self:GetThrustStrenght() * self.MaxThrust,250,800)

	PhysObj:SetVelocityInstantaneous( NewVelocity )
	PhysObj:SetAngleVelocityInstantaneous( data.OurOldAngularVelocity )

	return true
end

function ENT:PhysicsSimulate( phys, deltatime )
	if self:GetEngineActive() then phys:Wake() end

	if not self:GetEngineActive() then
		return Vector(0,0,0), Vector(0,0,0), SIM_NOTHING
	end

	local EntTable = self:GetTable()

	local Aero, Torque = self:CalcAero( phys, deltatime, EntTable )

	local Thrust = self:GetThrustStrenght() * EntTable.MaxThrust * 100

	if self:IsDestroyed() then
		Thrust = math.max( Thrust, 0 ) -- dont allow braking, but allow accelerating while destroyed
	end

	local ForceLinear = (Aero * 10000 * EntTable.ForceLinearMultiplier + Vector(Thrust,0,0)) * deltatime
	local ForceAngle = (Torque * 25 * EntTable.ForceAngleMultiplier - phys:GetAngleVelocity() * 1.5 * EntTable.ForceAngleDampingMultiplier) * deltatime * 250

	return ForceAngle, ForceLinear, SIM_LOCAL_ACCELERATION
end

function ENT:OnMaintenance()
	for _, Engine in pairs( self:GetEngines() ) do
		if not IsValid( Engine ) then continue end

		if not Engine.SetHP or not Engine.GetMaxHP or not Engine.SetDestroyed then continue end

		Engine:SetHP( Engine:GetMaxHP() )
		Engine:SetDestroyed( false ) 
	end
end
