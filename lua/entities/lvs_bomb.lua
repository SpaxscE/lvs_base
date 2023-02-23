AddCSLuaFile()

ENT.Type = "anim"

ENT.PrintName = "Bomb"
ENT.Author = "Luna"
ENT.Information = "LVS Bomb"
ENT.Category = "[LVS]"

ENT.Spawnable		= true
ENT.AdminOnly		= true

ENT.ExplosionEffect = "lvs_explosion_bomb"

ENT.lvsProjectile = true

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Active" )
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
	function ENT:SetDamage( num ) self._dmg = num end
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

			self:SetCollisionGroup( COLLISION_GROUP_WORLD )
		end )

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
		pObj:SetVelocityInstantaneous( self:GetSpeed() )

		self:SetTrigger( true )

		self:StartMotionController()

		self:PhysWake()

		self.SpawnTime = CurTime()

		self:SetActive( true )
	end

	function ENT:PhysicsSimulate( phys, deltatime )
		phys:Wake()

		local ForceLinear, ForceAngle = phys:CalculateForceOffset( physenv.GetGravity(), phys:LocalToWorld( phys:GetMassCenter() + Vector(10,0,0) ) )

		ForceAngle = ForceAngle - phys:GetAngleVelocity()  * 5

		return ForceAngle, ForceLinear, SIM_GLOBAL_ACCELERATION
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
		end

		local attacker = self:GetAttacker()

		util.BlastDamage( self, IsValid( attacker ) and attacker or game.GetWorld(), Pos, self:GetRadius(), self:GetDamage() )

		SafeRemoveEntityDelayed( self, FrameTime() )
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

local color_red = Color(255,0,0,255)
local HudTargets = {}
hook.Add( "HUDPaint", "!!!!lvs_bomb_hud", function()
	for ID, _ in pairs( HudTargets ) do
		local Missile = Entity( ID )

		if not IsValid( Missile ) or Missile:GetActive() then
			HudTargets[ ID ] = nil

			continue
		end

		local Grav = physenv.GetGravity()
		local FT = RealFrameTime()
		local Pos = Missile:GetPos()
		local Vel = Missile:GetSpeed()

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
				mask = MASK_SOLID_BRUSHONLY,
			} )

			render.DrawLine( StartPos, EndPos, color_red )

			Pos = EndPos

			if trace.Hit then
				break
			end
		end
		cam.End3D()

		local TargetPos = Pos:ToScreen()

		if not TargetPos.visible then continue end

		surface.DrawCircle( TargetPos.x, TargetPos.y, 20, color_red )
	end
end )

net.Receive( "lvs_bomb_hud", function( len )
	local ent = net.ReadEntity()

	if not IsValid( ent ) then return end

	HudTargets[ ent:EntIndex() ] = true
end )
