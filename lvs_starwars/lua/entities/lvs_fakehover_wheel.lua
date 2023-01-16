AddCSLuaFile()

ENT.Type            = "anim"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.DoNotDuplicate = true
ENT.lvsDoNotGrab = true

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

	function ENT:Think()
		return false
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
end

function ENT:Draw()
end

function ENT:OnRemove()
end
