EFFECT.Offset = Vector(-8,0,0)

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

		local particle = emitter:Add( Materials[ math.random(1, #Materials ) ], pos )
		if particle then
			particle:SetGravity( Vector(0,0,100) + VectorRand() * 50 ) 
			particle:SetVelocity( -self.Entity:GetForward() * 200  )
			particle:SetAirResistance( 600 ) 
			particle:SetDieTime( math.Rand(1.5,2) )
			particle:SetStartAlpha( 50 )
			particle:SetStartSize( 20 )
			particle:SetEndSize( 60 )
			particle:SetRoll( math.Rand( -1, 1 ) )
			particle:SetRollDelta( math.Rand( -1, 1 ) )
			particle:SetColor(40,40,40)
			particle:SetCollide( false )
		end

		local particle = emitter:Add( "particles/flamelet"..math.random(1,5), pos )
		if particle then
			particle:SetVelocity( -self.Entity:GetForward() * math.Rand(250,800) + self.Entity:GetVelocity())
			particle:SetDieTime( math.Rand(0.2,0.4) )
			particle:SetAirResistance( 0 ) 
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( 8 )
			particle:SetEndSize( 1 )
			particle:SetRoll( math.Rand(-1,1) )
			particle:SetColor( 255,255,255 )
			particle:SetGravity( Vector( 0, 0, 0 ) )
			particle:SetCollide( false )
		end
		
		local particle = emitter:Add( "particles/flamelet"..math.random(1,5), self.Entity:GetPos() )
		if particle then
			particle:SetVelocity( -self.Entity:GetForward() * 200 + VectorRand() * 50 )
			particle:SetDieTime( 0.25 )
			particle:SetAirResistance( 600 ) 
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( 6 )
			particle:SetEndSize( 2 )
			particle:SetRoll( math.Rand(-1,1) )
			particle:SetColor( 255,255,255 )
			particle:SetGravity( Vector( 0, 0, 0 ) )
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
	if IsValid(ent) then
		local pos = ent:LocalToWorld( self.Offset )

		render.SetMaterial( GlowMat )

		render.DrawSprite( pos, 100, 100, Color( 255, 200, 150, 255 ) )
	end
end
