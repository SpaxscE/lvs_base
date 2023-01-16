include("shared.lua")

function ENT:CalcViewOverride( ply, pos, angles, fov, pod )
	if pod == self:GetDriverSeat() then

		if pod:GetThirdPersonMode() then
			pos = pos + self:GetUp() * 200, angles, fov
		end

		return pos, angles, fov
	end

	return pos, angles, fov
end

function ENT:OnSpawn()
end

function ENT:OnFrame()
	local HeldEntity = self:GetHeldEntity()

	local IsHeld = IsValid( HeldEntity )

	if IsHeld ~= self._oldHeldEntity then
		self._oldHeldEntity = IsHeld

		if IsHeld then
			self:BuildFilter()
		else
			self:ResetFilters()
		end
	end
end

function ENT:OnStartBoost()
	self:EmitSound( "^lvs/vehicles/laat/boost_"..math.random(1,2)..".wav", 85 )
end

function ENT:OnStopBoost()
end
