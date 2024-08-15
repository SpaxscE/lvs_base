
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

local DecalMat = Material( util.DecalMaterial( "FadingScorch" ) )
function EFFECT:Init( data )
	local Pos = data:GetOrigin()
	local Dir = data:GetNormal()

	local emitter = ParticleEmitter( Pos, false )

	local trace = util.TraceLine( {
		start = Pos + Dir * 5,
		endpos = Pos - Dir * 5,
		filter = function( ent ) 
			if ent.GetOwningEnt then return false end
			return true
		end
	} )

	if trace.Hit and not trace.HitNonWorld then
		util.DecalEx( DecalMat, trace.Entity, trace.HitPos + trace.HitNormal, trace.HitNormal, color_white, 0.2, 0.2 )
	end

	local particle = emitter:Add( Materials[ math.random(1,table.Count( Materials )) ], Pos )
	
	local vel = VectorRand() * 100 + Dir * 40
	
	if particle then			
		particle:SetVelocity( vel )
		particle:SetDieTime( 0.5 )
		particle:SetAirResistance( 1000 ) 
		particle:SetStartAlpha( 50 )
		particle:SetStartSize( 2 )
		particle:SetEndSize( 6 )
		particle:SetRoll( math.Rand(-1,1) )
		particle:SetColor( 40,40,40 )
		particle:SetGravity( Dir * 10 )
		particle:SetCollide( false )
	end

	local particle = emitter:Add( "effects/spark", Pos )
	
	local vel = VectorRand() * 100 + Dir * 40
	
	if particle then
		particle:SetVelocity( vel )
		particle:SetAngles( vel:Angle() + Angle(0,90,0) )
		particle:SetDieTime( 1 )
		particle:SetStartAlpha( math.Rand( 200, 255 ) )
		particle:SetEndAlpha( 0 )
		particle:SetStartSize( 2 )
		particle:SetEndSize( 0 )
		particle:SetRoll( math.Rand(-100,100) )
		particle:SetRollDelta( math.Rand(-100,100) )
		particle:SetCollide( true )
		particle:SetBounce( 0.5 )
		particle:SetStartLength( 5 )
		particle:SetAirResistance( 0 )
		particle:SetColor( 150, 200, 255 )
		particle:SetGravity( Vector(0,0,-600) )
	end

	emitter:Finish()
end

function EFFECT:Think()

	return false
end

function EFFECT:Render()
end
