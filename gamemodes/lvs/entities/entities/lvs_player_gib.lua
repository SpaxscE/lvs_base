AddCSLuaFile()

ENT.Type            = "anim"

ENT.FortificationIgnorePhysicsDamage = true

if SERVER then
	function ENT:Initialize()
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

		local PObj = self:GetPhysicsObject()

		if not IsValid( PObj ) then 
			self:Remove()

			return
		end

		PObj:Wake()
	end

	function ENT:Think()
		if self.HasCollided then return false end

		self:NextThink( CurTime() + 0.2 )

		local effectdata = EffectData()
		effectdata:SetOrigin( self:GetPos() )
		util.Effect( "BloodImpact", effectdata, true, true )

		return true
	end

	function ENT:OnRemove()
	end

	function ENT:PhysicsCollide( data, physobj )
		self.HasCollided = true

		local effectdata = EffectData()
		effectdata:SetOrigin( self:GetPos() + Vector(0,0,5) )
		util.Effect( "BloodImpact", effectdata, true, true )

		if data.Speed > 20 and data.DeltaTime > 0.2 then
			self:EmitSound("physics/flesh/flesh_bloody_impact_hard1.wav")
		end

		util.Decal( "Blood", data.HitPos + data.HitNormal, data.HitPos - data.HitNormal, ents.GetAll() )
	end

	function ENT:OnTakeDamage( dmginfo )
	end
else
	function ENT:Draw( flags )
		self:DrawModel( flags )
	end
end