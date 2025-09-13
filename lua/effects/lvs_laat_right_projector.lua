EFFECT.Mat = Material( "effects/lvs/ballturret_projectorbeam" )
EFFECT.HitMat = Material( "sprites/light_glow02_add" )

function EFFECT:Init( data )
	self.Entity = data:GetEntity()
	
	if IsValid( self.Entity ) then
		self.ID = self.Entity:LookupAttachment( "muzzle_ballturret_right" )
		
		if self.ID then
			local Muzzle = self.Entity:GetAttachment( self.ID )

			self:SetRenderBoundsWS( self.Entity:GetPos(), Muzzle.Ang:Up() * 50000 )
		end
	end
end

function EFFECT:Think()
	if not IsValid( self.Entity ) or not self.ID or not self.Entity:GetBTRFire() then
		return false
	end
	
	return true
end


function EFFECT:Render()
	if not self.ID or not IsValid( self.Entity ) then return end

	local Muzzle = self.Entity:GetAttachment( self.ID )

	local Dir = Muzzle.Ang:Up()
	local StartPos = Muzzle.Pos + Dir * 14
	local Trace = util.TraceLine( { start = StartPos, endpos = StartPos + Dir * 50000, filter = self } )
	local EndPos = Trace.HitPos

	self:SetRenderBoundsWS( StartPos, EndPos )

	render.SetMaterial( self.Mat )
	render.DrawBeam( StartPos, EndPos, 14 + math.random(0,4), 1, 0, Color(0,255,0,255) )
	render.DrawBeam( StartPos, EndPos, 3 + math.random(0,4), 1, 0, Color(255,255,255,255) )

	render.SetMaterial( self.HitMat )
	local A = 150 + math.random(0,20)
	local B = 70 + math.random(0,20)
	render.DrawSprite( StartPos, A, A, Color(0,255,0,255) )
	render.DrawSprite( StartPos, B, B, Color(255,255,255,255) )

	render.DrawSprite( EndPos, A, A, Color(0,255,0,255) )
	render.DrawSprite( EndPos + VectorRand() * 10, B, B, Color(255,255,255,255) )

	if math.random(0,5) == 1 then
		local emitter = ParticleEmitter( EndPos, false )
		local dir = (self.Entity:GetPos() - EndPos):GetNormalized()

		for i = 0, 10 do
			local particle = emitter:Add( "sprites/rico1", EndPos )

			local vel = VectorRand()  * 100 + dir * 40

			if not particle then continue end

			particle:SetVelocity( vel )
			particle:SetAngles( vel:Angle() + Angle(0,90,0) )
			particle:SetDieTime( math.Rand(0.1,0.3) * 0.5 )
			particle:SetStartAlpha( math.Rand( 200, 255 ) )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( math.Rand(1,30) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand(-100,100) )
			particle:SetRollDelta( math.Rand(-100,100) )

			particle:SetAirResistance( 0 )
		end
		
		emitter:Finish()
	end
end
