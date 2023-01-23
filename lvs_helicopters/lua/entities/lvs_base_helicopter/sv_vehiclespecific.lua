
function ENT:ToggleVehicleSpecific()
	self._VSPEC = not self._VSPEC

	self:OnVehicleSpecificToggled( self._VSPEC )
end

function ENT:EnableVehicleSpecific()
	if self._VSPEC then return end

	self._VSPEC = true

	self:OnVehicleSpecificToggled( self._VSPEC )
end

function ENT:DisableVehicleSpecific()
	if not self._VSPEC then return end

	self._VSPEC = false

	self:OnVehicleSpecificToggled( self._VSPEC )
end

function ENT:OnVehicleSpecificToggled( IsActive )
end