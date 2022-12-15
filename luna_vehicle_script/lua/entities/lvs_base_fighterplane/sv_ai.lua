
function ENT:OnCreateAI()
	self:StartEngine()
end

function ENT:OnRemoveAI()
	self:StopEngine()
end

function ENT:RunAI()
	local RangerLength = 15000
	local mySpeed = self:GetVelocity():Length()
	local MinDist = 600 + mySpeed * 2
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

	local Up = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:GetUp() * RangerLength } )
	local Down = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos - self:GetUp() * RangerLength } )

	local Down2 = util.TraceLine( { start = self:LocalToWorld( Vector(0,0,100) ), filter = TraceFilter, endpos = StartPos + Vector(0,0,-RangerLength) } )

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

	local Up = Up.HitPos + Up.HitNormal * MinDist
	local Dp = Down.HitPos + Down.HitNormal * MinDist

	local TargetPos = (FLp+FRp+FL2p+FR2p+FL3p+FR3p+FUp+FDp+Up+Dp) / 10

	local alt = (self:GetPos() - Down2.HitPos):Length()

	if alt < MinDist then 
		self:SetThrottle( 1 )

		if self:GetStability() < 0.4 then
			self:SetThrottle( 1 )
			TargetPos.z = self:GetPos().z + 2000
		end
	else
		if self:GetStability() < 0.3 then
			self:SetThrottle( 1 )
			TargetPos.z = self:GetPos().z + 600
		else
			if alt > mySpeed then
				local Target = self:AIGetTarget()

				if IsValid( Target ) then
					if self:AITargetInFront( Target, 65 ) then
						TargetPos = Target:GetPos() + cAvoid * 8 + Target:GetVelocity() * math.abs(math.cos( CurTime() * 150 ) ) * 3
						
						local Throttle = (self:GetPos() - TargetPos):Length() / 8000
						self:SetThrottle( Throttle )

						local tr = util.TraceHull( {
							start =  StartPos,
							endpos = (StartPos + self:GetForward() * 50000),
							mins = Vector( -50, -50, -50 ),
							maxs = Vector( 50, 50, 50 ),
							filter = TraceFilter
						} )

						local CanShoot = (IsValid( tr.Entity ) and tr.Entity.LVS and tr.Entity.GetAITEAM) and (tr.Entity:GetAITEAM() ~= self:GetAITEAM() or tr.Entity:GetAITEAM() == 0) or true

						if CanShoot then
							if self:AITargetInFront( Target, 15 ) then
								--self:HandleWeapons( true )
								self:PrimaryAttack()
								
								if self:AITargetInFront( Target, 10 ) then
									--self:HandleWeapons( true, true )
								end
							end
						end
					else
						if alt > 6000 and self:AITargetInFront( Target, 90 ) then
							TargetPos = Target:GetPos()
						else
							TargetPos = TargetPos
						end
						
						self:SetThrottle( 1 )
					end
				else
					self:SetThrottle( 1 )
				end
			else
				self:SetThrottle( 1 )

				TargetPos.z = self:GetPos().z + 2000
			end
		end
		self:RaiseLandingGear()
	end

	self.smTargetPos = self.smTargetPos and self.smTargetPos + (TargetPos - self.smTargetPos) * FrameTime() or self:GetPos()

	local TargetAng = (self.smTargetPos - self:GetPos()):GetNormalized():Angle()

	self:ApproachTargetAngle( TargetAng )
end
