EFFECT.Mat = Material( "effects/lvs/ballturret_projectorbeam" )
EFFECT.HitMat = Material( "sprites/light_glow02_add" )

function EFFECT:Init( data )
	self.Entity = data:GetEntity()

	if IsValid( self.Entity ) then
		self.ID = self.Entity:LookupAttachment( "muzzle_primary" )

		if self.ID then
			local Muzzle = self.Entity:GetAttachment( self.ID )

			self:SetRenderBoundsWS( self.Entity:GetPos(), -Muzzle.Ang:Right() * 50000 )
		end
	end

	self.SpawnTime = CurTime()
end

function EFFECT:Think()
	if not IsValid( self.Entity ) or not self.ID or not self.Entity:GetProjectorBeam() then
		return false
	end

	return true
end

function EFFECT:Render()
	if not self.ID or not IsValid( self.Entity ) then return end

	local T = CurTime()

	local Mul = math.min( math.max( 1.5 - (T - self.SpawnTime), 0 ) ^ 2, 1 )

	local Muzzle = self.Entity:GetAttachment( self.ID )

	local Dir = -Muzzle.Ang:Right()
	local StartPos = Muzzle.Pos
	local Trace = util.TraceLine( { start = StartPos, endpos = StartPos + Dir * 50000, filter = self } )
	local EndPos = Trace.HitPos

	self:SetRenderBoundsWS( StartPos, EndPos )

	render.SetMaterial( self.Mat )
	render.DrawBeam( StartPos, EndPos, (16 + math.random(0,3)) * Mul, 1, 0, Color(255,0,0,255) )
	render.DrawBeam( StartPos, EndPos, (4 + math.random(0,2)) * Mul, 1, 0, Color(255,255,255,255) )

	render.SetMaterial( self.HitMat )
	local A = 150 + math.random(0,20)
	local B = 70 + math.random(0,20)
	render.DrawSprite( StartPos, A * Mul, A * Mul, Color(255,0,0,255) )
	render.DrawSprite( StartPos, B * Mul, B * Mul, Color(255,255,255,255) )

	render.DrawSprite( EndPos, A, A, Color(255,0,0,255) )
	render.DrawSprite( EndPos + VectorRand() * 10, B, B, Color(255,255,255,255) )

	if (self._Next or 0) > T then return end

	self._Next = T + 0.02

	local emitter = ParticleEmitter( EndPos, false )

	if not emitter or not IsValid( emitter ) then return end

	local dir = (self.Entity:GetPos() - EndPos):GetNormalized()
	
	for i = 0, 3 do
		local particle = emitter:Add( "sprites/light_glow02_add", EndPos )

		local vel = VectorRand() * 250 + Trace.HitNormal

		if not particle then continue end

		particle:SetVelocity( vel )
		particle:SetAngles( vel:Angle() + Angle(0,90,0) )
		particle:SetDieTime( math.Rand(0.2,0.4) )
		particle:SetStartAlpha( 255 )
		particle:SetEndAlpha( 0 )
		particle:SetStartSize( math.Rand(12,24) )
		particle:SetEndSize( 0 )
		particle:SetRoll( math.Rand(-100,100) )
		particle:SetRollDelta( math.Rand(-100,100) )
		particle:SetColor( 255, 0, 0 )
		particle:SetGravity( Vector(0,0,-600) )

		particle:SetAirResistance( 0 )

		particle:SetCollide( true )
		particle:SetBounce( 1 )
	end

	local Dist = (StartPos - EndPos):Length()

	local invMul = (1 - Mul)

	for i = 0, Dist, 25 do
		local Pos = StartPos + Dir * i

		local particle = emitter:Add( "sprites/rico1", Pos )
		
		local vel = VectorRand()  * 150
		
		if not particle then continue end

		particle:SetVelocity( vel + vel * invMul )
		particle:SetDieTime( 0.1 + 0.15 * invMul )
		particle:SetStartAlpha( 255 )
		particle:SetEndAlpha( 0 )
		particle:SetStartSize( math.Rand( 1, 5 ) + invMul * 2 )
		particle:SetEndSize( 0 )
		particle:SetColor( 50 + 205 * Mul, 0, 0 )
		particle:SetAirResistance( 0 )
		particle:SetRoll( math.Rand(-10,10) )
		particle:SetRollDelta( math.Rand(-10,10) )
		particle:SetGravity( Vector(0,0,-600 * invMul) )

		particle:SetAirResistance( 0 )
	end

	emitter:Finish()
end
