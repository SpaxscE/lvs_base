
EFFECT.MatBeam = Material( "effects/spark" )
EFFECT.MatSprite = Material( "sprites/light_glow02_add" )

function EFFECT:Init( data )
	local pos  = data:GetOrigin()
	local dir = data:GetNormal()

	self.ID = data:GetMaterialIndex()

	self:SetRenderBoundsWS( pos, pos + dir * 50000 )
end

function EFFECT:Think()
	if not LVS:GetBullet( self.ID ) then return false end

	return true
end

function EFFECT:Render()
	local bullet = LVS:GetBullet( self.ID )

	local endpos = bullet:GetPos()
	local dir = bullet:GetDir()

	local len = 300 * bullet:GetLength()

	render.SetMaterial( self.MatSprite ) 
	render.DrawBeam( endpos - dir * len * 2, endpos + dir * len * 2, 200, 1, 0, Color( 255, 0, 0, 255 ) )

	render.SetMaterial( self.MatBeam )
	render.DrawBeam( endpos - dir * len, endpos + dir * len, 45, 1, 0, Color( 255, 0, 0, 255 ) )
	render.DrawBeam( endpos - dir * len, endpos + dir * len, 15, 1, 0, Color( 255, 255, 255, 255 ) )
end
