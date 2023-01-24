
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
	local Pos = data:GetOrigin() + VectorRand() * 25
	local Ent = data:GetEntity()

	if not IsValid( Ent ) then return end

	local emitter = Ent:GetParticleEmitter( Pos )

	if not IsValid( emitter ) then return end

	local particle = emitter:Add( Materials[ math.random(1, #Materials ) ], Pos )
	
	if particle then
		particle:SetVelocity( VectorRand() * 100 )
		particle:SetDieTime( 2 )
		particle:SetAirResistance( 600 ) 
		particle:SetStartAlpha( 50 )
		particle:SetStartSize( 60 )
		particle:SetEndSize( 200 )
		particle:SetRoll( math.Rand(-1,1) * math.pi )
		particle:SetRollDelta( math.Rand(-1,1) )
		particle:SetColor( 60, 60, 60 )
		particle:SetGravity( Vector( 0, 0, 600 ) )
		particle:SetCollide( false )
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
