AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_camera.lua" )
AddCSLuaFile( "cl_hud.lua" )
AddCSLuaFile( "sh_camera_eyetrace.lua" )
include("shared.lua")
include("sv_controls.lua")
include("sv_wheels.lua")
include("sh_camera_eyetrace.lua")

function ENT:OnDriverChanged( Old, New, VehicleIsActive )
	if VehicleIsActive then return end

	self:SetSteer( 0 )
	self:SetMove( 0, 0 )
end

function ENT:PhysicsSimulate( phys, deltatime )
	phys:Wake()

	local OnGroundMul = self:HitGround() and 1 or 0

	local VelL = phys:WorldToLocal( phys:GetPos() + phys:GetVelocity() )

	local InputMove = self:GetMove()

	self._smMove = self._smMove and (self._smMove + (Vector(InputMove.x,InputMove.y,0):GetNormalized() - self._smMove) * deltatime * self.ForceLinearRate * 10) or InputMove

	local MoveX = (self.MaxVelocityX + self.BoostAddVelocityX * InputMove.z) * self._smMove.x
	local MoveY = (self.MaxVelocityY + self.BoostAddVelocityY * InputMove.z) * self._smMove.y

	local ForceLinear = ((Vector( MoveX, MoveY, 0 ) - Vector(VelL.x,VelL.y,0)) * self.ForceLinearMultiplier) * OnGroundMul * deltatime * 500
	local ForceAngle = (-phys:GetAngleVelocity() * self.ForceAngleDampingMultiplier * OnGroundMul) * 400 * deltatime

	return ForceAngle, ForceLinear, SIM_LOCAL_ACCELERATION
end
