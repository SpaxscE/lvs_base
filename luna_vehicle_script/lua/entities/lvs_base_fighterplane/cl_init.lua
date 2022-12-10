include("shared.lua")
include("cl_camera.lua")

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
	surface.DrawCircle( HitPlane.x, HitPlane.y, 5, Color( 255, 255, 255, 255 ) )
	surface.DrawCircle( HitPlane.x + 1, HitPlane.y + 1, 5, Color( 0, 0, 0, 80 ) )

	surface.DrawCircle( HitPlane.x, HitPlane.y, 18, Color( 255, 255, 255, 255 ) )
	surface.DrawCircle( HitPlane.x + 1, HitPlane.y + 1, 18, Color( 0, 0, 0, 80 ) )
end

function ENT:LVSHudPaintMouseAim( HitPlane, HitPilot, FreeLook )
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.DrawCircle( HitPlane.x, HitPlane.y, 10, Color( 255, 255, 255, 255 ) )
	surface.DrawLine( HitPlane.x + 10, HitPlane.y, HitPlane.x + 20, HitPlane.y ) 
	surface.DrawLine( HitPlane.x - 10, HitPlane.y, HitPlane.x - 20, HitPlane.y ) 
	surface.DrawLine( HitPlane.x, HitPlane.y + 10, HitPlane.x, HitPlane.y + 20 ) 
	surface.DrawLine( HitPlane.x, HitPlane.y - 10, HitPlane.x, HitPlane.y - 20 ) 
	surface.DrawCircle( HitPilot.x, HitPilot.y, 34, Color( 255, 255, 255, 255 ) )

	-- shadow
	surface.SetDrawColor( 0, 0, 0, 80 )
	surface.DrawCircle( HitPlane.x + 1, HitPlane.y + 1, 10, Color( 0, 0, 0, 80 ) )
	surface.DrawLine( HitPlane.x + 11, HitPlane.y + 1, HitPlane.x + 21, HitPlane.y + 1 ) 
	surface.DrawLine( HitPlane.x - 9, HitPlane.y + 1, HitPlane.x - 16, HitPlane.y + 1 ) 
	surface.DrawLine( HitPlane.x + 1, HitPlane.y + 11, HitPlane.x + 1, HitPlane.y + 21 ) 
	surface.DrawLine( HitPlane.x + 1, HitPlane.y - 19, HitPlane.x + 1, HitPlane.y - 16 ) 
	surface.DrawCircle( HitPilot.x + 1, HitPilot.y + 1, 34, Color( 0, 0, 0, 80 ) )

	local Sub = Vector(HitPilot.x,HitPilot.y,0) - Vector(HitPlane.x,HitPlane.y,0)
	local Len = Sub:Length()
	local Dir = Sub:GetNormalized()

	surface.SetDrawColor( 255, 255, 255, 100 )
	if Len > 34 and not FreeLook then
		surface.DrawLine( HitPlane.x + Dir.x * 10, HitPlane.y + Dir.y * 10, HitPilot.x - Dir.x * 34, HitPilot.y- Dir.y * 34 )

		-- shadow
		surface.SetDrawColor( 0, 0, 0, 50 )
		surface.DrawLine( HitPlane.x + Dir.x * 10 + 1, HitPlane.y + Dir.y * 10 + 1, HitPilot.x - Dir.x * 34+ 1, HitPilot.y- Dir.y * 34 + 1 )
	end
end
