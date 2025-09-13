AddCSLuaFile()

ENT.Base = "lvs_item_jerrycan"
DEFINE_BASECLASS( "lvs_item_jerrycan" )

ENT.PrintName = "Jerry Can (Diesel)"
ENT.Author = "Luna"
ENT.Category = "[LVS]"

ENT.Spawnable		= true
ENT.AdminOnly		= false

ENT.AutomaticFrameAdvance = true

ENT.FuelAmount = 120 -- seconds
ENT.FuelType = LVS.FUELTYPE_DIESEL

ENT.lvsGasStationFillSpeed = 0.05
ENT.lvsGasStationRefillMe = true

if SERVER then
	function ENT:Initialize()
		BaseClass.Initialize( self )
		self:SetSkin( 1 )
	end
end