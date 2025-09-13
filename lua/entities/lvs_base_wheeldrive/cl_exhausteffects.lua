
function ENT:IsBackFireEnabled()
	if not isfunction( self.GetBackfire ) then return false end

	return self:GetBackfire()
end

function ENT:DoExhaustFX( Magnitude )
	for _, data in ipairs( self.ExhaustPositions ) do
		if data.bodygroup then
			if not self:BodygroupIsValid( data.bodygroup.name, data.bodygroup.active ) then continue end
		end

		local effectdata = EffectData()
			effectdata:SetOrigin( self:LocalToWorld( data.pos ) )
			effectdata:SetNormal( self:LocalToWorldAngles( data.ang ):Forward() )
			effectdata:SetMagnitude( Magnitude )
			effectdata:SetEntity( self )
		util.Effect( "lvs_exhaust", effectdata )
	end
end

function ENT:ExhaustEffectsThink()
	if not self:IsBackFireEnabled() then return end

	local Throttle = self:GetThrottle()

	if self._backfireTHR ~= Throttle then
		self._backfireTHR = Throttle

		if Throttle ~= 0 then return end

		self:CalcExhaustPop()
	end
end

function ENT:CalcExhaustPop()
	local Engine = self:GetEngine()

	if not IsValid( Engine ) then return end

	local RPM = Engine:GetRPM()

	local num = (Engine:GetRPM() / 500)

	local Throttle = self:GetThrottle()

	if Throttle > 0 and Throttle < 0.6 then return end

	if Throttle ~= 0 or (not IsValid( self:GetTurbo() ) and not IsValid( self:GetCompressor() )) then num = 0 end

	for i = 0, num do
		timer.Simple( self.TransShiftSpeed + i * 0.1 , function()
			if not IsValid( self ) then return end

			if i > 0 and self:GetThrottle() ~= 0 then return end

			local Engine = self:GetEngine()

			if not IsValid( Engine ) then return end

			local RPM = Engine:GetRPM()

			if RPM < self.EngineMaxRPM * 0.6 then return end

			if i == 0 then
				self:DoExhaustPop( LVS.EngineVolume )
			else
				self:DoExhaustPop( 0.75 * LVS.EngineVolume )
			end
		end )
	end
end

function ENT:DoExhaustPop( volume )
	if not istable( self.ExhaustPositions ) then return end

	for _, data in ipairs( self.ExhaustPositions ) do
		if data.bodygroup then
			if not self:BodygroupIsValid( data.bodygroup.name, data.bodygroup.active ) then continue end
		end

		timer.Simple( math.Rand(0,0.2), function()
			local effectdata = EffectData()
				effectdata:SetOrigin( data.pos )
				effectdata:SetAngles( data.ang )
				effectdata:SetEntity( self )
				effectdata:SetMagnitude( volume or 1 )
			util.Effect( "lvs_carexhaust_pop", effectdata )
		end )
	end
end

function ENT:DoExhaustBackFire()
	if not istable( self.ExhaustPositions ) then return end

	for _, data in ipairs( self.ExhaustPositions ) do
		if data.bodygroup then
			if not self:BodygroupIsValid( data.bodygroup.name, data.bodygroup.active ) then continue end
		end

		if math.random( 1, math.floor( #self.ExhaustPositions * 0.75 ) ) ~= 1 then continue end

		timer.Simple( math.Rand(0.5,1), function()
			local effectdata = EffectData()
				effectdata:SetOrigin( data.pos )
				effectdata:SetAngles( data.ang )
				effectdata:SetEntity( self )
			util.Effect( "lvs_carexhaust_backfire", effectdata )
		end )
	end
end
