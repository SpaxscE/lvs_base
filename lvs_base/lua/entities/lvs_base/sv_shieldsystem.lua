
function ENT:CalcShieldDamage( dmginfo )
	local MaxShield = self:GetMaxShield()

	if MaxShield <= 0 then return end

	if not dmginfo:IsBulletDamage() then return end

	self:DelayNextShieldRecharge( 3 )

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
	local Rate = FrameTime() * 30

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