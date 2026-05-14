
function ENT:OnMissileSeek( missile )
end

function ENT:OnMissileLock( missile )
end

function ENT:GetMissileOffset()
	return self:OBBCenter()
end