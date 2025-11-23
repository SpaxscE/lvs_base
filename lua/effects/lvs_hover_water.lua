
function EFFECT:Init( data )
	local Pos = data:GetOrigin()
	local Ent = data:GetEntity()
	self.Size = data:GetMagnitude()

	if not IsValid( Ent ) then return end

	self.LifeTime = math.Rand(1.5,3)
	self.DieTime = CurTime() + self.LifeTime

	local LightColor = render.GetLightColor( Pos )
	local VecCol = Vector(1,1.2,1.4) * (0.06 + (0.2126 * LightColor.r) + (0.7152 * LightColor.g) + (0.0722 * LightColor.b)) * 1000
	VecCol.x = math.min( VecCol.x, 255 )
	VecCol.y = math.min( VecCol.y, 255 )
	VecCol.z = math.min( VecCol.z, 255 )

	self.Splash = {
		Pos = Pos,
		Mat = Material("effects/splashwake1"),
		RandomAng = math.random(0,360),
		Color = VecCol,
	}

	local emitter = Ent:GetParticleEmitter( Ent:GetPos() )

	if emitter and emitter.Add then
		local particle = emitter:Add( "effects/splash4", Pos )
		if not particle then return end

		local Vel = Ent:GetVelocity():Length()

		particle:SetVelocity( Vector(0,0,math.Clamp(Vel / 2,100,250)) )
		particle:SetDieTime( 0.25 + math.min(Vel / 200,0.35) )
		particle:SetAirResistance( 60 ) 
		particle:SetStartAlpha( 255 )
		particle:SetEndAlpha( 0 )
		particle:SetStartSize( self.Size * 0.2 )
		particle:SetEndSize(  self.Size * 2 )
		particle:SetRoll( math.Rand(-1,1) * 100 )
		particle:SetColor( VecCol.r, VecCol.g, VecCol.b )
		particle:SetGravity( Vector( 0, 0, -600 ) )
		particle:SetCollide( false )
	end
end


function EFFECT:Think()
	if CurTime() > self.DieTime then
		return false
	end
	return true
end

function EFFECT:Render()
	if self.Splash and self.LifeTime then
		local Scale = ((self.DieTime - self.LifeTime - CurTime()) / self.LifeTime)
		local S =  self.Size * 5 + (self.Size * 5) * Scale
		local Alpha = 100 + 100 * Scale

		cam.Start3D2D( self.Splash.Pos + Vector(0,0,1), Angle(0,0,0), 1 )
			surface.SetMaterial( self.Splash.Mat )
			surface.SetDrawColor( self.Splash.Color.r, self.Splash.Color.g, self.Splash.Color.b, Alpha )
			surface.DrawTexturedRectRotated( 0, 0, S , S, self.Splash.RandomAng )
		cam.End3D2D()
	end
end