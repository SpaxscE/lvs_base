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

	function ENT:SetBrakes( active )
		if not self._CanUseBrakes then
			actuve = false
		end

		if active ~= self._BrakesActive then
			self._BrakesActive = active

			if active then
				self:StartMotionController()
			else
				self:StopMotionController()
			end
		end
	end

	function ENT:SetBrakeForce( force )
		self._BrakeForce = force
	end

	function ENT:GetBrakeForce()
		return (self._BrakeForce or 25)
	end

	function ENT:Define( data )
		local bbox = Vector(data.radius,data.radius,data.radius)

		self:PhysicsInitSphere( data.radius, data.physmat )
		self:SetCollisionBounds( -bbox, bbox )

		local PhysObj = self:GetPhysicsObject()
		if IsValid( PhysObj ) then
			PhysObj:SetMass( data.mass )
		end

		self._CanUseBrakes = data.brake
	end

	function ENT:PhysicsSimulate( phys, deltatime )
		local BrakeForce = Vector( -phys:GetAngleVelocity().x, 0, 0 ) * self:GetBrakeForce()

		return BrakeForce, Vector(0,0,0), SIM_LOCAL_ACCELERATION
	end
	
	function ENT:Use( ply )
	end

	function ENT:Think()
		return false
	end

	function ENT:OnRemove()
	end

	function ENT:PhysicsCollide( data, physobj )
	end

	function ENT:OnTakeDamage( dmginfo )
		self:TakePhysicsDamage( dmginfo )
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
