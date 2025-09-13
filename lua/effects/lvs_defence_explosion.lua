
EFFECT.GlowMat = Material( "sprites/light_glow02_add" )
EFFECT.SmokeMat = {
	"particle/smokesprites_0001",
	"particle/smokesprites_0002",
	"particle/smokesprites_0003",
	"particle/smokesprites_0004",
	"particle/smokesprites_0005",
	"particle/smokesprites_0006",
	"particle/smokesprites_0007",
	"particle/smokesprites_0008",
	"particle/smokesprites_0009",
	"particle/smokesprites_0010",
	"particle/smokesprites_0011",
	"particle/smokesprites_0012",
	"particle/smokesprites_0013",
	"particle/smokesprites_0014",
	"particle/smokesprites_0015",
	"particle/smokesprites_0016"
}

EFFECT.DustMat = {
	"effects/lvs_base/particle_debris_01",
	"effects/lvs_base/particle_debris_02",
}

function EFFECT:Init( data )
	local pos = data:GetOrigin()
	local dir = data:GetNormal()
	local scale = data:GetMagnitude()

	self.LifeTime = 0.35
	self.DieTime = CurTime() + self.LifeTime

	self.Pos = pos
	self.Scale = scale

	sound.Play( "weapons/shotgun/shotgun_fire6.wav", pos, 75, 150, 1 )

	local VecCol = (render.GetLightColor( pos + dir ) * 0.5 + Vector(0.2,0.18,0.15)) * 255

	local emitter = ParticleEmitter( pos, false )

	for i = 0,20 do
		local particle = emitter:Add( self.SmokeMat[ math.random(1,#self.SmokeMat) ] , pos )
		
		if not particle then continue end

		particle:SetVelocity( VectorRand() * 500 * scale )
		particle:SetDieTime( math.Rand(0.4,0.6) )
		particle:SetAirResistance( 500 ) 
		particle:SetStartAlpha( 100 )
		particle:SetStartSize( 40 * scale )
		particle:SetEndSize( 200 * scale )
		particle:SetRollDelta( math.Rand(-1,1) )
		particle:SetColor( math.min( VecCol.r, 255 ), math.min( VecCol.g, 255 ), math.min( VecCol.b, 255 ) )
		particle:SetGravity( Vector(0,0,1200) )
		particle:SetCollide( true )
	end

	for i = 1,12 do
		local particle = emitter:Add( self.SmokeMat[ math.random(1,#self.SmokeMat) ] , pos )

		if not particle then continue end

		local ang = i * 30
		local X = math.cos( math.rad(ang) )
		local Y = math.sin( math.rad(ang) )

		local Vel = Vector(X,Y,0) * 1000
		Vel:Rotate( dir:Angle() + Angle(90,0,0) )

		particle:SetVelocity( Vel * scale )
		particle:SetDieTime( math.Rand(0.6,0.8) )
		particle:SetAirResistance( 500 ) 
		particle:SetStartAlpha( 100 )
		particle:SetStartSize( 30 * scale )
		particle:SetEndSize( 60 * scale )
		particle:SetRollDelta( math.Rand(-1,1) )
		particle:SetColor( math.min( VecCol.r, 255 ), math.min( VecCol.g, 255 ), math.min( VecCol.b, 255 ) )
		particle:SetGravity( Vector(0,0,600) )
		particle:SetCollide( true )
	end

	for i = 0, 15 do
		local particle = emitter:Add( "effects/lvs_base/flamelet"..math.random(1,5), pos )

		if not particle then continue end

		particle:SetVelocity( VectorRand() * 400 * scale )
		particle:SetDieTime( math.Rand(0.2,0.3) )
		particle:SetStartAlpha( 255 )
		particle:SetEndAlpha( 0 )
		particle:SetStartSize( 60 * scale )
		particle:SetEndSize( 10 * scale )
		particle:SetColor( 255, 255, 255 )
		particle:SetGravity( dir * 2500 )
		particle:SetRollDelta( math.Rand(-5,5) )
		particle:SetAirResistance( 300 )
	end

	for i = 0, 5 do
		local particle = emitter:Add( "effects/lvs_base/flamelet"..math.random(1,5), pos)

		if not particle then continue end

		particle:SetStartAlpha( 255 )
		particle:SetEndAlpha( 0 )
		particle:SetColor( 255, 255, 255 )
		particle:SetGravity( Vector(0,0,0) )

		local size = math.Rand(2, 12) * scale
		particle:SetEndSize( size )
		particle:SetStartSize( size )

		particle:SetStartLength( 100 * scale )
		particle:SetEndLength( size )

		particle:SetDieTime( math.Rand(0.1,0.2) )
		particle:SetVelocity( (dir * 2000 + VectorRand() * 1000) * scale )

		particle:SetAirResistance( 0 )
	end

	for i = 0, 40 do
		local particle = emitter:Add( "effects/fire_embers"..math.random(1,2), pos )

		if not particle then continue end

		particle:SetVelocity( VectorRand() * 400 * scale )
		particle:SetDieTime( math.Rand(0.4,0.6) )
		particle:SetStartAlpha( 255 )
		particle:SetEndAlpha( 0 )
		particle:SetStartSize( 20 * scale )
		particle:SetEndSize( 0 )
		particle:SetColor( 255, 255, 255 )
		particle:SetGravity( Vector(0,0,600) )
		particle:SetRollDelta( math.Rand(-8,8) )
		particle:SetAirResistance( 300 )
	end

	if dir.z > 0.8 then
		for i = 0,60 do
			local particle = emitter:Add( "effects/fleck_cement"..math.random(1,2), pos )
			local vel = dir * math.Rand(600,1000) + VectorRand() * 200

			if not particle then continue end

			particle:SetVelocity( vel * scale )
			particle:SetDieTime( math.Rand(10,15) )
			particle:SetAirResistance( 10 ) 
			particle:SetStartAlpha( 255 )

			local size = math.Rand(2, 4) * scale
			particle:SetEndSize( size )
			particle:SetStartSize( size )

			particle:SetRoll( math.Rand(-1,1) )
			particle:SetColor( math.min( VecCol.r, 255 ), math.min( VecCol.g, 255 ), math.min( VecCol.b, 255 ) )
			particle:SetGravity( Vector( 0, 0, -600 ) )
			particle:SetCollide( true )
			particle:SetBounce( 0.3 )
		end
	end

	emitter:Finish()
end

function EFFECT:Think()
	if self.DieTime < CurTime() then return false end

	return true
end

function EFFECT:Render()
	if not self.Scale then return end

	local Scale = (self.DieTime - CurTime()) / self.LifeTime
	local R1 = 800 * self.Scale
	render.SetMaterial( self.GlowMat )
	render.DrawSprite( self.Pos, R1 * Scale, R1 * Scale, Color( 255, 200, 150, 255) )
end
