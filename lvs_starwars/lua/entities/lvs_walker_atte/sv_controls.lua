
function ENT:TransformNormal( ent, Normal )
	ent.smNormal = ent.smNormal and ent.smNormal + (Normal - ent.smNormal) * FrameTime() * 2 or Normal

	return ent.smNormal
end

function ENT:SetTargetSteer( num )
	self._TargetSteer = num
end

function ENT:SetTargetSpeed( num )
	self._TargetVel = num
end

function ENT:GetTargetSpeed()
	local TargetSpeed = (self._TargetVel or 0)

	return TargetSpeed
end

function ENT:GetTargetSteer()
	return (self._TargetSteer or 0)
end

function ENT:ApproachTargetSpeed( MoveX )
	local Cur = self:GetTargetSpeed()
	local New = Cur + (MoveX - Cur) * FrameTime() * 3.5
	self:SetTargetSpeed( New )
end

function ENT:CalcThrottle( ply, cmd )
	local MoveSpeed = cmd:KeyDown( IN_SPEED ) and 150 or 100
	local MoveX = (cmd:KeyDown( IN_FORWARD ) and MoveSpeed or 0) + (cmd:KeyDown( IN_BACK ) and -MoveSpeed or 0)

	self:ApproachTargetSpeed( MoveX )
end

function ENT:CalcSteer( ply, cmd )
	local KeyLeft = cmd:KeyDown( IN_MOVELEFT )
	local KeyRight = cmd:KeyDown( IN_MOVERIGHT )
	local Steer = ((KeyLeft and 1 or 0) - (KeyRight and 1 or 0)) * 0.2 * math.abs( self:GetTargetSpeed() )

	local Cur = self:GetTargetSteer()
	local New = Cur + (Steer - Cur) * FrameTime() * 3.5

	self:SetTargetSteer( New )
end

function ENT:StartCommand( ply, cmd )
	if self:GetDriver() ~= ply then return end

	self:CalcThrottle( ply, cmd )
	self:CalcSteer( ply, cmd )
end

function ENT:GetHoverHeight( ent, phys )
	if ent == self:GetRearEntity() then
		local trace = self:ClimbTrace()

		local Len = self.HoverHeight

		if trace.Hit then
			Len = Len - 50* trace.InvFraction
		end

		return Len
	else
		local trace = self:ClimbTrace()

		local Len = self.HoverHeight

		if trace.Hit then
			Len = Len + 75 * trace.InvFraction
		end

		return Len
	end
end

function ENT:GetAlignment( ent, phys )
	local Move = self:GetMove()

	if ent == self:GetRearEntity() then
		local Right = ent:LocalToWorldAngles( Angle(0,0,math.cos( math.rad(Move + 90) ) * 0.5) ):Right()

		return ent:GetForward(), Right
	end

	local P = math.cos( math.rad(Move * 2) ) * 3
	local R = math.cos( math.rad(Move) ) * 2

	local trace = self:ClimbTrace()

	if trace.Hit then
		P = 45 * trace.InvFraction
	end

	local Ang = self:LocalToWorldAngles( Angle(P,0,R) )

	return Ang:Forward(), Ang:Right()
end

function ENT:ClimbTrace()
	local tracedata = {
		start = self:LocalToWorld( self:OBBCenter() ), 
		endpos = self:LocalToWorld( self:OBBCenter() + Vector(300,0,0) ),
		filter = function( ent ) 
			if self:GetCrosshairFilterLookup()[ ent:EntIndex() ] or ent:IsPlayer() or ent:IsNPC() or ent:IsVehicle() or self.HoverCollisionFilter[ ent:GetCollisionGroup() ] then
				return false
			end
			return true
		end,
	}

	local trace = util.TraceLine( tracedata )
	trace.InvFraction = (1 - math.max(trace.Fraction - 0.3,0) / 0.7) ^ 2

	trace.Hit = trace.Hit and not trace.HitSky

	return trace
end

function ENT:CalcMove( speed )
	self:SetMove( self:GetMove() + speed * 0.027 )

	local Move = self:GetMove()

	if Move > 360 then
		self:SetMove( Move - 360 )
	end

	if Move < -360 then
		self:SetMove( Move + 360 )
	end
end

function ENT:GetMoveXY( ent, phys, deltatime )
	local VelL = ent:WorldToLocal( ent:GetPos() + ent:GetVelocity() )

	local X = (self:GetTargetSpeed() - VelL.x)
	local Y = -VelL.y * 0.6

	if ent == self then self:CalcMove( VelL.x ) end

	if X > 0 then
		if ent == self:GetRearEntity() then
			return 0, Y
		end
		return X, Y
	else
		if ent == self:GetRearEntity() then
			return X, Y
		end
		return 0, Y
	end
end

function ENT:GetSteer( ent, phys )
	local Steer = -phys:GetAngleVelocity().z * 0.5

	if not IsValid( self:GetDriver() ) and not self:GetAI() then return Steer end

	if self:GetTargetSpeed() > 0 then
		if ent == self:GetRearEntity() then
			return 0
		else
			return Steer + self:GetTargetSteer()
		end
	else
		if ent == self:GetRearEntity() then
			return Steer + self:GetTargetSteer()
		else
			return 0
		end
	end
end
