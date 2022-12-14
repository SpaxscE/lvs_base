
EFFECT.MatBeam = Material( "effects/lvs_base/spark" )
EFFECT.MatSprite = Material( "effects/lvs_base/glow" )

function EFFECT:Init( data )
	local pos  = data:GetOrigin()
	local dir = data:GetNormal()

	self.ID = data:GetFlags()

	self:SetRenderBoundsWS( pos, pos + dir * 50000 )
end

function EFFECT:Think()
	if not LVS._ActiveBullets then return false end

	local bullet = LVS._ActiveBullets[ self.ID ]

	if not bullet then return false end

	return true
end

function EFFECT:Render()
	local bullet = LVS._ActiveBullets[ self.ID ]

	local endpos = bullet.curpos or bullet.Src
	local dir = bullet.Dir

	local len = 2500 * math.min((CurTime() - bullet.StartTime) * 16,1)

	render.SetMaterial( self.MatBeam )

	render.DrawBeam( endpos - dir * len, endpos + dir * len * 0.1, 10, 1, 0, Color( 255, 100, 0, 255 ) )

	render.DrawBeam( endpos - dir * len * 0.5, endpos + dir * len * 0.1,  7, 1, 0, Color( 255, 200, 0, 255 ) )
	render.DrawBeam( endpos - dir * len * 0.5, endpos + dir * len * 0.1, 5, 1, 0, Color( 255, 200, 0, 255 ) )
	render.DrawBeam( endpos - dir * len * 0.5, endpos + dir * len * 0.1, 5, 1, 0, Color( 255, 255, 00, 255 ) )
end
