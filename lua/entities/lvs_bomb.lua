AddCSLuaFile()

ENT.Type = "anim"

ENT.ExplosionEffect = "lvs_explosion_bomb"

ENT.lvsProjectile = true

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Active" )
	self:NetworkVar( "Bool", 1, "MaskSolid" )

	self:NetworkVar( "Vector", 0, "Speed" )
end

if SERVER then
	util.AddNetworkString( "lvs_bomb_hud" )

	function ENT:SetEntityFilter( filter )
		if not istable( filter ) then return end

		self._FilterEnts = {}

		for _, ent in pairs( filter ) do
			self._FilterEnts[ ent ] = true
		end
	end
	function ENT:GetEntityFilter()
		return self._FilterEnts or {}
	end
	function ENT:SetDamage( num ) self._dmg = num end
	function ENT:SetForce( num ) self._force = num end
	function ENT:SetThrust( num ) self._thrust = num end
	function ENT:SetRadius( num ) self._radius = num end
	function ENT:SetAttacker( ent )
		self._attacker = ent

		if not IsValid( ent ) or not ent:IsPlayer() then return end

		net.Start( "lvs_bomb_hud", true )
			net.WriteEntity( self )
		net.Send( ent )
	end

	function ENT:GetAttacker() return self._attacker or NULL end
	function ENT:GetDamage() return (self._dmg or 2000) end
	function ENT:GetForce() return (self._force or 8000) end
	function ENT:GetRadius() return (self._radius or 400) end

	function ENT:Initialize()
		self:SetModel( "models/props_phx/ww2bomb.mdl" )
		self:SetMoveType( MOVETYPE_NONE )
	end

	function ENT:OnTakeDamage( dmginfo )
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
		self:SetCollisionGroup( COLLISION_GROUP_WORLD )
		self:PhysWake()

		timer.Simple(1, function()
			if not IsValid( self ) then return end

			self:SetCollisionGroup( COLLISION_GROUP_NONE )
		end )

		self.IsEnabled = true

		local pObj = self:GetPhysicsObject()
		
		if not IsValid( pObj ) then
			self:Remove()

			print("LVS: missing model. Missile terminated.")

			return
		end

		pObj:SetMass( 500 ) 
		pObj:EnableGravity( false ) 
		pObj:EnableMotion( true )
		pObj:EnableDrag( false )
		pObj:SetVelocityInstantaneous( self:GetSpeed() )

		self:SetTrigger( true )

		self:StartMotionController()

		self:PhysWake()

		self.SpawnTime = CurTime()

		self:SetActive( true )
	end

	function ENT:PhysicsSimulate( phys, deltatime )
		phys:Wake()

		local ForceLinear = physenv.GetGravity()

		local Pos = self:GetPos()
		local TargetPos = Pos + self:GetVelocity()

		local AngForce = -self:WorldToLocalAngles( (TargetPos - Pos):Angle() )

		local ForceAngle = (Vector(AngForce.r,-AngForce.p,-AngForce.y) * 10 - phys:GetAngleVelocity() * 5 ) * 250 * deltatime

		return ForceAngle, ForceLinear, SIM_GLOBAL_ACCELERATION
	end

	function ENT:Think()	
		local T = CurTime()

		self:NextThink( T )

		self:UpdateTrajectory()

		if not self.SpawnTime then return true end

		if (self.SpawnTime + 12) < T then
			self:Detonate()
		end

		return true
	end

	function ENT:UpdateTrajectory()
		local base = self:GetParent()

		if not IsValid( base ) then return end

		self:SetSpeed( base:GetVelocity() )
	end

	ENT.IgnoreCollisionGroup = {
		[COLLISION_GROUP_NONE] = true,
		[COLLISION_GROUP_WORLD] =  true,
		[COLLISION_GROUP_IN_VEHICLE] = true
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

		local Pos =  self:GetPos() 

		local effectdata = EffectData()
			effectdata:SetOrigin( Pos )
		util.Effect( self.ExplosionEffect, effectdata )

		local attacker = self:GetAttacker()

		LVS:BlastDamage( Pos, self:GetForward(), IsValid( attacker ) and attacker or game.GetWorld(), self, self:GetDamage(), DMG_BLAST, self:GetRadius(), self:GetForce() )

		SafeRemoveEntityDelayed( self, FrameTime() )
	end

	return
end

function ENT:Enable()
	if self.IsEnabled then return end

	self.IsEnabled = true

	self.snd = CreateSound(self, "lvs/weapons/bomb_whistle_loop.wav")
	self.snd:SetSoundLevel( 110 )
	self.snd:PlayEx(0,150)
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

function ENT:Think()
	if self.snd then
		self.snd:ChangePitch( 100 * self:CalcDoppler(), 1 )
		self.snd:ChangeVolume(math.Clamp(-(self:GetVelocity().z + 1000) / 3000,0,1), 2)
	end

	if self.IsEnabled then return end

	if self:GetActive() then
		self:Enable()
	end
end

function ENT:Draw()
	local T = CurTime()

	if not self:GetActive() then
		self._PreventDrawTime = T + 0.1
		return
	end

	if (self._PreventDrawTime or 0) > T then return end

	self:DrawModel()
end

function ENT:SoundStop()
	if self.snd then
		self.snd:Stop()
	end
end

function ENT:OnRemove()
	self:SoundStop()
end

local color_red = Color(255,0,0,255)
local color_red_blocked = Color(100,0,0,255)
local HudTargets = {}
hook.Add( "HUDPaint", "!!!!lvs_bomb_hud", function()
	for ID, _ in pairs( HudTargets ) do
		local Missile = Entity( ID )

		if not IsValid( Missile ) or Missile:GetActive() then
			HudTargets[ ID ] = nil

			continue
		end

		local Grav = physenv.GetGravity()
		local FT = 0.05
		local MissilePos = Missile:GetPos()
		local Pos = MissilePos
		local Vel = Missile:GetSpeed()

		local LastColor = color_red
		local Mask = Missile.GetMaskSolid and (Missile:GetMaskSolid() and MASK_SOLID or MASK_SOLID_BRUSHONLY) or MASK_SOLID_BRUSHONLY

		cam.Start3D()
		local Iteration = 0
		while Iteration < 1000 do
			Iteration = Iteration + 1

			Vel = Vel + Grav * FT

			local StartPos = Pos
			local EndPos = Pos + Vel * FT

			local trace = util.TraceLine( {
				start = StartPos,
				endpos = EndPos,
				mask = Mask,
			} )

			local traceVisible = util.TraceLine( {
				start = MissilePos,
				endpos = StartPos,
				mask = Mask,
			} )

			LastColor = traceVisible.Hit and color_red_blocked or color_red

			render.DrawLine( StartPos, EndPos, LastColor )

			Pos = EndPos

			if trace.Hit then
				break
			end
		end
		cam.End3D()

		local TargetPos = Pos:ToScreen()

		if not TargetPos.visible then continue end

		surface.DrawCircle( TargetPos.x, TargetPos.y, 20, LastColor )
	end
end )

net.Receive( "lvs_bomb_hud", function( len )
	local ent = net.ReadEntity()

	if not IsValid( ent ) then return end

	HudTargets[ ent:EntIndex() ] = true
end )
