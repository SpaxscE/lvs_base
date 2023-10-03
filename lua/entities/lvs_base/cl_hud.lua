
LVS:AddHudEditor( "VehicleHealth", 10, ScrH() - 85,  220, 75, 220, 75, "VEHICLE HEALTH", 
	function( self, vehicle, X, Y, W, H, ScrX, ScrY, ply )
		if not vehicle.LVSHudPaintVehicleHealth then return end

		vehicle:LVSHudPaintVehicleHealth( X, Y, W, H, ScrX, ScrY, ply )
	end
)

LVS:AddHudEditor( "VehicleInfo", ScrW() - 460, ScrH() - 85,  220, 75, 220, 75, "VEHICLE INFORMATION", 
	function( self, vehicle, X, Y, W, H, ScrX, ScrY, ply )
		if not vehicle.LVSHudPaintInfoText then return end

		vehicle:LVSHudPaintInfoText( X, Y, W, H, ScrX, ScrY, ply )
	end
)

function ENT:LVSHudPaintVehicleHealth( X, Y, W, H, ScrX, ScrY, ply )
	draw.DrawText( "HEALTH ", "LVS_FONT", X + 102, Y + 35, color_white, TEXT_ALIGN_RIGHT )
	draw.DrawText( self:GetHP(), "LVS_FONT_HUD_LARGE", X + 102, Y + 20, color_white, TEXT_ALIGN_LEFT )
end

function ENT:LVSHudPaintVehicleIdentifier( X, Y, In_Col, target_ent )
	if not IsValid( target_ent ) then return end

	local HP = target_ent:GetHP()

	surface.SetDrawColor( In_Col.r, In_Col.g, In_Col.b, In_Col.a )
	LVS:DrawDiamond( X + 1, Y + 1, 20, HP / target_ent:GetMaxHP() )

	if target_ent:GetMaxShield() > 0 and HP > 0 then
		surface.SetDrawColor( 200, 200, 255, In_Col.a )
		LVS:DrawDiamond( X + 1, Y + 1, 24, target_ent:GetShield() / target_ent:GetMaxShield() )
	end
end

function ENT:LVSHudPaint( X, Y, ply )
end

function ENT:HurtMarker( intensity )
	LocalPlayer():EmitSound( "lvs/hit_receive"..math.random(1,2)..".wav", 75, math.random(95,105), 0.25 + intensity * 0.75, CHAN_STATIC )
	util.ScreenShake( Vector(0, 0, 0), 25 * intensity, 25 * intensity, 0.5, 1 )
end

function ENT:KillMarker()
	self.LastKillMarker = CurTime() + 0.5

	LocalPlayer():EmitSound( "lvs/hit_kill.wav", 85, 100, 0.4, CHAN_VOICE )
end

function ENT:HitMarker()
	self.LastHitMarker = CurTime() + 0.15

	LocalPlayer():EmitSound( "lvs/hit.wav", 85, math.random(95,105), 0.4, CHAN_ITEM )
end

function ENT:CritMarker()
	self.LastCritMarker = CurTime() + 0.15

	LocalPlayer():EmitSound(  "lvs/hit_crit.wav", 85, math.random(95,105), 0.4, CHAN_ITEM2 )
end

function ENT:GetHitMarker()
	return self.LastHitMarker or 0
end

function ENT:GetCritMarker()
	return self.LastCritMarker or 0
end

function ENT:GetKillMarker()
	return self.LastKillMarker or 0
end

function ENT:LVSPaintHitMarker( scr )
	local T = CurTime()

	local aV = math.cos( math.rad( math.max(((self:GetHitMarker() - T) / 0.15) * 360,0) ) )
	if aV ~= 1 then
		local Start = 12 + (1 - aV) * 8
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

	local aV = math.sin( math.rad( math.max(((self:GetCritMarker() - T) / 0.15) * 180,0) ) )
	if aV > 0.01 then
		local Start = 10 + aV * 40
		local End = 20 + aV * 45

		surface.SetDrawColor( 255, 100, 0, 255 )
		surface.DrawLine( scr.x + Start, scr.y + Start, scr.x + End, scr.y + End )
		surface.DrawLine( scr.x - Start, scr.y + Start, scr.x - End, scr.y + End ) 
		surface.DrawLine( scr.x + Start, scr.y - Start, scr.x + End, scr.y - End )
		surface.DrawLine( scr.x - Start, scr.y - Start, scr.x - End, scr.y - End ) 

		draw.NoTexture()
		surface.DrawTexturedRectRotated( scr.x + Start, scr.y + Start, 3, 20, 45 )
		surface.DrawTexturedRectRotated( scr.x - Start, scr.y + Start, 20, 3, 45 )
		surface.DrawTexturedRectRotated(  scr.x + Start, scr.y - Start, 20, 3, 45 )
		surface.DrawTexturedRectRotated( scr.x - Start, scr.y - Start, 3, 20, 45 )
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

function ENT:PaintCrosshairCenter( Pos2D, Col )
	if not Col then
		Col = Color( 255, 255, 255, 255 )
	end

	local Alpha = Col.a / 255
	local Shadow = Color( 0, 0, 0, 80 * Alpha )

	surface.DrawCircle( Pos2D.x, Pos2D.y, 4, Shadow )
	surface.DrawCircle( Pos2D.x, Pos2D.y, 5, Col )
	surface.DrawCircle( Pos2D.x, Pos2D.y, 6, Shadow )
end

function ENT:PaintCrosshairOuter( Pos2D, Col )
	if not Col then
		Col = Color( 255, 255, 255, 255 )
	end

	local Alpha = Col.a / 255
	local Shadow = Color( 0, 0, 0, 80 * Alpha )

	surface.DrawCircle( Pos2D.x,Pos2D.y, 17, Shadow )
	surface.DrawCircle( Pos2D.x, Pos2D.y, 18, Col )

	if LVS.AntiAliasingEnabled then
		surface.DrawCircle( Pos2D.x, Pos2D.y, 19, Color( Col.r, Col.g, Col.b, 150 * Alpha ) )
		surface.DrawCircle( Pos2D.x, Pos2D.y, 20, Shadow )
	else
		surface.DrawCircle( Pos2D.x, Pos2D.y, 19, Shadow )
	end
end

local Circles = {
	[1] = {r = -1, col = Color(0,0,0,200)},
	[2] = {r = 0, col = Color(255,255,255,200)},
	[3] = {r = 1, col = Color(255,255,255,255)},
	[4] = {r = 2, col = Color(255,255,255,200)},
	[5] = {r = 3, col = Color(0,0,0,200)},
}

function ENT:LVSDrawCircle( X, Y, target_radius, value )
	local endang = 360 * value

	if endang == 0 then return end

	for i = 1, #Circles do
		local data = Circles[ i ]
		local radius = target_radius + data.r
		local segmentdist = endang / ( math.pi * radius / 2 )

		for a = 0, endang, segmentdist do
			surface.SetDrawColor( data.col )

			surface.DrawLine( X - math.sin( math.rad( a ) ) * radius, Y + math.cos( math.rad( a ) ) * radius, X - math.sin( math.rad( a + segmentdist ) ) * radius, Y + math.cos( math.rad( a + segmentdist ) ) * radius )
		end
	end
end

function ENT:PaintCrosshairSquare( Pos2D, Col )
	if not Col then
		Col = Color( 255, 255, 255, 255 )
	end

	local X = Pos2D.x + 1
	local Y = Pos2D.y + 1

	local Size = 20

	surface.SetDrawColor( 0, 0, 0, 80 )
	surface.DrawLine( X - Size, Y + Size, X - Size * 0.5, Y + Size )
	surface.DrawLine( X + Size, Y + Size, X + Size * 0.5, Y + Size )
	surface.DrawLine( X - Size, Y + Size, X - Size, Y + Size * 0.5 )
	surface.DrawLine( X - Size, Y - Size, X - Size, Y - Size * 0.5 )
	surface.DrawLine( X + Size, Y + Size, X + Size, Y + Size * 0.5 )
	surface.DrawLine( X + Size, Y - Size, X + Size, Y - Size * 0.5 )
	surface.DrawLine( X - Size, Y - Size, X - Size * 0.5, Y - Size )
	surface.DrawLine( X + Size, Y - Size, X + Size * 0.5, Y - Size )

	if Col then
		surface.SetDrawColor( Col.r, Col.g, Col.b, Col.a )
	else
		surface.SetDrawColor( 255, 255, 255, 255 )
	end

	X = Pos2D.x
	Y = Pos2D.y

	surface.DrawLine( X - Size, Y + Size, X - Size * 0.5, Y + Size )
	surface.DrawLine( X + Size, Y + Size, X + Size * 0.5, Y + Size )
	surface.DrawLine( X - Size, Y + Size, X - Size, Y + Size * 0.5 )
	surface.DrawLine( X - Size, Y - Size, X - Size, Y - Size * 0.5 )
	surface.DrawLine( X + Size, Y + Size, X + Size, Y + Size * 0.5 )
	surface.DrawLine( X + Size, Y - Size, X + Size, Y - Size * 0.5 )
	surface.DrawLine( X - Size, Y - Size, X - Size * 0.5, Y - Size )
	surface.DrawLine( X + Size, Y - Size, X + Size * 0.5, Y - Size )
end