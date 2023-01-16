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

local MatDebris = {
	"particle/particle_debris_01",
	"particle/particle_debris_02",
}

function EFFECT:Init( data )
	local Pos = data:GetOrigin()
	local Ent = data:GetEntity()

	if not IsValid( Ent ) then return end

	local Dir = Ent:GetForward()

	local emitter = Ent:GetParticleEmitter( Ent:GetPos() )

	local VecCol = render.GetLightColor( Pos + Vector(0,0,10) ) * 0.5 + Vector(0.3,0.25,0.15)

	if emitter and emitter.Add then
		for i = 1, 3 do
			local particle = emitter:Add( MatDebris[math.random(1,#MatDebris)], Pos + VectorRand(-10,10) )
			if particle then
				particle:SetVelocity( Vector(0,0,150) - Dir * 150 )
				particle:SetDieTime( 0.2 )
				particle:SetAirResistance( 60 ) 
				particle:SetStartAlpha( 255 )
				particle:SetEndAlpha( 255 )
				particle:SetStartSize( 15 )
				particle:SetEndSize( 50 )
				particle:SetRoll( math.Rand(-1,1) * 100 )
				particle:SetColor( VecCol.x * 130,VecCol.y * 100,VecCol.z * 60 )
				particle:SetGravity( Vector( 0, 0, -600 ) )
				particle:SetCollide( false )
			end
		end

		local Right = Ent:GetRight() 
		Right.z = 0
		Right:Normalize()

		for i = -1,1,2 do
			local particle = emitter:Add( Materials[math.random(1,#Materials)], Pos + Vector(0,0,10)  )
			if particle then
				particle:SetVelocity( -Dir * 400 + Right * 150 * i )
				particle:SetDieTime( math.Rand(0.5,1) )
				particle:SetAirResistance( 150 ) 
				particle:SetStartAlpha( 50 )
				particle:SetStartSize( -80 )
				particle:SetEndSize( 400 )
				particle:SetColor( VecCol.x * 255,VecCol.y * 255,VecCol.z * 255 )
				particle:SetGravity( Vector( 0, 0, 100 ) )
				particle:SetCollide( false )
			end
		end
	end
end


function EFFECT:Think()
	return false
end

function EFFECT:Render()
end