
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
	local Pos = data:GetOrigin()
	local Dir = data:GetNormal()
	local Ent = data:GetEntity()
	local Scale = data:GetMagnitude()

	if not IsValid( Ent ) then return end

	local Vel = Ent:GetVelocity()

	local emitter = Ent:GetParticleEmitter( Pos )

	if not IsValid( emitter ) then return end

	local particle = emitter:Add( Materials[ math.random(1, #Materials ) ], Pos )

	if not particle then return end

	local Col = 100 - 60 * Scale

	particle:SetVelocity( Vel + Dir * (100 + 50 * Scale) )
	particle:SetDieTime( 0.4 - 0.3 * Scale )
	particle:SetAirResistance( 400 ) 
	particle:SetStartAlpha( 80 )
	particle:SetStartSize( 2 )
	particle:SetEndSize( 10 + 20 * Scale )
	particle:SetRoll( math.Rand( -1, 1 ) )
	particle:SetRollDelta( math.Rand( -1, 1 ) * 2 )
	particle:SetColor( Col, Col, Col )
	particle:SetGravity( Vector( 0, 0, 10 ) )
	particle:SetCollide( false )
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
