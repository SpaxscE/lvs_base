include("shared.lua")

function ENT:PreDraw()
	return false
end

function ENT:PreDrawTranslucent()
	return false
end

function ENT:DamageFX()
	self.nextDFX = self.nextDFX or 0

	if self.nextDFX < CurTime() then
		self.nextDFX = CurTime() + 0.05

		local HP = self:GetHP()
		local MaxHP = self:GetMaxHP()

		if HP > MaxHP * 0.25 then return end

		local effectdata = EffectData()
			effectdata:SetOrigin( self:LocalToWorld( Vector(-60,0,-10) ) )
			effectdata:SetNormal( self:GetUp() )
			effectdata:SetMagnitude( math.Rand(0.5,1.5) )
			effectdata:SetEntity( self )
		util.Effect( "lvs_exhaust_fire", effectdata )
	end
end

function ENT:OnFrame()
	self:AnimRotor()
	self:DamageFX()
end

function ENT:AnimRotor()
	local RPM = self:GetThrottle() * 2500

	self.RPM = self.RPM and (self.RPM + RPM * RealFrameTime() * 0.5) or 0

	local Rot = Angle( -self.RPM,0,0)
	Rot:Normalize() 

	local Body = self:GetBody()

	if not IsValid( Body ) then return end

	Body:ManipulateBoneAngles( 19, Rot )
end
