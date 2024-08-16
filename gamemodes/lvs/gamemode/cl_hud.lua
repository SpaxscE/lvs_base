
local VehicleIdentifierRange = 5000
local MatRing = Material( "effects/select_ring" )
local MatGlow = Material( "sprites/light_glow02_add" )
local size = 32

function GM:HUDPaintIndicator()
	if not LVS.ShowIdent or LVS:IsIndicatorForced() then return end

	local me = LocalPlayer()
	local myPos = me:GetShootPos()

	if not me:InVehicle() then return end

	local veh = me:lvsGetVehicle()

	if IsValid( veh ) then
		myPos = veh:LocalToWorld( veh:OBBCenter() )
	end

	local myTeam = me:lvsGetAITeam()

	for _, ply in pairs( player.GetAll() ) do
		local theirTeam = ply:lvsGetAITeam()

		if theirTeam == myTeam or theirTeam == 0 or theirTeam == 3 then continue end

		if ply:InVehicle() or not ply:Alive() then continue end

		local Pos = ply:LocalToWorld( ply:OBBCenter() )

		local Dist = (myPos - Pos):Length()

		if Dist > VehicleIdentifierRange or util.TraceLine( {start = myPos,endpos = Pos,mask = MASK_NPCWORLDSTATIC,} ).Hit then continue end

		local scr = Pos:ToScreen()

		local IconSize = size - Dist / 250
		local IconSize05 = IconSize * 0.5

		if IconSize < 0 then continue end

		local Alpha = 255 * (1 - (Dist / VehicleIdentifierRange) ^ 2)

		surface.SetDrawColor( 255, 0, 0, Alpha )
		surface.SetMaterial( MatRing ) 
		surface.DrawTexturedRect( scr.x - IconSize05, scr.y - IconSize05, IconSize, IconSize )
	end
end

local ColorNormal = color_white
local ColorLow = Color(255,0,0,255)

local function DrawPlayerHud( X, Y, ply )
	local Health = math.Round( ply:Health(), 0 )

	local ColHealth = (Health <= 20) and ColorLow or ColorNormal

	draw.DrawText( "HEALTH ", "LVS_FONT", X + 102, Y + 35, ColHealth, TEXT_ALIGN_RIGHT )
	draw.DrawText( Health, "LVS_FONT_HUD_LARGE", X + 102, Y + 20, ColHealth, TEXT_ALIGN_LEFT )

	local Armor = math.Round( ply:Armor(), 0 )

	if Armor <= 0 then return end

	local ColArmor = (Armor <= 20) and ColorLow or ColorNormal

	draw.DrawText( "ARMOR ", "LVS_FONT", X + 265, Y + 35, ColArmor, TEXT_ALIGN_RIGHT )
	draw.DrawText( Armor, "LVS_FONT_HUD_LARGE", X + 265, Y + 20, ColArmor, TEXT_ALIGN_LEFT )
end

local function DrawPlayerAmmo( X, Y, ply )
	local SWEP = ply:GetActiveWeapon()

	if not SWEP.DrawAmmoInfo then return end

	SWEP:DrawAmmoInfo( X, Y, ply )
end

function GM:PlayerHud( ply )
	if ply:InVehicle() or not ply:Alive() then return end

	local editor = LVS.HudEditors["VehicleHealth"]

	if not editor then return end

	local X = ScrW()
	local Y = ScrH()

	local ScaleX = editor.w / editor.DefaultWidth
	local ScaleY = editor.h / editor.DefaultHeight

	local PosX = editor.X / ScaleX
	local PosY = editor.Y / ScaleY

	local Width = editor.w / ScaleX
	local Height = editor.h / ScaleY

	local ScrW = X / ScaleX
	local ScrH = Y / ScaleY

	if ScaleX == 1 and ScaleY == 1 then
		DrawPlayerHud( PosX, PosY, ply )
	else
		local m = Matrix()
		m:Scale( Vector( ScaleX, ScaleY, 1 ) )

		cam.PushModelMatrix( m )
			DrawPlayerHud( PosX, PosY, ply )
		cam.PopModelMatrix()
	end
end

function GM:PlayerAmmo( ply )
	if ply:InVehicle() or not ply:Alive() then return end

	local editor = LVS.HudEditors["WeaponInfo"]

	if not editor then return end

	local X = ScrW()
	local Y = ScrH()

	local ScaleX = editor.w / editor.DefaultWidth
	local ScaleY = editor.h / editor.DefaultHeight

	local PosX = editor.X / ScaleX
	local PosY = editor.Y / ScaleY

	local Width = editor.w / ScaleX
	local Height = editor.h / ScaleY

	local ScrW = X / ScaleX
	local ScrH = Y / ScaleY

	if ScaleX == 1 and ScaleY == 1 then
		DrawPlayerAmmo( PosX, PosY, ply )
	else
		local m = Matrix()
		m:Scale( Vector( ScaleX, ScaleY, 1 ) )

		cam.PushModelMatrix( m )
			DrawPlayerAmmo( PosX, PosY, ply )
		cam.PopModelMatrix()
	end
end

function GM:HUDPaint()
	local ply = LocalPlayer()

	if not IsValid( ply ) or ply:Team() == TEAM_SPECTATOR then return end

	if hook.Call( "HUDShouldDraw", self, "LVSHudHealth" ) then
		self:PlayerHud( ply )
	end

	if hook.Call( "HUDShouldDraw", self, "LVSHudAmmo" ) then
		self:PlayerAmmo( ply )
	end

	if hook.Call( "HUDShouldDraw", self, "LVSHudMoney" ) then
		self:DrawPlayerMoney( ply )
	end

	self:HUDPaintIndicator()

	hook.Run( "HUDDrawTargetID" )
	hook.Run( "HUDDrawPickupHistory" )
	hook.Run( "DrawDeathNotice", 0.85, 0.04 )

	local ent = self:GameNetworkEntity()

	if not IsValid( ent ) then return end

	local GameState = ent:GetGameState()

	if GameState == GAMESTATE_WAIT_FOR_PLAYERS then
		self:HUDPaintWaiting( ent )

		return
	end

	if GameState == GAMESTATE_BUILD then
		self:HUDPaintBuild( ent )

		return
	end

	if GameState == GAMESTATE_START then
		self:HUDPaintStart( ent )

		return
	end

	if GameState == GAMESTATE_MAIN then
		self:HUDPaintMain( ent )

		return
	end

	if GameState ~= GAMESTATE_END then return end
	
	self:HUDPaintEnd( ent )
end

local hud = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudAmmo"] = true,
	["CHudSecondaryAmmo"] = true
}

function GM:HUDShouldDraw( name )

	if hud[name] then return false end

	return self.BaseClass.HUDShouldDraw(self, name)
end

local Shadow50 = Color( 0, 0, 0, 50 )
local Shadow120 = Color( 0, 0, 0, 120 )

local function FindTargetLVS( veh )
	if not IsValid( veh ) then return NULL end

	if veh.LVS then return veh end

	if not isfunction( veh.GetBase ) then return NULL end

	return veh:GetBase()
end

function GM:HUDDrawTargetID()

	local ply = LocalPlayer()
	local trace

	local veh = ply:lvsGetVehicle()

	if IsValid( veh ) then
		local pod = ply:GetVehicle()

		if IsValid( pod ) and pod ~= veh:GetDriverSeat() then
			local weapon = pod:lvsGetWeapon()

			if IsValid( weapon ) then
				trace = weapon:GetEyeTrace()
			else
				trace = ply:GetEyeTrace()
			end
		else
			if veh.GetEyeTrace then
				trace = veh:GetEyeTrace()
			else
				trace = ply:GetEyeTrace()
			end
		end
	else
		trace = ply:GetEyeTrace()
	end

	local scr = trace.HitPos:ToScreen()

	self:HUDPaintHitMarker( scr )

	if not trace.Hit then return end
	if not trace.HitNonWorld then return end

	local text = "ERROR"
	local font = "TargetID"
	local Health = 0
	local Col

	if trace.Entity:IsPlayer() then
		text = trace.Entity:Nick()
		Col = self:GetTeamColor( trace.Entity )
		Health = math.Round( ((trace.Entity:Health() + trace.Entity:Armor()) / (trace.Entity:GetMaxHealth() + trace.Entity:GetMaxArmor())) * 100, 0 )

		if trace.Entity:lvsGetAITeam() == LocalPlayer():lvsGetAITeam() then
			local X = scr.x
			local Y = scr.y

			surface.SetDrawColor( Color(255,0,0,255) )

			surface.DrawLine( X - 20, Y - 20, X + 20, Y + 20 )
			surface.DrawLine( X + 20, Y - 20, X - 20, Y + 20 )

			surface.SetDrawColor( Col )

			surface.SetMaterial( MatRing ) 
			surface.DrawTexturedRect(X - 15, Y - 15, 30, 30 )

			surface.SetMaterial( MatGlow ) 
			surface.DrawTexturedRect(X - 64, Y - 64, 128, 128 )
		end

	else
		local lvsVeh = FindTargetLVS( trace.Entity )

		if IsValid( lvsVeh ) then
			if lvsVeh:GetAITEAM() ~= LocalPlayer():lvsGetAITeam() then return end

			local X = scr.x
			local Y = scr.y

			surface.SetDrawColor( Color(255,0,0,255) )

			surface.DrawLine( X - 20, Y - 20, X + 20, Y + 20 )
			surface.DrawLine( X + 20, Y - 20, X - 20, Y + 20 )

			surface.SetDrawColor( self.ColorFriend )

			surface.SetMaterial( MatRing ) 
			surface.DrawTexturedRect(X - 15, Y - 15, 30, 30 )

			surface.SetMaterial( MatGlow ) 
			surface.DrawTexturedRect(X - 64, Y - 64, 128, 128 )

			return
		else
			if not trace.Entity.IsFortification and not trace.Entity._lvsPlayerSpawnPoint then return end

			local Owner = trace.Entity:GetCreatedBy()

			if not IsValid( Owner ) then return end

			text = "Owner: "..Owner:Nick()
			Col = trace.Entity:GetTeamColor()
			Health = math.Round( (trace.Entity:GetHP() / trace.Entity:GetMaxHP()) * 100, 0 )
		end
	end

	surface.SetFont( font )
	local w, h = surface.GetTextSize( text )

	local x = scr.x
	local y = scr.y

	x = x - w / 2
	y = y + 30

	-- The fonts internal drop shadow looks lousy with AA on
	draw.SimpleText( text, font, x + 1, y + 1, Shadow120 )
	draw.SimpleText( text, font, x + 2, y + 2, Shadow50 )
	draw.SimpleText( text, font, x, y, Col )

	y = y + h + 5

	-- Draw the health
	text = Health .. "%"
	font = "TargetIDSmall"

	surface.SetFont( font )
	w, h = surface.GetTextSize( text )
	x = scr.x - w / 2

	draw.SimpleText( text, font, x + 1, y + 1, Color( 0, 0, 0, 120 ) )
	draw.SimpleText( text, font, x + 2, y + 2, Shadow50 )
	draw.SimpleText( text, font, x, y, Col )
end
