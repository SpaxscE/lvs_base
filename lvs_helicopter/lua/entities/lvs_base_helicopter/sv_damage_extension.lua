
function ENT:StartDestroyTimer()
	if self._DestroyTimerStarted then return end

	self._DestroyTimerStarted = true

	timer.Simple( self:GetAI() and 5 or 60, function()
		if not IsValid( self ) then return end

		self.MarkForDestruction = true
	end )
end

function ENT:DestroySteering( movevalue )
	if self._SteerOverride then return end

	self._SteerOverride = true
	self._SteerOverrideMove = (movevalue or 1)
	self:StartDestroyTimer()
end

function ENT:DestroyEngine()
	if self._EngineDestroyed then return end

	self._EngineDestroyed = true

	self:TurnOffEngine()

	self:SetThrottle( 0 )
	self:SetThrust( 0 )

	self:StartDestroyTimer()
end