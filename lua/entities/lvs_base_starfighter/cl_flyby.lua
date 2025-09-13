
ENT.FlyByAdvance = 0

function ENT:FlyByThink()
	local ply = LocalPlayer()

	if not IsValid( ply ) then return end

	local EntTable = self:GetTable()

	if ply:lvsGetVehicle() == self then self.OldApproaching = false return end

	local ViewEnt = ply:GetViewEntity()

	if not IsValid( ViewEnt ) then return end

	local Time = CurTime()

	if (EntTable._nextflyby or 0) > Time then return end

	EntTable._nextflyby = Time + 0.1

	local Vel = self:GetVelocity()

	if self:GetThrottle() <= 0.75 or Vel:Length() <= EntTable.MaxVelocity * 0.75 then return end

	local Sub = ViewEnt:GetPos() - self:GetPos() - Vel * EntTable.FlyByAdvance
	local ToPlayer = Sub:GetNormalized()
	local VelDir = Vel:GetNormalized()

	local ApproachAngle = math.deg( math.acos( math.Clamp( ToPlayer:Dot( VelDir ) ,-1,1) ) )

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

	EntTable.flybysnd = CreateSound( self, EntTable.FlyBySound )
	EntTable.flybysnd:SetSoundLevel( 95 )
	EntTable.flybysnd:PlayEx( 1, Pitch )
end

function ENT:StopFlyBy()
	local EntTable = self:GetTable()

	if not EntTable.flybysnd then return end

	EntTable.flybysnd:Stop()
	EntTable.flybysnd = nil
end