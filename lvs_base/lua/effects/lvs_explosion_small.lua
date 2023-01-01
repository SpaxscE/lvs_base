
local GlowMat = Material( "sprites/light_glow02_add" )
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
	self.Pos = data:GetOrigin()
	self.LifeTime = 0.35
	self.DieTime = CurTime() + self.LifeTime

	local emitter = ParticleEmitter( self.Pos, false )

	for i = 0, 15 do
		local particle = emitter:Add( Materials[ math.random(1, #Materials ) ], self.Pos )
		
		if particle then
			particle:SetVelocity( VectorRand(-1,1) * 1000 )
			particle:SetDieTime( math.Rand(2,3) )
			particle:SetAirResistance( math.Rand(200,600) ) 
			particle:SetStartAlpha( 200 )
			particle:SetStartSize( 120 )
			particle:SetEndSize( 300 )
			particle:SetRoll( math.Rand(-1,1) )
			particle:SetRollDelta( math.Rand(-1,1) )
			particle:SetColor( 50,50,50 )
			particle:SetGravity( Vector( 0, 0, 600 ) )
			particle:SetCollide( false )
		end
	end

	for i = 0, 15 do
		local particle = emitter:Add( "sprites/flamelet"..math.random(1,5), self.Pos )
		
		if particle then
			particle:SetVelocity( VectorRand(-1,1) * 500 )
			particle:SetDieTime( math.Rand(0.15,0.3) )
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( 25 )
			particle:SetEndSize( math.Rand(70,100) )
			particle:SetEndAlpha( 100 )
			particle:SetRoll( math.Rand( -1, 1 ) )
			particle:SetColor( 200,150,150 )
			particle:SetCollide( false )
		end
	end

	for i = 0, 20 do
		local particle = emitter:Add( "sprites/rico1", self.Pos )
		
		local vel = VectorRand() * 800
		
		if particle then
			particle:SetVelocity( vel )
			particle:SetAngles( vel:Angle() + Angle(0,90,0) )
			particle:SetDieTime( math.Rand(0.2,0.4) )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( math.Rand(20,40) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand(-100,100) )
			particle:SetRollDelta( 0 )
			particle:SetColor( 255, 255, 255 )

			particle:SetAirResistance( 0 )
		end
	end

	emitter:Finish()

	local Pos = self.Pos
	local ply = LocalPlayer():GetViewEntity()
	if IsValid( ply ) then
		local delay = (Pos - ply:GetPos()):Length() / 13503.9
		if delay <= 0.11 then
			sound.Play( "ambient/explosions/explode_9.wav", Pos, 85, 100, 1 - delay * 8 )
		end

		timer.Simple( delay, function()
			sound.Play( "LVS.MISSILE_EXPLOSION", Pos )
		end )
	else
		sound.Play( "LVS.MISSILE_EXPLOSION", Pos )
	end
end

function EFFECT:Think()
	if self.DieTime < CurTime() then return false end

	return true
end

function EFFECT:Render()
	local Scale = (self.DieTime - CurTime()) / self.LifeTime
	render.SetMaterial( GlowMat )
	render.DrawSprite( self.Pos, 2000 * Scale, 2000 * Scale, Color( 255, 200, 150, 255) )
end
