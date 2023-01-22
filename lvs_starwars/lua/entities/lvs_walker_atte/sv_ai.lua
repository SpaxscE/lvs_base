
function ENT:RunAI()
	local RangerLength = 25000

	local Target = self:AIGetTarget()

	local StartPos = self:LocalToWorld( self:OBBCenter() )

	local TraceFilter = self:GetCrosshairFilterEnts()

	local Front = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:GetForward() * RangerLength } )
	local FrontLeft = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(0,15,0) ):Forward() * RangerLength } )
	local FrontRight = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(0,-15,0) ):Forward() * RangerLength } )
	local FrontLeft1 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(0,60,0) ):Forward() * RangerLength } )
	local FrontRight1 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(0,-60,0) ):Forward() * RangerLength } )
	local FrontLeft2 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(0,85,0) ):Forward() * RangerLength } )
	local FrontRight2 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(0,-85,0) ):Forward() * RangerLength } )

	local MovementTargetPos = (Front.HitPos + FrontLeft.HitPos + FrontRight.HitPos + FrontLeft1.HitPos + FrontRight1.HitPos + FrontLeft2.HitPos + FrontRight2.HitPos) / 7

	if IsValid( Target ) then
		MovementTargetPos = (MovementTargetPos + Target:GetPos()) * 0.5
	end

	self._smTargetPos = self._smTargetPos and self._smTargetPos + (MovementTargetPos - self._smTargetPos) * FrameTime() * 0.5 or MovementTargetPos

	local TargetPosLocal = self:WorldToLocal( self._smTargetPos )

	local Dir = math.Clamp( TargetPosLocal.y / 100, -1, 1 ) * 0.2 * math.abs( self:GetTargetSpeed() )

	local TargetPos = self:LocalToWorld( Vector(2000,0,150) )

	self._AIFireInput = false

	if IsValid( self:GetHardLockTarget() ) then
		TargetPos = self:GetHardLockTarget():GetPos()
		if self:AITargetInFront( self:GetHardLockTarget(), 65 ) then
			self._AIFireInput = true
		end

		self:SetTargetSteer( Dir )
		self:SetTargetSpeed( TargetPosLocal.x > 1000 and 150 or -150 )
	else
		if IsValid( Target ) then
			TargetPos = Target:LocalToWorld( Target:OBBCenter() )

			if self:AITargetInFront( Target, 65 ) then
				self._AIFireInput = true
			end

			self:SetTargetSteer( Dir )
			self:SetTargetSpeed( TargetPosLocal.x > 1000 and 150 or -150 )
		else
			self:SetTargetSteer( 0 )
			self:SetTargetSpeed( 0 )
		end
	end

	local pod = self:GetDriverSeat()

	if not IsValid( pod ) then return end

	self:SetAIAimVector( (TargetPos - pod:LocalToWorld( Vector(0,0,33) )):GetNormalized() )
end

function ENT:OnAITakeDamage( dmginfo )
	local attacker = dmginfo:GetAttacker()

	if not IsValid( attacker ) then return end

	if not self:AITargetInFront( attacker, IsValid( self:AIGetTarget() ) and 120 or 45 ) then
		self:SetHardLockTarget( attacker )
	end
end

function ENT:SetHardLockTarget( target )
	if not self:IsEnemy( target ) then return end

	self._HardLockTarget =  target
	self._HardLockTime = CurTime() + 4
end

function ENT:GetHardLockTarget()
	if (self._HardLockTime or 0) < CurTime() then return NULL end

	return self._HardLockTarget
end
