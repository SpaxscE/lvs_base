
local GlowMat = Material( "sprites/light_glow02_add" )
local FireMat = Material( "effects/fire_cloud1" )
local HeatMat = Material( "sprites/heatwave" )
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
	self.Entity = data:GetEntity()
	self.LifeTime = data:GetMagnitude()
	self.DieTime = CurTime() + self.LifeTime

	if not IsValid( self.Entity ) then return end

	local Pos, Dir = self:GetPosition()

	self.Emitter = ParticleEmitter( Pos, false )
	self:SetRenderBoundsWS( Pos, Pos + Dir * 50000 )

	local Pos, Dir = self:GetPosition()

	for i = 1,10 do
		self:MakeFlameStream( self.Emitter, Pos, Dir )
	end
end

function EFFECT:GetPosition()
	local ent = self.Entity

	if not IsValid( ent ) then return vector_origin, vector_origin end

	local Pos = ent:GetPos()
	local Dir = ent:GetForward()

	local Target = ent:GetTarget()
	local Attachment = ent:GetTargetAttachment()

	if IsValid( Target ) and Attachment ~= "" then
		local ID = Target:LookupAttachment( Attachment )
		local Muzzle = Target:GetAttachment( ID )
		Pos = Muzzle.Pos
		Dir = Muzzle.Ang:Forward()
	end

	return Pos, Dir
end

function EFFECT:MakeFlameStream( emitter, pos, dir )
	local particle = emitter:Add( Materials[ math.random(1, #Materials ) ], pos )

	if not particle then return end

	particle:SetVelocity( VectorRand() * 60 + dir * 200 )
	particle:SetDieTime( math.Rand(0.8,1.2) )
	particle:SetAirResistance( 400 ) 
	particle:SetStartAlpha( 100 )
	particle:SetStartSize( 2 )
	particle:SetEndSize( 20 )
	particle:SetRoll( math.Rand( -2, 2 ) )
	particle:SetRollDelta( math.Rand( -2, 2 ) )
	particle:SetColor( 0, 0, 0 )
	particle:SetGravity( Vector( 0, 0, 100 ) )
	particle:SetCollide( false )

	local particle = emitter:Add( "effects/lvs_base/fire", pos )
	if particle then
		particle:SetVelocity( VectorRand() * 60 + dir * math.Rand(100,200) )
		particle:SetDieTime( math.Rand(0.75,1.5) )
		particle:SetAirResistance( 40 ) 
		particle:SetStartAlpha( 255 )
		particle:SetStartSize( 1 )
		particle:SetEndSize( 0 )
		particle:SetRoll( math.Rand(-3,3) )
		particle:SetRollDelta( math.Rand(-6,6) )
		particle:SetColor( 255, 255, 255 )
		particle:SetGravity( Vector(0,0,-600) )
		particle:SetCollide( true )
	end

	local particle = emitter:Add( "effects/lvs_base/fire", pos )

	if particle then
		particle:SetVelocity( dir * 70 )
		particle:SetDieTime( 0.2 )
		particle:SetAirResistance( 0 ) 
		particle:SetStartAlpha( 255 )
		particle:SetStartSize( 5 )
		particle:SetEndSize( 0 )
		particle:SetRoll( math.Rand(-1,1) * 180 )
		particle:SetColor( 255,255,255 )
		particle:SetGravity( Vector( 0, 0, 100 ) )
		particle:SetCollide( false )
	end

	local particle = emitter:Add( "effects/lvs_base/flamelet"..math.random(1,5), pos )
	
	if particle then
		particle:SetVelocity( dir * 40 )
		particle:SetDieTime( 0.2 )
		particle:SetAirResistance( 0 ) 
		particle:SetStartAlpha( 255 )
		particle:SetStartSize( 2 )
		particle:SetEndSize( 0 )
		particle:SetRoll( math.Rand(-1,1) * 180 )
		particle:SetColor( 255,255,255 )
		particle:SetGravity( Vector( 0, 0, 100 ) )
		particle:SetCollide( false )
	end
end

function EFFECT:Think()
	local ent = self.Entity
	local emitter = self.Emitter

	local T = CurTime()

	if IsValid( ent ) and (self.DieTime or 0) > T then
		if (self.nextDFX or 0) < T then
			self.nextDFX = T + 0.01

			local Pos, Dir = self:GetPosition()

			self:SetRenderBoundsWS( Pos, Pos + Dir * 50000 )
		end

		return true
	end

	if emitter then
		emitter:Finish()
	end

	return false
end

function EFFECT:Render()
	local ent = self.Entity

	if not IsValid( ent ) then return end

	local Scale = (self.DieTime - CurTime()) / self.LifeTime
	local invScaleExp = (1 - Scale) ^ 2

	local Pos, Dir = self:GetPosition()

	local scroll = -CurTime() * 5

	local Up = Dir + VectorRand() * 0.08

	render.UpdateRefractTexture()
	render.SetMaterial( HeatMat )
	render.StartBeam( 3 )
		render.AddBeam( Pos, 8 * invScaleExp, scroll, Color( 0, 0, 255, 200 ) )
		render.AddBeam( Pos + Up * 32 * invScaleExp, 32 * invScaleExp, scroll + 2, color_white )
		render.AddBeam( Pos + Up * 128 * invScaleExp, 32 * invScaleExp, scroll + 5, Color( 0, 0, 0, 0 ) )
	render.EndBeam()

	local A = Scale ^ 2
	local Size = Scale * 64

	render.SetMaterial( GlowMat )
	render.DrawSprite( Pos, Size, Size, Color( 255 * A, 150 * A, 75 * A, 255 * A) )
end
