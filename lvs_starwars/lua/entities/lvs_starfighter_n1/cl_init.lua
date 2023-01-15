include("shared.lua")

function ENT:OnSpawn()
	self:RegisterTrail( Vector(-95,143.87,30.93), 0, 20, 2, 2500, 150 )
	self:RegisterTrail( Vector(-95,-143.87,30.93), 0, 20, 2, 2500, 150 )
end

function ENT:OnFrame()
	self:EngineEffects()
	self:AnimAstromech()
	self:AnimCockpit()
end

ENT.EngineGlow = Material( "sprites/light_glow02_add" )

function ENT:PostDrawTranslucent()
	if not self:GetEngineActive() then return end

	local Size = 80 + self:GetThrottle() * 120 + self:GetBoost()

	render.SetMaterial( self.EngineGlow )

	for i = -1,1,2 do
		local pos = self:LocalToWorld( Vector(20,143.87 * i,30.93) )
		render.DrawSprite( pos, Size, Size, Color( 0, 127, 255, 255) )
	end
end

function ENT:EngineEffects()
	if not self:GetEngineActive() then return end

	local T = CurTime()

	if (self.nextEFX or 0) > T then return end

	self.nextEFX = T + 0.01

	local THR = self:GetThrottle()

	local emitter = self:GetParticleEmitter( self:GetPos() )

	if not IsValid( emitter ) then return end

	for i = -1,1,2 do
		local vOffset = self:LocalToWorld( Vector(41,143.87 * i,30.93) )
		local vNormal = -self:GetForward()

		vOffset = vOffset + vNormal * 5

		local particle = emitter:Add( "effects/select_ring", vOffset )

		if not particle then continue end

		particle:SetVelocity( vNormal * (1000 + self:GetBoost() * 10) + self:GetVelocity() )
		particle:SetLifeTime( 0 )
		particle:SetDieTime( 0.05 )
		particle:SetStartAlpha( 255 )
		particle:SetEndAlpha( 0 )
		particle:SetStartSize( 20 )
		particle:SetEndSize( 20 )
		particle:SetAngles( vNormal:Angle() )
		particle:SetColor( math.Rand( 10, 100 ), math.Rand( 100, 220 ), math.Rand( 240, 255 ) )
	end
end

function ENT:AnimAstromech()
	local T = CurTime()

	if (self.nextAstro or 0) < T then
		self.nextAstro = T + math.Rand(0.5,2)
		self.AstroAng = math.Rand(-180,180)

		local HasShield = self:GetShield() > 0

		if self.OldShield == true and not HasShield then
			self:EmitSound( "lvs/vehicles/naboo_n1_starfighter/astromech/shieldsdown"..math.random(1,2)..".ogg", 100 )
		else
			if math.random(0,4) == 3 then
				self:EmitSound( "lvs/vehicles/naboo_n1_starfighter/astromech/"..math.random(1,11)..".ogg", 70 )
			end
		end
		
		self.OldShield = HasShield
	end

	self.smastro = self.smastro and (self.smastro + ((self.AstroAng or 0) - self.smastro) * RealFrameTime() * 10) or 0

	self:ManipulateBoneAngles( 2, Angle(self.smastro,0,0) )
end

function ENT:AnimCockpit()
	local bOn = self:GetActive()

	local TVal = bOn and 0 or 1

	local Speed = FrameTime() * 4

	self.SMcOpen = self.SMcOpen and self.SMcOpen + math.Clamp(TVal - self.SMcOpen,-Speed,Speed) or 0

	self:ManipulateBonePosition( 1, Vector(0,0,self.SMcOpen * 50) ) 
end

function ENT:OnStartBoost()
	self:EmitSound( "lvs/vehicles/naboo_n1_starfighter/boost.wav", 85 )
end

function ENT:OnStopBoost()
	self:EmitSound( "lvs/vehicles/naboo_n1_starfighter/brake.wav", 85 )
end
