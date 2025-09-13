
local GlowMat = Material( "sprites/light_glow02_add" )

function EFFECT:Init( data )
	self.Pos = data:GetOrigin()
	self.Col = data:GetStart() or Vector(255,100,0)

	self.LifeTime = 0.4
	self.DieTime = CurTime() + self.LifeTime

	local emitter = ParticleEmitter( self.Pos, false )

	if not IsValid( emitter ) then return end

	for i = 0, 20 do
		local particle = emitter:Add( "sprites/light_glow02_add", self.Pos )
		
		local vel = VectorRand() * 400
		
		if particle then
			particle:SetVelocity( vel )
			particle:SetAngles( vel:Angle() + Angle(0,90,0) )
			particle:SetDieTime( math.Rand(0.4,0.8) )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( math.Rand(24,48) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand(-100,100) )
			particle:SetRollDelta( math.Rand(-100,100) )
			particle:SetColor( self.Col.x,self.Col.y,self.Col.z )
			particle:SetGravity( Vector(0,0,-600) )

			particle:SetAirResistance( 0 )
			
			particle:SetCollide( true )
			particle:SetBounce( 0.5 )
		end
	end
	
	for i = 0, 20 do
		local particle = emitter:Add( "effects/lvs_base/flamelet"..math.random(1,5), self.Pos )
		
		if particle then
			particle:SetVelocity( VectorRand(-1,1) * 500 )
			particle:SetDieTime( 0.15 )
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( 10 )
			particle:SetEndSize( 32 )
			particle:SetEndAlpha( 100 )
			particle:SetRoll( math.Rand( -1, 1 ) )
			particle:SetRollDelta( math.Rand( -1, 1 ) * 100 )
			particle:SetColor( self.Col.x,self.Col.y,self.Col.z )
			particle:SetCollide( false )
		end
	end

	emitter:Finish()
end

function EFFECT:Think()
	if self.DieTime < CurTime() then return false end

	return true
end

function EFFECT:Render()
	if not self.Col then return end

	local Scale = (self.DieTime - CurTime()) / self.LifeTime
	render.SetMaterial( GlowMat )
	render.DrawSprite( self.Pos, 400 * Scale, 400 * Scale, Color( self.Col.x,self.Col.y,self.Col.z, 255) )
	render.DrawSprite( self.Pos, 100 * Scale, 100 * Scale, Color( 255, 255, 255, 255) )
end
