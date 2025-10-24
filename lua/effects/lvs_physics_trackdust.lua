
EFFECT.DustMat = {
	"effects/lvs/track_debris_01",
	"effects/lvs/track_debris_02",
}

function EFFECT:Init( data )
	local pos = data:GetOrigin()
	local ent = data:GetEntity()
	local size = data:GetMagnitude()

	if not IsValid( ent ) then return end

	local dir = data:GetNormal()

	local emitter = ent:GetParticleEmitter( ent:GetPos() )

	local VecCol = (render.GetLightColor( pos + dir ) * 0.5 + Vector(0.5,0.4,0.3)) * 255

	local scale = math.Clamp( size / 23, 0.5, 1.25 )

	local particle = emitter:Add( self.DustMat[ math.random(1,#self.DustMat) ] , pos + dir * 5 * scale + VectorRand() * 5 * scale )

	if not particle then return end

	particle:SetVelocity( (dir * 100 * scale + VectorRand() * 20 * scale) )
	particle:SetDieTime( math.Rand(0.4,0.6) )
	particle:SetAirResistance( 10 ) 
	particle:SetStartAlpha( math.random(100,255) )
	particle:SetStartSize( 6 * scale )
	particle:SetEndSize( math.random(20,25) * scale )
	particle:SetRollDelta( math.Rand(-1,1) )
	particle:SetColor( math.min( VecCol.r, 255 ), math.min( VecCol.g, 255 ), math.min( VecCol.b, 255 ) )
	particle:SetGravity( Vector(0,0,-600) )
	particle:SetCollide( false )
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
