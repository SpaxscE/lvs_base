
ENT.Base = "lvs_walker_atte_hoverscript"

ENT.PrintName = "ATTE"
ENT.Author = "Luna"
ENT.Information = "Assault Walker of the Galactic Republic"
ENT.Category = "[LVS] - Star Wars"

ENT.Spawnable		= true
ENT.AdminSpawnable	= false

ENT.MDL = "models/blu/atte.mdl"
ENT.GibModels = {
	"models/blu/atte.mdl",
	"models/blu/atte_rear.mdl",
	"models/blu/atte_bigfoot.mdl",
	"models/blu/atte_bigleg.mdl",
	"models/blu/atte_smallleg_part1.mdl",
	"models/blu/atte_smallleg_part2.mdl",
	"models/blu/atte_smallleg_part3.mdl"
}

ENT.AITEAM = 2

ENT.MaxHealth = 12000

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.HoverHeight = 140
ENT.HoverTraceLength = 200
ENT.HoverHullRadius = 20

ENT.CanMoveOn = {
	["func_door"] = true,
	["func_movelinear"] = true,
	["prop_physics"] = true,
}

function ENT:OnSetupDataTables()
	self:AddDT( "Entity", "RearEntity" )

	self:AddDT( "Float", "Move" )
	self:AddDT( "Bool", "IsMoving" )
	self:AddDT( "Bool", "IsCarried" )
	self:AddDT( "Bool", "IsRagdoll" )

	if SERVER then
		self:NetworkVarNotify( "IsCarried", self.OnIsCarried )
	end
end

function ENT:GetContraption()
	return {self, self:GetRearEntity()}
end
