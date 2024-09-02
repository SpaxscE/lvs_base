AddCSLuaFile()

ENT.Type            = "anim"

 ENT.PhysicsSounds = true
 
if SERVER then
	function ENT:Initialize()
		self:SetModel( "models/weapons/w_rocket_launcher.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

		timer.Simple( 5, function()
			if not IsValid( self ) then return end

			if self:GetVelocity():LengthSqr() > 1000 then
				self:Remove()

				return
			end

			self:SetSolid( SOLID_NONE )
			self:PhysicsDestroy()
		end)

		timer.Simple( 59.5, function()
			if not IsValid( self ) then return end

			self:SetRenderFX( kRenderFxFadeFast  ) 
		end)

		timer.Simple( 60, function()
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