
ENT.Base = "lvs_base_fakehover"

ENT.PrintName = "IFT-X"
ENT.Author = "Luna"
ENT.Information = "Hover Tank of the Galactic Republic"
ENT.Category = "[LVS] - Star Wars"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/iftx.mdl"

ENT.MaxHealth = 2700

ENT.LAATC_PICKUPABLE = true
ENT.LAATC_DROP_IN_AIR = true
ENT.LAATC_PICKUP_POS = Vector(-200,0,25)
ENT.LAATC_PICKUP_Angle = Angle(0,0,0)

function ENT:OnSetupDataTables()
	self:AddDT( "Bool", "BTLFire" )
	self:AddDT( "Bool", "IsCarried" )
	self:AddDT( "Bool", "LightsActive" )

	if SERVER then
		self:NetworkVarNotify( "IsCarried", self.OnIsCarried )
	end
end