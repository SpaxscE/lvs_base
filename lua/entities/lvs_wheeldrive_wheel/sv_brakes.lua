
function ENT:SetHandbrake( enable )
	if enable then

		self:EnableHandbrake()

		return
	end

	self:ReleaseHandbrake()
end

function ENT:IsHandbrakeActive()
	return self._handbrakeActive == true
end

function ENT:EnableHandbrake()
	if self._handbrakeActive then return end

	self._handbrakeActive = true

	self:LockRotation()
end

function ENT:ReleaseHandbrake()
	if not self._handbrakeActive then return end

	self._handbrakeActive = nil

	self:ReleaseRotation()
end

function ENT:LockRotation( TimedLock )

	if TimedLock then
		self._RotationLockTime = CurTime() + 0.15
	end

	if self:IsRotationLocked() then return end

	local Master = self:GetMaster()

	if not IsValid( Master ) then return end

	self.bsLock = constraint.AdvBallsocket(self,Master,0,0,vector_origin,vector_origin,0,0,-0.1,-0.1,-0.1,0.1,0.1,0.1,0,0,0,1,1)
	self.bsLock.DoNotDuplicate = true

	local PhysObj = self:GetPhysicsObject()

	if self._OriginalMass or not IsValid( PhysObj ) then return end

	local Mass = PhysObj:GetMass()

	self._OriginalMass = Mass

	PhysObj:SetMass( Mass * 1.5 )
end

function ENT:ReleaseRotation()
	if self._RotationLockTime then
		if self._RotationLockTime > CurTime() then
			return
		end
	end

	if not self:IsRotationLocked() then return end

	self.bsLock:Remove()

	local PhysObj = self:GetPhysicsObject()

	if not IsValid( PhysObj ) or not self._OriginalMass then return end

	PhysObj:SetMass( self._OriginalMass )

	self._OriginalMass = nil
end

function ENT:IsRotationLocked()
	return IsValid( self.bsLock )
end
