
ENT.MissileAlert = true
ENT.MissileAlertDelayMin = 0.05
ENT.MissileAlertDelayMax = 0.4
ENT.MissileAlertDistance = 20000

function ENT:DoMissileDistraction()
	--[[
	if not self:CanDoMissileDistraction() then return end

	self:CreateFlares( Vector(50,0,-50), Angle(0,0,0), 4 )

	self:SetNextMissileDistraction( 4 )
	]]
end

function ENT:AIDoMissileDistraction()
	timer.Simple( math.Rand(0,0.5), function()
		if not IsValid( self ) then return end

		self:DoMissileDistraction()
	end )
end

function ENT:CanDoMissileDistraction()
	return (self._NextMissileDistraction or 0) < CurTime()
end

function ENT:SetNextMissileDistraction( T )
	self._NextMissileDistraction = CurTime() + T
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

	self._LastMissileFlare = ent

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

	for i = 2, NumBursts do
		timer.Simple( (i - 1) * 0.5, function()
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

	if self:GetAI() then
		self:AIDoMissileDistraction()
	end
end

function ENT:OnMissileLock( missile )
	LVS:SendMissileAlert( self, missile )

	if self:GetAI() then
		self:AIDoMissileDistraction()
	end
end

function ENT:GetMissileOffset()
	return self:OBBCenter()
end