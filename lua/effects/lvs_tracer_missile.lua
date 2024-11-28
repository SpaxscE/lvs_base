
EFFECT.MatBeam = Material( "effects/lvs_base/spark" )
EFFECT.MatSprite = Material( "sprites/light_glow02_add" )

EFFECT.MatSmoke = {
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
	local pos  = data:GetOrigin()
	local dir = data:GetNormal()

	self.ID = data:GetMaterialIndex()

	self:SetRenderBoundsWS( pos, pos + dir * 50000 )

	self.emitter = ParticleEmitter( pos, false )

	self.OldPos = pos
	self.Dir = dir
end

function EFFECT:doFX( pos, curpos )
	if not IsValid( self.emitter ) then return end

	local particle = self.emitter:Add( self.MatSmoke[ math.random(1, #self.MatSmoke ) ], pos )
	if particle then
		particle:SetGravity( Vector(0,0,100) + VectorRand() * 50 ) 
		particle:SetVelocity( -self.Dir * 200  )
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

	local particle = self.emitter:Add( "particles/flamelet"..math.random(1,5), pos )
	if particle then
		particle:SetVelocity( -self.Dir * math.Rand(250,800) + self.Dir * 1500 )
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

	local particle = self.emitter:Add( "particles/flamelet"..math.random(1,5), curpos )
	if particle then
		particle:SetVelocity( -self.Dir * 200 + VectorRand() * 50 )
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

function EFFECT:Think()
	if not LVS:GetBullet( self.ID ) then
		if self.emitter then
			self.emitter:Finish()
		end

		return false
	end

	if not self.emitter then return true end

	local T = CurTime()

	if (self.nextDFX or 0) <= T then
		self.nextDFX = T + 0.02
		
		local bullet = LVS:GetBullet( self.ID )

		local Pos = bullet:GetPos()

		local Sub = self.OldPos - Pos
		local Dist = Sub:Length()
		local Dir = Sub:GetNormalized()

		for i = 0, Dist, 45 do
			local cur_pos = self.OldPos + Dir * i

			self:doFX( cur_pos, Pos )
		end

		self.OldPos = Pos
	end

	return true
end

function EFFECT:Render()
	local bullet = LVS:GetBullet( self.ID )

	local pos = bullet:GetPos()

	render.SetMaterial( self.MatSprite )
	render.DrawSprite( pos, 100, 100, Color( 255, 200, 150, 255 ) )
end
