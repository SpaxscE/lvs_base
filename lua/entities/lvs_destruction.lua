AddCSLuaFile()

ENT.Type            = "anim"

local gibs = {
	"models/gibs/manhack_gib01.mdl",
	"models/gibs/manhack_gib02.mdl",
	"models/gibs/manhack_gib03.mdl",
	"models/gibs/manhack_gib04.mdl",
	"models/props_c17/canisterchunk01a.mdl",
	"models/props_c17/canisterchunk01d.mdl",
	"models/props_c17/oildrumchunk01a.mdl",
	"models/props_c17/oildrumchunk01b.mdl",
	"models/props_c17/oildrumchunk01c.mdl",
	"models/props_c17/oildrumchunk01d.mdl",
	"models/props_c17/oildrumchunk01e.mdl",
}

for _, modelName in ipairs( gibs ) do
	util.PrecacheModel( modelName )
end

if SERVER then
	function ENT:Initialize()
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false ) 

		self.Vel = isvector( self.Vel ) and self.Vel or Vector(0,0,0)

		local fxPos = self:LocalToWorld( self:OBBCenter() )
	
		local effectdata = EffectData()
			effectdata:SetOrigin( fxPos )
		util.Effect( "lvs_explosion", effectdata )

		self.GibModels = istable( self.GibModels ) and self.GibModels or gibs

		self.Gibs = {}
		self.DieTime = CurTime() + 5

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
			ent:SetRenderMode( RENDERMODE_TRANSALPHA )
			ent:SetCollisionGroup( COLLISION_GROUP_WORLD )

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

			timer.Simple( 4.5 + math.Rand(0,0.5), function()
				if not IsValid( ent ) then return end

				ent:SetRenderMode( RENDERMODE_TRANSCOLOR )
				ent:SetRenderFX( kRenderFxFadeFast  )
			end )
		end
	end

	function ENT:Think()
		if self.DieTime < CurTime() then
			self:Remove()
		end

		self:NextThink( CurTime() + 1 )

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
else
	function ENT:Draw()
	end
end