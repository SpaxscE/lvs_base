
function EFFECT:Init( data )
	self.Ent = data:GetEntity()

	self.Particles = {}

	if not IsValid( self.Ent ) then return end

	self.Player = self.Ent:GetOwner()

	local P1 = self.Ent:GetPos()
	local P2 = P1 + self.Player:GetAimVector() * 20000

	self:SetRenderBoundsWS( P1, P2 )
end

function EFFECT:Think()
	if not IsValid( self.Ent ) or not IsValid( self.Player ) or self.Ent:GetActive() or (not self.Ent:GetShootActive() and not self.Ent.ChargeStartTime) then
		if IsValid( self.Emitter ) then
			self.Emitter:Finish()
		end

		return false
	end

	return true
end

local BeamMat = Material( "effects/tool_tracer" )
local BeamColor = Color( 150, 200, 255, 255)
local TipMat = Material( "particle/particle_glow_05_addnofog" )
local MuzzleFX = Material( "effects/select_ring" )
local MuzzleFX2 = Material( "sprites/light_glow02_add" )

function EFFECT:RenderBeamSmall( StartPos, EndPos )
	local Scale = self.Ent:GetCharge()

	local T = CurTime() * (2 + Scale * 0.01)

	render.SetMaterial( BeamMat )
	render.DrawBeam( StartPos, EndPos, math.Rand(4.5,5) * Scale, T - 1, T, color_white )

	render.SetMaterial( TipMat )
	render.DrawSprite( EndPos, math.Rand(10,12) * Scale, math.Rand(10,12) * Scale, BeamColor )
end

function EFFECT:GetEmitter()
	if  IsValid( self.Emitter ) then return self.Emitter end

	self.Emitter = ParticleEmitter( self.Player:GetShootPos(), false )

	return self.Emitter
end

function EFFECT:DoSpark( Pos )
	local T = CurTime()

	if (self._Next or 0) > T then return end

	self._Next = T + 0.01

	local emitter = self:GetEmitter()

	if not IsValid( emitter ) then return end

	local Scale = self.Ent:GetCharge()

	local Dir = VectorRand() * (25 + 10 * Scale)

	for id, particle in pairs( self.Particles ) do
		if not particle then
			self.Particles[ id ] = nil

			continue
		end

		particle:SetGravity( (Pos - particle:GetPos()) * (50 + 50 * (Scale ^ 2)) )
	end

	local particle = emitter:Add( "effects/spark", Pos + Dir )

	if not particle then return end

	particle:SetDieTime( 0.25 )
	particle:SetStartAlpha( 255 )
	particle:SetEndAlpha( 0 )
	particle:SetStartSize( 1 )
	particle:SetEndSize( 0 )
	particle:SetColor( 150, 200, 255 )
	particle:SetAirResistance( 0 )
	particle:SetStartLength( 5 * Scale )
	particle:SetRoll( math.Rand(-10,10) )
	particle:SetRollDelta( math.Rand(-10,10) )

	table.insert( self.Particles, particle )
end

function EFFECT:RenderCore( StartPos )
	if not IsValid( self.Ent ) then return end

	local Scale = self.Ent:GetCharge()

	render.SetMaterial( MuzzleFX )
	render.DrawSprite( StartPos, math.Rand(8,9) * Scale, math.Rand(8,9) * Scale, BeamColor )

	render.SetMaterial( MuzzleFX2 )
	render.DrawSprite( StartPos, math.Rand(120,124) * Scale, math.Rand(120,124) * Scale, BeamColor )
end
	

function EFFECT:Render()
	if self.Player == LocalPlayer() and self.Player:GetViewEntity() == self.Player and not self.Player:ShouldDrawLocalPlayer() then
		local vm = self.Player:GetViewModel()

		if not IsValid( vm ) then return end

		local att = vm:GetAttachment( vm:LookupAttachment( "muzzle" ) )

		if not att then return end

		local StartPos = att.Pos

		local Start = self.Player:GetShootPos()
		local End = Start + self.Player:GetAimVector() * 1000

		self:SetRenderBoundsWS( Start, End )

		self:RenderCore( StartPos )

		local att1 = vm:GetAttachment( vm:LookupAttachment( "fork1t" ) )
		local att2 = vm:GetAttachment( vm:LookupAttachment( "fork2t" ) )

		if not att1 or not att2 then return end

		self:RenderBeamSmall( StartPos, att1.Pos )
		self:RenderBeamSmall( StartPos, att2.Pos )

		self:DoSpark( StartPos )

		return
	end

	if not IsValid( self.Ent ) then return end

	local att = self.Ent:GetAttachment( self.Ent:LookupAttachment( "core" ) )

	if not att then return end

	local StartPos = att.Pos

	self:SetRenderBoundsWS( StartPos, StartPos )

	self:RenderCore( StartPos )

	local att1 = self.Ent:GetAttachment( self.Ent:LookupAttachment( "fork1t" ) )
	local att2 = self.Ent:GetAttachment( self.Ent:LookupAttachment( "fork2t" ) )
	local att3 = self.Ent:GetAttachment( self.Ent:LookupAttachment( "fork3t" ) )

	if not att1 or not att2 or not att3 then return end

	self:RenderBeamSmall( StartPos, att1.Pos )
	self:RenderBeamSmall( StartPos, att2.Pos )
	self:RenderBeamSmall( StartPos, att3.Pos )
end
