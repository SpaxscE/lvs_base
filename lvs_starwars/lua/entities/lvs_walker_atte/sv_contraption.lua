
function ENT:ContraptionThink()
	local OnMoveableFloor = self:CheckGround()

	if not IsValid( self:GetDriver() ) and not self:GetAI() then
		self:ApproachTargetSpeed( 0 )
		self:SetTargetSteer( 0 )
	end

	self:CheckUpRight()
	self:CheckActive()
	self:CheckMotion( OnMoveableFloor )
end

function ENT:CheckUpRight()
	if self:GetIsCarried() then return end

	if self:IsPlayerHolding() or self:GetRearEntity():IsPlayerHolding() then return end

	if self:HitGround() then
		return
	end

	if self._NumGround ~= 0 then return end

	self:BecomeRagdoll()
end

function ENT:CheckActive()
	local ShouldBeActive = not self:GetIsCarried() and self:HitGround() and not self:GetIsRagdoll()

	if ShouldBeActive ~= self:GetEngineActive() then
		self:SetEngineActive( ShouldBeActive )
	end
end

function ENT:ToggleGravity( PhysObj, Enable )
	if self:GetIsCarried() then Enable = false end

	if PhysObj:IsGravityEnabled() ~= Enable then
		PhysObj:EnableGravity( Enable )
	end
end

function ENT:CheckMotion( OnMoveableFloor )
	if self:GetIsRagdoll() or self:GetIsCarried() then

		if self:GetIsCarried() then self:ForceMotion() end
	
		return
	end

	local TargetSpeed = self:GetTargetSpeed()

	if not self:HitGround() or self:GetIsCarried() then
		self:SetIsMoving( false )
	else
		self:SetIsMoving( math.abs( TargetSpeed ) > 1 )
	end

	local IsHeld = self:IsPlayerHolding() or self:GetRearEntity():IsPlayerHolding() 

	if IsHeld then
		self:SetTargetSpeed( 200 )
	end

	if self:HitGround() and not OnMoveableFloor then
		local enable = self:GetIsMoving() or IsHeld

		for _, ent in ipairs( self:GetContraption() ) do
			if not IsValid( ent ) then continue end

			local phys = ent:GetPhysicsObject()

			if not IsValid( phys ) then continue end

			if phys:IsMotionEnabled() ~= enable then
				phys:EnableMotion( enable )
				phys:Wake()
			end
		end
	else
		local enable = self:GetIsMoving() or IsHeld or OnMoveableFloor

		for _, ent in ipairs( self:GetContraption() ) do
			if not IsValid( ent ) then continue end

			local phys = ent:GetPhysicsObject()

			if not IsValid( phys ) then continue end

			if not phys:IsMotionEnabled() then
				phys:EnableMotion( enable )
				phys:Wake()
			end
		end
	end
end

function ENT:HitGround()
	return self._HitGround == true
end

function ENT:CheckGround()
	local NumHits = 0
	local HitMoveable

	for _, ent in ipairs( self:GetContraption() ) do
		local phys = ent:GetPhysicsObject()

		if not IsValid( phys ) then continue end

		local masscenter = phys:LocalToWorld( phys:GetMassCenter() )

		local trace =  util.TraceHull( {
			start = masscenter, 
			endpos = masscenter - ent:GetUp() * self.HoverTraceLength,
			mins = Vector( -self.HoverHullRadius, -self.HoverHullRadius, 0 ),
			maxs = Vector( self.HoverHullRadius, self.HoverHullRadius, 0 ),
			filter = function( entity ) 
				if self:GetCrosshairFilterLookup()[ entity:EntIndex() ] or entity:IsPlayer() or entity:IsNPC() or entity:IsVehicle() or self.HoverCollisionFilter[ entity:GetCollisionGroup() ] then
					return false
				end

				return true
			end,
		} )

		if not HitMoveable then
			if IsValid( trace.Entity ) then
				HitMoveable = self.CanMoveOn[ trace.Entity:GetClass() ]
			end
		end

		if not trace.Hit or trace.HitSky then continue end

		NumHits = NumHits + 1
	end

	self._NumGround = NumHits
	self._HitGround = NumHits == 2

	return HitMoveable == true
end

function ENT:OnIsCarried( name, old, new)
	if new == old then return end

	if new then
		self:NudgeRagdoll()
	else
		self:SetTargetSpeed( 200 )
	end
end