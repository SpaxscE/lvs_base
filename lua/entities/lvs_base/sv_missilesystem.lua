
function ENT:SetMissileNoTarget( T )
	self._MissileNoTargetTime = CurTime() + T
end

function ENT:GetMissileNoTarget()
	return (self._MissileNoTargetTime or 0) > CurTime()
end

function ENT:CreateFlare( Pos, Dir, Vel )
	local ent = ents.Create( "lvs_missile_countermeasure" )
	ent:SetPos( Pos )
	ent:SetAngles( Dir:Angle() )
	ent:Spawn()
	ent:Activate()
	ent:SetLifeTime( 3 )

	local PhysObj = ent:GetPhysicsObject()

	if IsValid( PhysObj ) then
		PhysObj:SetVelocityInstantaneous( Dir * Vel )
	end
end

function ENT:OnMissileSeek( missile )
	--[[
	self:SetMissileNoTarget( 1 )

	local Vel = self:GetVelocity():Length() * 2

	for i = -2, 2 do
		self:CreateFlare( self:GetPos(), self:LocalToWorldAngles( Angle(5 * math.abs( i ),i * 10,0) ):Forward(), Vel - math.abs( i ) * 1000 )
		self:CreateFlare( self:GetPos(), self:LocalToWorldAngles( Angle(-5 * math.abs( i ),i * 10,0) ):Forward(), Vel - math.abs( i ) * 1000 )
	end
	]]
end

function ENT:OnMissileLock( missile )
end

function ENT:GetMissileOffset()
	return self:OBBCenter()
end