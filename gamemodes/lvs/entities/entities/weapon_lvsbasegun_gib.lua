AddCSLuaFile()

ENT.Type            = "anim"

ENT.PhysicsSounds = true
 
if SERVER then
	function ENT:SetAmmo( amount, type )
		self._ammo = amount
		self._ammotype = type
	end

	function ENT:GetAmmo()
		return (self._ammo or 0), (self._ammotype or "none")
	end

	function ENT:Pickup( entity )
		if not IsValid( entity ) or not entity:IsPlayer() then return end

		entity:GiveAmmo( self:GetAmmo() )

		self:Remove()
	end

	function ENT:Use( ply )
		self:Pickup( ply )
	end

	function ENT:Initialize()
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
		self:SetUseType( SIMPLE_USE )

		timer.Simple( 5.5, function()
			if not IsValid( self ) then return end

			self:SetRenderFX( kRenderFxFadeFast  ) 
		end)

		timer.Simple( 6, function()
			if not IsValid( self ) then return end

			self:Remove()
		end)
	end

	function ENT:Think()
		return false
	end

	function ENT:OnRemove()
	end
else
	function ENT:Draw( flags )
		self:DrawModel( flags )
	end
end