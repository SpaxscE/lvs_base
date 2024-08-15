
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

	if not self.emitter then return end

	local VecCol = (render.GetLightColor( pos ) * 0.8 + Vector(0.2,0.2,0.2)) * 255
	for i = 0,10 do
		local particle = self.emitter:Add( self.MatSmoke[math.random(1,#self.MatSmoke)], pos )

		if not particle then continue end

		particle:SetVelocity( dir * 700 + VectorRand() * 200 )
		particle:SetDieTime( math.Rand(2,3) )
		particle:SetAirResistance( 250 ) 
		particle:SetStartAlpha( 50 )
		particle:SetStartSize( 5 )
		particle:SetEndSize( 120 )
		particle:SetRollDelta( math.Rand(-1,1) )
		particle:SetColor( math.min( VecCol.r, 255 ), math.min( VecCol.g, 255 ), math.min( VecCol.b, 255 ) )
		particle:SetGravity( Vector(0,0,100) )
		particle:SetCollide( false )
	end

	for i = 0, math.random(1,12) do
		local particle = self.emitter:Add( "sprites/rico1", pos )

		if not particle then continue end

		particle:SetVelocity( dir * 2000 + VectorRand() * 50 )
		particle:SetDieTime( math.Rand(0.1,0.2) )
		particle:SetStartAlpha( 0 )
		particle:SetEndAlpha( 5 )
		particle:SetStartSize( math.Rand(0,0.5) )
		particle:SetEndSize( math.Rand(0,0.5) )
		particle:SetRollDelta( 100 )
		particle:SetAirResistance( 0 )
		particle:SetColor( 255, 200, 120 )
	end

	local trace = util.TraceLine( {
		start = pos,
		endpos = pos - Vector(0,0,500),
		mask = MASK_SOLID_BRUSHONLY,
	} )

	if not trace.Hit then return end

	local VecCol = (render.GetLightColor( trace.HitPos + trace.HitNormal ) * 0.8 + Vector(0.17,0.15,0.1)) * 255
	for i = 1,24 do
		local particle = self.emitter:Add( self.MatSmoke[math.random(1,#self.MatSmoke)], trace.HitPos )
		
		if not particle then continue end

		local ang = i * 15
		local X = math.cos( math.rad(ang) )
		local Y = math.sin( math.rad(ang) )

		particle:SetVelocity( Vector(X,Y,0) * 1000 )
		particle:SetDieTime( math.Rand(0.5,1) )
		particle:SetAirResistance( 500 ) 
		particle:SetStartAlpha( 100 )
		particle:SetStartSize( 25 )
		particle:SetEndSize( 80 )
		particle:SetRollDelta( math.Rand(-1,1) )
		particle:SetColor( math.min( VecCol.r, 255 ), math.min( VecCol.g, 255 ), math.min( VecCol.b, 255 ) )
		particle:SetGravity( Vector(0,0,150) + self.Dir * 2000 )
		particle:SetCollide( false )
	end
end

function EFFECT:Think()
	if not LVS:GetBullet( self.ID ) then
		if self.emitter then
			self.emitter:Finish()
		end

		local StartPos = self.OldPos
		local EndPos = StartPos + self.Dir * 1000

		local trace = util.TraceLine( {
			start = StartPos,
			endpos = EndPos,
		} )

		local effectdata = EffectData()
		effectdata:SetOrigin( trace.HitPos )
		effectdata:SetStart( self.Dir )
		effectdata:SetEntity( trace.Entity )
		effectdata:SetNormal( trace.HitNormal )
		effectdata:SetSurfaceProp( trace.SurfaceProps )
		util.Effect( "lvs_bullet_impact_ap", effectdata )

		return false
	end

	if not self.emitter then return true end

	local bullet = LVS:GetBullet( self.ID )

	local Pos = bullet:GetPos()

	local Sub = self.OldPos - Pos
	local Dist = Sub:Length()
	local Dir = Sub:GetNormalized()

	for i = 0, Dist, 25 do
		local cur_pos = self.OldPos + Dir * i

		local VecCol = (render.GetLightColor( cur_pos ) * 0.8 + Vector(0.2,0.2,0.2)) * 255

		local particle = self.emitter:Add( self.MatSmoke[math.random(1,#self.MatSmoke)], cur_pos )
		
		if not particle then continue end
		particle:SetVelocity( -Dir * 1500 + VectorRand() * 10 )
		particle:SetDieTime( math.Rand(0.05,1) )
		particle:SetAirResistance( 250 )
		particle:SetStartAlpha( 100 )
		particle:SetEndAlpha( 0 )

		particle:SetStartSize( 0 )
		particle:SetEndSize( 15 )

		particle:SetRollDelta( 1 )
		particle:SetColor( math.min( VecCol.r, 255 ), math.min( VecCol.g, 255 ), math.min( VecCol.b, 255 ) )
		particle:SetCollide( false )
	end

	self.OldPos = Pos

	return true
end

function EFFECT:Render()
	local bullet = LVS:GetBullet( self.ID )

	local endpos = bullet:GetPos()
	local dir = bullet:GetDir()

	local len = 1000 * bullet:GetLength()

	render.SetMaterial( self.MatBeam )

	render.DrawBeam( endpos - dir * len * 0.5, endpos + dir * len * 0.5, 10, 1, 0, Color( 100, 100, 100, 100 ) )
	render.DrawBeam( endpos - dir * len * 0.5, endpos + dir * len * 0.5 , 5, 1, 0, Color( 255, 255, 255, 255 ) )

	render.SetMaterial( self.MatSprite ) 
	render.DrawSprite( endpos, 400, 400, Color( 100, 100, 100, 255 ) )
end
