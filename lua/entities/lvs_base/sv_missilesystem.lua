
ENT.MissileAlert = true
ENT.MissileAlertDelayMin = 0.05
ENT.MissileAlertDelayMax = 0.4
ENT.MissileAlertDistance = 20000

function ENT:MissileDetected()
	return (self._MissileAlertTime or 0) > CurTime()
end

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
	ent:SetLifeTime( math.Rand(2.5,3.5) )
	ent:SetVehicle( self )

	local PhysObj = ent:GetPhysicsObject()

	if IsValid( PhysObj ) then
		PhysObj:SetVelocityInstantaneous( Dir * Vel )
	end

	return ent
end

function ENT:CreateFlares( PosOffset, AngOffset, NumBursts )
	if not NumBursts then NumBursts = 1 end
	if not PosOffset then PosOffset = Vector(0,0,0) end
	if not AngOffset then AngOffset = Angle(0,0,0) end

	local Pos = self:LocalToWorld( PosOffset )
	local Vel = self:GetVelocity():Length()

	self:SetMissileNoTarget( 1 )
	self:CreateFlare( Pos, self:LocalToWorldAngles( Angle(5,0,0) + AngOffset ):Forward(), Vel + 900 )
	self:CreateFlare( Pos, self:LocalToWorldAngles( Angle(5,15,0) + AngOffset ):Forward(), Vel + 600 )
	self:CreateFlare( Pos, self:LocalToWorldAngles( Angle(5,-15,0) + AngOffset ):Forward(), Vel + 600 )
	self:CreateFlare( Pos, self:LocalToWorldAngles( Angle(5,30,0) + AngOffset ):Forward(), Vel + 300 )
	self:CreateFlare( Pos, self:LocalToWorldAngles( Angle(5,-30,0) + AngOffset ):Forward(), Vel + 300 )
	self:EmitSound("weapons/flaregun/fire.wav",85,125,0.15)

	if NumBursts <= 1 then return end

	for i = 1, NumBursts do
		timer.Simple( i * 0.5, function()
			if not IsValid( self ) then return end

			local Pos = self:LocalToWorld( PosOffset )
			local Vel = self:GetVelocity():Length()

			self:SetMissileNoTarget( 1 )
			self:CreateFlare( Pos, self:LocalToWorldAngles( Angle(5,0,0) + AngOffset ):Forward(), Vel + 900 )
			self:CreateFlare( Pos, self:LocalToWorldAngles( Angle(5,10,0) + AngOffset ):Forward(), Vel + 600 )
			self:CreateFlare( Pos, self:LocalToWorldAngles( Angle(5,-10,0) + AngOffset ):Forward(), Vel + 600 )
			self:CreateFlare( Pos, self:LocalToWorldAngles( Angle(5,20,0) + AngOffset ):Forward(), Vel + 300 )
			self:CreateFlare( Pos, self:LocalToWorldAngles( Angle(5,-20,0) + AngOffset ):Forward(), Vel + 300 )
			self:EmitSound("weapons/flaregun/fire.wav",85,125,0.15)
		end )
	end
end

function ENT:OnMissileSeek( missile )
	LVS:SendMissileAlert( self, missile )
	self._MissileAlertTime = CurTime() + 0.5
end

function ENT:OnMissileLock( missile )
	LVS:SendMissileAlert( self, missile )
	self._MissileAlertTime = CurTime() + 0.5
end

function ENT:GetMissileOffset()
	return self:OBBCenter()
end