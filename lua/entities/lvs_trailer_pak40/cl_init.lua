include("shared.lua")
include("sh_turret.lua")
include("entities/lvs_tank_wheeldrive/modules/cl_tankview.lua")
include("cl_optics.lua")

function ENT:TankViewOverride( ply, pos, angles, fov, pod )
	if ply == self:GetDriver() then
		if pod:GetThirdPersonMode() then
			pos = self:LocalToWorld( Vector(35,0,40) )
		else
			local vieworigin, found = self:GetTurretViewOrigin()

			if found then pos = vieworigin end
		end
	end

	return pos, angles, fov
end

function ENT:UpdatePoseParameters( steer, speed_kmh, engine_rpm, throttle, brake, handbrake, clutch, gear, temperature, fuel, oil, ammeter )
	local Prongs = self:GetProngs()

	local T = CurTime()

	if Prongs then self._ProngTime = T + 1 end

	local ProngsActive = (self._ProngTime or 0) > T

	self:SetPoseParameter( "prong", self:QuickLerp( "prong", (ProngsActive and 1 or 0), 10 ) )
end
