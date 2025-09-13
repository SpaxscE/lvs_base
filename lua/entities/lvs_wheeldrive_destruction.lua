AddCSLuaFile()

ENT.Type            = "anim"

if SERVER then
	function ENT:Initialize()
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false ) 

		self.Vel = isvector( self.Vel ) and self.Vel or Vector(0,0,0)

		local fxPos = self:LocalToWorld( self:OBBCenter() )
	
		local effectdata = EffectData()
			effectdata:SetOrigin( fxPos )
		util.Effect( "lvs_explosion_bomb", effectdata )

		self.Gibs = {}

		if not istable( self.GibModels ) then return end

		local Speed = self.Vel:Length()

		for _, v in pairs( self.GibModels ) do
			local ent = ents.Create( "prop_physics" )

			if not IsValid( ent ) then continue end

			table.insert( self.Gibs, ent ) 

			ent:SetPos( self:GetPos() )
			ent:SetAngles( self:GetAngles() )
			ent:SetModel( v )
			ent:Spawn()
			ent:Activate()
			ent:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

			local PhysObj = ent:GetPhysicsObject()
			if IsValid( PhysObj ) then
				if Speed <= 250 then
					local GibDir = Vector( math.Rand(-1,1), math.Rand(-1,1), 1.5 ):GetNormalized()
					PhysObj:SetVelocityInstantaneous( GibDir * math.random(800,1300)  )
				else
					PhysObj:SetVelocityInstantaneous( VectorRand() * math.max(300,self.Vel:Length() / 3) + self.Vel  )
				end

				PhysObj:AddAngleVelocity( VectorRand() * 500 ) 
				PhysObj:EnableDrag( false ) 

				local effectdata = EffectData()
					effectdata:SetOrigin( fxPos )
					effectdata:SetStart( PhysObj:GetMassCenter() )
					effectdata:SetEntity( ent )
					effectdata:SetScale( math.Rand(0.3,0.7) )
					effectdata:SetMagnitude( math.Rand(0.5,2.5) )
				util.Effect( "lvs_firetrail", effectdata )
			end
		end
	end

	function ENT:Think()
		return false
	end

	function ENT:OnRemove()
		if istable( self.Gibs ) then
			for _, v in pairs( self.Gibs ) do
				if IsValid( v ) then
					v:Remove()
				end
			end
		end
	end
else
	function ENT:Draw()
	end
end