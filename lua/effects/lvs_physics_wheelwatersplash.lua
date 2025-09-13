
EFFECT.WaterWake = Material("effects/splashwake1")

function EFFECT:Init( data )
	local Pos = data:GetOrigin() + Vector(0,0,1)
	local Ent = data:GetEntity()
	self.Size = data:GetMagnitude()

	if not IsValid( Ent ) then return end

	self.LifeTime = 1
	self.DieTime = CurTime() + self.LifeTime

	local RainFX = data:GetFlags() == 1

	if RainFX then
		self.Size = self.Size * 2

	else
		self.Splash = {
			Pos = Pos,
			Mat = self.WaterWake,
			RandomAng = math.random(0,360),
		}
	end

	self.VecCol = (render.GetLightColor( Pos ) * 0.25 + Vector(0.75,0.75,0.75)) * 255

	local emitter = Ent:GetParticleEmitter( Ent:GetPos() )
	local Vel = Ent:GetVelocity():Length()

	for i = 1, 3 do
		if emitter and emitter.Add then
			local particle = emitter:Add( "effects/splash4", Pos + VectorRand() * self.Size * 0.1 )
			if not particle then continue end

			particle:SetVelocity( Vector(0,0,math.Clamp(Vel / 100,100,250)) )
			particle:SetDieTime( 0.25 + math.min(Vel / 500,0.2) )
			particle:SetAirResistance( 60 ) 
			particle:SetStartAlpha( RainFX and 5 or 150 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( self.Size * 0.2 )
			particle:SetEndSize(  self.Size )
			particle:SetRollDelta( math.Rand(-1,1) * 5 )
			particle:SetColor( math.min( self.VecCol.r, 255 ), math.min( self.VecCol.g, 255 ), math.min( self.VecCol.b, 255 ) )
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
	if not self.Splash or not self.LifeTime or not self.VecCol then return end

	local Scale = 1 - (self.DieTime - CurTime()) / self.LifeTime

	local Alpha = math.max( 100 - 150 * Scale ^ 2, 0 )

	if Alpha <= 0 then return end

	local Size = (self.Size + self.Size * Scale) * 1.5

	cam.Start3D2D( self.Splash.Pos, Angle(0,0,0), 1 )
		surface.SetMaterial( self.Splash.Mat )
		surface.SetDrawColor( math.min( self.VecCol.r, 255 ), math.min( self.VecCol.g, 255 ), math.min( self.VecCol.b, 255 ), Alpha )
		surface.DrawTexturedRectRotated( 0, 0, Size, Size, self.Splash.RandomAng )
	cam.End3D2D()
end