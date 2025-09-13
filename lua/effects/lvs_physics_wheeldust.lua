
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
	local ent = data:GetEntity()

	if not IsValid( ent ) then return end

	local dir = data:GetNormal()
	local scale = data:GetMagnitude()

	local underwater = data:GetFlags() == 1

	local emitter = ent:GetParticleEmitter( ent:GetPos() )

	local VecCol = render.GetLightColor( pos + dir ) * 0.5

	if underwater then
		VecCol = (VecCol * 0.25 + Vector(0.75,0.75,0.75)) * 255
	else
		VecCol = (VecCol + Vector(0.3,0.25,0.15)) * 255
	end

	local DieTime = math.Rand(0.8,1.6)

	for i = 1, 5 do
		local particle = emitter:Add( self.DustMat[ math.random(1,#self.DustMat) ] , pos )

		if not particle then continue end

		particle:SetVelocity( (dir * 50 * i + VectorRand() * 25) * scale )
		particle:SetDieTime( (i / 8) * DieTime )
		particle:SetAirResistance( 10 ) 
		particle:SetStartAlpha( 255 )
		particle:SetStartSize( 10 * scale )
		particle:SetEndSize( 20 * i * scale )
		particle:SetRollDelta( math.Rand(-1,1) )
		particle:SetColor( math.min( VecCol.r, 255 ), math.min( VecCol.g, 255 ), math.min( VecCol.b, 255 ) )
		particle:SetGravity( Vector(0,0,-600) * scale )
		particle:SetCollide( false )
	end

	for i = 1, 5 do
		local particle = emitter:Add( underwater and "effects/splash4" or self.SmokeMat[ math.random(1,#self.SmokeMat) ] , pos )

		if not particle then continue end

		particle:SetVelocity( (dir * 50 * i + VectorRand() * 40) * scale )
		particle:SetDieTime( (i / 8) * DieTime )
		particle:SetAirResistance( 10 ) 
		particle:SetStartAlpha( underwarter and 150 or 255 )
		particle:SetStartSize( 10 * scale )
		particle:SetEndSize( 20 * i * scale )
		particle:SetRollDelta( math.Rand(-1,1) )
		particle:SetColor( math.min( VecCol.r, 255 ), math.min( VecCol.g, 255 ), math.min( VecCol.b, 255 ) )
		particle:SetGravity( Vector(0,0,-600) * scale )
		particle:SetCollide( false )
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
