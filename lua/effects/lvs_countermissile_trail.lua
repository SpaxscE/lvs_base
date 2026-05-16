
local FlareColor = Color( 255, 255, 255, 255 )
local FlareMat = Material( "sprites/physg_glow1" )

local GlowColor = Color( 255, 150, 100, 255 )
local GlowMat = Material( "sprites/light_glow02_add" )

local SmokeColor = Vector(100,100,100)

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

function EFFECT:GetIntensity()
	local fxTable = self:GetTable()

	if not IsValid( fxTable.Entity ) then return 0 end

	if not isfunction( fxTable.Entity.GetIntensity ) then return 1 end

	return fxTable.Entity:GetIntensity()
end

function EFFECT:Init( data )
	self.RandomOffset = math.random(0,1337)
	self.Entity = data:GetEntity()

	if IsValid( self.Entity ) then
		self.OldPos = self.Entity:GetPos()

		self.Emitter = ParticleEmitter( self.Entity:LocalToWorld( self.OldPos ), false )
	end
end

function EFFECT:doFX( pos, scale, fxTable )
	if not IsValid( fxTable.Emitter ) then return end

	local scaleClamped = math.max( scale, 0.35 )

	local particle = fxTable.Emitter:Add( Materials[ math.random(1, #Materials ) ], pos )
	if particle then
		particle:SetGravity( (Vector(0,0,250) + VectorRand() * 50) * scaleClamped ) 
		particle:SetVelocity( vector_origin )
		particle:SetAirResistance( 600 * scaleClamped ) 
		particle:SetDieTime( 1 )
		particle:SetStartAlpha( 150 )
		particle:SetStartSize( 20 * scaleClamped )
		particle:SetEndSize( 80 * scaleClamped )
		particle:SetRoll( math.Rand( -1, 1 ) )
		particle:SetRollDelta( math.Rand(0.2,0.6) )
		particle:SetColor(GlowColor.r,GlowColor.g,GlowColor.b)
		particle:SetCollide( false )
		particle:SetNextThink( CurTime() )
		particle:SetThinkFunction( function( p )
			local Fade = math.Clamp( (fxTable.EntityPos - p:GetPos()):LengthSqr() / (40000 * scale), 0, 1 )
			local Col = Vector(GlowColor.r,GlowColor.g,GlowColor.b) * (1-Fade) + SmokeColor * Fade

			p:SetColor( Col.x, Col.y, Col.z )
			particle:SetStartAlpha( 150 * (1-Fade) + 50 * Fade )

			if Fade >= 1 then
				p:SetNextThink( CurTime() + 1 )
			else
				p:SetNextThink( CurTime() )
			end
		end )
	end
end

function EFFECT:UpdateTrail( fxTable )
	local oldpos = self.OldPos
	local newpos = self.EntityPos
	self:SetPos( newpos )

	local Sub = (newpos - oldpos)
	local Dir = Sub:GetNormalized()
	local Len = Sub:Length()

	self.OldPos = newpos

	if not IsValid( fxTable.Emitter ) then return end

	local scale = self:GetIntensity()

	for i = 0, Len, 40 do
		local pos = oldpos + Dir * i

		self:doFX( pos, scale, fxTable )
	end

	for i = 1, 10 do
		local spark = fxTable.Emitter:Add("effects/spark", newpos )

		if not spark then continue end

		spark:SetStartAlpha( 255 )
		spark:SetEndAlpha( 0 )
		spark:SetCollide( true )
		spark:SetBounce( math.Rand(0,1) )
		spark:SetColor( 255, 255, 255 )
		spark:SetGravity( Vector(0,0,-600) )
		spark:SetEndLength(0)

		spark:SetEndSize( 4 )
		spark:SetStartSize( 1 )

		spark:SetStartLength( math.Rand(10,20) )
		spark:SetDieTime( 0.2 )
		spark:SetVelocity( VectorRand() * 40 + VectorRand() * 400 * scale )
	end
end

function EFFECT:Think()
	local T = CurTime()
	local fxTable = self:GetTable()

	if IsValid( fxTable.Entity ) then
		fxTable.nextDFX = fxTable.nextDFX or 0

		if fxTable.nextDFX < T then
			fxTable.nextDFX = T + math.max( 0.25 - fxTable.Entity:GetVelocity():Length() / 1000, 0.025 )
			
			fxTable.EntityDir = fxTable.Entity:GetForward()
			fxTable.EntityPos = fxTable.Entity:GetPos()

			self:UpdateTrail( fxTable )
		end

		return true
	end

	if IsValid( fxTable.Emitter ) then
		fxTable.Emitter:Finish()
	end

	return false
end

function EFFECT:Render()
	local ent = self.Entity

	if not IsValid( ent ) then return end

	local scale = math.min( self:GetIntensity() * 2, 1 ) ^ 2
	local pos = ent:GetPos()

	render.SetMaterial( GlowMat )
	render.DrawSprite( pos, 320 * scale, 320 * scale, Color(GlowColor.r * 0.5,GlowColor.g * 0.5, GlowColor.b * 0.5, GlowColor.a * 0.5) )

	if not self.RandomOffset then return end

	render.SetMaterial( FlareMat )
	for i = 1, 10 do
		local Ang = (self.RandomOffset + CurTime()) * 1000 + i * 100
		local offset = Angle( Ang, Ang * 5, Ang * 1.25 ):Forward() * i * scale

		render.DrawSprite( pos + offset, 20 * scale, 20 * scale, FlareColor )
	end
end
