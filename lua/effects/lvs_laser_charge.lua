
EFFECT.HeatWaveMat = Material( "particle/warp1_warp" )
EFFECT.GlowMat = Material( "sprites/light_glow02_add" )

function EFFECT:Init( data )
	self.Ent = data:GetEntity()
	self.ID = data:GetAttachment()

	if not IsValid( self.Ent ) then return end

	
	local att = self.Ent:GetAttachment( self.ID )

	if not att then return end

	local Pos = att.Pos

	self.LifeTime = 0.35
	self.DieTime = CurTime() + self.LifeTime

	self.Emitter = ParticleEmitter( Pos, false )
	self.Particles = {}
end

function EFFECT:Think()
	if (self.DieTime or 0) < CurTime() or not IsValid( self.Ent ) then 
		if IsValid( self.Emitter ) then
			self.Emitter:Finish()
		end

		return false
	end

	self:DoSpark()

	return true
end

function EFFECT:DoSpark()
	local T = CurTime()

	if (self._Next or 0) > T then return end

	self._Next = T + 0.01

	if not IsValid( self.Emitter ) then return end

	if not IsValid( self.Ent ) or not self.ID then return end

	local att = self.Ent:GetAttachment( self.ID )

	if not att then return end

	local Pos = att.Pos
	local Dir = VectorRand() * 25

	for id, particle in pairs( self.Particles ) do
		if not particle then
			self.Particles[ id ] = nil

			continue
		end

		particle:SetGravity( (Pos - particle:GetPos()) * 50 )
	end

	local particle = self.Emitter:Add( "sprites/rico1", Pos + Dir )

	if not particle then return end

	particle:SetDieTime( 0.25 )
	particle:SetStartAlpha( 255 )
	particle:SetEndAlpha( 0 )
	particle:SetStartSize( math.Rand( 1, 5 ) )
	particle:SetEndSize( 0 )
	particle:SetColor( 255, 0, 0 )
	particle:SetAirResistance( 0 )
	particle:SetRoll( math.Rand(-10,10) )
	particle:SetRollDelta( math.Rand(-10,10) )

	table.insert( self.Particles, particle )
end

function EFFECT:Render()
	if not IsValid( self.Ent ) or not self.ID then return end

	local att = self.Ent:GetAttachment( self.ID )

	if not att then return end

	local Scale = (self.DieTime - CurTime()) / self.LifeTime

	if Scale <= 0 then return end

	local rnd = VectorRand() * math.Rand(0,0.5)

	render.SetMaterial( self.HeatWaveMat )
	render.DrawSprite( att.Pos, 30 *(1 - Scale), 30 * (1 - Scale), Color( 255, 255, 255, 255) )

	render.SetMaterial( self.GlowMat ) 
	render.DrawSprite( att.Pos + rnd, 120 *  (1 - Scale), 120 * (1 - Scale), Color(255,0,0,255) ) 
end
	
