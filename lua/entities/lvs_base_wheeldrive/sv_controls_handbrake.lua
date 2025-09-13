
function ENT:EnableHandbrake()
	if self:IsHandbrakeActive() then return end

	self:SetNWHandBrake( true )

	self._HandbrakeEnabled = true

	for _, Wheel in pairs( self:GetWheels() ) do
		if not self:GetAxleData( Wheel:GetAxle() ).UseHandbrake then continue end

		Wheel:SetHandbrake( true )
	end

	self:OnHandbrakeActiveChanged( true )
end

function ENT:ReleaseHandbrake()
	if not self:IsHandbrakeActive() then return end

	self:SetNWHandBrake( false )

	self._HandbrakeEnabled = nil

	for _, Wheel in pairs( self:GetWheels() ) do
		if not self:GetAxleData( Wheel:GetAxle() ).UseHandbrake then continue end

		Wheel:SetHandbrake( false )
	end

	self:OnHandbrakeActiveChanged( false )
end

function ENT:SetHandbrake( enable )
	if enable then

		self:EnableHandbrake()

		return
	end

	self:ReleaseHandbrake()
end

function ENT:IsHandbrakeActive()
	return self._HandbrakeEnabled == true
end

function ENT:OnHandbrakeActiveChanged( Active )
	if Active then
		self:EmitSound( "lvs/vehicles/generic/handbrake_on.wav", 75, 100, 0.25 )
	else
		self:EmitSound( "lvs/vehicles/generic/handbrake_off.wav", 75, 100, 0.25 )
	end
end