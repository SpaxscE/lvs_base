include("shared.lua")
include("cl_camera.lua")
include("cl_hud.lua")

function ENT:OnFrameActive()
	local ply = LocalPlayer()

	if not IsValid( ply ) then return end

	if ply:lvsGetVehicle() == self then return end

	local ViewEnt = ply:GetViewEntity()

	if not IsValid( ViewEnt ) then return end

	local Time = CurTime()

	if (self._nextflyby or 0) > Time then return end

	self._nextflyby = Time + 0.1

	local Vel = self:GetVelocity()

	if self:GetThrottle() <= 0.75 or Vel:Length() <= self.MaxVelocity * 0.75 then return end

	local Sub = ViewEnt:GetPos() - self:GetPos()
	local ToPlayer = Sub:GetNormalized()
	local VelDir = Vel:GetNormalized()

	local ApproachAngle = math.deg( math.acos( math.Clamp( ToPlayer:Dot( VelDir ) ,-1,1) ) )

	local Approaching = ApproachAngle < 80

	if Approaching ~= self.OldApproaching then
		self.OldApproaching = Approaching

		if not Approaching then
			self:OnFlyBy( 60 + 80 * math.min(ApproachAngle / 140,1) )
		end
	end
end

function ENT:OnFlyBy( Pitch )
end