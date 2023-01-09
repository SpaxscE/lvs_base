include("shared.lua")

ENT.EngineColor = Color( 255, 220, 150, 255)
ENT.EngineGlow = Material( "sprites/light_glow02_add" )
ENT.EngineCenter = Material( "vgui/circle" )
ENT.EnginePos = {
	[1] = Vector(-155,0,76.85),
	[2] = Vector(-155,0,41.82),
}

function ENT:CalcViewOverride( ply, pos, angles, fov, pod )
	if self:GetDriver() == ply then
		local newpos = pos + self:GetForward() * 37 + self:GetUp() * 8

		return newpos, angles, fov
	else
		return pos, angles, fov
	end
end

function ENT:OnSpawn()
	self:RegisterTrail( Vector(-152,55,55), 0, 20, 2, 1000, 150 )
	self:RegisterTrail( Vector(-152,-55,55), 0, 20, 2, 1000, 150 )
end

function ENT:OnFrame()
	self:EngineEffects()
	self:AnimWings()
end

function ENT:AnimWings()
	self._sm_wing = self._sm_wing or 1

	local target_wing = self:GetFoils() and 0 or 1
	local RFT = RealFrameTime() * (0.5 + math.abs( math.sin( self._sm_wing * math.pi ) ) * 0.5)
	local RateUp = RFT * 2
	local RateDown = RFT * 1.5

	self._sm_wing = self._sm_wing + math.Clamp(target_wing - self._sm_wing,-RateDown,RateUp)

	local DoneMoving = self._sm_wing == 1 or self._sm_wing == 0

	if self._oldDoneMoving ~= DoneMoving then
		self._oldDoneMoving = DoneMoving
		if not DoneMoving then
			self:EmitSound("lvs/vehicles/vwing/sfoils.wav")
		end
	end

	self:SetPoseParameter( "wings", 1 - self._sm_wing )

	self:InvalidateBoneCache()
end

function ENT:EngineEffects()
	if not self:GetEngineActive() then return end

	local T = CurTime()

	if (self.nextEFX or 0) > T then return end

	self.nextEFX = T + 0.01

	local THR = self:GetThrottle()

	local emitter = self:GetParticleEmitter( self:GetPos() )

	if not IsValid( emitter ) then return end

	for _, pos in pairs( self.EnginePos ) do
		local vOffset = self:LocalToWorld( pos )
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
		particle:SetColor( 255, 200, 50 )
	end
end

function ENT:PostDraw()
	if not self:GetEngineActive() then return end

	cam.Start3D2D( self:LocalToWorld( Vector(-136,0,76.85) ), self:LocalToWorldAngles( Angle(-90,0,0) ), 1 )
		surface.SetDrawColor( self.EngineColor )
		surface.SetMaterial( self.EngineCenter )
		surface.DrawTexturedRectRotated( 0, 0, 20, 20 , 0 )
		surface.SetDrawColor( color_white )
		surface.SetMaterial( self.EngineGlow )
		surface.DrawTexturedRectRotated( 0, 0, 20, 20 , 0 )
	cam.End3D2D()
	
	cam.Start3D2D( self:LocalToWorld( Vector(-136,0,41.82) ), self:LocalToWorldAngles( Angle(-90,0,0) ), 1 )
		surface.SetDrawColor( self.EngineColor )
		surface.SetMaterial( self.EngineCenter )
		surface.DrawTexturedRectRotated( 0, 0, 20, 20 , 0 )
		surface.SetDrawColor( color_white )
		surface.SetMaterial( self.EngineGlow )
		surface.DrawTexturedRectRotated( 0, 0, 20, 20 , 0 )
	cam.End3D2D()
end

function ENT:PostDrawTranslucent()
	if not self:GetEngineActive() then return end

	local Size = 60 + self:GetThrottle() * 60 + self:GetBoost()

	render.SetMaterial( self.EngineGlow )

	for _, pos in pairs( self.EnginePos ) do
		render.DrawSprite(  self:LocalToWorld( pos ), Size, Size, self.EngineColor )
	end
end

function ENT:OnStartBoost()
	self:EmitSound( "lvs/vehicles/vwing/boost.wav", 85 )
end

function ENT:OnStopBoost()
	self:EmitSound( "lvs/vehicles/vwing/brake.wav", 85 )
end
