
ENT.Base = "lvs_base_wheeldrive_trailer"

ENT.PrintName = "FlaK Trailer"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"

ENT.VehicleCategory = "Artillery"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/flakcarriage.mdl"

ENT.AITEAM = 0

ENT.MaxHealth = 200

ENT.DSArmorIgnoreForce = 1000

ENT.ForceAngleMultiplier = 2

ENT.lvsShowInSpawner = false

function ENT:OnSetupDataTables()
	self:AddDT( "Bool", "Prong" )
end

ENT.GibModels = {
	"models/blu/carriage_wheel.mdl",
	"models/blu/carriage_wheel.mdl",
	"models/gibs/manhack_gib01.mdl",
	"models/gibs/manhack_gib02.mdl",
	"models/gibs/manhack_gib03.mdl",
	"models/gibs/manhack_gib04.mdl",
	"models/props_c17/canisterchunk01a.mdl",
	"models/props_c17/canisterchunk01d.mdl",
	"models/blu/carriage_d1.mdl",
	"models/blu/carriage_d2.mdl",
	"models/blu/carriage_d3.mdl",
	"models/blu/carriage_d4.mdl",
	"models/blu/carriage_d5.mdl",
	"models/blu/carriage_d6.mdl",
}