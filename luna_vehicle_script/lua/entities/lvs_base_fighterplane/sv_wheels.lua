
function ENT:AddWheelSteeringPlate( rear )
	if rear then
		if IsValid( self._lvsSteerPlateRear ) then
			return self._lvsSteerPlateRear
		end
	else
		if IsValid( self._lvsSteerPlate ) then
			return self._lvsSteerPlate
		end
	end

	local SteerMaster = ents.Create( "prop_physics" )

	if not IsValid( SteerMaster ) then
		self:Remove()

		print("LVS: Failed to initialize steering plate. Vehicle terminated.")

		return
	end

	SteerMaster:SetModel( "models/hunter/plates/plate025x025.mdl" )
	SteerMaster:SetPos( self:GetPos() )
	SteerMaster:SetAngles( Angle(0,90,0) )
	SteerMaster:Spawn()
	SteerMaster:Activate()

	local PhysObj = SteerMaster:GetPhysicsObject()
	if IsValid( PhysObj ) then
		PhysObj:EnableMotion( false )
	else
		self:Remove()

		print("LVS: Failed to initialize steering plate. Vehicle terminated.")

		return
	end

	SteerMaster:SetOwner( self )
	SteerMaster:DrawShadow( false )
	SteerMaster:SetNotSolid( true )
	SteerMaster:SetNoDraw( true )
	SteerMaster.DoNotDuplicate = true
	self:DeleteOnRemove( SteerMaster )
	self:TransferCPPI( SteerMaster )

	if rear then
		self._lvsSteerPlateRear = SteerMaster
	else
		self._lvsSteerPlate = SteerMaster
	end

	return SteerMaster
end

function ENT:SetWheelSteer( SteerAngle )
	if IsValid( self._lvsSteerPlate ) then
		local PhysObj = self._lvsSteerPlate:GetPhysicsObject()

		if IsValid( PhysObj ) then
			if PhysObj:IsMotionEnabled() then
				PhysObj:EnableMotion( false )
			end
		end

		self._lvsSteerPlate:SetAngles( self:LocalToWorldAngles( Angle(0,math.Clamp(SteerAngle,-45,45),0) ) )
	end

	if not IsValid( self._lvsSteerPlateRear ) then return end

	local PhysObj = self._lvsSteerPlateRear:GetPhysicsObject()

	if not IsValid( PhysObj ) then return end

	if PhysObj:IsMotionEnabled() then
		PhysObj:EnableMotion( false )
	end

	self._lvsSteerPlateRear:SetAngles( self:LocalToWorldAngles( Angle(0,math.Clamp(-SteerAngle,-45,45),0) ) )
end

function ENT:AddWheel( pos, radius, mass, type )
	if not isvector( pos ) or not isnumber( radius ) or not isnumber( mass ) then return end

	if not type then
		type = LVS.WHEEL_STANDARD
	end

	local wheel = ents.Create( "prop_physics" )

	if not IsValid( wheel ) then
		self:Remove()

		print("LVS: Failed to initialize wheel. Vehicle terminated.")

		return
	end

	wheel:SetPos( self:LocalToWorld( pos ) )
	wheel:SetAngles( self:LocalToWorldAngles( Angle(0,90,0) ) )

	wheel:SetModel( "models/props_vehicles/tire001c_car.mdl" )
	wheel:Spawn()
	wheel:Activate()

	--wheel:SetNoDraw( true )
	wheel:DrawShadow( false )
	wheel.DoNotDuplicate = true

	wheel:PhysicsInitSphere( radius, "jeeptire" )
	wheel:SetCollisionBounds( Vector(-radius,-radius,-radius), Vector(radius,radius,radius) )

	local PhysObj = wheel:GetPhysicsObject()
	if not IsValid( PhysObj ) then
		self:Remove()
		
		print("LVS: Failed to initialize wheel phys model. Vehicle terminated.")
		return
	end

	PhysObj:EnableMotion( false )
	PhysObj:SetMass( mass )

	self:DeleteOnRemove( wheel )
	self:TransferCPPI( wheel )

	if type == LVS.WHEEL_STEER_NONE then
		self:TransferCPPI( constraint.AdvBallsocket(wheel, self,0,0,Vector(0,0,0),Vector(0,0,0),0,0, -180, -180, -180, 180, 180, 180, 0, 0, 0, 0, 1) )
	end

	if type == LVS.WHEEL_STANDARD then
		self:TransferCPPI( constraint.Axis( wheel, self, 0, 0, PhysObj:GetMassCenter(), wheel:GetPos(), 0, 0, 50, 0, Vector(1,0,0) , false ) )
	end

	if type == LVS.WHEEL_STEER_FRONT then
		wheel:SetAngles( Angle(0,0,0) )

		local SteerMaster = self:AddWheelSteeringPlate( false )

		self:TransferCPPI( constraint.AdvBallsocket(wheel, SteerMaster,0,0,Vector(0,0,0),Vector(0,0,0),0,0, -180, -0.01, -0.01, 180, 0.01, 0.01, 0, 0, 0, 1, 0) )
		self:TransferCPPI( constraint.AdvBallsocket(wheel,self,0,0,Vector(0,0,0),Vector(0,0,0),0,0, -180, -180, -180, 180, 180, 180, 0, 0, 0, 0, 0) )
	end

	if type == LVS.WHEEL_STEER_REAR then
		wheel:SetAngles( Angle(0,0,0) )

		local SteerMaster = self:AddWheelSteeringPlate( true )

		self:TransferCPPI( constraint.AdvBallsocket(wheel, SteerMaster,0,0,Vector(0,0,0),Vector(0,0,0),0,0, -180, -0.01, -0.01, 180, 0.01, 0.01, 0, 0, 0, 1, 0) )
		self:TransferCPPI( constraint.AdvBallsocket(wheel,self,0,0,Vector(0,0,0),Vector(0,0,0),0,0, -180, -180, -180, 180, 180, 180, 0, 0, 0, 0, 0) )
	end

	self:TransferCPPI( constraint.NoCollide( wheel, self, 0, 0 ) )

	PhysObj:EnableMotion( true )
	PhysObj:EnableDrag( false ) 

	local WheelData = {
		entity = wheel,
		mass = mass,
	}

	if not istable( self._lvsWheels ) then self._lvsWheels = {} end

	table.insert( self._lvsWheels, WheelData )

	return wheel
end
