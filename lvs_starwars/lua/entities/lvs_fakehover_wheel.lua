AddCSLuaFile()

ENT.Type            = "anim"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.DoNotDuplicate = true
ENT.lvsDoNotGrab = true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )
end

if SERVER then
	function ENT:Initialize()	
		self:SetModel( "models/props_vehicles/tire001c_car.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:DrawShadow( false )
	end

	function ENT:Define( data )
		local bbox = Vector(data.radius,data.radius,data.radius)

		self:PhysicsInitSphere( data.radius, "gmod_silent" )
		self:SetCollisionBounds( -bbox, bbox )

		local PhysObj = self:GetPhysicsObject()
		if IsValid( PhysObj ) then
			PhysObj:EnableDrag( false )
			PhysObj:EnableMotion( false )
			PhysObj:SetMass( data.mass )
			PhysObj:SetBuoyancyRatio( data.buoyancyratio )
		end
	end

	function ENT:SetPhysics( enable )
		if enable then
			if self.PhysicsEnabled then return end

			self:GetPhysicsObject():SetMaterial("jeeptire")
			self.PhysicsEnabled = true
		else
			if self.PhysicsEnabled == false then return end

			self:GetPhysicsObject():SetMaterial("friction_00")
			self.PhysicsEnabled = false
		end
	end

	function ENT:CheckPhysics()
		local base = self:GetBase()

		if not IsValid( base ) then return end

		if not base:GetEngineActive() then
			self:SetPhysics( true )

			self:NextThink( CurTime() + 0.25 )

			return
		end

		self:NextThink( CurTime() + 0.1 )

		local Ang = base:GetAngles()
		local steer = math.abs( base:WorldToLocalAngles( Angle(Ang.p,base:GetSteerTo(),Ang.r) ).y )
		local move = base:GetMove()
		local speed = base:GetVelocity():LengthSqr()

		local enable = (math.abs( move.x ) + math.abs( move.y )) < 0.001 and steer < 3 and speed < 600

		self:SetPhysics( enable )
	end

	function ENT:Think()
		self:CheckPhysics()

		return true
	end

	function ENT:OnTakeDamage( dmginfo )
		local base = self:GetBase()

		if not IsValid( base ) then return end

		base:TakeDamageInfo( dmginfo )
	end

	return
end

function ENT:Initialize()
end

function ENT:Think()
	local T = CurTime()

	if (self._nextFX or 0) > T then return end

	self._nextFX = T + 0.02

	local base = self:GetBase()

	if not IsValid( base ) then return end

	if base:GetVelocity():Length() < 50 then return end

	local data = {
		start = self:LocalToWorld( self:OBBCenter() ),
		endpos = self:LocalToWorld( Vector(0,0,self:OBBMins().z - 10 ) ),
		filter = base:GetCrosshairFilterEnts(),
		mask = MASK_WATER
	}

	local traceWater = util.TraceLine( data )

	if not traceWater.Hit then
		return
	end

	local effectdata = EffectData()
		effectdata:SetOrigin( traceWater.HitPos )
		effectdata:SetEntity( base )
		effectdata:SetMagnitude( self:BoundingRadius() )
	util.Effect( "lvs_hover_water", effectdata )
end

function ENT:Draw()
end

function ENT:OnRemove()
end
