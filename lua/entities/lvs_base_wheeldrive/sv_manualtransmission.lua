function ENT:EnableManualTransmission()
	self:SetReverse( false )
	self:SetNWGear( 1 )
end

function ENT:DisableManualTransmission()
	self:SetNWGear( -1 )
end

function ENT:CalcManualTransmission( ply, EntTable, ShiftUp, ShiftDn )
	if ShiftUp ~= EntTable._oldShiftUp then
		EntTable._oldShiftUp = ShiftUp

		if ShiftUp then
			self:ShiftUp()
		end
	end

	if ShiftDn ~= EntTable._oldShiftDn then
		EntTable._oldShiftDn = ShiftDn

		if ShiftDn then
			self:ShiftDown()
		end
	end
end

function ENT:OnShiftUp()
end

function ENT:OnShiftDown()
end

function ENT:ShiftUp()
	if self:OnShiftUp() == false then return end

	local Reverse = self:GetReverse()

	if Reverse then
		local NextGear = self:GetNWGear() - 1

		self:SetNWGear( math.max( NextGear, 1 ) )

		if NextGear <= 0 then
			self:SetReverse( false )
		end

		return
	end

	self:SetNWGear( math.min( self:GetNWGear() + 1, self.TransGears ) )
end

function ENT:ShiftDown()
	if self:OnShiftDown() == false then return end

	local Reverse = self:GetReverse()

	if Reverse then
		self:SetNWGear( math.min( self:GetNWGear() + 1, self.TransGearsReverse ) )

		return
	end

	local NextGear = self:GetNWGear() - 1

	self:SetNWGear( math.max( NextGear, 1 ) )

	if NextGear <= 0 then
		self:SetReverse( true )
	end
end
