local Materials = {
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

function EFFECT:Init( data )
	local pos = data:GetOrigin()
	
	local emitter = ParticleEmitter( pos, false )

	for i = 1,12 do
		local particle = emitter:Add( Materials[ math.random(1, #Materials ) ],pos )
		
		if not particle then continue end

		local ang = i * 30
		local X = math.cos( math.rad(ang) )
		local Y = math.sin( math.rad(ang) )
			
		particle:SetVelocity( Vector(X,Y,0) * math.Rand(3000,4000) )
		particle:SetDieTime( math.Rand(0.5,1) )
		particle:SetAirResistance( math.Rand(3000,5000) ) 
		particle:SetStartAlpha( 100 )
		particle:SetStartSize( 20 )
		particle:SetEndSize( math.Rand(30,40) )
		particle:SetRoll( math.Rand(-1,1) )
		particle:SetColor( 60,60,60 )
		particle:SetGravity( VectorRand() * 200 + Vector(0,0,1000) )
		particle:SetCollide( false )
	end

	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
