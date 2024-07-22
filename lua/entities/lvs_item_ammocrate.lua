AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName = "Ammo Crate"
ENT.Information = "Single-Use Ammo Refil Item"
ENT.Author = "Luna"
ENT.Category = "[LVS]"

ENT.Spawnable		= true
ENT.AdminOnly		= false

if SERVER then
	function ENT:SpawnFunction( ply, tr, ClassName )
		if not tr.Hit then return end

		local ent = ents.Create( ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal * 5 )
		ent:Spawn()
		ent:Activate()

		return ent
	end

	function ENT:Initialize()	
		self:SetModel( "models/items/item_item_crate.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:PhysWake()
	end

	function ENT:Think()
		return false
	end

	function ENT:Refil( entity )
		if self.MarkForRemove then return end

		if not IsValid( entity ) then return end

		if not entity.LVS then return end

		if entity:WeaponRestoreAmmo() then
			entity:EmitSound("items/ammo_pickup.wav")
		end

		entity:OnMaintenance()

		self.MarkForRemove = true

		SafeRemoveEntityDelayed( self, 0 )
	end

	function ENT:PhysicsCollide( data, physobj )
		self:Refil( data.HitEntity )
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
