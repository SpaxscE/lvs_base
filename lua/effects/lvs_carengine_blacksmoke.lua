EFFECT.Smoke = {
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
	local Pos = data:GetOrigin()
	local Ent = data:GetEntity()

	if not IsValid( Ent ) then return end

	local emitter = Ent:GetParticleEmitter( Ent:WorldToLocal( Pos ) )

	if not IsValid( emitter ) then return end

	local particle = emitter:Add( self.Smoke[ math.random(1, #self.Smoke ) ], Pos )

	local rCol = math.random(30,60)

	local Scale = math.Rand(1,8)

	if not particle then return end

	particle:SetVelocity( Vector(0,0,80) + VectorRand() * 80 )
	particle:SetDieTime( Scale )
	particle:SetAirResistance( 200 ) 
	particle:SetStartAlpha( 100 / Scale )
	particle:SetStartSize( 20 )
	particle:SetEndSize( math.random(15,30) * Scale )
	particle:SetRoll( math.pi / Scale )
	particle:SetRollDelta( math.Rand(-1,1) )
	particle:SetColor( rCol, rCol, rCol )
	particle:SetGravity( Vector( 0, 0, math.random(-40,80) ) )
	particle:SetCollide( true )
	particle:SetBounce( 0 )
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
