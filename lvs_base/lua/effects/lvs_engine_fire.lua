
function EFFECT:Init( data )
	local Pos = data:GetOrigin()
	local Ent = data:GetEntity()

	if not IsValid( Ent ) then return end

	local emitter = Ent:GetParticleEmitter( Pos )

	if not IsValid( emitter ) then return end

	local particle = emitter:Add( "particles/fire1", Pos )

	if particle then
		particle:SetVelocity( Vector(0,0,70) )
		particle:SetDieTime( 0.5 )
		particle:SetAirResistance( 0 ) 
		particle:SetStartAlpha( 255 )
		particle:SetStartSize( math.Rand(20,28) )
		particle:SetEndSize( math.Rand(0,6) )
		particle:SetRoll( math.Rand(-1,1) * 180 )
		particle:SetColor( 255,255,255 )
		particle:SetGravity( Vector( 0, 0, 70 ) )
		particle:SetCollide( false )
	end
	
	for i = 0,6 do
		local particle = emitter:Add( "particles/flamelet"..math.random(1,5), Pos )
		
		if particle then
			particle:SetVelocity( Vector(0,0,40) )
			particle:SetDieTime( 0.15 )
			particle:SetAirResistance( 0 ) 
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( 15 )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand(-1,1) * 180 )
			particle:SetColor( 255,255,255 )
			particle:SetGravity( Vector( 0, 0, 40 ) )
			particle:SetCollide( false )
		end
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
