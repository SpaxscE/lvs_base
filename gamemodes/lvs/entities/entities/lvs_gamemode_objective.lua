AddCSLuaFile()

ENT.Type            = "anim"

ENT.Spawnable		= false
ENT.AdminOnly		= false

if SERVER then
	function ENT:Initialize()	
		self:SetModel( "models/items/item_item_crate.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:PhysWake()
	end

	function ENT:Think()
		return false
	end

	function ENT:PhysicsCollide( data, physobj )
	end

	function ENT:OnTakeDamage( dmginfo )
	end
end

if CLIENT then
	function ENT:Draw( flags )
		self:DrawModel( flags )
	end

	function ENT:OnRemove()
	end

	function ENT:Think()
	end
end
