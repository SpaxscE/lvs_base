
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

function EFFECT:Explosion( pos )
	sound.Play( "weapons/shotgun/shotgun_fire6.wav", pos, 75, 150, 1 )

	local emitter = ParticleEmitter( pos, false )
	
	for i = 0, 20 do
		local particle = emitter:Add( "sprites/rico1", pos )
		
		local vel = VectorRand() * 800
		
		if particle then
			particle:SetVelocity( vel )
			particle:SetAngles( vel:Angle() + Angle(0,90,0) )
			particle:SetDieTime( math.Rand(0.1,0.15) )
			particle:SetStartAlpha( math.Rand( 200, 255 ) )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( math.Rand(6,12) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand(-100,100) )
			particle:SetRollDelta( math.Rand(-100,100) )
			particle:SetColor( 255, 255, 255 )

			particle:SetAirResistance( 0 )
		end
	end
	
	for i = 0, 40 do
		local particle = emitter:Add( "sprites/flamelet"..math.random(1,5), pos )
		
		if particle then
			particle:SetVelocity( VectorRand() * 300 )
			particle:SetDieTime( 0.14 )
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( math.Rand(10,20) )
			particle:SetEndAlpha( 100 )
			particle:SetRoll( math.Rand( -1, 1 ) )
			particle:SetColor( 200,150,150 )
			particle:SetCollide( false )
		end
	end
	
	emitter:Finish()
end


function EFFECT:Init( data )
	local pos = data:GetOrigin()

	self:Explosion( pos )

	local effectdata = EffectData()
	effectdata:SetOrigin( pos )
	effectdata:SetNormal( Vector(0,0,1) )
	effectdata:SetMagnitude( 0.5 )
	util.Effect( "lvs_bullet_impact", effectdata )
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
