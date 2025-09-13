
function ENT:CalcThrottle()
	if not self:GetEngineActive() then

		if self:GetThrottle() ~= 0 then self:SetThrottle( 0 ) end

		return
	end

	local Delta = FrameTime()

	local Cur = self:GetThrottle()
	local New = self._StopEngine and 0 or 1

	if self:IsDestroyed() then New = 0 end

	if Cur == New and New == 0 then self:TurnOffEngine() return end

	self:SetThrottle( Cur + math.Clamp( (New - Cur), -self.ThrottleRateDown * Delta, self.ThrottleRateUp * Delta ) )
end

function ENT:HandleStart()
	local Driver = self:GetDriver()

	if IsValid( Driver ) then
		local KeyReload = Driver:lvsKeyDown( "ENGINE" )

		if self.OldKeyReload ~= KeyReload then
			self.OldKeyReload = KeyReload

			if KeyReload then
				self:ToggleEngine()
			end
		end
	end

	self:CalcThrottle()
end

function ENT:ToggleEngine()
	if self:GetEngineActive() and not self._StopEngine then
		self:StopEngine()
	else
		self:StartEngine()
	end
end

function ENT:StartEngine()
	if not self:IsEngineStartAllowed() then return end
	if self._EngineDestroyed then return end

	if self:GetEngineActive() then
		self._StopEngine = nil

		return
	end

	self:PhysWake()

	self:SetEngineActive( true )
	self:OnEngineActiveChanged( true )

	self._StopEngine = nil
end

function ENT:StopEngine()
	if self._StopEngine then return end

	self._StopEngine = true
	self:OnEngineActiveChanged( false )

	if self:WaterLevel() >= self.WaterLevelAutoStop then
		self:TurnOffEngine()
	end
end

function ENT:TurnOffEngine()
	if not self:GetEngineActive() then return end

	self:SetEngineActive( false )

	self._StopEngine = nil
end
