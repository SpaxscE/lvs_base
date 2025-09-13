
ENT.FireTrailScale = 0.35
ENT.DSArmorBulletPenetrationAdd = 50

DEFINE_BASECLASS( "lvs_base" )

function ENT:OnTakeDamage( dmginfo )
	self.LastAttacker = dmginfo:GetAttacker() 
	self.LastInflictor = dmginfo:GetInflictor()

	BaseClass.OnTakeDamage( self, dmginfo )
end

function ENT:TakeCollisionDamage( damage, attacker )
	if not IsValid( attacker ) then
		attacker = game.GetWorld()
	end

	local Engine = self:GetEngine()

	if not IsValid( Engine ) then return end

	local dmginfo = DamageInfo()
	dmginfo:SetDamage(  (math.min(damage / 4000,1) ^ 2) * 200 )
	dmginfo:SetAttacker( attacker )
	dmginfo:SetInflictor( attacker )
	dmginfo:SetDamageType( DMG_CRUSH + DMG_VEHICLE )

	Engine:TakeTransmittedDamage( dmginfo )
end

function ENT:Explode()
	if self.ExplodedAlready then return end

	self.ExplodedAlready = true

	local Driver = self:GetDriver()

	if IsValid( Driver ) then
		self:HurtPlayer( Driver, 1000, self.FinalAttacker, self.FinalInflictor )
	end

	if istable( self.pSeats ) then
		for _, pSeat in pairs( self.pSeats ) do
			if not IsValid( pSeat ) then continue end

			local psgr = pSeat:GetDriver()
			if not IsValid( psgr ) then continue end

			self:HurtPlayer( psgr, 1000, self.FinalAttacker, self.FinalInflictor )
		end
	end

	self:OnFinishExplosion()

	if self.DeleteOnExplode or self.SpawnedByAISpawner then

		self:Remove()

		return
	end

	if self.MDL_DESTROYED then
		local numpp = self:GetNumPoseParameters() - 1
		local pps = {}

		for i = 0, numpp do
			local sPose = self:GetPoseParameterName( i )

			pps[ sPose ] = self:GetPoseParameter( sPose )
		end
	
		self:SetModel( self.MDL_DESTROYED )
		self:PhysicsDestroy()
		self:PhysicsInit( SOLID_VPHYSICS )

		for pName, pValue in pairs( pps ) do
			self:SetPoseParameter(pName, pValue)
		end
	else
		for id, group in pairs( self:GetBodyGroups() ) do
			for subid, subgroup in pairs( group.submodels ) do
				if subgroup == "" or string.lower( subgroup ) == "empty" then
					self:SetBodygroup( id - 1, subid )
				end
			end
		end
	end

	for _, ent in pairs( self:GetCrosshairFilterEnts() ) do
		if not IsValid( ent ) or ent == self then continue end

		ent:Remove()
	end

	for _, ent in pairs( self:GetChildren() ) do
		if not IsValid( ent ) then continue end

		ent:Remove()
	end

	self:SetDriver( NULL )

	self:RemoveWeapons()

	self:StopMotionController()

	self.DoNotDuplicate = true

	self:OnExploded()
end

function ENT:RemoveWeapons()
	self:WeaponsFinish()

	for _, pod in pairs( self:GetPassengerSeats() ) do
		local weapon = pod:lvsGetWeapon()

		if not IsValid( weapon ) then continue end

		weapon:WeaponsFinish()
	end

	self:WeaponsOnRemove()

	for id, _ in pairs( self.WEAPONS ) do
		self.WEAPONS[ id ] = {}
	end
end

function ENT:OnExploded()
	self:Ignite( 30 )

	local PhysObj = self:GetPhysicsObject()

	if not IsValid( PhysObj ) then return end

	PhysObj:SetVelocity( self:GetVelocity() + Vector(math.random(-5,5),math.random(-5,5),math.random(150,250)) )
end
