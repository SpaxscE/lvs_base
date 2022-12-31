
ENT._dmgParts = {}

function ENT:AddDS( data )
	if not data then return end

	data.pos = data.pos or Vector(0,0,0)
	data.ang = data.ang or Angle(0,0,0)
	data.mins = data.mins or Vector(-1,-1,-1)
	data.maxs = data.maxs or Vector(1,1,1)
	data.Callback = data.Callback or function( tbl, ent, dmginfo ) end

	debugoverlay.BoxAngles( self:LocalToWorld( data.pos ), data.mins, data.maxs, self:LocalToWorldAngles( data.ang ), 5, Color( 50, 50, 50, 150 ) )

	table.insert( self._dmgParts, data )
end

function ENT:CalcDamage( dmginfo )

	if dmginfo:IsDamageType( DMG_SONIC ) then return end

	if dmginfo:IsDamageType( DMG_BULLET ) then
		dmginfo:ScaleDamage( 0.01 )
	end

	local Len = self:BoundingRadius()
	local dmgPos = dmginfo:GetDamagePosition()
	local dmgDir = dmginfo:GetDamageForce():GetNormalized()
	local dmgPenetration = dmgDir * 250

	debugoverlay.Line( dmgPos - dmgDir * 250, dmgPos + dmgPenetration, 4, Color( 0, 0, 255 ) )

	local HitCrit = false
	local closestPart
	local closestDist = Len * 2

	for index, part in pairs( self._dmgParts ) do
		local mins = part.mins
		local maxs = part.maxs
		local pos = self:LocalToWorld( part.pos )
		local ang = self:LocalToWorldAngles( part.ang )

		local HitPos, HitNormal, Fraction = util.IntersectRayWithOBB( dmgPos, dmgPenetration, pos, ang, mins, maxs )

		if HitPos then
			debugoverlay.Cross( HitPos, 50, 4, Color( 255, 0, 255 ) )

			local dist = (HitPos - pos):Length()

			if closestDist > dist then
				closestPart = part
				closestDist = dist
			end
		end
	end

	for index, part in pairs( self._dmgParts ) do
		local mins = part.mins
		local maxs = part.maxs
		local pos = self:LocalToWorld( part.pos )
		local ang = self:LocalToWorldAngles( part.ang )

		if part == closestPart then
			HitCrit = true
			part:Callback( self, dmginfo )
			debugoverlay.BoxAngles( pos, mins, maxs, ang, 1, Color( 255, 0, 0, 150 ) )
		else
			debugoverlay.BoxAngles( pos, mins, maxs, ang, 1, Color( 100, 100, 100, 150 ) )
		end
	end

	local Damage = math.max( dmginfo:GetDamage(), 1 )

	local CurHealth = self:GetHP()

	local NewHealth = math.Clamp( CurHealth - Damage, -self:GetMaxHP(), self:GetMaxHP() )

	self:SetHP( NewHealth )

	if self:IsDestroyed() then return end

	local Attacker = dmginfo:GetAttacker() 

	if IsValid( Attacker ) and Attacker:IsPlayer() then
		net.Start( "lvs_hitmarker" )
			net.WriteBool( HitCrit )
		net.Send( Attacker )
	end

	if NewHealth <= 0 then
		self:SetDestroyed()

		self.FinalAttacker = dmginfo:GetAttacker() 
		self.FinalInflictor = dmginfo:GetInflictor()

		local Attacker = self.FinalAttacker
		if IsValid( Attacker ) and Attacker:IsPlayer() then
			net.Start( "lvs_killmarker" )
			net.Send( Attacker )
		end

		local ExplodeTime = math.Clamp((self:GetVelocity():Length() - 250) / 500,1.5,8)

		local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
		util.Effect( "lvs_explosion_nodebris", effectdata )

		local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
			effectdata:SetStart( self:GetPhysicsObject():GetMassCenter() )
			effectdata:SetEntity( self )
			effectdata:SetScale( 1 )
			effectdata:SetMagnitude( ExplodeTime )
		util.Effect( "lvs_firetrail", effectdata )

		timer.Simple( ExplodeTime, function()
			if not IsValid( self ) then return end
			self:Explode()
		end)
	end
end

function ENT:DamageThink()
	if self.MarkForDestruction then
		self:Explode()
	end

	if self:IsDestroyed() then
		if self:GetVelocity():Length() < 800 then
			self:Explode()
		end
	end
end

function ENT:Explode()
	if self.ExplodedAlready then return end

	self.ExplodedAlready = true

	local Driver = self:GetDriver()
	local Gunner = self:GetGunner()

	if IsValid( Driver ) then
		Driver:TakeDamage( 1000, self.FinalAttacker or Entity(0), self.FinalInflictor or Entity(0) )
	end

	if IsValid( Gunner ) then
		Gunner:TakeDamage( 1000, self.FinalAttacker or Entity(0), self.FinalInflictor or Entity(0) )
	end

	if istable( self.pSeats ) then
		for _, pSeat in pairs( self.pSeats ) do
			if IsValid( pSeat ) then
				local psgr = pSeat:GetDriver()
				if IsValid( psgr ) then
					psgr:TakeDamage( 1000, self.FinalAttacker or Entity(0), self.FinalInflictor or Entity(0) )
				end
			end
		end
	end

	local ent = ents.Create( "lvs_destruction" )
	if IsValid( ent ) then
		ent:SetPos( self:LocalToWorld( self:OBBCenter() ) )
		ent:SetAngles( self:GetAngles() )
		ent.GibModels = self.GibModels
		ent.Vel = self:GetVelocity()
		ent:Spawn()
		ent:Activate()
	end

	self:Remove()
end

function ENT:IsDestroyed()
	return self.Destroyed == true
end

function ENT:OnDestroyed()
end

util.AddNetworkString( "lvs_vehicle_destroy" )

function ENT:SetDestroyed()
	if self.Destroyed then return end

	self.Destroyed = true

	self:OnDestroyed()

	net.Start("lvs_vehicle_destroy")
		net.WriteEntity( self )
	net.SendPAS( self:GetPos() )
end
