
AccessorFunc(ENT, "axle", "Axle", FORCE_NUMBER)

function ENT:SetMaster( master )
	self._Master = master
end

function ENT:GetMaster()
	return self._Master
end

function ENT:GetDirectionAngle()
	if not IsValid( self._Master ) then
		local base = self:GetBase()

		if not IsValid( base ) then return angle_zero end

		local Steer = base:GetSteer()

		local ID = self:GetAxle()

		if not ID then return angle_zero end

		local Axle = base:GetAxleData( ID )
		local AxleAng = base:LocalToWorldAngles( Axle.ForwardAngle )

		if self.CamberCasterToe then
			AxleAng:RotateAroundAxis( AxleAng:Right(), self:GetCaster() )
			AxleAng:RotateAroundAxis( AxleAng:Forward(), self:GetCamber() )
			AxleAng:RotateAroundAxis( AxleAng:Up(), self:GetToe() )
		end

		if Axle.SteerType == LVS.WHEEL_STEER_REAR then
			AxleAng:RotateAroundAxis( AxleAng:Up(), math.Clamp(Steer,-Axle.SteerAngle,Axle.SteerAngle) )
		else
			if Axle.SteerType == LVS.WHEEL_STEER_FRONT then
				AxleAng:RotateAroundAxis( AxleAng:Up(), math.Clamp(-Steer,-Axle.SteerAngle,Axle.SteerAngle) )
			end
		end

		return AxleAng
	end

	return self._Master:GetAngles()
end

function ENT:GetRotationAxis()
	local WorldAngleDirection = -self:WorldToLocalAngles( self:GetDirectionAngle() )

	return WorldAngleDirection:Right()
end

function ENT:GetSteerType()
	if self._steerType then return self._steerType end

	local base = self:GetBase()

	if not IsValid( base ) then return 0 end

	self._steerType = base:GetAxleData( self:GetAxle() ).SteerType

	return self._steerType
end

function ENT:GetTorqueFactor()
	if self._torqueFactor then return self._torqueFactor end

	local base = self:GetBase()

	if not IsValid( base ) then return 0 end

	self._torqueFactor = base:GetAxleData( self:GetAxle() ).TorqueFactor or 0

	return self._torqueFactor
end

function ENT:GetBrakeFactor()
	if self._brakeFactor then return self._brakeFactor end

	local base = self:GetBase()

	if not IsValid( base ) then return 0 end

	self._brakeFactor = base:GetAxleData( self:GetAxle() ).BrakeFactor or 0

	return self._brakeFactor
end
