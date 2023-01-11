include("shared.lua")

function ENT:OnSpawn()
	self:RegisterTrail( Vector(-151,87,15), 0, 20, 2, 1000, 150 )
	self:RegisterTrail( Vector(-151,-87,15), 0, 20, 2, 1000, 150 )
	self:RegisterTrail( Vector(-151,87,-15), 0, 20, 2, 1000, 150 )
	self:RegisterTrail( Vector(-151,-87,-15), 0, 20, 2, 1000, 150 )
end

function ENT:OnFrame()
end

ENT.EngineGlow = Material( "sprites/light_glow02_add" )
ENT.EngineFXColor = Color( 38, 0, 230, 255)
ENT.EngineFxPos = {
	Vector(-49.5,-45.31,1.9),
	Vector(-47,-48.39,1.8),
	Vector(-45,-51.55,1.7),
	Vector(-43,-54.71,1.6),
	Vector(-41,-57.97,1.5),
	Vector(-39,-60.82,1.4),
	Vector(-49.5,45.31,1.9),
	Vector(-47,48.39,1.8),
	Vector(-45,51.55,1.7),
	Vector(-43,54.71,1.6),
	Vector(-41,57.97,1.5),
	Vector(-39,60.82,1.4),
	Vector(-49.5,-45.31,-1.9),
	Vector(-47,-48.39,-1.8),
	Vector(-45,-51.55,-1.7),
	Vector(-43,-54.71,-1.6),
	Vector(-41,-57.97,-1.5),
	Vector(-39,-60.82,-1.4),
	Vector(-49.5,45.31,-1.9),
	Vector(-47,48.39,-1.8),
	Vector(-45,51.55,-1.7),
	Vector(-43,54.71,-1.6),
	Vector(-41,57.97,-1.5),
	Vector(-39,60.82,-1.4),
}

function ENT:PostDraw()
	if not self:GetEngineActive() then return end

	cam.Start3D2D( self:LocalToWorld( Vector(-36.2,-62.6,0) ), self:LocalToWorldAngles( Angle(0,299,90) ), 1 )
		draw.NoTexture()
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawTexturedRectRotated( -11, -1.5, 19.7, 6 , -3.4 )
		surface.DrawTexturedRectRotated( -11, 1.5, 19.7, 6 , 3.4 )
	cam.End3D2D()

	cam.Start3D2D( self:LocalToWorld( Vector(-36.2,62.6,0) ), self:LocalToWorldAngles( Angle(0,61,-90) ), 1 )
		draw.NoTexture()
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawTexturedRectRotated( -11, -1.5, 19.7, 6 , -3.4 )
		surface.DrawTexturedRectRotated( -11, 1.5, 19.7, 6 , 3.4 )
	cam.End3D2D()
end

function ENT:PostDrawTranslucent()
	if not self:GetEngineActive() then return end

	local Size = 30 + self:GetThrottle() * 15 + self:GetBoost() * 0.4

	render.SetMaterial( self.EngineGlow )

	for _, v in pairs( self.EngineFxPos ) do
		local pos = self:LocalToWorld( v )
		render.DrawSprite( pos, Size, Size, self.EngineFXColor )
	end
end

function ENT:OnStartBoost()
	self:EmitSound( "lvs/vehicles/vulturedroid/boost.wav", 85 )
end

function ENT:OnStopBoost()
	self:EmitSound( "lvs/vehicles/vulturedroid/brake.wav", 85 )
end
