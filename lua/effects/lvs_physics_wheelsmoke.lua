
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

function EFFECT:Init( data )
	local pos = data:GetOrigin()
	local ent = data:GetEntity()

	if not IsValid( ent ) then return end

	local dir = data:GetNormal()

	local emitter = ent:GetParticleEmitter( ent:GetPos() )

	local VecCol = (render.GetLightColor( pos + dir ) * 0.5 + Vector(0.3,0.3,0.3)) * 255

	for i = 1, 2 do
		local particle = emitter:Add( self.SmokeMat[ math.random(1,#self.SmokeMat) ] , pos )

		if not particle then continue end

		particle:SetVelocity( VectorRand() * 50 )
		particle:SetDieTime( math.Rand(0.5,1.5) )
		particle:SetAirResistance( 10 ) 
		particle:SetStartAlpha( 50 )
		particle:SetStartSize( 20 )
		particle:SetEndSize( 60 )
		particle:SetRollDelta( math.Rand(-1,1) )
		particle:SetColor( math.min( VecCol.r, 255 ), math.min( VecCol.g, 255 ), math.min( VecCol.b, 255 ) )
		particle:SetGravity( Vector(0,0,5) )
		particle:SetCollide( false )
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
