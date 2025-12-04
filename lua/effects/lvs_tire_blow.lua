
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
	local Ent = data:GetEntity()

	if not IsValid( Ent ) then return end

	local Offset = Ent:GetPos()
	local Low, High = Ent:WorldSpaceAABB()
	local Vel = Ent:GetVelocity()

	local Radius = Ent:BoundingRadius()

	local NumParticles = Radius
	NumParticles = NumParticles * 4

	NumParticles = math.Clamp( NumParticles, 32, 256 )

	local emitter = ParticleEmitter( Offset )

	for i = 0, NumParticles do
		local Pos = Vector( math.Rand( Low.x, High.x ), math.Rand( Low.y, High.y ), math.Rand( Low.z, High.z ) )
		local particle = emitter:Add( "effects/fleck_tile"..math.random(1,2), Pos )

		if not particle then continue end

		particle:SetVelocity( ( Pos - Offset ) * 5 + Vel * 0.5 )
		particle:SetLifeTime( 0 )
		particle:SetDieTime( math.Rand( 0.5, 1 ) )
		particle:SetStartAlpha( 255 )
		particle:SetEndAlpha( 0 )
		particle:SetStartSize( math.Rand(3,6) * Radius * 0.025 )
		particle:SetEndSize( 1 )
		particle:SetRoll( math.Rand( 0, 360 ) )
		particle:SetRollDelta( math.Rand(-10,10) )

		particle:SetAirResistance( 25 )
		particle:SetGravity( Vector( 0, 0, -600 ) )
		particle:SetCollide( true )
		particle:SetColor( 50, 50, 50 )
		particle:SetBounce( 0.3 )
		particle:SetLighting( true )
	end

	for i = 1, 2 do
		local particle = emitter:Add( self.SmokeMat[ math.random(1,#self.SmokeMat) ] , Offset )

		if not particle then continue end

		particle:SetVelocity( VectorRand() * 100 * Radius + Vel * 0.5 )
		particle:SetDieTime( math.Rand(0.2,0.6) )
		particle:SetAirResistance( 200 * Radius ) 
		particle:SetStartAlpha( 255 )
		particle:SetStartSize( 0.5 * Radius )
		particle:SetEndSize( 2 * Radius  )
		particle:SetRollDelta( math.Rand(-1,1) )
		particle:SetColor( 255, 255, 255 )
		particle:SetGravity( Vector(0,0,600) )
		particle:SetCollide( false )
		particle:SetLighting( true )
	end

	emitter:Finish()

end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
