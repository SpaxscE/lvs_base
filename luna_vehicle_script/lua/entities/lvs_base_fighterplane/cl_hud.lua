
function ENT:LVSHudPaint( X, Y, ply )
	if ply ~= self:GetDriver() then return end

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

	self:LVSPaintHitMarker( HitPlane )
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

function ENT:LVSPaintHitMarker( scr )
	local T = CurTime()

	local HitMarkerTime = self:GetHitMarker()

	local aV = math.cos( math.rad( math.max(((HitMarkerTime - T) / 0.15) * 180,0) ) )

	if aV ~= 1 then
		local Start = 12 + (1 - aV ^ 2) * 8
		local dst = 10

		surface.SetDrawColor( 255, 255, 0, 255 )

		surface.DrawLine( scr.x + Start, scr.y + Start, scr.x + Start, scr.y + Start - dst )
		surface.DrawLine( scr.x + Start, scr.y + Start, scr.x + Start - dst, scr.y + Start )

		surface.DrawLine( scr.x + Start, scr.y - Start, scr.x + Start, scr.y - Start + dst )
		surface.DrawLine( scr.x + Start, scr.y - Start, scr.x + Start - dst, scr.y - Start )

		surface.DrawLine( scr.x - Start, scr.y + Start, scr.x - Start, scr.y + Start - dst )
		surface.DrawLine( scr.x - Start, scr.y + Start, scr.x - Start + dst, scr.y + Start )

		surface.DrawLine( scr.x - Start, scr.y - Start, scr.x - Start, scr.y - Start + dst )
		surface.DrawLine( scr.x - Start, scr.y - Start, scr.x - Start + dst, scr.y - Start )

		scr.x = scr.x + 1
		scr.y = scr.y + 1

		surface.SetDrawColor( 0, 0, 0, 80 )

		surface.DrawLine( scr.x + Start, scr.y + Start, scr.x + Start, scr.y + Start - dst )
		surface.DrawLine( scr.x + Start, scr.y + Start, scr.x + Start - dst, scr.y + Start )

		surface.DrawLine( scr.x + Start, scr.y - Start, scr.x + Start, scr.y - Start + dst )
		surface.DrawLine( scr.x + Start, scr.y - Start, scr.x + Start - dst, scr.y - Start )

		surface.DrawLine( scr.x - Start, scr.y + Start, scr.x - Start, scr.y + Start - dst )
		surface.DrawLine( scr.x - Start, scr.y + Start, scr.x - Start + dst, scr.y + Start )

		surface.DrawLine( scr.x - Start, scr.y - Start, scr.x - Start, scr.y - Start + dst )
		surface.DrawLine( scr.x - Start, scr.y - Start, scr.x - Start + dst, scr.y - Start )
	end

	local aV = math.sin( math.rad( math.sin( math.rad( math.max(((self:GetKillMarker() - T) / 0.2) * 90,0) ) ) * 90 ) )
	if aV > 0.01 then
		surface.SetDrawColor( 255, 255, 255, 15 * (aV ^ 4) )
		surface.DrawRect( 0, 0, ScrW(), ScrH() )

		local Start = 10 + aV * 40
		local End = 20 + aV * 45
		surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawLine( scr.x + Start, scr.y + Start, scr.x + End, scr.y + End )
		surface.DrawLine( scr.x - Start, scr.y + Start, scr.x - End, scr.y + End ) 
		surface.DrawLine( scr.x + Start, scr.y - Start, scr.x + End, scr.y - End )
		surface.DrawLine( scr.x - Start, scr.y - Start, scr.x - End, scr.y - End ) 

		draw.NoTexture()
		surface.DrawTexturedRectRotated( scr.x + Start, scr.y + Start, 5, 20, 45 )
		surface.DrawTexturedRectRotated( scr.x - Start, scr.y + Start, 20, 5, 45 )
		surface.DrawTexturedRectRotated(  scr.x + Start, scr.y - Start, 20, 5, 45 )
		surface.DrawTexturedRectRotated( scr.x - Start, scr.y - Start, 5, 20, 45 )
	end
end
