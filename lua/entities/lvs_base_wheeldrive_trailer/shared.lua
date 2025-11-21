
ENT.Base = "lvs_base_wheeldrive"

ENT.PrintName = "[LVS] Wheeldrive Trailer"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS] - Cars"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

ENT.DeleteOnExplode = true

ENT.lvsAllowEngineTool = false
ENT.lvsShowInSpawner = false

ENT.AllowSuperCharger = false
ENT.AllowTurbo = false

ENT.PhysicsDampingSpeed = 1000
ENT.PhysicsDampingForward = true
ENT.PhysicsDampingReverse = true

function ENT:SetupDataTables()
	self:CreateBaseDT()

	self:AddDT( "Entity", "InputTarget" )
	self:AddDT( "Entity", "LightsHandler" )
	self:AddDT( "Vector", "AIAimVector" )

	self:TurretSystemDT()
	self:TrackSystemDT()
end
	
function ENT:GetVehicleType()
	return "LBaseTrailer"
end

function ENT:StartCommand( ply, cmd )
end

function ENT:SetNWHandBrake()
end

function ENT:GetGear()
	return -1
end

function ENT:GetWheelVelocity()
	return self:GetVelocity():Length()
end

function ENT:GetRacingTires()
	return false
end

function ENT:IsManualTransmission()
	return false
end

function ENT:SetThrottle()
end

function ENT:SetReverse()
end

function ENT:GetEngine()
	local InputTarget = self:GetInputTarget()

	if not IsValid( InputTarget ) or not InputTarget.GetEngine then return NULL end

	return InputTarget:GetEngine()
end

function ENT:GetFuelTank()
	local InputTarget = self:GetInputTarget()

	if not IsValid( InputTarget ) or not InputTarget.GetFuelTank then return NULL end

	return InputTarget:GetFuelTank()
end

function ENT:GetThrottle()
	local InputTarget = self:GetInputTarget()

	if not IsValid( InputTarget ) or not InputTarget.GetThrottle then return 0 end

	return InputTarget:GetThrottle()
end

function ENT:GetSteer()
	local InputTarget = self:GetInputTarget()

	if not IsValid( InputTarget ) or not InputTarget.GetSteer then return 0 end

	return InputTarget:GetSteer()
end

function ENT:GetNWMaxSteer()
	local InputTarget = self:GetInputTarget()

	if not IsValid( InputTarget ) or not InputTarget.GetNWMaxSteer then return 1 end

	return InputTarget:GetNWMaxSteer()
end

function ENT:GetTurnMode()
	local InputTarget = self:GetInputTarget()

	if not IsValid( InputTarget ) or not InputTarget.GetTurnMode then return 0 end

	return InputTarget:GetTurnMode()
end

function ENT:GetReverse()
	local InputTarget = self:GetInputTarget()

	if not IsValid( InputTarget ) or not InputTarget.GetReverse then return false end

	return InputTarget:GetReverse()
end

function ENT:GetNWHandBrake()
	local ApplyBrakes = not IsValid( self:GetInputTarget() )

	if ApplyBrakes and self._HandBrakeForceDisabled then
		return false
	end

	return ApplyBrakes
end

function ENT:GetBrake()
	local InputTarget = self:GetInputTarget()

	if not IsValid( InputTarget ) or not InputTarget.GetBrake then return 0 end

	return InputTarget:GetBrake()
end