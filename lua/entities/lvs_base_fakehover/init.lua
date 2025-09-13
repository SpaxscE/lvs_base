AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_camera.lua" )
AddCSLuaFile( "cl_hud.lua" )
AddCSLuaFile( "sh_camera_eyetrace.lua" )
include("shared.lua")
include("sv_controls.lua")
include("sv_components.lua")
include("sv_vehiclespecific.lua")
include("sh_camera_eyetrace.lua")
include("sv_ai.lua")

DEFINE_BASECLASS( "lvs_base" )

function ENT:OnDriverChanged( Old, New, VehicleIsActive )
	if VehicleIsActive then
		if not self:GetEngineActive() and self:IsEngineStartAllowed() then
			self:SetEngineActive( true )
		end

		return
	end

	self:SetEngineActive( false )
	self:SetMove( 0, 0 )
end

function ENT:StartEngine()
	for _, wheel in pairs( self:GetWheels() ) do
		if not IsValid( wheel ) then continue end

		wheel:PhysWake()
	end

	BaseClass.StartEngine( self )
end

function ENT:PhysicsSimulate( phys, deltatime )
	if self:GetEngineActive() then phys:Wake() end

	local OnGroundMul = self:HitGround() and 1 or 0

	local VelL = phys:WorldToLocal( phys:GetPos() + phys:GetVelocity() )

	local InputMove = self:GetMove()

	self._smMove = self._smMove and (self._smMove + (Vector(InputMove.x,InputMove.y,0):GetNormalized() - self._smMove) * deltatime * self.ForceLinearRate * 10) or InputMove

	local MoveX = (self.MaxVelocityX + self.BoostAddVelocityX * InputMove.z) * self._smMove.x
	local MoveY = (self.MaxVelocityY + self.BoostAddVelocityY * InputMove.z) * self._smMove.y

	local Ang = self:GetAngles()

	if not self:GetEngineActive() then
		self:SetSteerTo( Ang.y )
		self.smY = Ang.y
	end

	self.smY = self.smY and math.ApproachAngle( self.smY, self:GetSteerTo(), self.MaxTurnRate * deltatime * 100 ) or Ang.y

	local Steer = self:WorldToLocalAngles( Angle(Ang.p,self.smY,Ang.y) ).y

	local ForceLinear = ((Vector( MoveX, MoveY, 0 ) - Vector(VelL.x,VelL.y,0)) * self.ForceLinearMultiplier) * OnGroundMul * deltatime * 500
	local ForceAngle = (Vector(0,0,Steer) * self.ForceAngleMultiplier * 2 - phys:GetAngleVelocity() * self.ForceAngleDampingMultiplier) * OnGroundMul * deltatime * 600 

	local SIMULATE = self:GetDisabled() and SIM_NOTHING or SIM_LOCAL_ACCELERATION

	return ForceAngle, ForceLinear, SIMULATE
end

function ENT:IsEngineStartAllowed()
	if hook.Run( "LVS.IsEngineStartAllowed", self ) == false then return false end

	if self:GetDisabled() then return false end

	if self:WaterLevel() > self.WaterLevelPreventStart then return false end

	return true
end

function ENT:OnDisabled( name, old, new)
	if new == old then return end

	if new then
		if not self:GetEngineActive() then return end
		self:SetEngineActive( false )
	end
end
