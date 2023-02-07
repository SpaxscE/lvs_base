
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
	"particle/particle_debris_01",
	"particle/particle_debris_02",
}

function EFFECT:Init( data )
	local pos = data:GetOrigin()
	local dir = data:GetNormal()
	local scale = data:GetMagnitude()

	sound.Play( "physics/flesh/flesh_strider_impact_bullet"..math.random(1,3)..".wav", pos, 85, math.random(180,200) + 55 * math.max(1 - scale,0), 0.75 )
	sound.Play( "ambient/materials/rock"..math.random(1,5)..".wav", pos, 75, 180, 1 )

	local emitter = ParticleEmitter( pos, false )

	local VecCol = (render.GetLightColor( pos + dir ) * 0.5 + Vector(0.2,0.18,0.15)) * 255

	local DieTime = math.Rand(0.8,1.6)

	if dir.z > 0.85 then
		for i = 1, 10 do
			for n = 0,6 do
				local particle = emitter:Add( self.DustMat[ math.random(1,#self.DustMat) ] , pos )

				if not particle then continue end

				particle:SetVelocity( (dir * 50 * i + VectorRand() * 25) * scale )
				particle:SetDieTime( (i / 8) * DieTime )
				particle:SetAirResistance( 10 ) 
				particle:SetStartAlpha( 255 )
				particle:SetStartSize( 10 * scale )
				particle:SetEndSize( 20 * i * scale )
				particle:SetRollDelta( math.Rand(-1,1) )
				particle:SetColor( VecCol.r, VecCol.g, VecCol.b )
				particle:SetGravity( Vector(0,0,-600) * scale )
				particle:SetCollide( false )
			end
		end

		for i = 1, 10 do
			local particle = emitter:Add( self.SmokeMat[ math.random(1,#self.SmokeMat) ] , pos )

			if not particle then continue end

			particle:SetVelocity( (dir * 50 * i + VectorRand() * 40) * scale )
			particle:SetDieTime( (i / 8) * DieTime )
			particle:SetAirResistance( 10 ) 
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( 10 * scale )
			particle:SetEndSize( 20 * i * scale )
			particle:SetRollDelta( math.Rand(-1,1) )
			particle:SetColor( VecCol.r, VecCol.g, VecCol.b )
			particle:SetGravity( Vector(0,0,-600) * scale )
			particle:SetCollide( false )
		end
	end

	for i = 1,12 do
		local particle = emitter:Add( self.SmokeMat[ math.random(1,#self.SmokeMat) ] , pos )
		
		if particle then
			local ang = i * 30
			local X = math.cos( math.rad(ang) )
			local Y = math.sin( math.rad(ang) )

			local Vel = Vector(X,Y,0) * math.Rand(200,1600) + Vector(0,0,50)
			Vel:Rotate( dir:Angle() + Angle(90,0,0) )

			particle:SetVelocity( Vel * scale )
			particle:SetDieTime( DieTime )
			particle:SetAirResistance( 500 ) 
			particle:SetStartAlpha( 100 )
			particle:SetStartSize( 40 * scale )
			particle:SetEndSize( 200 * scale )
			particle:SetRollDelta( math.Rand(-1,1) )
			particle:SetColor( VecCol.r, VecCol.g, VecCol.b )
			particle:SetGravity( Vector(0,0,60) * scale )
			particle:SetCollide( true )
		end
	end

	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
