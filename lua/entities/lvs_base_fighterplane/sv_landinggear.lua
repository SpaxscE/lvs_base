
function ENT:HandleLandingGear( Rate )
	local EnableBrakes = self:GetThrottle() <= 0

	local Cur = self:GetLandingGear()

	if self.WheelAutoRetract then
		if self:HitGround() then
			self.LandingGearUp = false
		else
			self.LandingGearUp = self:GetStability() > 0.4
		end
	end

	local New = Cur + math.Clamp((self.LandingGearUp and 0 or 1) - Cur,-Rate,Rate)

	local SetValue = Cur ~= New

	if SetValue then
		self:SetLandingGear( New )
	end

	for _, data in pairs( self:GetWheels() ) do
		local wheel = data.entity
		local mass = data.mass
		local physobj = data.physobj

		if not IsValid( wheel ) or not IsValid( physobj ) then continue end

		wheel:SetBrakes( EnableBrakes )

		if not SetValue then continue end

		physobj:SetMass( 1 + (mass - 1) * New ^ 4 )
	end
end

function ENT:ToggleLandingGear()
	if self.WheelAutoRetract then return end

	self.LandingGearUp = not self.LandingGearUp

	self:OnLandingGearToggled( self.LandingGearUp )
end

function ENT:RaiseLandingGear()
	if self.WheelAutoRetract then return end

	if not self.LandingGearUp then
		self.LandingGearUp = true
		
		self:OnLandingGearToggled( self.LandingGearUp )
	end
end

function ENT:DeployLandingGear()
	if self.WheelAutoRetract then return end

	if self.LandingGearUp then
		self.LandingGearUp = false
		
		self:OnLandingGearToggled( self.LandingGearUp )
	end
end

function ENT:OnLandingGearToggled( IsDeployed )
end