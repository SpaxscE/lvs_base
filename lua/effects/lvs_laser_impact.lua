EFFECT.GlowMat = Material( "sprites/light_glow02_add" )

function EFFECT:Init( data )
	self.Pos = data:GetOrigin()
	self.Dir = data:GetNormal()
	self.Col = data:GetStart() or Vector(255,100,0)

	self.LifeTime = 0.2
	self.DieTime = CurTime() + self.LifeTime

	local trace = util.TraceLine( {
		start = self.Pos - self.Dir,
		endpos = self.Pos + self.Dir,
		mask = MASK_SOLID_BRUSHONLY,
	} )

	self.Flat = trace.Hit and not trace.HitSky

	local Col = self.Col
	local Pos = self.Pos

	local emitter = ParticleEmitter( Pos, false )

	for i = 0, 10 do
		local particle = emitter:Add( "sprites/light_glow02_add", Pos )

		local vel = VectorRand() * 200 + self.Dir  * 80

		if not particle then continue end

		particle:SetVelocity( vel )
		particle:SetAngles( vel:Angle() + Angle(0,90,0) )
		particle:SetDieTime( math.Rand(0.2,0.4) )
		particle:SetStartAlpha( 255 )
		particle:SetEndAlpha( 0 )
		particle:SetStartSize( math.Rand(12,24) )
		particle:SetEndSize( 0 )
		particle:SetRoll( math.Rand(-100,100) )
		particle:SetRollDelta( math.Rand(-100,100) )
		particle:SetColor( Col.x,Col.y,Col.z )
		particle:SetGravity( Vector(0,0,-600) )

		particle:SetAirResistance( 0 )

		particle:SetCollide( true )
		particle:SetBounce( 0.5 )
	end

	emitter:Finish()
end

function EFFECT:Think()
	if self.DieTime < CurTime() then return false end

	return true
end

function EFFECT:Render()
	local Scale = (self.DieTime - CurTime()) / self.LifeTime

	local S1 = 200 * Scale
	local S2 = 50 * Scale

	if self.Flat then
		cam.Start3D2D( self.Pos + self.Dir, self.Dir:Angle() + Angle(90,0,0), 1 )
			surface.SetMaterial( self.GlowMat )
			surface.SetDrawColor( self.Col.x, self.Col.y, self.Col.z, 255 )
			surface.DrawTexturedRectRotated( 0, 0, S1 , S1 , 0 )

			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.DrawTexturedRectRotated( 0, 0, S2 , S2 , 0 )
		cam.End3D2D()
	end

	render.SetMaterial( self.GlowMat )
	render.DrawSprite( self.Pos + self.Dir, S1, S1, Color( self.Col.x, self.Col.y, self.Col.z, 255 ) )
	render.DrawSprite( self.Pos + self.Dir, S2, S2, Color( 255, 255, 255, 255) )
end
