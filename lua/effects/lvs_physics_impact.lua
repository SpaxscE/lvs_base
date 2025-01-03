
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
	if not LVS.ShowPhysicsEffects then return end

	local dir = data:GetNormal()
	local pos  = data:GetOrigin() + dir

	local emitter = ParticleEmitter( pos, false )

	for i = 0, 10 do
		local particle = emitter:Add( "effects/spark", pos )

		local vel = VectorRand() * 75 + dir * 75 + Vector(0,0,100)

		if not particle then continue end

		particle:SetVelocity( vel )
		particle:SetDieTime( math.Rand(2.5,5) )
		particle:SetAirResistance( 10 ) 
		particle:SetStartAlpha( 255 )

		particle:SetStartLength( 6 )
		particle:SetEndLength(0)

		particle:SetStartSize( 3 )
		particle:SetEndSize( 0 )

		particle:SetRoll( math.Rand(-5,5) )
		particle:SetColor( 255, 200, 50 )
		particle:SetGravity( Vector(0,0,-600) )
		particle:SetCollide( true )
	end

	local smoke = emitter:Add( Materials[ math.random(1, #Materials ) ], pos )

	if smoke then
		smoke:SetVelocity( dir * 30 + VectorRand() * 15 )
		smoke:SetDieTime( math.Rand(1.5,3) )
		smoke:SetAirResistance( 100 ) 
		smoke:SetStartAlpha( 100 )
		smoke:SetEndAlpha( 0 )
		smoke:SetStartSize( 15 )
		smoke:SetEndSize( 30 )
		smoke:SetColor(30,30,30)
		smoke:SetGravity(Vector(0,0,40))
		smoke:SetCollide( false )
		smoke:SetRollDelta( math.Rand(-1,1) )
	end

	local flash = emitter:Add( "effects/yellowflare",pos )

	if flash then
		flash:SetPos( pos )
		flash:SetStartAlpha( 200 )
		flash:SetEndAlpha( 0 )
		flash:SetColor( 255, 200, 0 )
		flash:SetEndSize( 100 )
		flash:SetDieTime( 0.1 )
		flash:SetStartSize( 0 )
	end

	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
