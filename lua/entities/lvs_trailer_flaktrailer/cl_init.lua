include("shared.lua")

function ENT:LVSHudPaintVehicleIdentifier( X, Y, In_Col, target_ent )
end

function ENT:UpdatePoseParameters( steer, speed_kmh, engine_rpm, throttle, brake, handbrake, clutch, gear, temperature, fuel, oil, ammeter )
	local Prongs = self:GetProng()

	local T = CurTime()

	if Prongs then self._ProngTime = T + 0.25 end

	local ProngsActive = (self._ProngTime or 0) > T

	self:SetPoseParameter( "fold", self:QuickLerp( "prong", (ProngsActive and 1 or 0), 10 ) )
end
