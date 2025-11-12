
function EFFECT:Init( data )
	local Pos = data:GetOrigin()
	local Ent = data:GetEntity()

	if not IsValid( Ent ) then return end

	self.LifeTime = math.Rand(1.5,3)
	self.DieTime = CurTime() + self.LifeTime

	local LightColor = render.GetLightColor( Pos )
	self.VecCol = Vector(1,1.2,1.4) * (0.06 + (0.2126 * LightColor.r) + (0.7152 * LightColor.g) + (0.0722 * LightColor.b)) * 1000
	self.VecCol.x = math.min( self.VecCol.x, 255 )
	self.VecCol.y = math.min( self.VecCol.y, 255 )
	self.VecCol.z = math.min( self.VecCol.z, 255 )

	self.Splash = {
		Pos = Pos,
		Mat = Material("effects/splashwake1"),
		RandomAng = math.random(0,360),
	}

	local emitter = Ent:GetParticleEmitter( Ent:GetPos() )

	if emitter and emitter.Add then
		local particle = emitter:Add( "effects/splash4", Pos + VectorRand(-10,10) - Vector(0,0,20) )
		if particle then
			particle:SetVelocity( Vector(0,0,250) )
			particle:SetDieTime( 0.8 )
			particle:SetAirResistance( 60 ) 
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 50 )
			particle:SetEndSize( 100 )
			particle:SetRoll( math.Rand(-1,1) * 100 )
			particle:SetColor(self.VecCol.r,self.VecCol.g,self.VecCol.b)
			particle:SetGravity( Vector( 0, 0, -600 ) )
			particle:SetCollide( false )
		end
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
		local Scale = (self.DieTime - self.LifeTime - CurTime()) / self.LifeTime
		local S = 200 - Scale * 600
		local Alpha = 100 + 100 * Scale

		cam.Start3D2D( self.Splash.Pos + Vector(0,0,1), Angle(0,0,0), 1 )
			surface.SetMaterial( self.Splash.Mat )
			surface.SetDrawColor( self.VecCol.r, self.VecCol.g, self.VecCol.b, Alpha )
			surface.DrawTexturedRectRotated( 0, 0, S , S, self.Splash.RandomAng )
		cam.End3D2D()
	end
end