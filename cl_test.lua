
local W = 300
local H = 300
local S = 50
local R = 10

local X = W * 0.5 + 100
local Y = H * 0.5 + 100

local NumGearsForward = 4
local NumGearsReverse = 5

local GearsTotal = NumGearsForward + NumGearsReverse

local pattern = {}

local ypos = true
local xpos = 0

for i = 1, GearsTotal do
	ypos = not ypos

	if not ypos then
		xpos = xpos + 1
	end

	local name

	if i <= NumGearsForward then
		name = tostring( i )
	else
		local N = i - NumGearsForward - 1
		if N == 0 then
			name = "R"
		else
			name = "R"..tostring( N )
		end
	end

	pattern[ i ] = {
		x = xpos,
		y = ypos and 1 or -1,
		name = name,
	}
end

for id, data in pairs( pattern ) do
	data.x = ((data.x - 1) / (xpos - 1)) - 0.5
end

local OldX = X
local OldY = Y

hook.Add( "HUDPaint", "HUDPaint_DrawABox", function()
	draw.RoundedBox( R, X - W * 0.5, Y - H * 0.5, W, H, Color(150,150,150,255) )

	local oldX

	for index, data in pairs( pattern ) do
		local originX = X + data.x * (W - S)
		local originY = Y + data.y * (H - S) * 0.5

		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawLine( originX, originY, originX, Y )
		surface.DrawLine( originX + 1, originY, originX + 1, Y )
		surface.DrawLine( originX - 1, originY, originX - 1, Y )
		surface.DrawLine( originX + 2, originY, originX + 2, Y )
		surface.DrawLine( originX - 2, originY, originX - 2, Y )
		surface.DrawLine( originX + 3, originY, originX + 3, Y )
		surface.DrawLine( originX - 3, originY, originX - 3, Y )

		if not oldX then
			oldX = originX
		else
			if oldX ~= originX then
				surface.DrawLine( oldX, Y, originX, Y )
				surface.DrawLine( oldX, Y - 1, originX, Y - 1 )
				surface.DrawLine( oldX, Y + 1, originX, Y + 1 )
				surface.DrawLine( oldX, Y - 2, originX, Y - 2 )
				surface.DrawLine( oldX, Y + 2, originX, Y + 2 )
				surface.DrawLine( oldX, Y - 3, originX, Y - 3 )
				surface.DrawLine( oldX, Y + 3, originX, Y + 3 )
			end
		end

		--draw.SimpleText( data.name, "LVS_FONT_PANEL", originX, originY, Color(0,0,0,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		oldX = originX
	end

	if not vgui.CursorVisible() or input.IsKeyDown( KEY_Q ) then
		for index, data in pairs( pattern ) do
			local originX = X + data.x * (W - S)
			local originY = Y + data.y * (H - S) * 0.5

			draw.RoundedBox( 10, originX - 10, originY - 10, 20, 20, Color(255,255,255,255) )

			draw.SimpleText( data.name, "LVS_FONT_PANEL", originX, originY, Color(0,0,0,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end

		return
	end

	render.CapturePixels()

	local xmin = X - W * 0.5
	local xmax = xmin + W

	local ymin = Y - H * 0.5
	local ymax = ymin + H

	local MouseX = gui.MouseX()
	local MouseY = gui.MouseY()

	local Rate = 500 * RealFrameTime()

	for i = 1, Rate, 1 do
		local mX = math.Clamp( OldX + math.Clamp(MouseX - OldX,-1,1), xmin + R, xmax - R )
		local mY = math.Clamp( OldY + math.Clamp(MouseY - OldY,-1,1), ymin + R, ymax - R )

		local r,g,b,a = render.ReadPixel( mX, OldY )
		if (r+g+b) == 255 * 3 then OldX = mX end

		r,g,b,a = render.ReadPixel( OldX, mY )
		if (r+g+b) == 255 * 3 then OldY = mY end
	end

	for index, data in pairs( pattern ) do
		local originX = X + data.x * (W - S)
		local originY = Y + data.y * (H - S) * 0.5

		if math.abs(originX - OldX) < 10 and math.abs(originY - OldY) < 10 then
			draw.RoundedBox( 10, originX - 10, originY - 10, 20, 20, Color(255,0,0,255) )
		else
			draw.RoundedBox( 10, originX - 10, originY - 10, 20, 20, Color(255,255,255,255) )
		end

		draw.SimpleText( data.name, "LVS_FONT_PANEL", originX, originY, Color(0,0,0,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	draw.RoundedBox( R, OldX - R, OldY - R, R * 2, R * 2, Color(0,0,0,255) )

	if math.abs(MouseX - X - W * 0.5) > W then
		input.SetCursorPos( OldX, gui.MouseY() )
	end

	if math.abs(MouseY - Y - H * 0.5) > H then
		input.SetCursorPos( gui.MouseX(), OldY )
	end
end )
