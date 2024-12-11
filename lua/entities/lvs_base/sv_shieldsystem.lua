
ENT.ShieldRechargeDelay = 5
ENT.ShieldRechargeRate = 1
ENT.ShieldBlockableTypes = {
	[1] = DMG_BULLET,
	[2] = DMG_AIRBOAT,
	[3] = DMG_BUCKSHOT,
	[4] = DMG_SNIPER,
	[5] = DMG_BLAST,
}

function ENT:CalcShieldDamage( dmginfo )
	local MaxShield = self:GetMaxShield()

	if MaxShield <= 0 then return end

	local DMG_ENUM = DMG_GENERIC
	for _, ENUM in ipairs( self.ShieldBlockableTypes ) do
		DMG_ENUM = DMG_ENUM + ENUM
	end

	if not dmginfo:IsDamageType( DMG_ENUM ) then return end

	self:DelayNextShieldRecharge( self.ShieldRechargeDelay )

	local DamageRemaining = self:TakeShieldDamage( dmginfo:GetDamage() )

	dmginfo:SetDamage( DamageRemaining )

	self:OnTakeShieldDamage( dmginfo )
end

function ENT:CanShieldRecharge()
	return (self.NextShieldRecharge or 0) < CurTime()
end

function ENT:DelayNextShieldRecharge( delay )
	self.NextShieldRecharge = CurTime() + delay
end

function ENT:ShieldThink()
	local MaxShield = self:GetMaxShield()

	if MaxShield <= 0 or self:GetShieldPercent() == 1 then return end

	if not self:CanShieldRecharge() then return end

	local Cur = self:GetShield()
	local Rate = FrameTime() * 20 * self.ShieldRechargeRate

	self:SetShield( Cur + math.Clamp(MaxShield - Cur,-Rate,Rate) )
end

function ENT:TakeShieldDamage( damage )
	local cur = self:GetShield()
	local sub = cur - damage
	local new = math.Clamp( sub , 0, self:GetMaxShield() )

	self:SetShield( new )

	if sub < 0 then
		return math.abs( sub )
	else
		return 0
	end
end

function ENT:OnTakeShieldDamage( dmginfo )
	if dmginfo:GetDamage() ~= 0 then return end

	local dmgNormal = -dmginfo:GetDamageForce():GetNormalized() 
	local dmgPos = dmginfo:GetDamagePosition()

	dmginfo:SetDamagePosition( dmgPos + dmgNormal * 250 * self:GetShieldPercent() )

	local effectdata = EffectData()
		effectdata:SetOrigin( dmginfo:GetDamagePosition() )
		effectdata:SetEntity( self )
	util.Effect( "lvs_shield_impact", effectdata )
end