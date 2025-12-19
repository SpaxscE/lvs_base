
ENT.FlyByVelocity = 500
ENT.FlyByMinThrottle = 0
ENT.FlyByAdvance = 1
ENT.FlyBySound = "lvs/vehicles/generic/car_flyby.wav"

function ENT:FlyByThink()
	local ply = LocalPlayer()

	if not IsValid( ply ) then return end

	local veh = ply:lvsGetVehicle()

	local EntTable = self:GetTable()

	if veh == self then EntTable.OldApproaching = false return end

	local ViewEnt = ply:GetViewEntity()

	if not IsValid( ViewEnt ) then return end

	if IsValid( veh ) and ViewEnt == ply then
		ViewEnt = veh
	end

	local Time = CurTime()

	if (EntTable._nextflyby or 0) > Time then return end

	EntTable._nextflyby = Time + 0.1

	local Vel = self:GetVelocity()

	if self:GetThrottle() <= EntTable.FlyByMinThrottle or Vel:Length() <= EntTable.FlyByVelocity then return end

	local Sub = ViewEnt:GetPos() - self:GetPos() - Vel * EntTable.FlyByAdvance
	local ToPlayer = Sub:GetNormalized()
	local VelDir = Vel:GetNormalized()

	local ApproachAngle = self:AngleBetweenNormal( ToPlayer, VelDir  )

	local Approaching = ApproachAngle < 80

	if Approaching ~= EntTable.OldApproaching then
		EntTable.OldApproaching = Approaching

		if Approaching then
			self:StopFlyBy()
		else
			self:OnFlyBy( 60 + 80 * math.min(ApproachAngle / 140,1) )
		end
	end
end

function ENT:OnFlyBy( Pitch )
	if not self.FlyBySound then return end

	local EntTable = self:GetTable()

	EntTable.flybysnd = CreateSound( self, self.FlyBySound )
	EntTable.flybysnd:SetSoundLevel( 95 )
	EntTable.flybysnd:PlayEx( 1, Pitch )
end

function ENT:StopFlyBy()
	local EntTable = self:GetTable()

	if not EntTable.flybysnd then return end

	EntTable.flybysnd:Stop()
	EntTable.flybysnd = nil
end
