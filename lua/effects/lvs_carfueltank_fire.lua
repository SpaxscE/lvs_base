
EFFECT.GlowMat = Material( "sprites/light_glow02_add" )
EFFECT.FireMat = {
	[1] = Material( "effects/lvs_base/flamelet1" ),
	[2] = Material( "effects/lvs_base/flamelet2" ),
	[3] = Material( "effects/lvs_base/flamelet3" ),
	[4] = Material( "effects/lvs_base/flamelet4" ),
	[5] = Material( "effects/lvs_base/flamelet5" ),
	[6] = Material( "effects/lvs_base/fire" ),
}

EFFECT.SmokeMat = {
	[1] = Material( "particle/smokesprites_0001" ),
	[2] = Material( "particle/smokesprites_0002" ),
	[3] = Material( "particle/smokesprites_0003" ),
	[4] = Material( "particle/smokesprites_0004" ),
	[5] = Material( "particle/smokesprites_0005" ),
	[6] = Material( "particle/smokesprites_0006" ),
	[7] = Material( "particle/smokesprites_0007" ),
	[8] = Material( "particle/smokesprites_0008" ),
	[9] = Material( "particle/smokesprites_0009" ),
	[10] = Material( "particle/smokesprites_0010" ),
	[11] = Material( "particle/smokesprites_0011" ),
	[12] = Material( "particle/smokesprites_0012" ),
	[13] = Material( "particle/smokesprites_0013" ),
	[14] = Material( "particle/smokesprites_0014" ),
	[15] = Material( "particle/smokesprites_0015" ),
	[16] = Material( "particle/smokesprites_0016" ),
}

EFFECT.Smoke = {
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
	local Ent = data:GetEntity()

	self.LifeTime = 1
	self.DieTime = CurTime() + self.LifeTime

	if not IsValid( Ent ) then return end

	self.Ent = Ent
	self.Pos = Ent:WorldToLocal( Pos + VectorRand() * 20 )
	self.RandomSize = math.Rand( 1, 2 )
	self.Vel = self.Ent:GetVelocity()

	local emitter = Ent:GetParticleEmitter( self.Pos )

	if not IsValid( emitter ) then return end

	for i = 1, 8 do
		local particle = emitter:Add( self.Smoke[ math.random(1, #self.Smoke ) ], Pos )

		local Dir = Angle(0,math.Rand(-180,180),0):Forward()
		Dir.z = -0.5
		Dir:Normalize()

		if particle then
			particle:SetVelocity( Dir * 250 )
			particle:SetDieTime( 0.5 + i * 0.01 )
			particle:SetAirResistance( 125 ) 
			particle:SetStartAlpha( 100 )
			particle:SetStartSize( 20 )
			particle:SetEndSize( 40 )
			particle:SetRoll( math.Rand(-1,1) * math.pi )
			particle:SetRollDelta( math.Rand(-1,1) * 3 )
			particle:SetColor( 0, 0, 0 )
			particle:SetGravity( Vector( 0, 0, 600 ) )
			particle:SetCollide( true )
			particle:SetBounce( 0 )
		end
	end
end

function EFFECT:Think()
	if not IsValid( self.Ent ) then return false end

	if self.DieTime < CurTime() then return false end

	self:SetPos( self.Ent:LocalToWorld( self.Pos ) )

	return true
end

function EFFECT:Render()
	if not IsValid( self.Ent ) or not self.Pos then return end

	self:RenderSmoke()
	self:RenderFire()
end

function EFFECT:RenderSmoke()
	local Scale = (self.DieTime - CurTime()) / self.LifeTime

	local Pos = self.Ent:LocalToWorld( self.Pos ) + Vector(0,0,25)

	local InvScale = 1 - Scale

	local Num = #self.SmokeMat - math.Clamp(math.ceil( Scale * #self.SmokeMat ) - 1,0, #self.SmokeMat - 1)

	local C = 10 + 10 * self.RandomSize
	local Size = (25 + 30 * InvScale) * self.RandomSize
	local Offset = (self.Vel * InvScale ^ 2) * 0.5

	render.SetMaterial( self.SmokeMat[ Num ] )
	render.DrawSprite( Pos + Vector(0,0,InvScale ^ 2 * 80 * self.RandomSize) - Offset, Size, Size, Color( C, C, C, 200 * Scale) )
end

function EFFECT:RenderFire()
	local Scale = (self.DieTime - 0.4 - CurTime()) / 0.6

	if Scale < 0 then return end

	local Pos = self.Ent:LocalToWorld( self.Pos )

	local InvScale = 1 - Scale

	render.SetMaterial( self.GlowMat )
	render.DrawSprite( Pos + Vector(0,0,InvScale ^ 2 * 10), 100 * InvScale, 100 * InvScale, Color( 255, 150, 75, 255) )

	local Num = #self.FireMat - math.Clamp(math.ceil( Scale * #self.FireMat ) - 1,0, #self.FireMat - 1)

	local Size = (10 + 20 * Scale) * self.RandomSize
	local Offset = (self.Vel * InvScale ^ 2) * 0.025

	render.SetMaterial( self.FireMat[ Num ] )
	render.DrawSprite( Pos + Vector(0,0,InvScale ^ 2 * 25) - Offset, Size, Size, Color( 255, 255, 255, 255) )
end