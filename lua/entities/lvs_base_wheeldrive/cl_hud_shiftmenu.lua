local W = 300
local H = 300
local S = 50
local R = 10

LVS:AddHudEditor( "CarShiftMenu",  50, ScrH() * 0.5 - H * 0.5,  W, H, W, H, "CAR MENU",
	function( self, vehicle, X, Y, W, H, ScrX, ScrY, ply )
		if not vehicle.LVSHudPaintCarShiftMenu then return end

		vehicle:LVSHudPaintCarShiftMenu( X, Y, W, H, ScrX, ScrY, ply )
	end
)

local mDeltaX = 0
local mDeltaY = 0

function ENT:InputMouseApply( ply, cmd, x, y, ang )
	if not ply:lvsKeyDown( "CAR_CLUTCH" ) then return end

	mDeltaX = x
	mDeltaY = y

	return true
end

local SelectorX = 0
local SelectorY = 0

function ENT:LVSHudPaintCarShiftMenu( X, Y, w, h, ScrX, ScrY, ply )
	if self:GetDriver() ~= ply then return end

	local MenuOpen = ply:lvsKeyDown( "CAR_CLUTCH" )

	if not MenuOpen then

		SelectorX = X + w * 0.5
		SelectorY = Y + h * 0.5

		return
	end

	draw.RoundedBox( R, X, Y, w, h, Color(0,0,0,200) )

	local CenterX = X + w * 0.5
	local CenterY = Y + h * 0.5

	local NumGearsForward = self.TransGears
	local NumGearsReverse = self.TransGearsReverse

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

	for id, data in ipairs( pattern ) do
		data.x = ((data.x - 1) / (xpos - 1)) - 0.5
	end

	local oldX

	for index, data in ipairs( pattern ) do
		local originX = CenterX + data.x * (W - S)
		local originY = CenterY + data.y * (H - S) * 0.5

		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawLine( originX, originY, originX, CenterY )

		if not oldX then
			oldX = originX
		else
			if oldX ~= originX then
				surface.DrawLine( oldX, CenterY, originX, CenterY )
			end
		end

		draw.RoundedBox( 10, originX - 10, originY - 10, 20, 20, Color(255,255,255,255) )
		draw.SimpleText( data.name, "LVS_FONT_PANEL", originX, originY, Color(0,0,0,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		oldX = originX
	end


	if MouseXDelta ~= 0 then
		SelectorX = math.Clamp( SelectorX + MouseXDelta, X, X + W )
		MouseXDelta = 0
	end

	if MouseYDelta ~= 0 then
		SelectorY = math.Clamp( SelectorY + MouseYDelta, Y, Y + H )
		MouseYDelta = 0
	end

	draw.RoundedBox( 10, SelectorX - 10, SelectorY - 10, 20, 20, Color(255,0,0,255) )
end