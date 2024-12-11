
ENT._armorParts = {}
ENT._dmgParts = {}

ENT.DSArmorDamageReduction = 0.1
ENT.DSArmorDamageReductionType = DMG_BULLET + DMG_CLUB

ENT.DSArmorIgnoreDamageType = DMG_SONIC
ENT.DSArmorIgnoreForce = 0

ENT.DSArmorBulletPenetrationAdd = 250

function ENT:AddDS( data )
	if not data then return end

	data.pos = data.pos or Vector(0,0,0)
	data.ang = data.ang or Angle(0,0,0)
	data.mins = data.mins or Vector(-1,-1,-1)
	data.maxs = data.maxs or Vector(1,1,1)
	data.Callback = data.Callback or function( tbl, ent, dmginfo ) end

	debugoverlay.BoxAngles( self:LocalToWorld( data.pos ), data.mins, data.maxs, self:LocalToWorldAngles( data.ang ), 5, Color( 50, 0, 50, 150 ) )

	table.insert( self._dmgParts, data )
end

function ENT:AddDSArmor( data )
	if not data then return end

	data.pos = data.pos or Vector(0,0,0)
	data.ang = data.ang or Angle(0,0,0)
	data.mins = data.mins or Vector(-1,-1,-1)
	data.maxs = data.maxs or Vector(1,1,1)
	data.Callback = data.Callback or function( tbl, ent, dmginfo ) end

	debugoverlay.BoxAngles( self:LocalToWorld( data.pos ), data.mins, data.maxs, self:LocalToWorldAngles( data.ang ), 5, Color( 0, 50, 50, 150 ) )

	table.insert( self._armorParts, data )
end

function ENT:CalcComponentDamage( dmginfo )
	local Len = self:BoundingRadius()
	local dmgPos = dmginfo:GetDamagePosition()
	local dmgDir = dmginfo:GetDamageForce():GetNormalized()
	local dmgPenetration = dmgDir * self.DSArmorBulletPenetrationAdd

	debugoverlay.Line( dmgPos - dmgDir * self.DSArmorBulletPenetrationAdd, dmgPos + dmgPenetration, 4, Color( 0, 0, 255 ) )

	local closestPart
	local closestDist = Len * 2
	local HitDistance

	for index, part in ipairs( self._armorParts ) do
		local mins = part.mins
		local maxs = part.maxs
		local pos = self:LocalToWorld( part.pos )
		local ang = self:LocalToWorldAngles( part.ang )

		local HitPos, HitNormal, Fraction = util.IntersectRayWithOBB( dmgPos, dmgPenetration, pos, ang, mins, maxs )

		if HitPos then
			debugoverlay.Cross( HitPos, 50, 4, Color( 255, 0, 255 ) )

			local dist = (HitPos - dmgPos):Length()

			if closestDist > dist then
				closestPart = part
				closestDist = dist
				HitDistance = (HitPos - dmgPos):Length()
			end
		end
	end

	local lastPartDS
	local closestPartDS
	local closestDistDS = Len * 2
	for index, part in ipairs( self._dmgParts ) do
		local mins = part.mins
		local maxs = part.maxs
		local pos = self:LocalToWorld( part.pos )
		local ang = self:LocalToWorldAngles( part.ang )

		local HitPos, HitNormal, Fraction = util.IntersectRayWithOBB( dmgPos, dmgPenetration, pos, ang, mins, maxs )

		if HitPos and HitDistance then
			lastPartDS = part

			if HitDistance < (HitPos - dmgPos):Length() then continue end

			closestPart = nil
			closestDist = Len * 2
		end

		if not HitPos then continue end

		debugoverlay.Cross( HitPos, 50, 4, Color( 255, 0, 255 ) )

		local dist = (HitPos - pos):Length()

		if closestDistDS > dist then
			closestPartDS = part
			closestDistDS = dist
		end
	end

	local Hit = false
	for index, part in pairs( self._dmgParts ) do
		local mins = part.mins
		local maxs = part.maxs
		local pos = self:LocalToWorld( part.pos )
		local ang = self:LocalToWorldAngles( part.ang )

		if part == closestPartDS then
			Hit = true
			part:Callback( self, dmginfo )
			debugoverlay.BoxAngles( pos, mins, maxs, ang, 1, Color( 255, 0, 0, 150 ) )
		end
	end

	for index, part in pairs( self._armorParts ) do
		local mins = part.mins
		local maxs = part.maxs
		local pos = self:LocalToWorld( part.pos )
		local ang = self:LocalToWorldAngles( part.ang )

		if part == closestPart then
			if not part:Callback( self, dmginfo ) then
				lastPartDS = nil
			end

			debugoverlay.BoxAngles( pos, mins, maxs, ang, 1, Color( 0, 150, 0, 150 ) )
		end
	end

	if lastPartDS then
		lastPartDS:Callback( self, dmginfo )

		local mins = lastPartDS.mins
		local maxs = lastPartDS.maxs
		local pos = self:LocalToWorld( lastPartDS.pos )
		local ang = self:LocalToWorldAngles( lastPartDS.ang )

		debugoverlay.BoxAngles( pos, mins, maxs, ang, 1, Color( 255, 0, 0, 150 ) )

		Hit = false
	end

	return Hit
end

function ENT:CalcDamage( dmginfo )
	if dmginfo:IsDamageType( self.DSArmorIgnoreDamageType ) then return end

	if dmginfo:IsDamageType( self.DSArmorDamageReductionType ) then
		if dmginfo:GetDamage() ~= 0 then
			dmginfo:ScaleDamage( self.DSArmorDamageReduction )

			dmginfo:SetDamage( math.max(dmginfo:GetDamage(),1) )
		end
	end

	local IsFireDamage = dmginfo:IsDamageType( DMG_BURN )
	local IsCollisionDamage = dmginfo:GetDamageType() == (DMG_CRUSH + DMG_VEHICLE)
	local CriticalHit = false

	if dmginfo:GetDamageForce():Length() < self.DSArmorIgnoreForce and not IsFireDamage then return end

	if not IsCollisionDamage then
		CriticalHit = self:CalcComponentDamage( dmginfo )
	end

	local Damage = dmginfo:GetDamage()

	if Damage <= 0 then return end

	local CurHealth = self:GetHP()

	local NewHealth = math.Clamp( CurHealth - Damage, -self:GetMaxHP(), self:GetMaxHP() )

	self:SetHP( NewHealth )

	if self:IsDestroyed() then return end

	local Attacker = dmginfo:GetAttacker() 

	if IsValid( Attacker ) and Attacker:IsPlayer() and not IsFireDamage then
		net.Start( "lvs_hitmarker" )
			net.WriteBool( CriticalHit )
		net.Send( Attacker )
	end

	if Damage > 1 and not IsCollisionDamage and not IsFireDamage then
		net.Start( "lvs_hurtmarker" )
			net.WriteFloat( math.min( Damage / 50, 1 ) )
		net.Send( self:GetEveryone() )
	end

	if NewHealth <= 0 then
		self.FinalAttacker = dmginfo:GetAttacker() 
		self.FinalInflictor = dmginfo:GetInflictor()

		self:SetDestroyed( IsCollisionDamage )

		self:ClearPDS()

		local Attacker = self.FinalAttacker
		if IsValid( Attacker ) and Attacker:IsPlayer() then
			net.Start( "lvs_killmarker" )
			net.Send( Attacker )
		end

		local ExplodeTime = self:PreExplode( math.Clamp((self:GetVelocity():Length() - 200) / 200,1.5,16) )

		timer.Simple( ExplodeTime, function()
			if not IsValid( self ) then return end
			self:Explode()
		end)
	end
end

function ENT:PreExplode( ExplodeTime )
	self:OnStartExplosion()

	local PhysObj = self:GetPhysicsObject()

	if not IsValid( PhysObj ) then return 0 end

	self:OnStartFireTrail( PhysObj, ExplodeTime )

	return ExplodeTime
end

function ENT:FindDS( PosToCheck, RadiusAdd )

	if not isnumber( RadiusAdd ) then
		RadiusAdd = 1
	end

	local closestPart
	local closestDist = 50000

	local ToCenter = (self:LocalToWorld( self:OBBCenter() ) - PosToCheck):GetNormalized()

	debugoverlay.Cross( PosToCheck, 50, 4, Color( 255, 255, 0 ) )

	for _, tbl in ipairs( { self._armorParts, self._dmgParts } ) do
		for index, part in ipairs( tbl ) do
			local mins = part.mins
			local maxs = part.maxs
			local pos = self:LocalToWorld( part.pos )
			local ang = self:LocalToWorldAngles( part.ang )

			local HitPos, HitNormal, Fraction = util.IntersectRayWithOBB( PosToCheck, ToCenter * RadiusAdd, pos, ang, mins, maxs )

			if HitPos then
				local dist = (HitPos - PosToCheck):Length()

				if closestDist > dist then
					closestPart = part
					closestDist = dist
				end
			end
		end
	end

	if closestPart then
		local mins = closestPart.mins
		local maxs = closestPart.maxs
		local pos = self:LocalToWorld( closestPart.pos )
		local ang = self:LocalToWorldAngles( closestPart.ang )
		debugoverlay.BoxAngles( pos, mins, maxs, ang, 1, Color( 255, 255, 0, 150 ) )
	end

	return closestPart
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

function ENT:HurtPlayer( ply, dmg, attacker, inflictor )
	if not IsValid( ply ) then return end

	if not IsValid( attacker ) then
		attacker = game.GetWorld()
	end

	if not IsValid( inflictor ) then
		inflictor = game.GetWorld()
	end

	local dmginfo = DamageInfo()
	dmginfo:SetDamage( dmg )
	dmginfo:SetAttacker( attacker )
	dmginfo:SetInflictor( inflictor )
	dmginfo:SetDamageType( DMG_DIRECT )

	ply:TakeDamageInfo( dmginfo )
end

function ENT:Explode()
	if self.ExplodedAlready then return end

	self.ExplodedAlready = true

	local Driver = self:GetDriver()

	if IsValid( Driver ) then
		self:HurtPlayer( Driver, Driver:Health() + Driver:Armor(), self.FinalAttacker, self.FinalInflictor )
	end

	if istable( self.pSeats ) then
		for _, pSeat in pairs( self.pSeats ) do
			if not IsValid( pSeat ) then continue end

			local psgr = pSeat:GetDriver()
			if not IsValid( psgr ) then continue end

			self:HurtPlayer( psgr, psgr:Health() + psgr:Armor(), self.FinalAttacker, self.FinalInflictor )
		end
	end

	self:OnFinishExplosion()

	self:Remove()
end

function ENT:OnStartExplosion()
	local effectdata = EffectData()
		effectdata:SetOrigin( self:GetPos() )
	util.Effect( "lvs_explosion_nodebris", effectdata )
end

function ENT:OnFinishExplosion()
	local ent = ents.Create( "lvs_destruction" )

	if not IsValid( ent ) then return end

	ent:SetModel( self:GetModel() )
	ent:SetPos( self:GetPos() )
	ent:SetAngles( self:GetAngles() )
	ent.GibModels = self.GibModels
	ent.Vel = self:GetVelocity()
	ent:Spawn()
	ent:Activate()
end

function ENT:OnStartFireTrail( PhysObj, ExplodeTime )
	local effectdata = EffectData()
		effectdata:SetOrigin( self:GetPos() )
		effectdata:SetStart( PhysObj:GetMassCenter() )
		effectdata:SetEntity( self )
		effectdata:SetScale( (self.FireTrailScale or 1) )
		effectdata:SetMagnitude( ExplodeTime )
	util.Effect( "lvs_firetrail", effectdata )
end

function ENT:IsDestroyed()
	return self.Destroyed == true
end

function ENT:OnDestroyed()
end

util.AddNetworkString( "lvs_vehicle_destroy" )

function ENT:SetDestroyed( SuppressOnDestroy )
	if self.Destroyed then return end

	self.Destroyed = true

	hook.Run( "LVS.OnVehicleDestroyed", self, self.FinalAttacker, self.FinalInflictor )

	hook.Run( "LVS.UpdateRelationship", self )

	if SuppressOnDestroy then return end

	self:OnDestroyed()

	net.Start("lvs_vehicle_destroy")
		net.WriteEntity( self )
	net.SendPAS( self:GetPos() )
end

include("sv_damagesystem_armor.lua")
