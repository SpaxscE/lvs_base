
function EFFECT:Init( data )
	local Pos = data:GetOrigin()
	local Dir = data:GetNormal()
	local Ent = data:GetEntity()
	local Vel = Dir * 10

	if IsValid( Ent ) then
		Vel = Ent:GetVelocity()
	end

	local emitter = ParticleEmitter( Pos, false )

	if not IsValid( emitter ) then return end

	for i = 0, 12 do
		local particle = emitter:Add( "effects/gunshipmuzzle", Pos + Dir * i * 0.7 * math.random(1,2) * 0.5 )
		local Size = 1

		if not particle then continue end

		particle:SetVelocity( Dir * 800 + Vel )
		particle:SetDieTime( 0.05 )
		particle:SetStartAlpha( 255 * Size )
		particle:SetStartSize( math.max( math.random(10,24) - i * 0.5,0.1 ) * Size )
		particle:SetEndSize( 0 )
		particle:SetRoll( math.Rand( -1, 1 ) )
		particle:SetColor( 255, 255, 255 )
		particle:SetCollide( false )
	end

	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
