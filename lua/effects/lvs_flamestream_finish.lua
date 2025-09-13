
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
	self.LifeTime = data:GetMagnitude() * 4
	self.DieTime = CurTime() + self.LifeTime

	if not IsValid( self.Entity ) then return end

	local Pos, Dir = self:GetPosition()

	self.Emitter = ParticleEmitter( Pos, false )
	self:SetRenderBoundsWS( Pos, Pos + Dir * 50000 )
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

function EFFECT:DoSmoke( emitter, pos, dir )

	local Scale = (self.DieTime - CurTime()) / self.LifeTime

	local particle = emitter:Add( Materials[ math.random(1, #Materials ) ], pos )

	if not particle then return end

	particle:SetVelocity( dir * 20 )
	particle:SetDieTime( math.Rand(0.8,1.2) )
	particle:SetAirResistance( 400 ) 
	particle:SetStartAlpha( 50 * Scale )
	particle:SetStartSize( 2 )
	particle:SetEndSize( 20 )
	particle:SetRoll( math.Rand( -2, 2 ) )
	particle:SetRollDelta( math.Rand( -2, 2 ) )
	particle:SetColor( 0, 0, 0 )
	particle:SetGravity( Vector( 0, 0, 100 ) )
	particle:SetCollide( false )
end

function EFFECT:Think()
	local ent = self.Entity
	local emitter = self.Emitter

	local T = CurTime()

	if IsValid( ent ) and (self.DieTime or 0) > T then
		if (self.nextDFX or 0) < T then
			self.nextDFX = T + 0.01

			local Pos, Dir = self:GetPosition()

			if not ent:GetActive() and math.random(1,6) == 1 then
				self:DoSmoke( emitter, Pos, Dir )
			end

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
end
