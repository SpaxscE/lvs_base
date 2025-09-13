
function EFFECT:Init( data )
	local pos = data:GetOrigin()
	local dir = data:GetNormal()

	local emitter = ParticleEmitter( pos, false )

	for i = 1, 360 do
		if math.random(1,30) ~= 10 then continue end

		local ang = i

		local X = math.cos( math.rad(ang) )
		local Y = math.sin( math.rad(ang) )

		local forward = Vector(X,Y,0)
		forward:Rotate( dir:Angle() + Angle(90,0,0) )

		local spark = emitter:Add("effects/spark", pos + VectorRand() * 10 )

		if not spark then continue end

		spark:SetStartAlpha( 255 )
		spark:SetEndAlpha( 0 )
		spark:SetCollide( true )
		spark:SetBounce( math.Rand(0,1) )
		spark:SetColor( 255, 255, 255 )
		spark:SetGravity( Vector(0,0,-600) )
		spark:SetEndLength(0)

		local size = math.Rand(2, 4)
		spark:SetEndSize( size )
		spark:SetStartSize( size )

		spark:SetStartLength( math.Rand(5,7) )
		spark:SetDieTime( math.Rand(0.1, 0.3) )
		spark:SetVelocity( forward * math.random(75,100) + VectorRand() * 50 )
	end

	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
