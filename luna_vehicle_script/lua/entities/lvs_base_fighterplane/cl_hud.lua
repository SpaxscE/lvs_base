
function ENT:LVSHudPaint( X, Y, ply )
	self:LVSHudPaintInfoText( X, Y, ply )

	local pod = self:GetDriverSeat()

	if not IsValid( pod ) then return end

	local pos = pod:LocalToWorld( pod:OBBCenter() )

	local HitPlane = util.TraceLine( {
		start = pos,
		endpos = (pos + self:GetForward() * 50000),
		filter = self:GetCrosshairFilterEnts()
	} ).HitPos:ToScreen()

	if ply:lvsMouseAim() then
		local HitPilot = util.TraceLine( {
			start = pos,
			endpos = (pos + ply:EyeAngles():Forward() * 50000),
			filter = self:GetCrosshairFilterEnts()
		} ).HitPos:ToScreen()

		self:LVSHudPaintMouseAim( HitPlane, HitPilot, ply:lvsKeyDown( "FREELOOK" ) )
	else
		self:LVSHudPaintDirectInput( HitPlane )
	end
end

function ENT:LVSHudPaintInfoText( X, Y, ply )
	local Throttle = math.Round(self:GetThrottle() * 100,0)
	local speed = math.Round( self:GetVelocity():Length() * 0.09144,0)

	draw.SimpleText( "THR", "LVS_FONT", 10, 10, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	draw.SimpleText( Throttle.."%" , "LVS_FONT", 120, 10, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

	draw.SimpleText( "IAS", "LVS_FONT", 10, 35, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	draw.SimpleText( speed.."km/h", "LVS_FONT", 120, 35, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
end

function ENT:LVSHudPaintDirectInput( HitPlane )
	surface.DrawCircle( HitPlane.x, HitPlane.y, 4, Color( 0, 0, 0, 80) )
	surface.DrawCircle( HitPlane.x, HitPlane.y, 5, Color( 255, 255, 255, 255 ) )
	surface.DrawCircle( HitPlane.x, HitPlane.y, 6, Color( 0, 0, 0, 80) )

	surface.DrawCircle( HitPlane.x, HitPlane.y, 17, Color( 0, 0, 0, 80 ) )
	surface.DrawCircle( HitPlane.x, HitPlane.y, 18, Color( 255, 255, 255, 255 ) )
	surface.DrawCircle( HitPlane.x, HitPlane.y, 19, Color( 255, 255, 255, 150 ) )
	surface.DrawCircle( HitPlane.x, HitPlane.y, 20, Color( 0, 0, 0, 80 ) )
end

function ENT:LVSHudPaintMouseAim( HitPlane, HitPilot, FreeLook )
	surface.DrawCircle( HitPlane.x, HitPlane.y, 4, Color( 0, 0, 0, 80) )
	surface.DrawCircle( HitPlane.x, HitPlane.y, 5, Color( 255, 255, 255, 255 ) )
	surface.DrawCircle( HitPlane.x, HitPlane.y, 6, Color( 0, 0, 0, 80) )

	surface.DrawCircle( HitPilot.x, HitPilot.y, 17, Color( 0, 0, 0, 80 ) )
	surface.DrawCircle( HitPilot.x, HitPilot.y, 18, Color( 255, 255, 255, 255 ) )
	surface.DrawCircle( HitPilot.x, HitPilot.y, 19, Color( 255, 255, 255, 150 ) )
	surface.DrawCircle( HitPilot.x, HitPilot.y, 20, Color( 0, 0, 0, 80 ) )

	local Sub = Vector(HitPilot.x,HitPilot.y,0) - Vector(HitPlane.x,HitPlane.y,0)
	local Len = Sub:Length()
	local Dir = Sub:GetNormalized()

	surface.SetDrawColor( 255, 255, 255, 100 )
	if Len > 20 and not FreeLook then
		surface.DrawLine( HitPlane.x + Dir.x * 5, HitPlane.y + Dir.y * 5, HitPilot.x - Dir.x * 20, HitPilot.y- Dir.y * 20 )

		-- shadow
		surface.SetDrawColor( 0, 0, 0, 50 )
		surface.DrawLine( HitPlane.x + Dir.x * 5 + 1, HitPlane.y + Dir.y * 5 + 1, HitPilot.x - Dir.x * 20+ 1, HitPilot.y- Dir.y * 20 + 1 )
	end
end
