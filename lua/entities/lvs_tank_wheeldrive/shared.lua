
ENT.Base = "lvs_base_wheeldrive"

ENT.PrintName = "[LVS] Wheeldrive Tank"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS] - Cars"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

ENT.MaxHealthEngine = 400
ENT.MaxHealthFuelTank = 100

ENT.WheelTickInterval = 0.2
ENT.WheelTickIntervalBraking = 0.02

function ENT:TrackSystemDT()
	self:AddDT( "Entity", "TrackDriveWheelLeft" )
	self:AddDT( "Entity", "TrackDriveWheelRight" )
end

function ENT:GetVehicleType()
	return "tank"
end