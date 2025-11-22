
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
	local Pos = data:GetOrigin()
	local Dir = data:GetNormal()
	local Ent = data:GetEntity()

	if not IsValid( Ent ) or not isfunction( Ent.GetThrottle ) then return end

	local Engine = Ent:GetEngine()

	if not IsValid( Engine ) or not isfunction( Engine.GetRPM ) then return end

	local Vel = Ent:GetVelocity()

	local emitter = Ent:GetParticleEmitter( Pos )

	if not IsValid( emitter ) then return end

	local throttle = math.min( Ent:GetThrottle() / 0.5, 1 )
	local clutch = Ent:GetQuickVar( "clutch" )
	local hasClutch = Ent:HasQuickVar( "clutch" )
	local ClutchActive = Engine:GetClutch()
	if not clutch then
		clutch = ClutchActive and 1 or 0
	end
	if ClutchActive then
		throttle = math.max( throttle - clutch, 0 )
	end

	local Scale = math.min( (math.max( Engine:GetRPM() - Ent.EngineIdleRPM, 0 ) / (Ent.EngineMaxRPM - Ent.EngineIdleRPM)) * (throttle ^ 2), 1 )

	local temp = 0
	if Ent:HasQuickVar("temp") then
		temp = math.Clamp( 1 - Ent:GetQuickVar( "temp" ) / 0.5, 0, 1 )
	end

	local Col = 50 + 205 * temp

	Col = Col - (Scale * Col)

	local particle = emitter:Add( Materials[ math.random(1, #Materials ) ], Pos )

	if not particle then return end

	local invert = (1 - Dir.z) / 2

	particle:SetVelocity( Vel + Dir * (100 + math.min( 800 * Scale, 300)) + VectorRand() * 50 * Scale + (Ent:GetVelocity() * 0.5 + Vector(0,0,Scale * 100)) * invert )
	particle:SetDieTime( math.max((1.4 - temp) - Ent:GetVelocity():LengthSqr() * 0.0001,0.2) + Scale * math.Rand(0.8,1.2) * invert )
	particle:SetAirResistance( 400 ) 
	particle:SetStartAlpha( 100 - 50 * temp + Scale * 100 )
	particle:SetStartSize( 2 + (throttle + Scale) * 4 )
	particle:SetEndSize( 10 + 35 * (throttle + Scale) )
	particle:SetRoll( math.Rand( -1, 1 ) )
	particle:SetRollDelta( math.Rand( -1, 1 ) * (2 - Scale * 1.75) )
	particle:SetColor( Col, Col, Col )
	particle:SetGravity( Vector( 0, 0, 10 + Scale * 300 ) + Ent:GetVelocity() * 4 )
	particle:SetCollide( true )
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
