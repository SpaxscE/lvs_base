
EFFECT.MatBeam = Material( "effects/lvs_base/spark" )

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

	local len = 500 * bullet:GetLength()

	render.SetMaterial( self.MatBeam )
	render.DrawBeam( endpos - dir * len, endpos + dir * len, 4, 1, 0, Color( 255, 255, 125, 255 ) )
	render.DrawBeam( endpos - dir * len, endpos + dir * len, 8, 1, 0, Color( 125, 80, 0, 255 ) )
end
