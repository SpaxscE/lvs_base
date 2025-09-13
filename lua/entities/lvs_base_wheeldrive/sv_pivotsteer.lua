
ENT.PivotSteerEnable = false
ENT.PivotSteerByBrake = true
ENT.PivotSteerWheelRPM = 40
ENT.PivotSteerTorqueMul = 2

function ENT:GetPivotSteer()
	return self._PivotSteer or 0
end

function ENT:SetPivotSteer( new )
	self._PivotSteer = new
end

function ENT:PivotSteer()
	if not self.PivotSteerEnable then return false end

	return (self._PivotSteer or 0) ~= 0
end

function ENT:CalcPivotSteer( ply )
	local KeyLeft = ply:lvsKeyDown( "CAR_STEER_LEFT" )
	local KeyRight = ply:lvsKeyDown( "CAR_STEER_RIGHT" )
	local KeyThrottle = ply:lvsKeyDown( "CAR_THROTTLE" )
	local KeyBrake = ply:lvsKeyDown( "CAR_BRAKE" )

	local ShouldSteer = (KeyLeft or KeyRight) and not KeyBrake and not KeyThrottle

	local Throttle = self:GetThrottle()

	if self._oldShouldSteer ~= ShouldSteer then
		self._oldShouldSteer = ShouldSteer

		if ShouldSteer then
			self._ShouldSteer = true
		end
	end

	if ShouldSteer then
		self._PivotSteer = (KeyRight and 1 or 0) - (KeyLeft and 1 or 0)
		self:SetSteer( 0 )
	end

	if not ShouldSteer and self._ShouldSteer then
		self:LerpThrottle( 0 )

		if Throttle <= 0 then
			self._ShouldSteer = nil
			self._PivotSteer = 0
		end

		return
	end

	if not self._ShouldSteer then return end

	self:LerpThrottle( (KeyRight or KeyLeft) and 1 or 0 )
end