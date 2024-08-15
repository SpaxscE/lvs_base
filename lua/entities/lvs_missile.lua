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

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Active" )
	self:NetworkVar( "Entity", 0, "NWTarget" )
end

if SERVER then
	util.AddNetworkString( "lvs_missile_hud" )

	function ENT:GetAvailableTargets()
		local targets = {
			[1] = player.GetAll(),
			[2] = LVS:GetVehicles(),
			[3] = LVS:GetNPCs(),
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

		local ply = self:GetAttacker()

		if not IsValid( ply ) or not ply:IsPlayer() then return end

		net.Start( "lvs_missile_hud", true )
			net.WriteEntity( self )
		net.Send( ply )
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
	function ENT:SetThrust( num ) self._thrust = num end
	function ENT:SetSpeed( num ) self._speed = num end
	function ENT:SetTurnSpeed( num ) self._turnspeed = num end
	function ENT:SetRadius( num ) self._radius = num end
	function ENT:SetAttacker( ent ) self._attacker = ent end

	function ENT:GetAttacker() return self._attacker or NULL end
	function ENT:GetDamage() return (self._dmg or 100) end
	function ENT:GetRadius() return (self._radius or 250) end
	function ENT:GetSpeed() return (self._speed or 4000) end
	function ENT:GetTurnSpeed() return (self._turnspeed or 1) * 100 end
	function ENT:GetThrust() return (self._thrust or 500) end
	function ENT:GetTarget()
		if IsValid( self:GetNWTarget() ) then
			local Pos = self:GetPos()
			local tPos = self:GetTargetPos()

			local Sub = tPos - Pos
			local Len = Sub:Length()
			local Dir = Sub:GetNormalized()
			local Forward = self:GetForward()

			local AngToTarget = math.deg( math.acos( math.Clamp( Forward:Dot( Dir ) ,-1,1) ) )

			local LooseAng = math.min( Len / 100, 90 )

			if AngToTarget > LooseAng then
				self:SetNWTarget( NULL )
			end
		end

		return self:GetNWTarget()
	end
	function ENT:GetTargetPos()
		local Target = self:GetNWTarget()

		if not IsValid( Target ) then return Vector(0,0,0) end

		if isfunction( Target.GetShield ) then
			if Target:GetShield() > 0 then
				return Target:LocalToWorld( VectorRand() * math.random( -1000, 1000 ) )
			end
		end

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

		self:Detonate()
	end

	function ENT:OnTakeDamage( dmginfo )	
	end

	function ENT:Detonate( target )
		if not self.IsEnabled or self.IsDetonated then return end

		self.IsDetonated = true

		local Pos =  self:GetPos() 

		local effectdata = EffectData()
			effectdata:SetOrigin( Pos )
		util.Effect( self.ExplosionEffect, effectdata )

		if IsValid( target ) and not target:IsNPC() then
			Pos = target:GetPos() -- place explosion inside the hit targets location so they receive full damage. This fixes all the garbage code the LFS' missile required in order to deliver its damage

			if isfunction( target.GetBase ) then
				local Base = target:GetBase()

				if IsValid( Base ) and isentity( Base ) then
					Pos = Base:GetPos()
				end
			end
		end

		local attacker = self:GetAttacker()

		util.BlastDamage( self, IsValid( attacker ) and attacker or game.GetWorld(), Pos, self:GetRadius(), self:GetDamage() )

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

	local function DrawDiamond( X, Y, radius, angoffset )
		angoffset = angoffset or 0

		local segmentdist = 90
		local radius2 = radius + 1

		for ang = 0, 360, segmentdist do
			local a = ang + angoffset
			surface.DrawLine( X + math.cos( math.rad( a ) ) * radius, Y - math.sin( math.rad( a ) ) * radius, X + math.cos( math.rad( a + segmentdist ) ) * radius, Y - math.sin( math.rad( a + segmentdist ) ) * radius )
			surface.DrawLine( X + math.cos( math.rad( a ) ) * radius2, Y - math.sin( math.rad( a ) ) * radius2, X + math.cos( math.rad( a + segmentdist ) ) * radius2, Y - math.sin( math.rad( a + segmentdist ) ) * radius2 )
		end
	end

	local color_red = Color(255,0,0,255)
	local HudTargets = {}
	hook.Add( "HUDPaint", "!!!!lvs_missile_hud", function()
		local T = CurTime()

		local Index = 0

		surface.SetDrawColor( 255, 0, 0, 255 )

		for ID, _ in pairs( HudTargets ) do
			local Missile = Entity( ID )

			if not IsValid( Missile ) then
				HudTargets[ ID ] = nil

				continue
			end

			local Target = Missile:GetNWTarget()

			if not IsValid( Target ) then
				HudTargets[ ID ] = nil

				continue
			end

			local MissilePos = Missile:GetPos():ToScreen()
			local TargetPos = Target:LocalToWorld( Target:OBBCenter() ):ToScreen()

			Index =  Index + 1

			if not TargetPos.visible then continue end

			DrawDiamond( TargetPos.x, TargetPos.y, 40, ID * 1337 - T * 100 )

			if isfunction( Target.GetShield ) and Target:GetShield() > 0 then
				draw.DrawText("WEAK LOCK", "LVS_FONT", TargetPos.x + 20, TargetPos.y + 20, color_red, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
			else
				draw.DrawText(" FULL LOCK", "LVS_FONT", TargetPos.x + 20, TargetPos.y + 20, color_red, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
			end

			if not MissilePos.visible then continue end

			DrawDiamond( MissilePos.x, MissilePos.y, 16, ID * 1337 - T * 100 )
			draw.DrawText( Index, "LVS_FONT", MissilePos.x + 10, MissilePos.y + 10, color_red, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		
			surface.DrawLine( MissilePos.x, MissilePos.y, TargetPos.x, TargetPos.y )
		end
	end )

	net.Receive( "lvs_missile_hud", function( len )
		local ent = net.ReadEntity()

		if not IsValid( ent ) then return end

		HudTargets[ ent:EntIndex() ] = true
	end )
end