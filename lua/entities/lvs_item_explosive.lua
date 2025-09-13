AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName = "Explosive"
ENT.Author = "Luna"
ENT.Category = "[LVS]"

ENT.Spawnable		= false
ENT.AdminOnly		= false

if SERVER then
	function ENT:SetDamage( num ) self._dmg = num end
	function ENT:SetRadius( num ) self._radius = num end
	function ENT:SetAttacker( ent ) self._attacker = ent end

	function ENT:GetAttacker() return self._attacker or NULL end
	function ENT:GetDamage() return (self._dmg or 250) end
	function ENT:GetRadius() return (self._radius or 250) end

	function ENT:SpawnFunction( ply, tr, ClassName )
		if not tr.Hit then return end

		local ent = ents.Create( ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal * 5 )
		ent:Spawn()
		ent:Activate()

		return ent
	end

	function ENT:Initialize()	
		self:SetModel( "models/Items/grenadeAmmo.mdl" )

		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetRenderMode( RENDERMODE_TRANSALPHA )
		self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

		self.TrailEntity = util.SpriteTrail( self, 0, Color(120,120,120,120), false, 5, 40, 0.2, 1 / ( 15 + 1 ) * 0.5, "trails/smoke" )
	end

	function ENT:Think()
		self:NextThink( CurTime() )

		if self.Active then
			self:Detonate()
		end

		return true
	end

	function ENT:Detonate()
		if self.IsExploded then return end

		self.IsExploded = true

		local Pos = self:GetPos()

		local effectdata = EffectData()
		effectdata:SetOrigin( Pos )
		effectdata:SetNormal( Vector(0,0,1) )
		effectdata:SetMagnitude( 1 )

		if self:WaterLevel() >= 2 then
			util.Effect( "WaterSurfaceExplosion", effectdata, true, true )
		else
			util.Effect( "lvs_defence_explosion", effectdata )
		end

		local dmginfo = DamageInfo()
		dmginfo:SetDamage( self:GetDamage() )
		dmginfo:SetAttacker( IsValid( self:GetAttacker() ) and self:GetAttacker() or self )
		dmginfo:SetDamageType( DMG_SONIC )
		dmginfo:SetInflictor( self )
		dmginfo:SetDamagePosition( Pos )

		util.BlastDamageInfo( dmginfo, Pos, self:GetRadius() )

		self:Remove()
	end

	function ENT:PhysicsCollide( data, physobj )
		self.Active = true

		if data.Speed > 60 and data.DeltaTime > 0.2 then
			local VelDif = data.OurOldVelocity:Length() - data.OurNewVelocity:Length()

			if VelDif > 200 then
				self:EmitSound( "Grenade.ImpactHard" )
			else
				self:EmitSound( "Grenade.ImpactSoft" )
			end

			physobj:SetVelocity( data.OurOldVelocity * 0.5 )
		end
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