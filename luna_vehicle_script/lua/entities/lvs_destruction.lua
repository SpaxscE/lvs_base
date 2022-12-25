AddCSLuaFile()

ENT.Type            = "anim"

if CLIENT then
	function ENT:Draw()
	end
end

if SERVER then
	function ENT:Initialize()
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false ) 

		self.Vel = isvector( self.Vel ) and self.Vel or Vector(0,0,0)

		local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
		util.Effect( "lvs_explosion", effectdata )

		local gibs = {
			"models/XQM/wingpiece2.mdl",
			"models/XQM/wingpiece2.mdl",
			"models/XQM/jetwing2medium.mdl",
			"models/XQM/jetwing2medium.mdl",
			"models/props_phx/misc/propeller3x_small.mdl",
			"models/props_c17/TrapPropeller_Engine.mdl",
			"models/props_junk/Shoe001a.mdl",
			"models/XQM/jetbody2fuselage.mdl",
			"models/XQM/jettailpiece1medium.mdl",
			"models/XQM/pistontype1huge.mdl",
		}

		self.GibModels = istable( self.GibModels ) and self.GibModels or gibs

		self.Gibs = {}
		self.DieTime = CurTime() + 5

		for _, v in pairs( self.GibModels ) do
			local ent = ents.Create( "prop_physics" )

			if IsValid( ent ) then
				table.insert( self.Gibs, ent ) 

				ent:SetPos( self:GetPos() )
				ent:SetAngles( self:GetAngles() )
				ent:SetModel( v )
				ent:Spawn()
				ent:Activate()
				ent:SetRenderMode( RENDERMODE_TRANSALPHA )
				ent:SetCollisionGroup( COLLISION_GROUP_WORLD )

				local PhysObj = ent:GetPhysicsObject()
				if IsValid( PhysObj ) then
					PhysObj:SetVelocityInstantaneous( VectorRand() * math.max(300,self.Vel:Length() / 3) + self.Vel  )
					PhysObj:AddAngleVelocity( VectorRand() * 500 ) 
					PhysObj:EnableDrag( false ) 

					local effectdata = EffectData()
						effectdata:SetOrigin( ent:GetPos() )
						effectdata:SetStart( PhysObj:GetMassCenter() )
						effectdata:SetEntity( ent )
						effectdata:SetScale( math.Rand(0.3,0.7) )
						effectdata:SetMagnitude( math.Rand(0.5,2.5) )
					util.Effect( "lvs_firetrail", effectdata )
				end

				timer.Simple( 4.5 + math.Rand(0,0.5), function()
					if not IsValid( ent ) then return end
					ent:SetRenderFX( kRenderFxFadeFast  ) 
				end)
			end
		end
	end

	function ENT:Think()
		if self.DieTime < CurTime() then
			self:Remove()
		end

		self:NextThink( CurTime() )

		return true
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

	function ENT:OnTakeDamage( dmginfo )
	end

	function ENT:PhysicsCollide( data, physobj )
	end
end