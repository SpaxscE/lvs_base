AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName = "Missile"
ENT.Author = "Luna"
ENT.Information = "LVS Missile"
ENT.Category = "[LVS]"

ENT.Spawnable		= true
ENT.AdminOnly		= true

ENT.ExplosionEffect = "lvs_explosion_small"

ENT.lvsProjectile = true
ENT.VJ_ID_Danger = true

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Active" )
	self:NetworkVar( "Entity", 0, "NWTarget" )
end

function ENT:GetLockTarget()
	return self:GetNWTarget()
end

if SERVER then
	function ENT:GetAvailableTargets()
		local targets = {
			[1] = player.GetAll(),
			[2] = LVS:GetVehicles(),
			[3] = LVS:GetNPCs(),
			[4] = LVS:GetFlares(),
		}

		return targets
	end

	function ENT:FindTarget( pos, forward, cone_ang, cone_len )
		local targets = self:GetAvailableTargets()

		local Attacker = self:GetAttacker()
		local Parent = self:GetParent()
		local Owner = self:GetOwner()
		local Target = NULL
		local DistToTarget = 0

		for _, tbl in ipairs( targets ) do
			for _, ent in pairs( tbl ) do
				if not IsValid( ent ) or ent == Parent or ent == Owner or Target == ent or Attacker == ent then continue end

				if ent:IsPlayer() and ent:InVehicle() then
					ent = ent:lvsGetVehicle()

					if not IsValid( ent ) then continue end

				end

				if isfunction( ent.GetMissileNoTarget ) and ent:GetMissileNoTarget() then continue end

				local pos_ent = ent:GetPos()
				local dir = (pos_ent - pos):GetNormalized()
				local ang = math.deg( math.acos( math.Clamp( forward:Dot( dir ) ,-1,1) ) )

				if ang > cone_ang then continue end

				local dist, _, _ = util.DistanceToLine( pos, pos + forward * cone_len, pos_ent )

				if not IsValid( Target ) then
					Target = ent
					DistToTarget = dist

					continue
				end

				if dist < DistToTarget then
					Target = ent
					DistToTarget = dist
				end
			end
		end

		self:SetTarget( Target )

		if isfunction( Target.OnMissileSeek ) then
			Target:OnMissileSeek( self )
		end

		self:SendToHUD( self:GetAttacker() )
	end

	function ENT:SendToHUD( data )
		if istable( data ) then
			for _, ply in pairs( data ) do
				if not IsValid( ply ) or not ply:IsPlayer() then continue end

				ply:lvsAddMissileToHud( self )
			end

			return
		end

		if not IsValid( data ) or not data:IsPlayer() then return end

		data:lvsAddMissileToHud( self )
	end

	function ENT:NotifyTarget()
		local Target = self:GetTarget()

		if not IsValid( Target ) or not isfunction( Target.OnMissileLock ) then return end

		Target:OnMissileLock( self )
	end

	function ENT:SetEntityFilter( filter )
		if not istable( filter ) then return end

		self._FilterEnts = {}

		for _, ent in pairs( filter ) do
			self._FilterEnts[ ent ] = true
		end
	end
	function ENT:SetTarget( ent ) self:SetNWTarget( ent ) end
	function ENT:SetDamage( num ) self._dmg = num end
	function ENT:SetForce( num ) self._force = num end
	function ENT:SetThrust( num ) self._thrust = num end
	function ENT:SetSpeed( num ) self._speed = num end
	function ENT:SetTurnSpeed( num ) self._turnspeed = num end
	function ENT:SetRadius( num ) self._radius = num end
	function ENT:SetAttacker( ent ) self._attacker = ent end

	function ENT:GetAttacker() return self._attacker or NULL end
	function ENT:GetDamage() return (self._dmg or 100) end
	function ENT:GetForce() return (self._force or 4000) end
	function ENT:GetRadius() return (self._radius or 250) end
	function ENT:GetSpeed() return (self._speed or 4000) end
	function ENT:GetTurnSpeed() return (self._turnspeed or 1) * 100 end
	function ENT:GetThrust() return (self._thrust or 500) end
	function ENT:GetTarget()
		local Target = self:GetNWTarget()

		if IsValid( Target ) then
			local Pos = self:GetPos()
			local tPos = self:GetTargetPos()

			local Sub = tPos - Pos
			local Len = Sub:Length()
			local Dir = Sub:GetNormalized()
			local Forward = self:GetForward()

			local AngToTarget = math.deg( math.acos( math.Clamp( Forward:Dot( Dir ) ,-1,1) ) )

			local LooseAng = math.min( Len / 100, 90 )

			local Notarget = isfunction( Target.GetMissileNoTarget ) and Target:GetMissileNoTarget()
			local OutOfRange = AngToTarget > LooseAng

			if Notarget or OutOfRange then
				self:SetNWTarget( NULL )
			end
		end

		return self:GetNWTarget()
	end
	function ENT:GetTargetPos()
		local Target = self:GetNWTarget()

		if not IsValid( Target ) then return Vector(0,0,0) end

		if isfunction( Target.GetMissileOffset ) then
			return Target:LocalToWorld( Target:GetMissileOffset() )
		end

		return Target:GetPos()
	end

	function ENT:SpawnFunction( ply, tr, ClassName )

		local ent = ents.Create( ClassName )
		ent:SetPos( ply:GetShootPos() )
		ent:SetAngles( ply:EyeAngles() )
		ent:Spawn()
		ent:Activate()
		ent:SetAttacker( ply )
		ent:Enable()

		return ent
	end

	function ENT:Initialize()	
		self:SetModel( "models/weapons/w_missile_launch.mdl" )
		self:SetMoveType( MOVETYPE_NONE )
		self:SetRenderMode( RENDERMODE_TRANSALPHA )
	end

	function ENT:Enable()
		if self.IsEnabled then return end

		local Parent = self:GetParent()

		if IsValid( Parent ) then
			self:SetOwner( Parent )
			self:SetParent( NULL )
		end

		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetCollisionGroup( COLLISION_GROUP_NONE )
		self:PhysWake()

		self.IsEnabled = true

		local pObj = self:GetPhysicsObject()
		
		if not IsValid( pObj ) then
			self:Remove()

			print("LVS: missing model. Missile terminated.")

			return
		end

		pObj:SetMass( 1 ) 
		pObj:EnableGravity( false ) 
		pObj:EnableMotion( true )
		pObj:EnableDrag( false )

		self:SetTrigger( true )

		self:StartMotionController()

		self:PhysWake()

		self.SpawnTime = CurTime()

		self:SetActive( true )

		timer.Simple(0, function()
			if not IsValid( self ) then return end

			self:NotifyTarget()
		end)
	end

	function ENT:PhysicsSimulate( phys, deltatime )
		phys:Wake()

		local Thrust = self:GetThrust()
		local Speed = self:GetSpeed()
		local Pos = self:GetPos()
		local velL = self:WorldToLocal( Pos + self:GetVelocity() )

		local ForceLinear = (Vector( Speed * Thrust,0,0) - velL) * deltatime

		local Target = self:GetTarget()

		if not IsValid( Target ) then
			return (-phys:GetAngleVelocity() * 250 * deltatime), ForceLinear, SIM_LOCAL_ACCELERATION
		end

		local AngForce = -self:WorldToLocalAngles( (self:GetTargetPos() - Pos):Angle() )

		local ForceAngle = (Vector(AngForce.r,-AngForce.p,-AngForce.y) * self:GetTurnSpeed() - phys:GetAngleVelocity() * 5 ) * 250 * deltatime

		return ForceAngle, ForceLinear, SIM_LOCAL_ACCELERATION
	end

	function ENT:Think()	
		local T = CurTime()

		self:NextThink( T + 1 )

		if not self.SpawnTime then return true end

		if (self.SpawnTime + 12) < T then
			self:Detonate()
		end

		return true
	end

	ENT.IgnoreCollisionGroup = {
		[COLLISION_GROUP_NONE] = true,
		[COLLISION_GROUP_WORLD] =  true,
		[COLLISION_GROUP_INTERACTIVE_DEBRIS] = true,
	}

	function ENT:StartTouch( entity )
		if entity == self:GetAttacker() then return end

		if istable( self._FilterEnts ) and self._FilterEnts[ entity ] then return end

		if entity.GetCollisionGroup and self.IgnoreCollisionGroup[ entity:GetCollisionGroup() ] then return end

		if entity.lvsProjectile then return end

		self:Detonate( entity )
	end

	function ENT:EndTouch( entity )
	end

	function ENT:Touch( entity )
	end

	function ENT:PhysicsCollide( data )
		if istable( self._FilterEnts ) and self._FilterEnts[ data.HitEntity ] then return end

		self:Detonate( data.HitEntity )
	end

	function ENT:OnTakeDamage( dmginfo )	
	end

	function ENT:Detonate( target )
		if not self.IsEnabled or self.IsDetonated then return end

		self.IsDetonated = true

		local Pos = self:GetPos() 
		local Dir = self:GetForward()

		local effectdata = EffectData()
			effectdata:SetOrigin( Pos )
			effectdata:SetNormal( Dir )
		util.Effect( self.ExplosionEffect, effectdata, true, true )

		local attacker = self:GetAttacker()

		LVS:BlastDamage( Pos, Dir, IsValid( attacker ) and attacker or game.GetWorld(), self, self:GetDamage(), DMG_BLAST, self:GetRadius(), self:GetForce() )

		SafeRemoveEntityDelayed( self, FrameTime() )
	end
else
	function ENT:Initialize()	
	end

	function ENT:Enable()
		if self.IsEnabled then return end

		self.IsEnabled = true

		self.snd = CreateSound(self, "weapons/rpg/rocket1.wav")
		self.snd:SetSoundLevel( 80 )
		self.snd:Play()

		local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
			effectdata:SetEntity( self )
		util.Effect( "lvs_missiletrail", effectdata )
	end

	function ENT:CalcDoppler()
		local Ent = LocalPlayer()

		local ViewEnt = Ent:GetViewEntity()

		if Ent:lvsGetVehicle() == self then
			if ViewEnt == Ent then
				Ent = self
			else
				Ent = ViewEnt
			end
		else
			Ent = ViewEnt
		end

		local sVel = self:GetVelocity()
		local oVel = Ent:GetVelocity()

		local SubVel = oVel - sVel
		local SubPos = self:GetPos() - Ent:GetPos()

		local DirPos = SubPos:GetNormalized()
		local DirVel = SubVel:GetNormalized()

		local A = math.acos( math.Clamp( DirVel:Dot( DirPos ) ,-1,1) )

		return (1 + math.cos( A ) * SubVel:Length() / 13503.9)
	end

	function ENT:Draw()
		if not self:GetActive() then return end

		self:DrawModel()
	end

	function ENT:Think()
		if self.snd then
			self.snd:ChangePitch( 100 * self:CalcDoppler() )
		end

		if self.IsEnabled then return end

		if self:GetActive() then
			self:Enable()
		end
	end

	function ENT:SoundStop()
		if self.snd then
			self.snd:Stop()
		end
	end

	function ENT:OnRemove()
		self:SoundStop()
	end
end
