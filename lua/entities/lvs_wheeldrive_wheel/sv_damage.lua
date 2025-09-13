
ENT.DSDamageAllowedType = DMG_SLASH + DMG_AIRBOAT + DMG_BULLET + DMG_SNIPER + DMG_BUCKSHOT + DMG_PREVENT_PHYSICS_FORCE
ENT.DSArmorIgnoreForce = 0

function ENT:OnTakeDamage( dmginfo )
	local base = self:GetBase()

	if not IsValid( base ) then return end

	if self:GetWheelChainMode() then
		if dmginfo:IsDamageType( DMG_PREVENT_PHYSICS_FORCE ) then return end

		base:OnTakeDamage( dmginfo )

		return
	end

	local MaxArmor = self:GetMaxHP()
	local Damage = dmginfo:GetDamage()

	if not dmginfo:IsDamageType( DMG_PREVENT_PHYSICS_FORCE ) then
		local IsFireDamage = dmginfo:IsDamageType( DMG_BURN )

		if dmginfo:GetDamageForce():Length() < self.DSArmorIgnoreForce and not IsFireDamage then return end

		local MaxHealth = base:GetMaxHP()

		local ArmoredHealth = MaxHealth + MaxArmor
		local NumShotsToKill = ArmoredHealth / Damage

		local ScaleDamage =  math.Clamp( MaxHealth / (NumShotsToKill * Damage),0,1)

		dmginfo:ScaleDamage( ScaleDamage )

		base:OnTakeDamage( dmginfo )
	end

	if not dmginfo:IsDamageType( self.DSDamageAllowedType ) then return end

	if not isnumber( base.WheelPhysicsTireHeight ) or base.WheelPhysicsTireHeight <= 0 then return end

	local CurHealth = self:GetHP()

	local NewHealth = math.Clamp( CurHealth - Damage, 0, MaxArmor )

	self:SetHP( NewHealth )

	if NewHealth > 0 then
		self:StartLeakAir()

		return
	end

	self:DestroyTire()
end

function ENT:StartLeakAir()
	if self._IsLeakingAir then return end

	self._IsLeakingAir = true

	local ID = "lvsLeakAir"..self:EntIndex()

	timer.Create( ID, 0.2, 0, function()
		if not IsValid( self ) then timer.Remove( ID ) return end

		local dmg = DamageInfo()
		dmg:SetDamage( 1 )
		dmg:SetAttacker( self )
		dmg:SetInflictor( self )
		dmg:SetDamageType( DMG_PREVENT_PHYSICS_FORCE )
		self:TakeDamageInfo( dmg )
	end)
end

function ENT:StopLeakAir()
	if not self._IsLeakingAir then return end

	local ID = "lvsLeakAir"..self:EntIndex()

	timer.Remove( ID )

	self._IsLeakingAir = nil
end

function ENT:HealthValueChanged( name, old, new)
	if new == old or old > new or new ~= self:GetMaxHP() then return end

	self:RepairTire()
end

function ENT:DestroyTire()
	if self:GetNWDamaged() then return end

	self:SetNWDamaged( true )

	self:StopLeakAir()

	local base = self:GetBase()
	local PhysObj = self:GetPhysicsObject()

	if not IsValid( base ) or not IsValid( PhysObj ) then return end

	self._OldTirePhysProp = PhysObj:GetMaterial()

	PhysObj:SetMaterial( "glass" )

	self:EmitSound("lvs/wheel_pop"..math.random(1,4)..".ogg")

	local effectdata = EffectData()
	effectdata:SetOrigin( self:GetPos() )
	effectdata:SetEntity( base )
	effectdata:SetNormal( Vector(0,0,1) )
	util.Effect( "lvs_physics_wheelsmoke", effectdata, true, true )

	self._RestoreBodyGroups = {}

	for id, group in pairs( self:GetBodyGroups() ) do
		for subid, subgroup in pairs( group.submodels ) do
			if subgroup == "" or string.lower( subgroup ) == "empty" then

				local bodyGroupId = id - 1

				self._RestoreBodyGroups[ bodyGroupId ] = self:GetBodygroup( bodyGroupId )
	
				self:SetBodygroup( bodyGroupId, subid )
			end
		end
	end

	if not IsValid( self.SuspensionConstraintElastic ) then return end

	local Length = (self.SuspensionConstraintElastic:GetTable().length or 25) - base.WheelPhysicsTireHeight 

	self.SuspensionConstraintElastic:Fire( "SetSpringLength", math.max( Length - base.WheelPhysicsTireHeight , 1 ) )
end

function ENT:RepairTire()
	self:StopLeakAir()

	if not self._OldTirePhysProp then return end

	if istable( self._RestoreBodyGroups ) then
		for bodyGroupId, subid in pairs( self._RestoreBodyGroups ) do
			self:SetBodygroup( bodyGroupId, subid )
		end

		self._RestoreBodyGroups = nil
	end

	self:SetNWDamaged( false )
	self:SetSuspensionHeight( self._SuspensionHeightMultiplier )

	local PhysObj = self:GetPhysicsObject()

	if not IsValid( PhysObj ) or PhysObj:GetMaterial() ~= "glass" then
		goto FinishRepairTire
	end

	PhysObj:SetMaterial( self._OldTirePhysProp )

	-- coders from the industry hate this, so we use it intentionally to assert dominance
	:: FinishRepairTire ::

	self._OldTirePhysProp = nil
end

function ENT:IsTireDestroyed()
	return isstring( self._OldTirePhysProp )
end

function ENT:SetDamaged( new )
	if new == self:GetNWDamaged() then return end

	self:SetNWDamaged( new )

	if new then
		if not self._torqueFactor or self.old_torqueFactor then return end

		self.old_torqueFactor = self._torqueFactor
		self._torqueFactor = self._torqueFactor * 0.25

		return
	end

	if not self.old_torqueFactor then return end

	self._torqueFactor = self.old_torqueFactor
	self.old_torqueFactor = nil
end

function ENT:Destroy()
	if self:GetDestroyed() then return end

	self:SetDestroyed( true )
	self:SetDamaged( true )

	local Master = self:GetMaster()

	if not IsValid( Master ) or IsValid( self.bsLockDMG ) then return end

	local Fric = 10

	self.bsLockDMG = constraint.AdvBallsocket(self,Master,0,0,vector_origin,vector_origin,0,0,-180,-180,-180,180,180,180,Fric,Fric,Fric,1,1)
	self.bsLockDMG.DoNotDuplicate = true
end

function ENT:Repair()
	self:SetHP( self:GetMaxHP() )

	self:SetDestroyed( false )
	self:SetDamaged( false )

	if IsValid( self.bsLockDMG ) then
		self.bsLockDMG:Remove()
	end
end