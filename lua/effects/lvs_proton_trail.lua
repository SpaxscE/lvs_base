EFFECT.Offset = Vector(-8,0,0)

local GlowMat = Material( "effects/select_ring" )

function EFFECT:Init( data )
	self.Entity = data:GetEntity()

	if IsValid( self.Entity ) then
		self.OldPos = self.Entity:LocalToWorld( self.Offset )

		self.Emitter = ParticleEmitter( self.Entity:LocalToWorld( self.OldPos ), false )
	end
end

function EFFECT:doFX( pos )
	if not IsValid( self.Entity ) then return end

	if IsValid( self.Emitter ) then
		local emitter = self.Emitter

		local particle = emitter:Add( "effects/lvs_base/flamelet"..math.random(1,5), pos )
		if particle then
			particle:SetVelocity( -self.Entity:GetForward() * math.Rand(250,800) + self.Entity:GetVelocity())
			particle:SetDieTime( 1 )
			particle:SetAirResistance( 0 ) 
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( 8 )
			particle:SetEndSize( 1 )
			particle:SetRoll( math.Rand(-1,1) )
			particle:SetColor( 0,0,255 )
			particle:SetGravity( Vector( 0, 0, 600 ) )
			particle:SetCollide( false )
		end
		
		local particle = emitter:Add( "effects/lvs_base/flamelet"..math.random(1,5), self.Entity:GetPos() )
		if particle then
			particle:SetVelocity( -self.Entity:GetForward() * 200 + VectorRand() * 50 )
			particle:SetDieTime( 1 )
			particle:SetAirResistance( 600 ) 
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( 6 )
			particle:SetEndSize( 2 )
			particle:SetRoll( math.Rand(-1,1) )
			particle:SetColor( 0,0,255 )
			particle:SetGravity( Vector( 0, 0, 600 ) )
			particle:SetCollide( false )
		end
	end
end

function EFFECT:Think()
	if IsValid( self.Entity ) then
		self.nextDFX = self.nextDFX or 0
		
		if self.nextDFX < CurTime() then
			self.nextDFX = CurTime() + 0.02

			local oldpos = self.OldPos
			local newpos = self.Entity:LocalToWorld( self.Offset )
			self:SetPos( newpos )

			local Sub = (newpos - oldpos)
			local Dir = Sub:GetNormalized()
			local Len = Sub:Length()

			self.OldPos = newpos

			for i = 0, Len, 45 do
				local pos = oldpos + Dir * i

				self:doFX( pos )
			end
		end

		return true
	end

	if IsValid( self.Emitter ) then
		self.Emitter:Finish()
	end

	return false
end

function EFFECT:Render()
	local ent = self.Entity
	local pos = ent:LocalToWorld( self.Offset )

	render.SetMaterial( GlowMat )

	render.DrawSprite( pos, 100, 100, Color( 0, 127, 255, 50 ) )
end
