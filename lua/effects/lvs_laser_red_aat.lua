
EFFECT.MatBeam = Material( "effects/spark" )
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

	local emitter = ParticleEmitter( pos, false )

	if not IsValid( emitter ) then return end

	local trace = util.TraceLine( {
		start = pos,
		endpos = pos - Vector(0,0,500),
		mask = MASK_SOLID_BRUSHONLY,
	} )

	if not trace.Hit then return end

	local VecCol = (render.GetLightColor( trace.HitPos + trace.HitNormal ) * 0.8 + Vector(0.17,0.15,0.1)) * 255
	for i = 1,24 do
		local particle = emitter:Add( self.MatSmoke[math.random(1,#self.MatSmoke)], trace.HitPos )
		
		if not particle then continue end

		local ang = i * 15
		local X = math.cos( math.rad(ang) )
		local Y = math.sin( math.rad(ang) )

		particle:SetVelocity( Vector(X,Y,0) * 3000 )
		particle:SetDieTime( math.Rand(0.5,1) )
		particle:SetAirResistance( 500 ) 
		particle:SetStartAlpha( 100 )
		particle:SetStartSize( 50 )
		particle:SetEndSize( 240 )
		particle:SetRollDelta( math.Rand(-1,1) )
		particle:SetColor( math.min( VecCol.r, 255 ), math.min( VecCol.g, 255 ), math.min( VecCol.b, 255 ) )
		particle:SetGravity( Vector(0,0,150) + dir * 2000 )
		particle:SetCollide( false )
	end

	emitter:Finish()

	local ply = LocalPlayer()

	if not IsValid( ply ) then return end

	local ViewEnt = ply:GetViewEntity()

	if not IsValid( ViewEnt ) then return end

	local Intensity = 8
	local Ratio = math.min( 250 / (ViewEnt:GetPos() - trace.HitPos):Length(), 1 )

	if Ratio < 0 then return end

	util.ScreenShake( trace.HitPos, Intensity * Ratio, 0.1, 0.5, 250 )
end

function EFFECT:Think()
	if not LVS:GetBullet( self.ID ) then return false end

	return true
end

function EFFECT:Render()
	local bullet = LVS:GetBullet( self.ID )

	local endpos = bullet:GetPos()
	local dir = bullet:GetDir()

	local len = 100 * bullet:GetLength()

	render.SetMaterial( self.MatSprite ) 
	render.DrawBeam( endpos - dir * len * 8, endpos + dir * len * 8, 200, 1, 0, Color( 255, 0, 0, 255 ) )

	render.SetMaterial( self.MatBeam )
	render.DrawBeam( endpos - dir * len, endpos + dir * len, 60, 1, 0, Color( 255, 0, 0, 255 ) )
	render.DrawBeam( endpos - dir * len, endpos + dir * len, 30, 1, 0, Color( 255, 255, 255, 255 ) )
end
