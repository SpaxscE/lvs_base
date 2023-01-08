include("shared.lua")

ENT.EngineFXPos = {
	Vector(-104.75,0,31.59),
	Vector(-104.75,-27.74,-15.54),
	Vector(-104.75,27.74,-15.54),
}

function ENT:OnSpawn()
	self:RegisterTrail( Vector(-120,0,31.59), 0, 20, 2, 1000, 150 )
	self:RegisterTrail( Vector(-120,-27.74,-15.54), 0, 20, 2, 1000, 150 )
	self:RegisterTrail( Vector(-120,27.74,-15.54), 0, 20, 2, 1000, 150 )
end

function ENT:OnFrame()
	self:EngineEffects()
end

ENT.EngineGlow = Material( "sprites/light_glow02_add" )

function ENT:PostDrawTranslucent()
	if not self:GetEngineActive() then return end

	local Size = 80 + self:GetThrottle() * 40 + self:GetBoost() * 0.8

	render.SetMaterial( self.EngineGlow )
	render.DrawSprite( self:LocalToWorld( Vector(-120,0,31.59) ), Size, Size, Color( 255, 100, 0, 255) )
	render.DrawSprite( self:LocalToWorld( Vector(-120,-27.74,-15.54) ), Size, Size, Color( 255, 100, 0, 255) )
	render.DrawSprite( self:LocalToWorld( Vector(-120,27.74,-15.54) ), Size, Size, Color( 255, 100, 0, 255) )

	render.DrawSprite( self:LocalToWorld( Vector(79,16.99,9.81) ), 16, 16, Color( 255, 0, 0, 255) )
	render.DrawSprite( self:LocalToWorld( Vector(84,13.55,8.05) ), 12, 12, Color( 255, 0, 0, 255) )

	render.DrawSprite( self:LocalToWorld( Vector(79,-16.99,9.81) ), 16, 16, Color( 255, 0, 0, 255) )
	render.DrawSprite( self:LocalToWorld( Vector(84,-13.55,8.05) ), 12, 12, Color( 255, 0, 0, 255) )
end

function ENT:EngineEffects()
	if not self:GetEngineActive() then return end

	local T = CurTime()

	if (self.nextEFX or 0) > T then return end

	self.nextEFX = T + 0.01

	local THR = self:GetThrottle()

	local emitter = self:GetParticleEmitter( self:GetPos() )

	if not IsValid( emitter ) then return end

	for _, v in pairs( self.EngineFXPos ) do
		local Sub = Mirror and 1 or -1
		local vOffset = self:LocalToWorld( v )
		local vNormal = -self:GetForward()

		vOffset = vOffset + vNormal * 5

		local particle = emitter:Add( "effects/muzzleflash2", vOffset )

		if not particle then continue end

		particle:SetVelocity( vNormal * math.Rand(500,1000) + self:GetVelocity() )
		particle:SetLifeTime( 0 )
		particle:SetDieTime( 0.1 )
		particle:SetStartAlpha( 255 )
		particle:SetEndAlpha( 0 )
		particle:SetStartSize( math.Rand(15,25) )
		particle:SetEndSize( math.Rand(0,10) )
		particle:SetRoll( math.Rand(-1,1) * 100 )
		
		particle:SetColor( 255, 100, 200 )
	end
end

function ENT:OnStartBoost()
	self:EmitSound( "lvs/vehicles/vulturedroid/boost.wav", 85 )
end

function ENT:OnStopBoost()
	self:EmitSound( "lvs/vehicles/vulturedroid/brake.wav", 85 )
end
