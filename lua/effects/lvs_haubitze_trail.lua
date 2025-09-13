local MatBeam = Material( "effects/lvs_base/spark" )
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
		self.OldPos = self.Entity:GetPos()

		self.Emitter = ParticleEmitter( self.Entity:LocalToWorld( self.OldPos ), false )
	end
end

function EFFECT:doFX( pos )
	if not IsValid( self.Entity ) then return end

	if IsValid( self.Emitter ) then
		local emitter = self.Emitter

		local VecCol = (render.GetLightColor( pos ) * 0.8 + Vector(0.2,0.2,0.2)) * 255

		local particle = emitter:Add( Materials[ math.random(1, #Materials ) ], pos )
		if particle then
			particle:SetVelocity( -self.Entity:GetForward() * 1500 + VectorRand() * 10  )
			particle:SetDieTime( math.Rand(0.05,1) )
			particle:SetAirResistance( 250 )
			particle:SetStartAlpha( 100 )
			particle:SetEndAlpha( 0 )

			particle:SetStartSize( 0 )
			particle:SetEndSize( 30 )

			particle:SetRollDelta( 1 )
			particle:SetColor( math.min( VecCol.r, 255 ), math.min( VecCol.g, 255 ), math.min( VecCol.b, 255 ) )
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
			local newpos = self.Entity:GetPos()
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

	if not IsValid( ent ) then return end

	local pos = ent:GetPos()
	local dir = ent:GetForward()

	local len = 250

	render.SetMaterial( MatBeam )
	render.DrawBeam( pos - dir * len, pos + dir * len * 0.1, 32, 1, 0, Color( 100, 100, 100, 100 ) )
	render.DrawBeam( pos - dir * len * 0.5, pos + dir * len * 0.1, 16, 1, 0, Color( 255, 255, 255, 255 ) )

	render.SetMaterial( GlowMat )
	render.DrawSprite( pos, 250, 250, Color( 100, 100, 100, 255 ) )
end
