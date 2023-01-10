include("shared.lua")

function ENT:CalcViewOverride( ply, pos, angles, fov, pod )
	if self:GetDriver() == ply then
		local newpos = pos + self:GetForward() * 37 + self:GetUp() * 8

		return newpos, angles, fov
	else
		return pos, angles, fov
	end
end

function ENT:OnSpawn()
end

function ENT:OnFrame()
end

function ENT:OnStartBoost()
	self:EmitSound( "lvs/vehicles/vwing/boost.wav", 85 )
end

function ENT:OnStopBoost()
	self:EmitSound( "lvs/vehicles/vwing/brake.wav", 85 )
end
