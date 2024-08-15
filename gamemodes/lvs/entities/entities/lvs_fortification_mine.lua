AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName		= "Mine"
ENT.Author		= "Blu-x92"
ENT.Information		= "Immobilize Tanks"
ENT.Category = "[LVS]"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false

if SERVER then
	function ENT:SetDamage( num ) self._dmg = num end
	function ENT:SetRadius( num ) self._radius = num end
	function ENT:SetAttacker( ent ) self._attacker = ent end

	function ENT:GetAttacker() return self._attacker or NULL end
	function ENT:GetDamage() return (self._dmg or 1500) end
	function ENT:GetRadius() return (self._radius or 150) end

	function ENT:GetCreatedBy()
		return self:GetAttacker()
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

	function ENT:SpawnFunction( ply, tr, ClassName )

		if not tr.Hit then return end

		local ent = ents.Create( ClassName )
		ent.Attacker = ply
		ent:SetPos( tr.HitPos + tr.HitNormal )
		ent:Spawn()
		ent:Activate()

		return ent

	end

	function ENT:Initialize()	
		self:SetModel( "models/blu/lvsmine.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		self:SetCollisionGroup( COLLISION_GROUP_WEAPON  )

		self.First = true
	end

	function ENT:Use( ply )
	end

	function ENT:Detonate()
		if self.IsExploded then return end

		self.IsExploded = true

		local Pos = self:GetPos()

		local effectdata = EffectData()
		effectdata:SetOrigin( Pos )

		if self:WaterLevel() >= 2 then
			util.Effect( "WaterSurfaceExplosion", effectdata, true, true )
		else
			util.Effect( "lvs_fortification_explosion_mine", effectdata )
		end

		self:SetNoDraw( true )

		timer.Simple( 0.1, function()
			if not IsValid( self ) then return end

			local dmginfo = DamageInfo()
			dmginfo:SetDamage( self:GetDamage() )
			dmginfo:SetAttacker( IsValid( self:GetAttacker() ) and self:GetAttacker() or self )
			dmginfo:SetDamageType( DMG_BLAST )
			dmginfo:SetInflictor( self )
			dmginfo:SetDamagePosition( Pos )

			util.BlastDamageInfo( dmginfo, Pos, self:GetRadius() )

			self:Remove()
		end )
	end

	function ENT:Think()
		if self.ShouldDetonate then
			self:Detonate()
		end

		self:NextThink( CurTime() + 0.1 )

		return true
	end

	function ENT:OnRemove()
	end

	function ENT:PhysicsCollide( data, PhysObj )
		local HitEnt = data.HitEntity

		if self.First then
			self.First = nil
			self.IgnoreEnt = HitEnt
		end

		if HitEnt == self.IgnoreEnt or not self:IsEnemy( HitEnt ) then
			if data.Speed > 60 and data.DeltaTime > 0.1 then
				self:EmitSound( "weapon.ImpactHard" )
			end

			return
		end

		PhysObj:SetVelocity( data.OurOldVelocity * 0.5 )

		if not IsValid( HitEnt ) or HitEnt:IsWorld() then 
			if data.Speed > 60 and data.DeltaTime > 0.1 then
				self:EmitSound( "weapon.ImpactHard" )
			end
			
			return
		end

		if not HitEnt:IsPlayer() and PhysObj:GetStress() > 10 and HitEnt:GetClass() ~= self:GetClass() then
			self.ShouldDetonate = true
		else
			if data.Speed > 60 and data.DeltaTime > 0.1 then
				self:EmitSound( "weapon.ImpactHard" )
			end
		end
	end

	function ENT:OnTakeDamage( dmginfo )
		self:Detonate()
	end
else
	function ENT:Draw()
		self:DrawModel()
	end

	function ENT:Think()
		return false
	end

	function ENT:OnRemove()
	end
end