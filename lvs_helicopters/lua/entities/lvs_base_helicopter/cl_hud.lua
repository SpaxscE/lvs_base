ENT.IconEngine = Material( "lvs/engine.png" )

function ENT:LVSHudPaintInfoText( X, Y, W, H, ScrX, ScrY, ply )
	local kmh = math.Round(self:GetVelocity():Length() * 0.09144,0)
	draw.DrawText( "km/h ", "LVS_FONT", X + 72, Y + 35, color_white, TEXT_ALIGN_RIGHT )
	draw.DrawText( kmh, "LVS_FONT_HUD_LARGE", X + 72, Y + 20, color_white, TEXT_ALIGN_LEFT )

	if ply ~= self:GetDriver() then return end

	local hX = X + W - H * 0.5
	local hY = Y + H * 0.25 + H * 0.25

	surface.SetMaterial( self.IconEngine )
	surface.SetDrawColor( 0, 0, 0, 200 )
	surface.DrawTexturedRectRotated( hX + 4, hY + 1, H * 0.5, H * 0.5, 0 )
	surface.SetDrawColor( color_white )
	surface.DrawTexturedRectRotated( hX + 2, hY - 1, H * 0.5, H * 0.5, 0 )

	if not self:GetEngineActive() then
		draw.SimpleText( "X" , "LVS_FONT",  hX, hY, Color(0,0,0,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	self:LVSDrawCircle( hX, hY, H * 0.35, self:GetThrustPercent() )
end

function ENT:LVSPreHudPaint( X, Y, ply )
	return true
end

ENT.Hud = true
ENT.HudThirdPerson = false
ENT.HudGradient = Material("gui/center_gradient")
ENT.HudColor = Color(255,255,255)

function ENT:PaintHeliFlightInfo( X, Y, ply, Pos2D )
	local Roll = self:GetAngles().r

	surface.SetDrawColor(0,0,0,40)
	surface.SetMaterial( self.HudGradient )
	surface.DrawTexturedRect( Pos2D.x - 270, Pos2D.y - 10, 140, 20 )
	surface.DrawTexturedRect( Pos2D.x + 130, Pos2D.y - 10, 140, 20 )

	local X = math.cos( math.rad( Roll ) )
	local Y = math.sin( math.rad( Roll ) )

	surface.SetDrawColor( self.HudColor.r, self.HudColor.g, self.HudColor.b, 255 )
	surface.DrawLine( Pos2D.x + X * 50, Pos2D.y + Y * 50, Pos2D.x + X * 125, Pos2D.y + Y * 125 ) 
	surface.DrawLine( Pos2D.x - X * 50, Pos2D.y - Y * 50, Pos2D.x - X * 125, Pos2D.y - Y * 125 ) 

	surface.DrawLine( Pos2D.x + 125, Pos2D.y, Pos2D.x + 130, Pos2D.y + 5 ) 
	surface.DrawLine( Pos2D.x + 125, Pos2D.y, Pos2D.x + 130, Pos2D.y - 5 ) 
	surface.DrawLine( Pos2D.x - 125, Pos2D.y, Pos2D.x - 130, Pos2D.y + 5 ) 
	surface.DrawLine( Pos2D.x - 125, Pos2D.y, Pos2D.x - 130, Pos2D.y - 5 ) 
	
	surface.SetDrawColor( 0, 0, 0, 80 )
	surface.DrawLine( Pos2D.x + X * 50 + 1, Pos2D.y + Y * 50 + 1, Pos2D.x + X * 125 + 1, Pos2D.y + Y * 125 + 1 ) 
	surface.DrawLine( Pos2D.x - X * 50 + 1, Pos2D.y - Y * 50 + 1, Pos2D.x - X * 125 + 1, Pos2D.y - Y * 125 + 1 ) 
	
	surface.DrawLine( Pos2D.x + 126, Pos2D.y + 1, Pos2D.x + 131, Pos2D.y + 6 ) 
	surface.DrawLine( Pos2D.x + 126, Pos2D.y + 1, Pos2D.x + 131, Pos2D.y - 4 ) 
	surface.DrawLine( Pos2D.x - 126, Pos2D.y + 1, Pos2D.x - 129, Pos2D.y + 6 ) 
	surface.DrawLine( Pos2D.x - 126, Pos2D.y + 1, Pos2D.x - 129, Pos2D.y - 4 )

	local X = math.cos( math.rad( Roll + 45 ) )
	local Y = math.sin( math.rad( Roll + 45 ) )
	surface.DrawLine( Pos2D.x + X * 30 - 1, Pos2D.y + Y * 30 + 1, Pos2D.x + X * 60 - 1, Pos2D.y + Y * 60 + 1 ) 
	local X = math.cos( math.rad( Roll + 135 ) )
	local Y = math.sin( math.rad( Roll + 135 ) )
	surface.DrawLine( Pos2D.x + X * 30 + 1, Pos2D.y + Y * 30 + 1, Pos2D.x + X * 60 + 1, Pos2D.y + Y * 60 + 1 ) 

	surface.SetDrawColor( self.HudColor.r, self.HudColor.g, self.HudColor.b, 255 )
	local X = math.cos( math.rad( Roll + 45 ) )
	local Y = math.sin( math.rad( Roll + 45 ) )
	surface.DrawLine( Pos2D.x + X * 30, Pos2D.y + Y * 30, Pos2D.x + X * 60, Pos2D.y + Y * 60 ) 
	local X = math.cos( math.rad( Roll + 135 ) )
	local Y = math.sin( math.rad( Roll + 135 ) )
	surface.DrawLine( Pos2D.x + X * 30, Pos2D.y + Y * 30, Pos2D.x + X * 60, Pos2D.y + Y * 60 )

	local Pitch = -self:GetAngles().p

	surface.DrawLine( Pos2D.x - 220, Pos2D.y, Pos2D.x - 180, Pos2D.y )
	surface.DrawLine( Pos2D.x + 220, Pos2D.y, Pos2D.x + 180, Pos2D.y )
	surface.SetDrawColor( 0, 0, 0, 80 )
	surface.DrawLine( Pos2D.x - 220, Pos2D.y + 1, Pos2D.x - 180, Pos2D.y + 1 )
	surface.DrawLine( Pos2D.x + 220, Pos2D.y + 1, Pos2D.x + 180, Pos2D.y + 1 )

	draw.DrawText( math.Round( Pitch, 2 ), "LVS_FONT_PANEL", Pos2D.x - 175, Pos2D.y - 7, Color( self.HudColor.r, self.HudColor.g, self.HudColor.b, 255 ), TEXT_ALIGN_LEFT )
	draw.DrawText( math.Round( Pitch, 2 ), "LVS_FONT_PANEL", Pos2D.x + 175, Pos2D.y - 7, Color( self.HudColor.r, self.HudColor.g, self.HudColor.b, 255 ), TEXT_ALIGN_RIGHT )

	for i = -90, 90 do
		local Y = -i * 10 + Pitch

		local absN = math.abs( i ) 

		local IsTen = absN == math.Round( absN / 10, 0 ) * 10

		local SizeX = IsTen and 20 or 10

		local Alpha = 255 - (math.min( math.abs( Y ) / 200,1) ^ 2) * 255
		surface.SetDrawColor( self.HudColor.r, self.HudColor.g, self.HudColor.b, Alpha * 0.75 )
		surface.DrawLine(Pos2D.x - 200 - SizeX, Pos2D.y + Y, Pos2D.x - 200, Pos2D.y + Y ) 
		surface.DrawLine(Pos2D.x + 200 + SizeX, Pos2D.y + Y, Pos2D.x + 200, Pos2D.y + Y ) 
		surface.SetDrawColor( 0, 0, 0, Alpha * 0.25 )
		surface.DrawLine(Pos2D.x - 200 - SizeX, Pos2D.y + Y + 1, Pos2D.x - 200, Pos2D.y + Y + 1 ) 
		surface.DrawLine(Pos2D.x + 200 + SizeX, Pos2D.y + Y + 1, Pos2D.x + 200, Pos2D.y + Y + 1) 

		if not IsTen then continue end

		draw.DrawText( i, "LVS_FONT_HUD", Pos2D.x - 225, Pos2D.y + Y - 10, Color( self.HudColor.r, self.HudColor.g, self.HudColor.b, Alpha * 0.5 ), TEXT_ALIGN_RIGHT )
		draw.DrawText( i, "LVS_FONT_HUD", Pos2D.x + 225, Pos2D.y + Y - 10, Color( self.HudColor.r, self.HudColor.g, self.HudColor.b, Alpha * 0.5 ), TEXT_ALIGN_LEFT )
	end
end

function ENT:LVSHudPaint( X, Y, ply )
	if not self:LVSPreHudPaint( X, Y, ply ) then return end

	if ply ~= self:GetDriver() then return end

	local HitPlane = self:GetEyeTrace( true ).HitPos:ToScreen()
	local HitPilot = self:GetEyeTrace().HitPos:ToScreen()

	local pod = ply:GetVehicle()

	if self.Hud then
		if not pod:GetThirdPersonMode() then
			self:PaintHeliFlightInfo( X, Y, ply, HitPilot )
		end
	end

	if self.HudThirdPerson then
		if pod:GetThirdPersonMode() then
			self:PaintHeliFlightInfo( X, Y, ply, HitPilot )
		end
	end

	self:PaintCrosshairCenter( HitPlane )
	self:PaintCrosshairOuter( HitPilot )

	if ply:lvsMouseAim() and not ply:lvsKeyDown( "FREELOOK" ) then
		self:LVSHudPaintMouseAim( HitPlane, HitPilot )
	end

	self:LVSPaintHitMarker( HitPilot )
end

function ENT:LVSHudPaintDirectInput( Pos2D )
	self:PaintCrosshairCenter( Pos2D )
	self:PaintCrosshairOuter( Pos2D )
end

function ENT:LVSHudPaintMouseAim( HitPlane, HitPilot )
	local Sub = Vector(HitPilot.x,HitPilot.y,0) - Vector(HitPlane.x,HitPlane.y,0)
	local Len = Sub:Length()
	local Dir = Sub:GetNormalized()

	surface.SetDrawColor( 255, 255, 255, 100 )
	if Len > 20 then
		surface.DrawLine( HitPlane.x + Dir.x * 5, HitPlane.y + Dir.y * 5, HitPilot.x - Dir.x * 20, HitPilot.y- Dir.y * 20 )

		-- shadow
		surface.SetDrawColor( 0, 0, 0, 50 )
		surface.DrawLine( HitPlane.x + Dir.x * 5 + 1, HitPlane.y + Dir.y * 5 + 1, HitPilot.x - Dir.x * 20+ 1, HitPilot.y- Dir.y * 20 + 1 )
	end
end

