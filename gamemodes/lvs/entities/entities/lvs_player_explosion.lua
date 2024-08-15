AddCSLuaFile()

ENT.Type            = "anim"

local gibs = {
	"models/Gibs/HGIBS.mdl",
	"models/Gibs/HGIBS_rib.mdl",
	"models/Gibs/HGIBS_scapula.mdl",
	"models/Gibs/HGIBS_spine.mdl",
}

for _, modelName in ipairs( gibs ) do
	util.PrecacheModel( modelName )
end

if SERVER then
	function ENT:SetDissolve( shoulddissolve )
		self._Dissolve = shoulddissolve
	end

	function ENT:GetDissolve()
		return self._Dissolve == true
	end

	function ENT:SetHull( Mins, Maxs )
		self._Mins = Mins
		self._Maxs = Maxs
	end

	function ENT:GetHull()
		if not self._Mins then
			self._Mins = Vector(-16,-16,0)
		end

		if not self._Maxs then
			self._Maxs = Vector(16,16,72)
		end

		return self._Mins, self._Maxs
	end

	function ENT:GetForce()
		if not self._Force then return vector_origin end

		return self._Force
	end

	function ENT:SetForce( force )
		self._Force = force
	end

	function ENT:SpawnFunction( ply, tr, ClassName )
		if not tr.Hit then return end

		local ent = ents.Create( ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal )
		ent:Spawn()
		ent:Activate()

		return ent
	end

	function ENT:Initialize()
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false )

		self.DieTime = CurTime() + 30

		local Pos = self:GetPos()

		local Mins, Maxs = self:GetHull()

		self:EmitSound("physics/flesh/flesh_bloody_break.wav", 85)

		local AllEnts = ents.GetAll()
		local ShouldDissolve = self:GetDissolve()

		for i = 1, 20 do
			timer.Simple( math.Rand(0,0.2), function()
				local NewPos = Pos + Vector( math.Rand(Mins.x,Maxs.x), math.Rand(Mins.y,Maxs.y), math.Rand(Mins.z,Maxs.z) )

				local effectdata = EffectData()
				effectdata:SetOrigin( NewPos )
				util.Effect( "BloodImpact", effectdata, true, true )

				util.Decal( "Blood", NewPos, NewPos - Vector(0,0,120), AllEnts )
			end)
		end

		local Force = self:GetForce()

		self.Gibs = {}

		for _, v in pairs( gibs ) do
			local ent = ents.Create( "lvs_player_gib" )

			if not IsValid( ent ) then continue end

			table.insert( self.Gibs, ent ) 

			ent:SetPos( Pos + Vector( math.Rand(Mins.x,Maxs.x), math.Rand(Mins.y,Maxs.y), math.Rand(Maxs.z * 0.5,Maxs.z) ) )
			ent:SetAngles( self:GetAngles() )
			ent:SetModel( v )
			ent:Spawn()
			ent:Activate()
			ent.FortificationIgnorePhysicsDamage = true

			if v == "models/Gibs/HGIBS.mdl" then
				local ply = self:GetOwner()
				if IsValid( ply ) then
					ply:Spectate( OBS_MODE_CHASE )
					ply:SpectateEntity( ent )
				end
			end

			local PhysObj = ent:GetPhysicsObject()

			if IsValid( PhysObj ) then
				if ShouldDissolve then
					PhysObj:EnableGravity( false ) 
					PhysObj:SetVelocity( VectorRand() * 400 )

					local dissolver = ents.Create("env_entity_dissolver")
					dissolver:SetMoveParent( ent )
					dissolver:SetSaveValue("m_flStartTime",0 )
					dissolver:Spawn()
					dissolver:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )

					ent:SetSaveValue("m_flDissolveStartTime", 0 )
					ent:SetSaveValue("m_hEffectEntity", dissolver )
					ent:AddFlags( FL_DISSOLVING )

					timer.Simple(0.1, function()
						if not IsValid( PhysObj ) then return end

						PhysObj:SetDragCoefficient( 400 )
					end)
				else
					PhysObj:SetVelocityInstantaneous( VectorRand() * 100 + Force )
					PhysObj:AddAngleVelocity( VectorRand() * 500 ) 
					PhysObj:EnableDrag( false ) 
				end

			end

			timer.Simple( self.DieTime - math.Rand(0.5,1), function()
				if not IsValid( ent ) then return end

				ent:SetRenderFX( kRenderFxFadeFast  ) 
			end)
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
		if not istable( self.Gibs ) then return end

		for _, v in pairs( self.Gibs ) do
			if IsValid( v ) then
				v:Remove()
			end
		end
	end

else
	function ENT:Draw()
	end
end