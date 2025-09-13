
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

EFFECT.GlowMat = Material( "sprites/light_glow02_add" )
EFFECT.FireMat = Material( "effects/muzzleflash2" )

function EFFECT:Init( data )
	self.Pos = data:GetOrigin()
	self.Ang = data:GetAngles()
	self.Ent = data:GetEntity()

	self.LifeTime = 0.5
	self.DieTime = CurTime() + self.LifeTime

	if not IsValid( self.Ent ) then return end

	self.Mat = self.SmokeMat[ math.random(1,#self.SmokeMat) ]

	local Pos = self.Ent:LocalToWorld( self.Pos )

	self:SetPos( Pos )

	local dlight = DynamicLight( self.Ent:EntIndex() * math.random(1,4), true )
	if dlight then
		dlight.pos = Pos
		dlight.r = 255
		dlight.g = 180
		dlight.b = 100
		dlight.brightness = 1
		dlight.Decay = 2000
		dlight.Size = 300
		dlight.DieTime = CurTime() + 0.2
	end

	sound.Play( "lvs/vehicles/generic/exhaust_backfire"..math.random(1,3)..".ogg", Pos, 75, 100, 1 )

	local vel = self.Ent:GetVelocity()
	local dir = self.Ent:LocalToWorldAngles( self.Ang ):Forward()
	local emitter = ParticleEmitter( Pos, false )

	if emitter then
		for i = 0, 12 do
			local particle = emitter:Add( "sprites/rico1", Pos )

			if not particle then continue end

			particle:SetVelocity( vel + dir * 100 + VectorRand() * 100 )
			particle:SetDieTime( math.Rand(0.2,0.4) )
			particle:SetStartAlpha( 0 )
			particle:SetEndAlpha( 25 )
			particle:SetStartSize( 1 )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand(-100,100) )
			particle:SetRollDelta( math.Rand(-100,100) )
			particle:SetCollide( true )
			particle:SetBounce( 0.5 )
			particle:SetAirResistance( 0 )
			particle:SetColor( 255, 225, 150 )
			particle:SetGravity( Vector(0,0,-600) )
		end

		emitter:Finish()
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
end

function EFFECT:RenderSmoke()
	if not self.Pos or not self.Ang then return end

	local Scale = (self.DieTime - CurTime()) / self.LifeTime
	local InvScale = 1 - Scale

	local Pos = self.Ent:LocalToWorld( self.Pos )
	local Ang = self.Ent:LocalToWorldAngles( self.Ang )

	local FlameSize = 40 * Scale ^ 2
	render.SetMaterial( self.FireMat )
	for i = 1, 4 do
		render.DrawSprite( Pos + Ang:Forward() * InvScale * 5 + VectorRand() * 2, FlameSize, FlameSize, Color( 255, 255, 255, 255 * InvScale) )
	end

	local GlowSize = 80 * Scale ^ 2
	render.SetMaterial( self.GlowMat )
	render.DrawSprite( Pos + Ang:Forward() * InvScale * 10, GlowSize, GlowSize, Color(255* InvScale, 150* InvScale,75* InvScale,255* InvScale) )

	if not self.Mat then return end

	local C = 40
	local Size = (20 + 50 * InvScale)

	render.SetMaterial( self.Mat )
	render.DrawSprite( Pos + Ang:Forward() * InvScale * 40, Size, Size, Color( C, C, C, 255 * Scale) )
end

