
function ENT:CanRechargeShield()
	return (self.NextShieldRecharge or 0) < CurTime()
end

function ENT:SetNextShieldRecharge( delay )
	self.NextShieldRecharge = CurTime() + delay
end

--[[
function ENT:RechargeShield()
	local MaxShield = self:GetMaxShield()

	if MaxShield <= 0 then return end

	if not self:CanRechargeShield() then return end

	local Cur = self:GetShield()
	local Rate = FrameTime() * 30

	self:SetShield( Cur + math.Clamp(MaxShield - Cur,-Rate,Rate) )
end
]]

function ENT:TakeShieldDamage( damage )
	local cur = self:GetShield()
	local new = math.Clamp( cur - damage , 0, self:GetMaxShield()  )

	self:SetShield( new )
end
