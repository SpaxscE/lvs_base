include("shared.lua")

function ENT:LFSHudPaintInfoText()
	local Throttle = math.ceil(self:GetThrottle() * 100)
	local Col = Color(255,255,255,255)

	draw.SimpleText( "THR", "miniLFS_FONT", 10, 10, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	draw.SimpleText( Throttle.."%" , "miniLFS_FONT", 120, 10, Col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
end

function ENT:LFSHudPaintCrosshair( HitPlane, HitPilot )
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.DrawCircle( HitPlane.x, HitPlane.y, 10, 255, 255, 255, 255 )
	surface.DrawLine( HitPlane.x + 10, HitPlane.y, HitPlane.x + 20, HitPlane.y ) 
	surface.DrawLine( HitPlane.x - 10, HitPlane.y, HitPlane.x - 20, HitPlane.y ) 
	surface.DrawLine( HitPlane.x, HitPlane.y + 10, HitPlane.x, HitPlane.y + 20 ) 
	surface.DrawLine( HitPlane.x, HitPlane.y - 10, HitPlane.x, HitPlane.y - 20 ) 
	--surface.DrawCircle( HitPilot.x, HitPilot.y, 34, 255, 255, 255, 255 )

	-- shadow
	surface.SetDrawColor( 0, 0, 0, 80 )
	surface.DrawCircle( HitPlane.x + 1, HitPlane.y + 1, 10, 0, 0, 0, 80 )
	surface.DrawLine( HitPlane.x + 11, HitPlane.y + 1, HitPlane.x + 21, HitPlane.y + 1 ) 
	surface.DrawLine( HitPlane.x - 9, HitPlane.y + 1, HitPlane.x - 16, HitPlane.y + 1 ) 
	surface.DrawLine( HitPlane.x + 1, HitPlane.y + 11, HitPlane.x + 1, HitPlane.y + 21 ) 
	surface.DrawLine( HitPlane.x + 1, HitPlane.y - 19, HitPlane.x + 1, HitPlane.y - 16 ) 
	--surface.DrawCircle( HitPilot.x + 1, HitPilot.y + 1, 34, 0, 0, 0, 80 )
end

function ENT:LFSCalcViewThirdPerson( view, ply )
	return view
end

function ENT:Initialize()
end

function ENT:Think()
end

function ENT:OnRemove()
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:DrawTranslucent()
end
