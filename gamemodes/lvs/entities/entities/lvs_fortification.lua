AddCSLuaFile()

ENT.Type            = "anim"

ENT.Spawnable		= false
ENT.AdminOnly		= false

ENT.IsFortification = true

ENT.DefaultHP = 100

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",1, "CreatedBy" )
	self:NetworkVar( "Float",1, "HP" )
	self:NetworkVar( "Float",2, "MaxHP" )
	self:NetworkVar( "Float", 3, "LastTouched" )

	if SERVER then
		self:SetHP( self.DefaultHP )
		self:SetMaxHP( self.DefaultHP )
	end
end

function ENT:GetAITEAM()
	local ply = self:GetCreatedBy()

	if not IsValid( ply ) then return 0 end

	return ply:lvsGetAITeam()
end

function ENT:IsEnemy( otherEnt )
	if not IsValid( otherEnt ) then return true end

	local myTeam = self:GetAITEAM()
	local theirTeam = 0

	if otherEnt:IsPlayer() then
		theirTeam = otherEnt:lvsGetAITeam()
	else
		if isfunction( otherEnt.GetAITEAM ) then
			theirTeam = otherEnt:GetAITEAM()
		end
	end

	return myTeam ~= theirTeam
end

if SERVER then
	function ENT:Initialize()
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )

		local PObj = self:GetPhysicsObject()

		if not IsValid( PObj ) then 
			self:Remove()

			return
		end

		PObj:EnableMotion( false )

		timer.Simple(1, function()
			if not IsValid( self ) then return end

			if not istable( self.GibModels ) then return end

			for _, modelName in ipairs( self.GibModels ) do
				util.PrecacheModel( modelName )
			end
		end)
	end

	function ENT:Think()
		return false
	end

	function ENT:TakeCollisionDamage( damage, attacker )
		if not IsValid( attacker ) then
			attacker = game.GetWorld()
		end

		local inflictor = attacker

		if isfunction( attacker.GetDriver ) then
			attacker = attacker:GetDriver()
		else
			if isfunction( inflictor.GetBase ) then
				inflictor = inflictor:GetBase()

				if isfunction( inflictor.GetDriver ) then
					attacker = inflictor:GetDriver()
				end
			end
		end

		local dmginfo = DamageInfo()
		dmginfo:SetDamage( damage )
		dmginfo:SetAttacker( attacker )
		dmginfo:SetInflictor( inflictor )
		dmginfo:SetDamageType( DMG_CRUSH + DMG_VEHICLE )
		self:TakeDamageInfo( dmginfo )
	end

	function ENT:PhysicsCollide( data, physobj )
		if not IsValid( data.HitEntity ) then return end

		if data.HitEntity.FortificationIgnorePhysicsDamage then return end

		if self:GetMaxHP() > 100 then
			if data.HitEntity.GetVehicleType then
				if data.HitEntity:GetVehicleType() ~= "tank" then return end
			else
				if not data.HitEntity.GetBase then return end

				local Base = data.HitEntity:GetBase()

				if not IsValid( Base ) or not Base.GetVehicleType then return end

				if Base:GetVehicleType() ~= "tank" then return end
			end
		else
			if data.HitEntity:IsPlayer() then return end
		end

		local PhysObj = data.HitEntity:GetPhysicsObject()

		if not IsValid( PhysObj ) then return end

		self:TakeCollisionDamage( self:GetHP(), data.HitEntity )

		local Vel = data.TheirOldVelocity
		local AngVel = data.TheirOldAngularVelocity

		PhysObj:SetVelocityInstantaneous( Vel )
		PhysObj:SetAngleVelocityInstantaneous( AngVel )

		timer.Simple( 0, function()
			if not IsValid( PhysObj ) then return end

			PhysObj:SetVelocityInstantaneous( Vel )
			PhysObj:SetAngleVelocityInstantaneous( AngVel )
		end )
	end

	ENT.DamageIgnoreForce = 3000
	ENT.DamageIgnoreType = DMG_GENERIC

	function ENT:OnTakeDamage( dmginfo )
		if self.IsDestroyed then return end

		if dmginfo:IsDamageType( self.DamageIgnoreType ) then return end

		local IsBlastDamage = dmginfo:IsDamageType( DMG_BLAST )
		local IsFireDamage = dmginfo:IsDamageType( DMG_BURN )
		local IsCollisionDamage = dmginfo:GetDamageType() == (DMG_CRUSH + DMG_VEHICLE)

		if not IsBlastDamage and not IsFireDamage and not IsCollisionDamage then
			if dmginfo:GetDamageForce():Length() < self.DamageIgnoreForce then
				return
			end
		end

		local Damage = dmginfo:GetDamage()

		if Damage <= 0 then return end

		local CurHealth = self:GetHP()

		local NewHealth = math.Clamp( CurHealth - Damage, -self:GetMaxHP(), self:GetMaxHP() )

		self:SetHP( NewHealth )
		self:SetLastTouched( CurTime() )

		if NewHealth <= 0 then
			self:Destroy()

			local ply = dmginfo:GetAttacker()

			if not IsValid( ply ) or not ply:IsPlayer() then return end

			GAMEMODE:OnPlayerDestroyFortification( ply, self, not self:IsEnemy( ply ) )
		end
	end

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

	function ENT:SpawnGibs()
		local pos = self:LocalToWorld( self:OBBCenter() )
		local ang = self:GetAngles()

		self.GibModels = istable( self.GibModels ) and self.GibModels or gibs

		for _, v in pairs( self.GibModels ) do
			local ent = ents.Create( "prop_physics" )

			if not IsValid( ent ) then continue end

			ent:SetPos( pos )
			ent:SetAngles( ang )
			ent:SetModel( v )
			ent:Spawn()
			ent:Activate()
			ent:SetRenderMode( RENDERMODE_TRANSALPHA )
			ent:SetCollisionGroup( COLLISION_GROUP_WORLD )

			local PhysObj = ent:GetPhysicsObject()

			if IsValid( PhysObj ) then
				PhysObj:SetVelocityInstantaneous( Vector( math.Rand(-1,1), math.Rand(-1,1), 1.5 ):GetNormalized() * math.random(250,400)  )
				PhysObj:AddAngleVelocity( VectorRand() * 500 ) 
				PhysObj:EnableDrag( false ) 
			end

			timer.Simple( 5, function()
				if not IsValid( ent ) then return end

				if ent:GetVelocity():LengthSqr() > 1000 then
					ent:Remove()

					return
				end
	
				ent:SetSolid( SOLID_NONE )
				ent:PhysicsDestroy()
			end)

			timer.Simple( 119.5, function()
				if not IsValid( ent ) then return end

				ent:SetRenderFX( kRenderFxFadeFast  ) 
			end)

			timer.Simple( 120, function()
				if not IsValid( ent ) then return end

				ent:Remove()
			end)
		end
	end

	function ENT:Explode()
		local effectdata = EffectData()
			effectdata:SetOrigin( self:LocalToWorld( self:OBBCenter() ) )
		util.Effect( "lvs_fortification_explosion", effectdata, true, true )

		if istable( self.BreakSounds ) then
			self:EmitSound( table.Random( self.BreakSounds ),80,100,1)
		else
			if isstring( self.BreakSounds ) then
				self:EmitSound( self.BreakSounds,80,100,1)
			end
		end

		self:SpawnGibs()
	end

	function ENT:OnDestroyed()
	end

	function ENT:Destroy()
		if self.IsDestroyed then return end

		self.IsDestroyed = true

		self:Explode()
		self:OnDestroyed()
		self:SetSolid( SOLID_NONE )
		self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
		SafeRemoveEntityDelayed( self, 0 )
	end
end

if CLIENT then
	local ColFriend = Color(0,127,255,255)
	local ColEnemy = Color(255,0,0,255)

	function ENT:GetTeamColor()
		if self:GetAITEAM() ~= LocalPlayer():lvsGetAITeam() then return ColEnemy end

		return ColFriend
	end

	function ENT:Draw( flags )
		self:DrawModel( flags )
	end

	function ENT:OnRemove()
	end

	function ENT:Think()
	end
end
