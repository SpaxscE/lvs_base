
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

local SmokeMat = EFFECT.SmokeMat
local function MakeDustParticle( emitter, emitter3D, pos, vel, r, g, b )
	local particle = emitter:Add( SmokeMat[ math.random(1,#SmokeMat) ], pos )

	if not particle then return end

	particle:SetVelocity( vel )
	particle:SetDieTime( 0.4 )
	particle:SetAirResistance( 0 ) 
	particle:SetStartAlpha( 255 )
	particle:SetStartSize( 20 )
	particle:SetEndSize( 30 )
	particle:SetRollDelta( math.Rand(-6,6) )
	particle:SetColor( r, g, b )
	particle:SetGravity( Vector(0,0,-600) )
	particle:SetCollide( false )
	particle:SetNextThink( CurTime() )
	particle:SetThinkFunction( function( p )
		if not IsValid( emitter3D ) then return end

		p:SetNextThink( CurTime() + 0.05 )

		local pos = p:GetPos()
		local vel = p:GetVelocity()

		local traceData = {
			start = pos,
			endpos = pos + Vector(0,0,vel.z) * 0.06,
			mask = MASK_SOLID_BRUSHONLY,
		}

		local trace = util.TraceLine( traceData )

		if not trace.Hit then return end

		p:SetEndSize( 0 )
		p:SetDieTime( 0 )

		local pHit = emitter3D:Add( SmokeMat[ math.random(1,#SmokeMat) ], trace.HitPos + trace.HitNormal )
		pHit:SetStartSize( 15 )
		pHit:SetEndSize( 15 )
		pHit:SetDieTime( math.Rand(5,6) )
		pHit:SetStartAlpha( 50 )
		pHit:SetEndAlpha( 0 )
		pHit:SetColor( p:GetColor() )

		local Ang = trace.HitNormal:Angle()
		Ang:RotateAroundAxis( trace.HitNormal, math.Rand(-180,180) )

		pHit:SetAngles( Ang )
	end )
end

function EFFECT:Init( data )
	local pos = data:GetOrigin()
	local ent = data:GetEntity()

	if not IsValid( ent ) then return end

	local dir = data:GetNormal()
	local scale = data:GetMagnitude()
	local speed = ent:GetVelocity():LengthSqr()
	local tooSlow = speed < 30000
	local tooFast = speed > 400000
	local underwater = data:GetFlags() == 1

	local start = ent:GetPos()
	local emitter = ent:GetParticleEmitter( start )
	local emitter3D = ent:GetParticleEmitter3D( start )

	local VecCol
	local LightColor = render.GetLightColor( pos + dir )

	if underwater then
		VecCol = Vector(1,1.2,1.4) * (0.06 + (0.2126 * LightColor.r) + (0.7152 * LightColor.g) + (0.0722 * LightColor.b)) * 1000
		VecCol.x = math.min( VecCol.x, 255 )
		VecCol.y = math.min( VecCol.y, 255 )
		VecCol.z = math.min( VecCol.z, 255 )
	else
		VecCol = (LightColor * 0.5 + Vector(0.3,0.25,0.15)) * 255
	end

	local DieTime = math.Rand(0.8,1.6)

	if not tooSlow then
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

		if underwater or tooFast then continue end

		particle:SetNextThink( CurTime() )
		particle:SetThinkFunction( function( p )
			if not IsValid( ent ) or not IsValid( emitter ) or not IsValid( emitter3D ) then return end

			p:SetNextThink( CurTime() + 0.05 )

			local pos = p:GetPos()
			local vel = p:GetVelocity()
			local dir = vel:GetNormalized()
			local speed = vel:Length()

			local traceData = {
				start = pos,
				endpos = pos + dir * speed * 0.06,
				whitelist = true,
				filter =  ent,
			}
			local trace = util.TraceLine( traceData )

			if not trace.Hit then return end

			if tooSlow then
				p:SetEndSize( 0 )
				p:SetDieTime( 0 )
			end

			MakeDustParticle( emitter, emitter3D, trace.HitPos - trace.HitNormal * 10, trace.HitNormal * 20 + VectorRand() * 40, p:GetColor() )
		end )
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
