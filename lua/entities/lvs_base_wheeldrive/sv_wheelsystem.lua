ENT._WheelEnts = {}
ENT._WheelAxleID = 0
ENT._WheelAxleData = {}

function ENT:ClearWheels()
	for _, ent in pairs( self:GetWheels() ) do
		ent:Remove()
	end

	table.Empty( self._WheelEnts )
	table.Empty( self._WheelAxleData )

	self._WheelAxleID = 0
end

function ENT:GetWheels()
	local EntTable = self:GetTable()

	for id, ent in pairs( EntTable._WheelEnts ) do
		if IsValid( ent ) then continue end

		EntTable._WheelEnts[ id ] = nil
	end

	return EntTable._WheelEnts
end

function ENT:GetAxleData( ID )
	local EntTable = self:GetTable()

	if not EntTable._WheelAxleData[ ID ] then return {} end

	return EntTable._WheelAxleData[ ID ]
end

function ENT:CreateSteerMaster( TargetEntity )
	if not IsValid( TargetEntity ) then return end

	local Master = ents.Create( "lvs_wheeldrive_steerhandler" )

	if not IsValid( Master ) then
		self:Remove()

		print("LVS: Failed to create steermaster entity. Vehicle terminated.")

		return
	end

	Master:SetPos( TargetEntity:GetPos() )
	Master:SetAngles( Angle(0,90,0) )
	Master:Spawn()
	Master:Activate()

	self:DeleteOnRemove( Master )
	self:TransferCPPI( Master )

	return Master
end

function ENT:AddWheel( data )
	if not istable( data ) or not isvector( data.pos ) then return end

	local Wheel = ents.Create( "lvs_wheeldrive_wheel" )

	if not IsValid( Wheel ) then
		self:Remove()

		print("LVS: Failed to create wheel entity. Vehicle terminated.")

		return
	end

	Wheel:SetModel( data.mdl or "models/props_vehicles/tire001c_car.mdl" )
	Wheel:SetPos( self:LocalToWorld( data.pos ) )
	Wheel:SetAngles( Angle(0,0,0) )
	Wheel:Spawn()
	Wheel:Activate()

	Wheel:SetBase( self )

	Wheel:SetAlignmentAngle( data.mdl_ang or Angle(0,0,0) )

	Wheel:SetHideModel( data.hide == true )

	Wheel:lvsMakeSpherical( data.radius or -1 )

	Wheel:SetWidth( data.width or 4 )

	Wheel:SetCamber( data.camber or 0 )
	Wheel:SetCaster( data.caster or 0 )
	Wheel:SetToe( data.toe or 0 )
	Wheel:CheckAlignment()
	Wheel:SetWheelType( data.wheeltype )

	if isnumber( data.MaxHealth ) then
		Wheel:SetMaxHP( data.MaxHealth )
		Wheel:SetHP( data.MaxHealth )
	end

	if isnumber( data.DSArmorIgnoreForce ) then
		Wheel.DSArmorIgnoreForce = data.DSArmorIgnoreForce
	end

	self:DeleteOnRemove( Wheel )
	self:TransferCPPI( Wheel )

	local PhysObj = Wheel:GetPhysicsObject()

	if not IsValid( PhysObj ) then
		self:Remove()

		print("LVS: Failed to create wheel physics. Vehicle terminated.")

		return
	end

	PhysObj:SetMass( self.WheelPhysicsMass * self.PhysicsWeightScale )
	PhysObj:SetInertia( self.WheelPhysicsInertia * self.PhysicsWeightScale )
	PhysObj:EnableDrag( false )
	PhysObj:EnableMotion( false )

	local nocollide_constraint = constraint.NoCollide(self,Wheel,0,0)
	nocollide_constraint.DoNotDuplicate = true

	debugoverlay.Line( self:GetPos(), self:LocalToWorld( data.pos ), 5, Color(150,150,150), true )

	table.insert( self._WheelEnts, Wheel )

	local Master = self:CreateSteerMaster( Wheel )

	local Lock = 0.0001

	local B1 = constraint.AdvBallsocket( Wheel,Master,0,0,vector_origin,vector_origin,0,0,-180,-Lock,-Lock,180,Lock,Lock,0,0,0,1,1)
	B1.DoNotDuplicate = true

	local B2 = constraint.AdvBallsocket( Master,Wheel,0,0,vector_origin,vector_origin,0,0,-180,Lock,Lock,180,-Lock,-Lock,0,0,0,1,1)
	B2.DoNotDuplicate = true

	local expectedMaxRPM = math.max( self.MaxVelocity, self.MaxVelocityReverse ) * 60 / math.pi / (Wheel:GetRadius() * 2)

	if expectedMaxRPM > 800 then
		local B3 = constraint.AdvBallsocket( Wheel,Master,0,0,vector_origin,vector_origin,0,0,-180,Lock,Lock,180,-Lock,-Lock,0,0,0,1,1)
		B3.DoNotDuplicate = true

		local B4 = constraint.AdvBallsocket( Master,Wheel,0,0,vector_origin,vector_origin,0,0,-180,-Lock,-Lock,180,Lock,Lock,0,0,0,1,1)
		B4.DoNotDuplicate = true
	end

	if expectedMaxRPM > 2150 then
		local possibleMaxVelocity = (2150 * (math.pi * (Wheel:GetRadius() * 2))) / 60

		self.MaxVelocity = math.min( self.MaxVelocity, possibleMaxVelocity )
		self.MaxVelocityReverse = math.min( self.MaxVelocityReverse, possibleMaxVelocity )

		print("[LVS] - peripheral speed out of range! clamping!" )
	end

	Wheel:SetMaster( Master )

	timer.Simple(0, function()
		if not IsValid( self ) or not IsValid( Wheel ) or not IsValid( PhysObj ) then return end

		Master:SetAngles( self:GetAngles() )
		Wheel:SetAngles( self:LocalToWorldAngles( Angle(0,-90,0) ) )

		self:AddToMotionController( PhysObj )

		PhysObj:EnableMotion( true )
	end )

	if isnumber( self._WheelSkin ) then Wheel:SetSkin( self._WheelSkin ) end

	if IsColor( self._WheelColor ) then Wheel:SetColor( self._WheelColor ) end

	return Wheel
end

function ENT:DefineAxle( data )
	if not istable( data ) then print("LVS: couldn't define axle: no axle data") return end

	if not istable( data.Axle ) or not istable( data.Wheels ) or not istable( data.Suspension ) then print("LVS: couldn't define axle: no axle/wheel/suspension data") return end

	self._WheelAxleID = self._WheelAxleID + 1

	-- defaults
	if self.ForcedForwardAngle then
		data.Axle.ForwardAngle = self.ForcedForwardAngle
	else
		data.Axle.ForwardAngle = data.Axle.ForwardAngle or Angle(0,0,0)
	end

	data.Axle.SteerType = data.Axle.SteerType or LVS.WHEEL_STEER_NONE
	data.Axle.SteerAngle = data.Axle.SteerAngle or 20
	data.Axle.TorqueFactor = data.Axle.TorqueFactor or 1
	data.Axle.BrakeFactor = data.Axle.BrakeFactor or 1
	data.Axle.UseHandbrake = data.Axle.UseHandbrake == true

	if not self.ForwardAngle then self.ForwardAngle = data.Axle.ForwardAngle end

	data.Suspension.Height = data.Suspension.Height or 20
	data.Suspension.MaxTravel = data.Suspension.MaxTravel or data.Suspension.Height
	data.Suspension.ControlArmLength = data.Suspension.ControlArmLength or 25
	data.Suspension.SpringConstant = data.Suspension.SpringConstant or 20000
	data.Suspension.SpringDamping = data.Suspension.SpringDamping or 2000
	data.Suspension.SpringRelativeDamping = data.Suspension.SpringRelativeDamping or 2000

	local AxleCenter = Vector(0,0,0)
	for _, Wheel in ipairs( data.Wheels ) do
		if not IsEntity( Wheel ) then print("LVS: !ERROR!, given wheel is not a entity!") return end

		AxleCenter = AxleCenter + Wheel:GetPos()

		if not Wheel.SetAxle then continue end

		Wheel:SetAxle( self._WheelAxleID )
	end
	AxleCenter = AxleCenter / #data.Wheels

	debugoverlay.Text( AxleCenter, "Axle "..self._WheelAxleID.." Center ", 5, true )
	debugoverlay.Cross( AxleCenter, 5, 5, Color( 255, 0, 0 ), true )
	debugoverlay.Line( AxleCenter, AxleCenter + self:LocalToWorldAngles( data.Axle.ForwardAngle ):Forward() * 25, 5, Color(255,0,0), true )
	debugoverlay.Text( AxleCenter + self:LocalToWorldAngles( data.Axle.ForwardAngle ):Forward() * 25, "Axle "..self._WheelAxleID.." Forward", 5, true )

	data.Axle.CenterPos = self:WorldToLocal( AxleCenter )

	self._WheelAxleData[ self._WheelAxleID ] = {
		ForwardAngle = data.Axle.ForwardAngle,
		AxleCenter = data.Axle.CenterPos,
		SteerType = data.Axle.SteerType,
		SteerAngle = data.Axle.SteerAngle,
		TorqueFactor = data.Axle.TorqueFactor,
		BrakeFactor = data.Axle.BrakeFactor,
		UseHandbrake = data.Axle.UseHandbrake,
	}

	for id, Wheel in ipairs( data.Wheels ) do
		local Elastic = self:CreateSuspension( Wheel, AxleCenter, self:LocalToWorldAngles( data.Axle.ForwardAngle ), data.Suspension )

		Wheel.SuspensionConstraintElastic = Elastic

		debugoverlay.Line( AxleCenter, Wheel:GetPos(), 5, Color(150,0,0), true )
		debugoverlay.Text( Wheel:GetPos(), "Axle "..self._WheelAxleID.." Wheel "..id, 5, true )

		local AngleStep = 15
		for ang = 15, 360, AngleStep do
			if not Wheel.GetRadius then continue end

			local radius = Wheel:GetRadius()
			local X1 = math.cos( math.rad( ang ) ) * radius
			local Y1 = math.sin( math.rad( ang ) ) * radius

			local X2 = math.cos( math.rad( ang + AngleStep ) ) * radius
			local Y2 = math.sin( math.rad( ang + AngleStep ) ) * radius

			local P1 = Wheel:GetPos() + self:LocalToWorldAngles( data.Axle.ForwardAngle ):Up() * Y1 + self:LocalToWorldAngles( data.Axle.ForwardAngle ):Forward() * X1
			local P2 = Wheel:GetPos() + self:LocalToWorldAngles( data.Axle.ForwardAngle ):Up() * Y2 + self:LocalToWorldAngles( data.Axle.ForwardAngle ):Forward() * X2

			debugoverlay.Line( P1, P2, 5, Color( 150, 150, 150 ), true )
		end

		-- nocollide them with each other
		for i = id, #data.Wheels do
			local Ent = data.Wheels[ i ]
			if Ent == Wheel then continue end

			local nocollide_constraint = constraint.NoCollide(Ent,Wheel,0,0)
			nocollide_constraint.DoNotDuplicate = true
		end
	end

	return self._WheelAxleData[ self._WheelAxleID ]
end

function ENT:CreateSuspension( Wheel, CenterPos, DirectionAngle, data )
	if not IsValid( Wheel ) or not IsEntity( Wheel ) then return end

	local height = data.Height
	local maxtravel = data.MaxTravel
	local constant = data.SpringConstant
	local damping = data.SpringDamping
	local rdamping = data.SpringRelativeDamping

	local LimiterLength = 60
	local LimiterRopeLength = math.sqrt( maxtravel ^ 2 + LimiterLength ^ 2 )

	local Pos = Wheel:GetPos()

	local PosL, _ = WorldToLocal( Pos, DirectionAngle, CenterPos, DirectionAngle )

	local Forward = DirectionAngle:Forward()
	local Right = DirectionAngle:Right() * (PosL.y > 0 and 1 or -1)
	local Up = DirectionAngle:Up()

	local RopeSize = 0
	local RopeLength = data.ControlArmLength

	if height == 0 or maxtravel == 0 or RopeLength == 0 then
		local ballsocket = constraint.Ballsocket( self, Wheel, 0, 0, Vector(0,0,0), 0, 0, 1 )
		ballsocket.DoNotDuplicate = true

		return
	end

	local P1 = Pos + Forward * RopeLength * 0.5 + Right * RopeLength
	local P2 = Pos
	local Rope1 = constraint.Rope(self, Wheel,0,0,self:WorldToLocal( P1 ), Vector(0,0,0), Vector(RopeLength * 0.5,RopeLength,0):Length(), 0, 0, RopeSize,"cable/cable2", true )
	Rope1.DoNotDuplicate = true
	debugoverlay.Line( P1, P2, 5, Color(0,255,0), true )

	P1 = Pos - Forward * RopeLength * 0.5 + Right * RopeLength
	local Rope2 = constraint.Rope(self, Wheel,0,0,self:WorldToLocal( P1 ), Vector(0,0,0), Vector(RopeLength * 0.5,RopeLength,0):Length(), 0, 0, RopeSize,"cable/cable2", true )
	Rope2.DoNotDuplicate = true
	debugoverlay.Line( P1, P2, 5, Color(0,255,0), true )

	local Offset = Up * height

	Wheel:SetPos( Pos - Offset )

	local Limiter = constraint.Rope(self,Wheel,0,0,self:WorldToLocal( Pos - Up * height * 0.5 - Right * LimiterLength), Vector(0,0,0),LimiterRopeLength, 0, 0, RopeSize,"cable/cable2", false )
	Limiter.DoNotDuplicate = true

	P1 = Wheel:GetPos() + Up * (height * 2 + maxtravel * 2)

	local Elastic = constraint.Elastic( Wheel, self, 0, 0, Vector(0,0,0), self:WorldToLocal( P1 ), constant, damping, rdamping,"cable/cable2", RopeSize, false ) 
	Elastic.DoNotDuplicate = true
	debugoverlay.SweptBox( P1, P2,- Vector(0,1,1), Vector(0,1,1), (P1 - P2):Angle(), 5, Color( 255, 255, 0 ), true )

	Wheel:SetPos( Pos )

	return Elastic
end

function ENT:AlignWheel( Wheel )
	if not IsValid( Wheel ) then return false end

	local Master = Wheel.MasterEntity

	if not IsValid( Master ) then
		if not isfunction( Wheel.GetMaster ) then return false end

		Master = Wheel:GetMaster()

		Wheel.MasterEntity = Master

		if IsValid( Master ) then
			Wheel.MasterPhysObj = Master:GetPhysicsObject()
		end

		return false
	end

	local PhysObj = Wheel.MasterPhysObj

	if not IsValid( PhysObj ) then Wheel:Remove() return false end

	local Steer = self:GetSteer()

	if PhysObj:IsMotionEnabled() then PhysObj:EnableMotion( false ) return false end

	if not Master.lvsValidAxleData then
		local ID = Wheel:GetAxle()

		if ID then
			local Axle = self:GetAxleData( ID )

			Master.AxleCenter = Axle.AxleCenter
			Master.ForwardAngle = Axle.ForwardAngle or angle_zero
			Master.SteerAngle = Axle.SteerAngle or 0
			Master.SteerType = Axle.SteerType or LVS.WHEEL_STEER_NONE

			Master.lvsValidAxleData = true

			if Axle.SteerType == LVS.WHEEL_STEER_ACKERMANN then
				if not self._AckermannCenter then
					local AxleCenter = vector_origin
					local NumAxles = 0

					for _, data in pairs( self._WheelAxleData ) do
						if data.SteerType and data.SteerType ~= LVS.WHEEL_STEER_NONE then continue end

						AxleCenter = AxleCenter + data.AxleCenter
						NumAxles = NumAxles + 1
					end

					self._AckermannCenter = AxleCenter / NumAxles
				end

				local Dist = (self._AckermannCenter - Axle.AxleCenter):Length()

				if not self._AckermannDist or Dist > self._AckermannDist then
					self._AckermannDist = Dist
				end
			end
		end

		return false
	end

	local AxleAng = self:LocalToWorldAngles( Master.ForwardAngle )

	if Wheel.CamberCasterToe then
		AxleAng:RotateAroundAxis( AxleAng:Right(), Wheel:GetCaster() )
		AxleAng:RotateAroundAxis( AxleAng:Forward(), Wheel:GetCamber() )
		AxleAng:RotateAroundAxis( AxleAng:Up(), Wheel:GetToe() )
	end

	local SteerType = Master.SteerType

	if SteerType <= LVS.WHEEL_STEER_NONE then Master:SetAngles( AxleAng ) return true end

	if SteerType == LVS.WHEEL_STEER_ACKERMANN then
		local EntTable = self:GetTable()

		local P1 = Wheel:GetPos() + Master:GetAngles():Right() * 5000
		local P2 = Wheel:GetPos() - Master:GetAngles():Right() * 5000

		debugoverlay.Line( P1, P2, 0.05 )

		if Steer ~= 0 then
			local AxleCenter = self:LocalToWorld( Master.AxleCenter )
			local RotCenter = self:LocalToWorld( EntTable._AckermannCenter  )
			local RotPoint = self:LocalToWorld( EntTable._AckermannCenter + Master.ForwardAngle:Right() * (EntTable._AckermannDist / math.tan( math.rad( Steer ) )) )

			local A = (AxleCenter - RotCenter):Length()
			local C = (Wheel:GetPos() - RotPoint):Length()

			local Invert = ((self:VectorSplitNormal( Master.ForwardAngle:Forward(), Master.AxleCenter - EntTable._AckermannCenter ) < 0) and -1 or 1) * self:Sign( -Steer )

			local Ang = (90 - math.deg( math.acos( A / C ) )) * Invert

			AxleAng:RotateAroundAxis( AxleAng:Up(), Ang )
		end
	else
		AxleAng:RotateAroundAxis( AxleAng:Up(), math.Clamp((SteerType == LVS.WHEEL_STEER_FRONT) and -Steer or Steer,-Master.SteerAngle,Master.SteerAngle) )
	end

	Master:SetAngles( AxleAng )

	return true
end

function ENT:WheelsOnGround()

	for _, ent in pairs( self:GetWheels() ) do
		if not IsValid( ent ) then continue end

		if ent:PhysicsOnGround() then
			return true
		end
	end

	return false
end

function ENT:OnWheelCollision( data, physobj )
end
