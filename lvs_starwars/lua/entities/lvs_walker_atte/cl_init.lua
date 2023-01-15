include("shared.lua")
include( "cl_ikfunctions.lua" )
include( "cl_camera.lua" )
include( "cl_legs.lua" )

function ENT:PreDraw()
	return false
end

function ENT:PreDrawTranslucent()
	return true
end

local Zoom = 0
local zoom_mat = Material( "vgui/zoom" )

function ENT:LVSHudPaint( X, Y, ply )
	if ply ~= self:GetDriver() then return end

	local Pos2D = self:GetEyeTrace().HitPos:ToScreen()

	self:PaintCrosshairCenter( Pos2D )
	self:PaintCrosshairOuter( Pos2D )
	self:LVSPaintHitMarker( Pos2D )

	local TargetZoom = ply:lvsKeyDown( "ZOOM" ) and 1 or 0

	Zoom = Zoom + (TargetZoom - Zoom) * RealFrameTime() * 10

	surface.SetDrawColor( Color(255,255,255,255 * Zoom) )
	surface.SetMaterial(zoom_mat ) 
	surface.DrawTexturedRectRotated( X + X * 0.5, Y * 0.5, X, Y, 0 )
	surface.DrawTexturedRectRotated( X + X * 0.5, Y + Y * 0.5, Y, X, 270 )
	surface.DrawTexturedRectRotated( X * 0.5, Y * 0.5, Y, X, 90 )
	surface.DrawTexturedRectRotated( X * 0.5, Y + Y * 0.5, X, Y, 180 )
end
