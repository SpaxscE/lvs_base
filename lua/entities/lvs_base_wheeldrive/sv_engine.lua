
DEFINE_BASECLASS( "lvs_base" )

function ENT:IsEngineStartAllowed()
	if hook.Run( "LVS.IsEngineStartAllowed", self ) == false then return false end

	if self:WaterLevel() > self.WaterLevelPreventStart then return false end

	local FuelTank = self:GetFuelTank()

	if IsValid( FuelTank ) and FuelTank:GetFuel() <= 0 then return false end

	local Engine = self:GetEngine()

	if IsValid( Engine ) and Engine:GetDestroyed() then
		Engine:EmitSound( "lvs/vehicles/generic/gear_grind"..math.random(1,6)..".ogg", 75, math.Rand(70,100), 0.25 )

		return false
	end

	return true
end

function ENT:StartEngine()
	for _, wheel in pairs( self:GetWheels() ) do
		if not IsValid( wheel ) then continue end

		wheel:PhysWake()
	end

	BaseClass.StartEngine( self )
end

function ENT:OnEngineStalled()
	timer.Simple(math.Rand(0.8,1.6), function()
		if not IsValid( self ) or self:GetEngineActive() then return end

		self:StartEngine()
	end)
end

function ENT:StallEngine()
	self:StopEngine()

	if self:GetNWGear() ~= -1 then
		self:SetNWGear( 1 )
	end

	self:OnEngineStalled()
end

function ENT:ShutDownEngine()
	if not self:GetEngineActive() then return end

	self:SetThrottle( 0 )
	self:StopEngine()
end

function ENT:GetEngineTorque()
	if self:IsManualTransmission() then
		local Gear = self:GetGear()
		local EntTable = self:GetTable()

		local NumGears = Reverse and EntTable.TransGearsReverse or EntTable.TransGears
		local MaxVelocity = Reverse and EntTable.MaxVelocityReverse or EntTable.MaxVelocity

		local PitchValue = MaxVelocity / NumGears

		local Vel = self:GetVelocity():Length()

		local preRatio = math.Clamp(Vel / (PitchValue * (Gear - 1)),0,1)
		local Ratio = math.Clamp( 2 - math.max( Vel - PitchValue * (Gear - 1), 0 ) / PitchValue, 0, 1 )

		local RatioIdeal = math.min( Ratio, preRatio )

		if Gear < NumGears and Ratio < 0.5 then
			local engine = self:GetEngine()

			if IsValid( engine ) and Ratio < 0.5 * self:GetThrottle() then
				local dmginfo = DamageInfo()
				dmginfo:SetDamage( 1 )
				dmginfo:SetAttacker( self )
				dmginfo:SetInflictor( self )
				dmginfo:SetDamageType( DMG_DIRECT )
				engine:TakeTransmittedDamage( dmginfo )
			end
		end

		if preRatio <= 0.05 and Vel < PitchValue and Gear > 1 then
			self:SetNWGear( 1 )
		end

		return math.deg( self.EngineTorque ) * RatioIdeal
	end

	return math.deg( self.EngineTorque )
end