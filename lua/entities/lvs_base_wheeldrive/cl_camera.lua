
function ENT:CalcViewOverride( ply, pos, angles, fov, pod )
	return pos, angles, fov
end

function ENT:CalcViewDirectInput( ply, pos, angles, fov, pod )
	return LVS:CalcView( self, ply, pos, angles,  fov, pod )
end

function ENT:CalcViewMouseAim( ply, pos, angles, fov, pod )
	return LVS:CalcView( self, ply, pos, angles,  fov, pod )
end

function ENT:CalcViewDriver( ply, pos, angles, fov, pod )
	pos = pos + pod:GetUp() * 7 - pod:GetRight() * 11

	if ply:lvsMouseAim() then
		angles = ply:EyeAngles()

		return self:CalcViewMouseAim( ply, pos, angles,  fov, pod )
	else
		return self:CalcViewDirectInput( ply, pos, angles,  fov, pod )
	end
end

function ENT:CalcViewPassenger( ply, pos, angles, fov, pod )
	return LVS:CalcView( self, ply, pos, angles, fov, pod )
end

function ENT:LVSCalcView( ply, original_pos, original_angles, original_fov, pod )
	local pos, angles, fov = self:CalcViewOverride( ply, original_pos, original_angles, original_fov, pod )

	local new_fov = math.min( fov + self:CalcViewPunch( ply, pos, angles, fov, pod ), 180 )

	if self:GetDriverSeat() == pod then
		return self:CalcViewDriver( ply, pos, angles, new_fov, pod )
	else
		return self:CalcViewPassenger( ply, pos, angles, new_fov, pod )
	end
end

function ENT:SuppressViewPunch( time )
	self._viewpunch_supressed_time = CurTime() + (time or 0.2)
end

function ENT:IsViewPunchSuppressed()
	return (self._viewpunch_supressed_time or 0) > CurTime()
end

function ENT:CalcViewPunch( ply, pos, angles, fov, pod )
	local Vel = self:GetVelocity()
	local VelLength = Vel:Length()
	local VelPercentMaxSpeed = math.min( VelLength / 1000, 1 )

	if ply:lvsMouseAim() then
		angles = ply:EyeAngles()
	end

	local direction = (90 - self:AngleBetweenNormal( angles:Forward(), Vel:GetNormalized() )) / 90

	local FovValue = math.min( VelPercentMaxSpeed ^ 2 * 100, 15 )

	local Throttle = self:GetThrottle()
	local Brake = self:GetBrake()

	if self:IsViewPunchSuppressed() then
		self._viewpunch_fov = self._viewpunch_fov and self._viewpunch_fov + (-VelPercentMaxSpeed * FovValue - self._viewpunch_fov) * RealFrameTime() or 0
	else
		local newFov =(1 - VelPercentMaxSpeed) * Throttle * FovValue - VelPercentMaxSpeed * Brake * FovValue

		self._viewpunch_fov = self._viewpunch_fov and self._viewpunch_fov + (newFov - self._viewpunch_fov) * RealFrameTime() * 10 or 0
	end

	return self._viewpunch_fov * (90 - self:AngleBetweenNormal( angles:Forward(), Vel:GetNormalized() )) / 90
end
