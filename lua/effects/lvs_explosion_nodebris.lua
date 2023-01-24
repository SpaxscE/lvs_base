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

	self:Explosion( Pos, 2 )

	local ply = LocalPlayer():GetViewEntity()
	if IsValid( ply ) then
		local delay = (Pos - ply:GetPos()):Length() / 13503.9
		timer.Simple( delay, function()
			sound.Play( "LVS.EXPLOSION", Pos )
		end )
	else
		sound.Play( "LVS.EXPLOSION", Pos )
	end

	for i = 1, 20 do
		timer.Simple(math.Rand(0,0.01) * i, function()
			if not IsValid( self ) then return end

			local p = Pos + VectorRand() * 10 * i
			
			self:Explosion( p, math.Rand(0.5,0.8) )
		end)
	end
end

function EFFECT:Explosion( pos , scale )
	local emitter = ParticleEmitter( pos, false )

	if not IsValid( emitter ) then return end

	for i = 0,10 do
		local particle = emitter:Add( Materials[ math.random(1, #Materials ) ], pos )

		if not particle then continue end

		particle:SetVelocity( VectorRand() * 1000 * scale )
		particle:SetDieTime( math.Rand(0.75,1.5) * scale )
		particle:SetAirResistance( math.Rand(200,600) ) 
		particle:SetStartAlpha( 255 )
		particle:SetStartSize( math.Rand(60,120) * scale )
		particle:SetEndSize( math.Rand(160,280) * scale )
		particle:SetRoll( math.Rand(-1,1) )
		particle:SetColor( 40,40,40 )
		particle:SetGravity( Vector( 0, 0, 100 ) )
		particle:SetCollide( false )
	end

	for i = 0, 40 do
		local particle = emitter:Add( "particles/flamelet"..math.random(1,5), pos )

		if not particle then continue end

		particle:SetVelocity( VectorRand() * 1000 * scale )
		particle:SetDieTime( 0.14 )
		particle:SetStartAlpha( 255 )
		particle:SetStartSize( 10 * scale )
		particle:SetEndSize( math.Rand(60,120) * scale )
		particle:SetEndAlpha( 100 )
		particle:SetRoll( math.Rand( -1, 1 ) )
		particle:SetColor( 200,150,150 )
		particle:SetCollide( false )
	end

	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
