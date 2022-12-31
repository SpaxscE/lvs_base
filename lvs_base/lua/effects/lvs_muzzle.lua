
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
	local Vel = Dir * 10

	if IsValid( Ent ) then
		Vel = Ent:GetVelocity()
	end

	local emitter = ParticleEmitter( Pos, false )

	for i = 0, 12 do
		local particle = emitter:Add( "effects/muzzleflash2", Pos + Dir * i * 0.7 * math.random(1,2) * 0.5 )
		local Size = 1

		if not particle then continue end

		particle:SetVelocity( Dir * 800 + Vel )
		particle:SetDieTime( 0.05 )
		particle:SetStartAlpha( 255 * Size )
		particle:SetStartSize( math.max( math.random(10,24) - i * 0.5,0.1 ) * Size )
		particle:SetEndSize( 0 )
		particle:SetRoll( math.Rand( -1, 1 ) )
		particle:SetColor( 255,255,255 )
		particle:SetCollide( false )
	end

	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
