
local DustMat = {
	"effects/lvs/track_debris_01",
	"effects/lvs/track_debris_02",
}

function EFFECT:Init( data )
	local pos = data:GetOrigin()
	local ent = data:GetEntity()
	local size = data:GetMagnitude()

	if not IsValid( ent ) then return end

	local dir = data:GetNormal()

	local start = ent:GetPos()
	local emitter = ent:GetParticleEmitter( start )
	local emitter3D = ent:GetParticleEmitter3D( start )

	local VecCol = (render.GetLightColor( pos + dir ) * 0.5 + Vector(0.5,0.4,0.3)) * 255

	local traceData = {
		start = pos + Vector(0,0,1),
		endpos = pos - Vector(0,0,1),
		mask = MASK_SOLID_BRUSHONLY,
	}

	local trace = util.TraceLine( traceData )

	if trace.Hit then
		local Ang = trace.HitNormal:Angle()
		Ang:RotateAroundAxis( trace.HitNormal, math.Rand(-180,180) )

		local pHit = emitter3D:Add( DustMat[ math.random(1,#DustMat) ], trace.HitPos + trace.HitNormal )
		pHit:SetStartSize( 15 )
		pHit:SetEndSize( 15 )
		pHit:SetDieTime( math.Rand(0.75,1) )
		pHit:SetStartAlpha( 255 )
		pHit:SetEndAlpha( 0 )
		pHit:SetColor( math.min( VecCol.r, 255 ), math.min( VecCol.g, 255 ), math.min( VecCol.b, 255 ) )
		pHit:SetAngles( Ang )
	end

	local scale = math.Clamp( size / 23, 0.5, 1.25 )

	local particle = emitter:Add( DustMat[ math.random(1,#DustMat) ], pos + dir * 5 * scale + VectorRand() * 5 * scale )

	if not particle then return end

	particle:SetVelocity( (dir * 100 * scale + VectorRand() * 20 * scale) )
	particle:SetDieTime( math.Rand(0.4,0.6) )
	particle:SetAirResistance( 10 ) 
	particle:SetStartAlpha( math.random(100,255) )
	particle:SetStartSize( 8 * scale )
	particle:SetEndSize( math.random(30,40) * scale )
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
