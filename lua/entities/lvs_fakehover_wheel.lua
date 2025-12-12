AddCSLuaFile()

ENT.Type            = "anim"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.DoNotDuplicate = true

ENT._lvsNoPhysgunInteraction = true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )
	self:NetworkVar( "Float",0, "fxRadius" )
end

if SERVER then
	function ENT:Initialize()	
		self:SetModel( "models/props_vehicles/tire001c_car.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:DrawShadow( false )

		self:AddEFlags( EFL_NO_PHYSCANNON_INTERACTION )

		-- this is so vj npcs can still see us
		self:AddEFlags( EFL_DONTBLOCKLOS )

		self:SetCollisionGroup( COLLISION_GROUP_PASSABLE_DOOR )
	end

	function ENT:Define( data )
		self:SetfxRadius( data.radius )
		self:PhysicsInitSphere( data.radius, "gmod_silent" )

		local VectorNull = Vector(0,0,0)

		self:SetCollisionBounds( VectorNull, VectorNull )

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
		if dmginfo:IsDamageType( DMG_BLAST ) then return end

		local base = self:GetBase()

		if not IsValid( base ) then return end

		base:TakeDamageInfo( dmginfo )
	end

	function ENT:UpdateTransmitState() 
		return TRANSMIT_NEVER
	end

	return
end

function ENT:Initialize()
end

function ENT:Think()
end

function ENT:Draw()
end

function ENT:OnRemove()
end
