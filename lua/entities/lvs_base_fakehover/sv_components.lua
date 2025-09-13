
ENT._WheelEnts = {}

function ENT:GetWheels()
	for id, ent in pairs( self._WheelEnts ) do
		if IsValid( ent ) then continue end

		self._WheelEnts[ id ] = nil
	end

	return self._WheelEnts
end

function ENT:AddWheel( pos, radius, mass, buoyancyratio, brakeforce )
	if not isvector( pos ) or not isnumber( radius ) or not isnumber( mass ) then return end

	local wheel = ents.Create( "lvs_fakehover_wheel" )

	if not IsValid( wheel ) then
		self:Remove()

		print("LVS: Failed to initialize wheel. Vehicle terminated.")

		return
	end

	local WheelPos = self:LocalToWorld( pos )
	local CenterPos = self:LocalToWorld( self:OBBCenter() )

	debugoverlay.Sphere( WheelPos, radius, 5, Color(150,150,150), true )
	debugoverlay.Line( CenterPos, WheelPos, 5, Color(150,150,150), true )

	wheel:SetPos( WheelPos )
	wheel:SetAngles( self:LocalToWorldAngles( Angle(0,90,0) ) )
	wheel:Spawn()
	wheel:Activate()
	wheel:SetBase( self )
	wheel:SetNoDraw( true )
	wheel:DrawShadow( false )
	wheel.DoNotDuplicate = true
	wheel:Define( 
		{
			radius = radius,
			mass = mass,
			buoyancyratio = buoyancyratio or 0,
		}
	)

	table.insert( self._WheelEnts, wheel )

	local PhysObj = wheel:GetPhysicsObject()
	if not IsValid( PhysObj ) then
		self:Remove()
		
		print("LVS: Failed to initialize wheel phys model. Vehicle terminated.")
		return
	end

	if PhysObj:GetMaterial() ~= "gmod_silent" then
		self:Remove()

		print("LVS: Failed to initialize physprop material on wheel. Vehicle terminated.")

		return
	end

	self:DeleteOnRemove( wheel )
	self:TransferCPPI( wheel )

	local ballsocket = constraint.AdvBallsocket(wheel, self,0,0,Vector(0,0,0),Vector(0,0,0),0,0, -1, -1, -1, 1, 1, 1, 0, 0, 0, 0, 1)
	ballsocket.DoNotDuplicate = true
	self:TransferCPPI( ballsocket )

	local nocollide = constraint.NoCollide( wheel, self, 0, 0 )
	nocollide.DoNotDuplicate = true
	self:TransferCPPI( nocollide )

	PhysObj:EnableMotion( true )

	return wheel
end

function ENT:AddEngineSound( pos )
	local EngineSND = ents.Create( "lvs_fakehover_soundemitter" )

	if not IsValid( EngineSND ) then
		self:Remove()

		print("LVS: Failed to create engine sound entity. Vehicle terminated.")

		return
	end

	EngineSND:SetPos( self:LocalToWorld( pos ) )
	EngineSND:SetAngles( self:GetAngles() )
	EngineSND:Spawn()
	EngineSND:Activate()
	EngineSND:SetParent( self )
	EngineSND:SetBase( self )

	self:DeleteOnRemove( EngineSND )

	self:TransferCPPI( EngineSND )

	return EngineSND
end