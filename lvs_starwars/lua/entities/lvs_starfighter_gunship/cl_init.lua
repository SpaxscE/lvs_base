include("shared.lua")

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
