
local ColNeutral = GM.ColorNeutral
local ColFriend = GM.ColorFriend
local ColEnemy = GM.ColorEnemy
local ColFriendBG = GM.ColorFriendDark
local ColEnemyBG = GM.ColorEnemyDark

local function DrawDiamond( X, Y, radius )
	local segmentdist = 90
	local radius2 = radius + 1
	
	for a = 0, 360, segmentdist do
		surface.DrawLine( X + math.cos( math.rad( a ) ) * radius, Y - math.sin( math.rad( a ) ) * radius, X + math.cos( math.rad( a + segmentdist ) ) * radius, Y - math.sin( math.rad( a + segmentdist ) ) * radius )
		surface.DrawLine( X + math.cos( math.rad( a ) ) * radius2, Y - math.sin( math.rad( a ) ) * radius2, X + math.cos( math.rad( a + segmentdist ) ) * radius2, Y - math.sin( math.rad( a + segmentdist ) ) * radius2 )
	end
end

local DiamondShadow = Color(0, 0, 0, 80)
local function DrawFancyDiamond( X, Y, radius, col )
	surface.SetDrawColor( col )
	DrawDiamond( X, Y, radius )
	surface.SetDrawColor( DiamondShadow )
	DrawDiamond( X + 1, Y + 1, radius )
end

function GM:HUDPaintWaiting()
	local X = ScrW()
	local Y = ScrH()

	local num = 0
	local suffix = ""

	for i = 0, math.Round( CurTime() - math.floor( CurTime() ), 1 ), 0.25 do

		num = num + 1

		if i == 0 then continue end

		suffix = suffix.."."

		if num > 3 then break end
	end

	draw.DrawText( "WAITING FOR PLAYERS TO CREATE SPAWNPOINTS"..suffix, "LVS_FONT_HUD_LARGE", 10, 10, color_white, TEXT_ALIGN_LEFT )

	if IsValid( LocalPlayer():GetSpawnPoint() ) then return end

	draw.DrawText( "#lvs_hint_nospawnpoint", "LVS_FONT", 10, 60, color_white, TEXT_ALIGN_LEFT )
end

local circles = include("includes/circles/circles.lua")

local circle_background = circles.New(CIRCLE_OUTLINED, 38, 0, 0, 5)
circle_background:SetColor( Color(0, 0, 0, 100) )

local circle = circles.New(CIRCLE_OUTLINED, 38, 0, 0, 5)
circle:SetColor( Color(255, 255, 255, 255) )

local OldTime = 0

local function DrawFancyTimer( X, Y, StartTime, Delay, Time )

	if not Time then Time = CurTime() end

	local TimerAccurate = math.max( (StartTime + Delay) - Time, 0 )

	local TimerRounded = math.floor( TimerAccurate )

	local Timer = math.Clamp( TimerAccurate - TimerRounded, 0, 1 )

	local Alpha = 255 * math.min( Timer * 2, 1 ) ^ 2

	if OldTime ~= TimerRounded then
		OldTime = TimerRounded

		if TimerRounded <= 5 then
			surface.PlaySound( "buttons/lightswitch2.wav" )
		end
	end

	if Alpha <= 1 then return 0 end

	if Timer ~= 0 then
		draw.SimpleText( TimerRounded, "LVS_FONT_HUD_LARGE", X, Y, Color(255,255,255,Alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		local EndAng = 360 * Timer
		local StartAng = -90

		draw.NoTexture()
		circle_background:SetColor( Color(0, 0, 0, Alpha) )
		circle_background:SetX(X + 1)
		circle_background:SetY(Y + 1)
		circle_background:SetStartAngle( StartAng - EndAng * 2 )
		circle_background:SetEndAngle( StartAng + EndAng - EndAng * 2 )
		circle_background()

		circle:SetColor( Color(255, 255, 255, Alpha) )
		circle:SetX(X)
		circle:SetY(Y)
		circle:SetStartAngle( StartAng - EndAng * 2 )
		circle:SetEndAngle( StartAng + EndAng - EndAng * 2 )
		circle()
	end

	return Alpha
end

function GM:HUDPaintBuild()
	local StartTime, Delay = self:GetGameTime()

	local X = ScrW() * 0.5
	local Y = 50

	DrawFancyTimer( X, Y, StartTime, Delay )

	local ply = LocalPlayer()

	local myPos = ply:GetPos()
	local myTeam = ply:lvsGetAITeam()

	for _, ent in pairs( _LVS_ALL_SPAWN_POINTS ) do
		if ent:GetAITEAM() ~= myTeam then continue end

		local owner = ent:GetCreatedBy()

		if not IsValid( owner ) then continue end

		local pos = ent:GetPos()
		local scr = pos:ToScreen()

		local Sub = pos - myPos
		local Dist = Sub:Length()

		DrawFancyDiamond( scr.x, scr.y, 5, ColFriend )

		draw.SimpleText( owner:Nick(), "LVS_FONT_SWITCHER", scr.x, scr.y + 8, ColFriend, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
		draw.SimpleText( math.Round( Dist * 0.0254, 0 ).."m", "LVS_FONT_SWITCHER", scr.x, scr.y + 24, ColFriend, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
	end
end

function GM:HUDPaintStart()
	local StartTime, Delay = self:GetGameTime()

	local X = ScrW() * 0.5
	local Y = 50

	DrawFancyTimer( X, Y, StartTime, Delay )
end

local PixVis

local BorderDist = 40
local ColorDefend = Color(0,255,0,255)
local ColorDefendBlocked = Color(0,150,0,255)
local ColorCapture = Color(255,0,0,255)
local ArrowMat = Material( "lvs/3d2dmats/arrow.png" )

function GM:HUDPaintMain()
	local ply = LocalPlayer()
	local GoalEnt = self:GetGoalEntity()

	if not IsValid( GoalEnt ) then return end

	local maxX = ScrW()
	local maxY = ScrH()

	if GoalEnt:GetHoldingPlayer() == ply then
		local myPos = ply:GetPos()
		local myTeam = ply:lvsGetAITeam()

		local numPoints = 0

		for _, ent in pairs( _LVS_ALL_SPAWN_POINTS ) do
			if ent:GetAITEAM() ~= myTeam then continue end

			numPoints = numPoints + 1

			local pos = ent:GetPos() + Vector(0,0,20)
			local scr = pos:ToScreen()

			local visible = util.PixelVisible( pos, 16, ent:GetPixVis() )

			local Blocked = not visible or visible == 0

			local Col = ColorDefend
			if Blocked then
				Col = ColorDefendBlocked
			end

			local Sub = pos - myPos
			local Dist = Sub:Length()

			DrawFancyDiamond( scr.x, scr.y, 5, Col )

			draw.SimpleText( "#lvs_goal_deliver", "LVS_FONT_SWITCHER", scr.x, scr.y + 8, Col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
			draw.SimpleText( math.Round( Dist * 0.0254, 0 ).."m", "LVS_FONT_SWITCHER", scr.x, scr.y + 24, Col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
		end

		self:DrawGoalInfo( ply, GoalEnt, ColorDefend, numPoints == 0 and "#lvs_goal_survive" or "#lvs_goal_deliver" )

		return
	end

	local pos = self:GetGoalPos()
	local scr = pos:ToScreen()

	local X = math.Clamp( scr.x, BorderDist , maxX - BorderDist  )
	local Y = math.Clamp( scr.y, BorderDist , maxY - BorderDist )

	local Sub = pos - ply:GetPos()
	local Dist = Sub:Length()

	local RadiusHidden = 5
	local Radius = 15

	local EyeAng
	local trace

	local veh = ply:lvsGetVehicle()

	local IsDefending = GoalEnt:GetAITEAM() == ply:lvsGetAITeam()
	local DiamondText = IsDefending and "#lvs_goal_defend" or "#lvs_goal_capture"

	if IsValid( GoalEnt:GetLinkedSpawnPoint() ) and not IsDefending then
		DiamondText = "#lvs_goal_destroy"
	end

	local DiamondColor = IsDefending and ColorDefend or ColorCapture

	self:DrawGoalInfo( ply, GoalEnt, DiamondColor, DiamondText )

	if IsValid( veh ) then
		local pod = ply:GetVehicle()

		if IsValid( pod ) and pod ~= veh:GetDriverSeat() then
			local weapon = pod:lvsGetWeapon()

			if IsValid( weapon ) then
				trace = weapon:GetEyeTrace()
				EyeAng = weapon:GetAimVector():Angle()
			else
				trace = ply:GetEyeTrace()
				EyeAng = ply:EyeAngles()
			end
		else
			if veh.GetEyeTrace then
				trace = veh:GetEyeTrace()
				EyeAng = veh:GetAimVector():Angle()
			else
				trace = ply:GetEyeTrace()
				EyeAng = ply:EyeAngles()
			end
		end
	else
		trace = ply:GetEyeTrace()
		EyeAng = ply:EyeAngles()
	end

	if X == BorderDist  or X == (maxX - BorderDist ) or Y == BorderDist  or Y == (maxY - BorderDist ) then

		local WorldAng = (pos - trace.HitPos):Angle()
		WorldAng:Normalize()

		local _, LAng = WorldToLocal( vector_origin, WorldAng, vector_origin, Angle(0,EyeAng.y,0) )

		local newX = maxX * 0.5 - math.sin( math.rad( LAng.y ) ) * maxX * 0.35
		local newY = maxY * 0.5 - math.cos( math.rad( LAng.y ) ) * maxY * 0.35

		surface.SetDrawColor( DiamondColor )
		surface.SetMaterial( ArrowMat )
		surface.DrawTexturedRectRotated( newX, newY, 64, 64, LAng.y )

		return
	end

	if not PixVis then
		PixVis = util.GetPixelVisibleHandle()
	end

	local visible = util.PixelVisible( pos, 16, PixVis )

	if not visible or visible == 0 then
		Radius = RadiusHidden
	end

	DrawFancyDiamond( X, Y, Radius, DiamondColor )

	draw.SimpleText( DiamondText, "LVS_FONT", X, Y + Radius, DiamondColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
	draw.SimpleText( math.Round( Dist * 0.0254, 0 ).."m", "LVS_FONT_SWITCHER", X, Y + Radius + 20, DiamondColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
end

local PointIcon = Material( "vgui/circle" )

local ring = Material( "effects/select_ring" )
local mat = Material( "sprites/light_glow02_add" )

local GoalInfoWidth = 256
local GoalInfoHeight = 10
local GoalInfoDistance = 125

local SpawnPointsIconSize = 8

function GM:DrawGoalInfo( ply, GoalEnt, Col, text )
	local X = ScrW()

	local myTeam = ply:lvsGetAITeam()

	local CenterX = X * 0.5
	local CenterY = 10

	local MulTeam1, MulTeam2 = self:GetGameProgression()
	
	local MyMul
	local TheirMul

	if myTeam == 1 then
		MyMul = MulTeam1
		TheirMul = MulTeam2
	else
		MyMul = MulTeam2
		TheirMul = MulTeam1
	end

	local NumPointsFriend = 0
	local NumPointsEnemy = 0

	for _, ent in pairs( _LVS_ALL_SPAWN_POINTS ) do
		if ent:GetAITEAM() == myTeam then
			NumPointsFriend = NumPointsFriend + 1

			continue
		end

		NumPointsEnemy = NumPointsEnemy + 1
	end

	surface.SetDrawColor( Col )

	draw.SimpleText( text, "LVS_FONT_HUD_LARGE", CenterX, 30, Col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

	surface.SetDrawColor( ColFriendBG )
	surface.DrawRect(CenterX - GoalInfoWidth - GoalInfoDistance, CenterY, GoalInfoWidth, GoalInfoHeight )

	surface.SetDrawColor( ColFriend )
	surface.DrawRect( math.ceil( CenterX - GoalInfoWidth + GoalInfoWidth * (1 - MyMul) - GoalInfoDistance ), CenterY, GoalInfoWidth * MyMul, GoalInfoHeight )

	draw.SimpleText( math.floor( MyMul * 100 ).."%", "LVS_FONT_SWITCHER", CenterX - GoalInfoDistance + 5, CenterY + 10, ColFriend, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

	surface.SetDrawColor( ColEnemyBG )
	surface.DrawRect(CenterX + GoalInfoDistance, CenterY, GoalInfoWidth, GoalInfoHeight )

	surface.SetDrawColor( ColEnemy )
	surface.DrawRect(CenterX + GoalInfoDistance, CenterY, GoalInfoWidth * TheirMul, GoalInfoHeight )

	draw.SimpleText( math.floor( TheirMul * 100 ).."%", "LVS_FONT_SWITCHER", CenterX + GoalInfoDistance - 5, CenterY + 10, ColEnemy, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )

	surface.SetMaterial( PointIcon )

	local XStart = CenterX - GoalInfoDistance + SpawnPointsIconSize
	local YStart = CenterY + GoalInfoHeight + SpawnPointsIconSize

	local PosX = 0
	local PosY = 0

	surface.SetDrawColor( ColFriend )
	for i = 0, NumPointsFriend do
		if i == 0 then continue end

		PosX = PosX + SpawnPointsIconSize * 2

		if PosX > GoalInfoWidth then
			PosX = SpawnPointsIconSize * 2
			PosY = PosY + SpawnPointsIconSize * 2
		end

		surface.DrawTexturedRectRotated( XStart - PosX, YStart + PosY, SpawnPointsIconSize, SpawnPointsIconSize, 0 )
	end

	XStart = CenterX + GoalInfoDistance - SpawnPointsIconSize
	YStart = CenterY + GoalInfoHeight + SpawnPointsIconSize

	PosX = 0
	PosY = 0

	surface.SetDrawColor( ColEnemy )
	for i = 0, NumPointsEnemy do
		if i == 0 then continue end

		PosX = PosX + SpawnPointsIconSize * 2

		if PosX > GoalInfoWidth then
			PosX = SpawnPointsIconSize * 2
			PosY = PosY + SpawnPointsIconSize * 2
		end

		surface.DrawTexturedRectRotated( XStart + PosX, YStart + PosY, SpawnPointsIconSize, SpawnPointsIconSize, 0 )
	end
end

function GM:HUDPaintEnd()
	local StartTime, Delay = self:GetGameTime()

	local X = ScrW() * 0.5
	local Y = 50

	DrawFancyTimer( X, Y, StartTime, Delay )
end