
LVS:AddHudEditor( "Tachometer",  ScrW() - 530, ScrH() - 250,  300, 220, 300, 220, "TACH",
	function( self, vehicle, X, Y, W, H, ScrX, ScrY, ply )
		if not vehicle.LVSHudPaintTach or not vehicle.GetRacingHud then return end

		vehicle:LVSHudPaintTach( X, Y, W, H, ScrX, ScrY, ply )
	end
)

local THE_FONT = {
	font = "Verdana",
	extended = false,
	size = 100,
	weight = 2000,
	blursize = 0,
	scanlines = 0,
	antialias = false,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
}
surface.CreateFont( "LVS_TACHOMETER", THE_FONT )

local circles = include("includes/circles/circles.lua")

local Center = 650

local startAngleSpeedo = 180
local endAngleSpeedo = 375

local startAngleTach = 165
local endAngleTach = 360

local Ring = circles.New( CIRCLE_OUTLINED, 300, 0, 0, 60 )
Ring:SetMaterial( true )

local Circle = circles.New( CIRCLE_OUTLINED, 625, 0, 0, 230 )
Circle:SetX( Center )
Circle:SetY( Center )
Circle:SetMaterial( true )

local RingOuter = circles.New( CIRCLE_OUTLINED, 645, 0, 0, 35 )
RingOuter:SetX( Center )
RingOuter:SetY( Center )
RingOuter:SetMaterial( true )

local RingInner = circles.New( CIRCLE_OUTLINED, 640, 0, 0, 25 )
RingInner:SetX( Center )
RingInner:SetY( Center )
RingInner:SetMaterial( true )

local RingFrame = circles.New( CIRCLE_OUTLINED, 390, 0, 0, 10 )
RingFrame:SetX( Center )
RingFrame:SetY( Center )
RingFrame:SetMaterial( true )

local RingFrameOuter = circles.New( CIRCLE_OUTLINED, 395, 0, 0, 20 )
RingFrameOuter:SetX( Center )
RingFrameOuter:SetY( Center )
RingFrameOuter:SetMaterial( true )

local RingOuterRedline = circles.New( CIRCLE_OUTLINED, 645, 0, 0, 20 )
RingOuterRedline:SetX( Center )
RingOuterRedline:SetY( Center )
RingOuterRedline:SetMaterial( true )

local RingInnerRedline = circles.New( CIRCLE_OUTLINED, 640, 0, 0, 10 )
RingInnerRedline:SetX( Center )
RingInnerRedline:SetY( Center )
RingInnerRedline:SetMaterial( true )

local VehicleTach = {}

function ENT:GetBakedTachMaterial( MaxRPM )
	local Class = self:GetClass()

	if VehicleTach[ Class ] then return VehicleTach[ Class ] end

	local TachRange = endAngleTach - startAngleTach

	local Steps = math.ceil(MaxRPM / 1000)
	local AngleStep = TachRange / Steps
	local AngleRedline = startAngleTach + (TachRange / MaxRPM) * self.EngineMaxRPM

	local tachRT = GetRenderTarget( "lvs_tach_"..Class, Center * 2, Center * 2 )

	local old = DisableClipping( true )

	render.OverrideAlphaWriteEnable( true, true )

	render.PushRenderTarget( tachRT )

	cam.Start2D()
		render.ClearDepth()
		render.Clear( 0, 0, 0, 0 )

		surface.SetDrawColor( Color( 0, 0, 0, 150 ) )

		Circle:SetStartAngle( startAngleTach )
		Circle:SetEndAngle( endAngleTach )
		Circle()

		surface.SetDrawColor( Color( 0, 0, 0, 200 ) )

		RingOuter:SetStartAngle( startAngleTach )
		RingOuter:SetEndAngle( AngleRedline )
		RingOuter()

		RingOuterRedline:SetStartAngle( AngleRedline )
		RingOuterRedline:SetEndAngle( endAngleTach )
		RingOuterRedline()

		RingFrameOuter:SetStartAngle( startAngleTach )
		RingFrameOuter:SetEndAngle( endAngleTach )
		RingFrameOuter()

		surface.SetDrawColor( color_white )

		for i = 0, Steps do
			local Ang = AngleStep * i + startAngleTach

			local AngX = math.cos( math.rad( Ang ) )
			local AngY = math.sin( math.rad( Ang ) )

			local StartX = Center + AngX * 554
			local StartY = Center + AngY * 554

			local EndX = Center + AngX * 635
			local EndY = Center + AngY * 635

			if Ang > AngleRedline then
				surface.SetDrawColor( Color(255,0,0,255) )
			else
				surface.SetDrawColor( color_white )
			end

			draw.NoTexture()
			surface.DrawTexturedRectRotated( (StartX + EndX) * 0.5, (StartY + EndY) * 0.5, 90, 15, -Ang )

			local TextX = Center + AngX * 485
			local TextY = Center + AngY * 485

			if Ang > AngleRedline then
				draw.SimpleText( i, "LVS_TACHOMETER", TextX, TextY, Color(255,0,0,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			else
				draw.SimpleText( i, "LVS_TACHOMETER", TextX, TextY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			end
		end

		for i = 1, Steps do
			local Start = AngleStep * i + startAngleTach

			for n = 1, 9 do
				local Ang = Start - (AngleStep / 10) * n

				if Ang > AngleRedline then
					surface.SetDrawColor( Color(150,0,0,255) )
				else
					surface.SetDrawColor( Color(150,150,150,255) )
				end

				local AngX = math.cos( math.rad( Ang ) )
				local AngY = math.sin( math.rad( Ang ) )

				local StartX = Center + AngX * 575
				local StartY = Center + AngY * 575

				local EndX = Center + AngX * 635
				local EndY = Center + AngY * 635

				draw.NoTexture()
				surface.DrawTexturedRectRotated( (StartX + EndX) * 0.5, (StartY + EndY) * 0.5, 60, 5, -Ang )
			end
		end

		surface.SetDrawColor( color_white )

		RingInner:SetStartAngle( startAngleTach )
		RingInner:SetEndAngle( AngleRedline )
		RingInner()

		RingFrame:SetStartAngle( startAngleTach )
		RingFrame:SetEndAngle( endAngleTach )
		RingFrame()

		surface.SetDrawColor( Color(255,0,0,255) )

		RingInnerRedline:SetStartAngle( AngleRedline )
		RingInnerRedline:SetEndAngle( endAngleTach )
		RingInnerRedline()

	cam.End2D()

	render.OverrideAlphaWriteEnable( false )

	render.PopRenderTarget()

	local Mat = CreateMaterial( "lvs_tach_"..Class.."_mat", "UnlitGeneric", { ["$basetexture"] = tachRT:GetName(), ["$translucent"] = 1, ["$vertexcolor"] = 1 } )

	VehicleTach[ Class ] = Mat

	DisableClipping( old )

	return Mat
end

local TachNeedleColor = Color(255,0,0,255)
local TachNeedleRadiusInner = 90
local TachNeedleRadiusOuter = 145
local TachNeedleBlurTime = 0.1
local TachNeedles = {}
local CurRPM = 0
local CurSpeed = 0

function ENT:LVSHudPaintTach( X, Y, w, h, ScrX, ScrY, ply )
	if ply ~= self:GetDriver() then return end

	if not self:GetRacingHud() then return end

	local Engine = self:GetEngine()

	if not IsValid( Engine ) then return end

	local Delta = (Engine:GetRPM() - CurRPM) * RealFrameTime() * 20

	CurRPM = CurRPM + Delta

	local EntTable = self:GetTable()

	local MaxRPM = EntTable.EngineMaxRPM + 3000

	local Ang = startAngleTach + (endAngleTach - startAngleTach) * (CurRPM / MaxRPM)

	local T = CurTime()

	local FuelTank = self:GetFuelTank()

	local UsesFuel = IsValid( FuelTank )

	if self:GetEngineActive() then
		local Gear = self:GetGear()

		local printGear = Gear

		if Gear == -1 then
			printGear = self:GetReverse() and "R" or "D"
		else
			if self:GetReverse() then
				printGear = "-"..Gear
			end
		end

		draw.DrawText( printGear, "LVS_FONT_HUD_HUMONGOUS", X + w * 0.5, Y + w * 0.25, color_white, TEXT_ALIGN_CENTER )
	else
		surface.SetMaterial( EntTable.IconEngine )
		if UsesFuel and FuelTank:GetFuel() <= 0 then
			surface.SetMaterial( EntTable.IconFuel )
		end

		surface.SetDrawColor( Color(255,0,0, math.abs( math.cos( T * 5 ) ) * 255 ) )
		surface.DrawTexturedRectRotated( X + w * 0.5 + 2, Y + w * 0.35 - 1, w * 0.15, w * 0.15, 0 )
	end

	if (EntTable._nextRefreshVel or 0) < T then
		EntTable._nextRefreshVel = T + 0.1
		EntTable._refreshVel = self:GetVelocity():Length()
	end

	local kmh = math.Round( (EntTable._refreshVel or 0) * 0.09144,0)
	draw.DrawText( "km/h ", "LVS_FONT", X + w * 0.81, Y + w * 0.6, color_white, TEXT_ALIGN_LEFT )
	draw.DrawText( kmh, "LVS_FONT_HUD_LARGE", X + w * 0.81 - 5, Y + w * 0.6, color_white, TEXT_ALIGN_RIGHT )

	-- fuel, oil, coolant
	local barlength = w * 0.2
	if UsesFuel then
		surface.SetDrawColor( 0, 0, 0, 200 )
		surface.DrawRect( X + w * 0.5 - barlength * 0.5 - 1, Y + w * 0.5 - 1, barlength + 2, 7 )

		local col = LVS.FUELTYPES[ FuelTank:GetFuelType() ].color
		surface.SetDrawColor( Color(col.r,col.g,col.b,255) )
		surface.DrawRect( X + w * 0.5 - barlength * 0.5, Y + w * 0.5, barlength * FuelTank:GetFuel(), 5 )

		draw.DrawText( "fuel", "LVS_FONT_PANEL", X + w * 0.5 + barlength * 0.5 + 5, Y + w * 0.5 - 5, Color(255,150,0,255), TEXT_ALIGN_LEFT )
	end
	if EntTable._smValueoil then
		surface.SetDrawColor( 0, 0, 0, 200 )
		surface.DrawRect( X + w * 0.5 - barlength * 0.5 - 1, Y + w * 0.5 - 1 + 10, barlength + 2, 7 )

		surface.SetDrawColor( 80, 80, 80, 255 )
		surface.DrawRect( X + w * 0.5 - barlength * 0.5, Y + w * 0.5 + 10, barlength * math.min(EntTable._smValueoil,1), 5 )
		draw.DrawText( "oil pressure", "LVS_FONT_PANEL", X + w * 0.5 + barlength * 0.5 + 5, Y + w * 0.5 + 5, Color(0, 0, 0, 255), TEXT_ALIGN_LEFT )
	end
	if EntTable._smValuetemp then
		surface.SetDrawColor( 0, 0, 0, 200 )
		surface.DrawRect( X + w * 0.5 - barlength * 0.5 - 1, Y + w * 0.5 - 1 + 20, barlength + 2, 7 )

		surface.SetDrawColor( 0, 127, 255, 255 )
		surface.DrawRect( X + w * 0.5 - barlength * 0.5, Y + w * 0.5 + 20, barlength * math.min(EntTable._smValuetemp,1), 5 )
		draw.DrawText( "coolant temp", "LVS_FONT_PANEL", X + w * 0.5 + barlength * 0.5 + 5, Y + w * 0.5 + 15, Color(0, 0, 255, 255), TEXT_ALIGN_LEFT )
	end

	
	-- brake, clutch, throttle bar
	local throttle = self:GetThrottle()
	local clutch = EntTable._smValueclutch
	local brake = self:GetBrake()
	local engine = self:GetEngine()
	if IsValid( engine ) then
		local ClutchActive = engine:GetClutch()

		if not clutch then
			clutch = ClutchActive and 1 or 0
		end

		if ClutchActive then
			throttle = math.max( throttle - clutch, 0 )
		end
	end
	surface.SetDrawColor( 0, 0, 0, 200 )
	surface.DrawRect( X + w * 0.3 - 1, Y + w * 0.4 - 1, 7, barlength + 2 )
	surface.DrawRect( X + w * 0.3 + 10 - 1, Y + w * 0.4 - 1, 7, barlength + 2 )
	surface.DrawRect( X + w * 0.3 - 10 - 1, Y + w * 0.4 - 1, 7, barlength + 2 )
	surface.SetDrawColor( 255, 255, 255, 255 )
	local cllength = barlength * clutch
	surface.DrawRect( X + w * 0.3, Y + w * 0.4 + barlength - cllength, 5, cllength )
	local brlength = barlength * brake
	surface.DrawRect( X + w * 0.3 - 10, Y + w * 0.4 + barlength - brlength, 5, brlength )
	local thrlength = barlength * throttle
	surface.DrawRect( X + w * 0.3 + 10, Y + w * 0.4 + barlength - thrlength, 5, thrlength )
	draw.DrawText( "b", "LVS_FONT_PANEL", X + w * 0.3 - 7, Y + w * 0.4 + barlength, color_white, TEXT_ALIGN_CENTER )
	draw.DrawText( "c", "LVS_FONT_PANEL", X + w * 0.3 + 3, Y + w * 0.4 + barlength, color_white, TEXT_ALIGN_CENTER )
	draw.DrawText( "t", "LVS_FONT_PANEL", X + w * 0.3 + 13, Y + w * 0.4 + barlength, color_white, TEXT_ALIGN_CENTER )


	local TachRange = endAngleTach - startAngleTach
	local AngleRedline = startAngleTach + (TachRange / MaxRPM) * EntTable.EngineMaxRPM
	Ring:SetX( X + w * 0.5 )
	Ring:SetY( Y + w * 0.5 )
	Ring:SetRadius( w * 0.49 )
	Ring:SetOutlineWidth( w * 0.04 )
	Ring:SetStartAngle( startAngleTach )
	Ring:SetEndAngle( math.min( Ang, AngleRedline ) )
	Ring()

	if Ang > AngleRedline then
		surface.SetDrawColor( 255, 0, 0, 255 )
		Ring:SetStartAngle( AngleRedline )
		Ring:SetEndAngle( math.min( Ang, endAngleTach ) )
		Ring()
	end

	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetMaterial( self:GetBakedTachMaterial( MaxRPM ) )
	surface.DrawTexturedRect( X, Y, w, w )

	local CenterX = X + w * 0.5
	local CenterY = Y + w * 0.5

	local T = CurTime()

	local AngX = math.cos( math.rad( Ang ) )
	local AngY = math.sin( math.rad( Ang ) )

	if math.abs( Delta ) > 1 then
		local data = {
			StartX = (CenterX + AngX * TachNeedleRadiusInner),
			StartY = (CenterY + AngY * TachNeedleRadiusInner),
			EndX = (CenterX + AngX * TachNeedleRadiusOuter),
			EndY = (CenterY + AngY * TachNeedleRadiusOuter),
			Time = T + TachNeedleBlurTime
		}

		table.insert( TachNeedles, data )
	else
		local StartX = CenterX + AngX * TachNeedleRadiusInner
		local StartY = CenterY + AngY * TachNeedleRadiusInner
		local EndX = CenterX + AngX * TachNeedleRadiusOuter
		local EndY = CenterY + AngY * TachNeedleRadiusOuter

		surface.SetDrawColor( TachNeedleColor )
		surface.DrawLine( StartX, StartY, EndX, EndY )
	end

	for index, data in pairs( TachNeedles ) do
		if data.Time < T then
			TachNeedles[ index ] = nil

			continue
		end

		local Brightness = (data.Time - T) / TachNeedleBlurTime

		surface.SetDrawColor( Color( TachNeedleColor.r * Brightness, TachNeedleColor.g * Brightness, TachNeedleColor.b * Brightness, TachNeedleColor.a * Brightness ^ 2 ) )
		surface.DrawLine( data.StartX, data.StartY, data.EndX, data.EndY )
	end
end
