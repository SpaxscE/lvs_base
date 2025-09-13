
function ENT:OnCreateAI()
	self:StartEngine()
end

function ENT:OnRemoveAI()
	self:StopEngine()
end

function ENT:RunAI()
	local RangerLength = 15000
	local mySpeed = self:GetVelocity():Length()
	local MinDist = 600 + mySpeed

	local StartPos = self:LocalToWorld( self:OBBCenter() )

	local TraceFilter = self:GetCrosshairFilterEnts()

	local FrontLeft = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(0,20,0) ):Forward() * RangerLength } )
	local FrontRight = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(0,-20,0) ):Forward() * RangerLength } )

	local FrontLeft2 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(25,65,0) ):Forward() * RangerLength } )
	local FrontRight2 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(25,-65,0) ):Forward() * RangerLength } )

	local FrontLeft3 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(-25,65,0) ):Forward() * RangerLength } )
	local FrontRight3 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(-25,-65,0) ):Forward() * RangerLength } )

	local FrontUp = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(-20,0,0) ):Forward() * RangerLength } )
	local FrontDown = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(20,0,0) ):Forward() * RangerLength } )

	local TraceForward = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:GetForward() * RangerLength } )
	local TraceDown = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + Vector(0,0,-RangerLength) } )
	local TraceUp = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + Vector(0,0,RangerLength) } )

	local cAvoid = Vector(0,0,0)

	local myRadius = self:BoundingRadius() 
	local myPos = self:GetPos()
	local myDir = self:GetForward()
	for _, v in pairs( LVS:GetVehicles() ) do
		if v == self then continue end

		local theirRadius = v:BoundingRadius() 
		local Sub = (myPos - v:GetPos())
		local Dir = Sub:GetNormalized()
		local Dist = Sub:Length()
		
		if Dist < (theirRadius + myRadius + 200) then
			if math.deg( math.acos( math.Clamp( myDir:Dot( -Dir ) ,-1,1) ) ) < 90 then
				cAvoid = cAvoid + Dir * (theirRadius + myRadius + 500)
			end
		end
	end

	local FLp = FrontLeft.HitPos + FrontLeft.HitNormal * MinDist + cAvoid * 8
	local FRp = FrontRight.HitPos + FrontRight.HitNormal * MinDist + cAvoid * 8

	local FL2p = FrontLeft2.HitPos + FrontLeft2.HitNormal * MinDist
	local FR2p = FrontRight2.HitPos + FrontRight2.HitNormal * MinDist

	local FL3p = FrontLeft3.HitPos + FrontLeft3.HitNormal * MinDist
	local FR3p = FrontRight3.HitPos + FrontRight3.HitNormal * MinDist

	local FUp = FrontUp.HitPos + FrontUp.HitNormal * MinDist
	local FDp = FrontDown.HitPos + FrontDown.HitNormal * MinDist

	local Up = TraceUp.HitPos + TraceUp.HitNormal * MinDist
	local Dp = TraceDown.HitPos + TraceDown.HitNormal * MinDist

	local TargetPos = (FLp+FRp+FL2p+FR2p+FL3p+FR3p+FUp+FDp+Up+Dp) / 10

	local alt = (StartPos - TraceDown.HitPos):Length()
	local ceiling = (StartPos - TraceUp.HitPos):Length()

	local WallDist = (StartPos - TraceForward.HitPos):Length()

	local Throttle = math.min( WallDist / mySpeed, 1 )

	self._AIFireInput = false

	if alt < 600 or ceiling < 600 or WallDist < (MinDist * 3 * (math.deg( math.acos( math.Clamp( Vector(0,0,1):Dot( myDir ) ,-1,1) ) ) / 180) ^ 2) then
		Throttle = 1

		if self:HitGround() then
			TargetPos.z = StartPos.z + 750
		end
	else
		if IsValid( self:GetHardLockTarget() ) then
			TargetPos = self:GetHardLockTarget():GetPos() + cAvoid * 8
		else
			if alt > mySpeed then
				local Target = self._LastAITarget

				if not IsValid( self._LastAITarget ) or not self:AITargetInFront( self._LastAITarget, 135 ) or not self:AICanSee( self._LastAITarget ) then
					Target = self:AIGetTarget()
				end

				if IsValid( Target ) then
					if self:AITargetInFront( Target, 65 ) then
						local T = CurTime() + self:EntIndex() * 1337
						TargetPos = Target:GetPos() + cAvoid * 8 + Vector(0,0, math.sin( T * 5 ) * 500 ) + Target:GetVelocity() * math.abs( math.cos( T * 13.37 ) ) * 5

						Throttle = math.min( (StartPos - TargetPos):Length() / mySpeed, 1 )

						local tr = util.TraceHull( {
							start =  StartPos,
							endpos = (StartPos + self:GetForward() * 50000),
							mins = Vector( -50, -50, -50 ),
							maxs = Vector( 50, 50, 50 ),
							filter = TraceFilter
						} )

						local CanShoot = (IsValid( tr.Entity ) and tr.Entity.LVS and tr.Entity.GetAITEAM) and (tr.Entity:GetAITEAM() ~= self:GetAITEAM() or tr.Entity:GetAITEAM() == 0) or true

						if CanShoot and self:AITargetInFront( Target, 22 ) then
							local CurHeat = self:GetNWHeat()
							local CurWeapon = self:GetSelectedWeapon()

							if CurWeapon > 2 then
								self:AISelectWeapon( 1 )
							else
								if CurHeat > 0.9 then
									if CurWeapon == 1 and self:AIHasWeapon( 2 ) then
										self:AISelectWeapon( 2 )

									elseif CurWeapon == 2 then
										self:AISelectWeapon( 1 )
									end
								else
									if CurHeat == 0 and math.cos( T ) > 0 then
										self:AISelectWeapon( 1 )
									end
								end
							end

							self._AIFireInput = true
						end
					else
						self:AISelectWeapon( 1 )

						if alt > 6000 and self:AITargetInFront( Target, 90 ) then
							TargetPos = Target:GetPos()
						end
					end
				end
			else
				TargetPos.z = StartPos.z + 2000

				self:EnableVehicleSpecific()
			end
		end
	end

	self:SetThrottle( Throttle )

	self.smTargetPos = self.smTargetPos and self.smTargetPos + (TargetPos - self.smTargetPos) * FrameTime() or self:GetPos()

	self._lvsAITargetAng = (self.smTargetPos - self:GetPos()):GetNormalized():Angle()
end

function ENT:AISelectWeapon( ID )
	if ID == self:GetSelectedWeapon() then return end

	local T = CurTime()

	if (self._nextAISwitchWeapon or 0) > T then return end

	self._nextAISwitchWeapon = T + math.random(3,6)

	self:SelectWeapon( ID )
end

function ENT:OnAITakeDamage( dmginfo )
	local attacker = dmginfo:GetAttacker()

	if not IsValid( attacker ) then return end

	if not self:AITargetInFront( attacker, IsValid( self:AIGetTarget() ) and 120 or 45 ) then
		self:SetHardLockTarget( attacker )
	end
end

function ENT:SetHardLockTarget( target )
	self._HardLockTarget =  target
	self._HardLockTime = CurTime() + 4
end

function ENT:GetHardLockTarget()
	if (self._HardLockTime or 0) < CurTime() then return NULL end

	return self._HardLockTarget
end
