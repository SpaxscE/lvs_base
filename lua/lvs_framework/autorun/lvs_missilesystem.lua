
if SERVER then
	local meta = FindMetaTable( "Player" )

	function meta:lvsAddMissileToHud( missile )
		net.Start( "lvs_missile_hud", true )
			net.WriteEntity( missile )
		net.Send( self )
	end

	return
end

net.Receive( "lvs_missile_hud", function( len )
	LVS:AddMissileToHUD( net.ReadEntity() )
end )

local HudTargetsMissile = {}
local HudTargetsFlare = {}

function LVS:GetMissiles()
	local Missiles = {}

	for ID, _ in pairs( HudTargetsMissile ) do
		local Missile = Entity( ID )

		if not IsValid( Missile ) then
			HudTargetsMissile[ ID ] = nil

			continue
		end

		table.insert( Missiles, Missile )
	end

	return Missiles
end

function LVS:GetFlares()
	local Flares = {}

	for ID, _ in pairs( HudTargetsFlare ) do
		local Flare = Entity( ID )

		if not IsValid( Flare ) then
			HudTargetsFlare[ ID ] = nil

			continue
		end

		table.insert( Flares, Flare )
	end

	return Flares
end

function LVS:AddMissileToHUD( missile )
	if not IsValid( missile ) then return end

	HudTargetsMissile[ missile:EntIndex() ] = true
end

function LVS:AddFlareToHUD( flare )
	if not IsValid( flare ) then return end

	HudTargetsFlare[ flare:EntIndex() ] = true
end

local function DrawDiamond( X, Y, radius, angoffset )
	angoffset = angoffset or 0

	local segmentdist = 90
	local radius2 = radius + 1

	for ang = 0, 360, segmentdist do
		local a = ang + angoffset
		surface.DrawLine( X + math.cos( math.rad( a ) ) * radius, Y - math.sin( math.rad( a ) ) * radius, X + math.cos( math.rad( a + segmentdist ) ) * radius, Y - math.sin( math.rad( a + segmentdist ) ) * radius )
		surface.DrawLine( X + math.cos( math.rad( a ) ) * radius2, Y - math.sin( math.rad( a ) ) * radius2, X + math.cos( math.rad( a + segmentdist ) ) * radius2, Y - math.sin( math.rad( a + segmentdist ) ) * radius2 )
	end
end

local color_red = Color(255,0,0,255)
local function MissileHUD()
	local T = CurTime()

	local Index = 0
	surface.SetDrawColor( color_red )

	for _, Missile in pairs( LVS:GetMissiles() ) do
		local Target = Missile:GetNWTarget()

		if not IsValid( Target ) then continue end

		local ID = Missile:EntIndex()
		local MissilePos = Missile:GetPos():ToScreen()
		local TargetPos = Target:LocalToWorld( Target:OBBCenter() ):ToScreen()

		Index =  Index + 1

		if not TargetPos.visible then continue end

		DrawDiamond( TargetPos.x, TargetPos.y, 40, ID * 1337 - T * 100 )

		draw.DrawText("LOCK", "LVS_FONT", TargetPos.x + 20, TargetPos.y + 20, color_red, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

		if not MissilePos.visible then continue end

		DrawDiamond( MissilePos.x, MissilePos.y, 16, ID * 1337 - T * 100 )
		draw.DrawText( Index, "LVS_FONT", MissilePos.x + 10, MissilePos.y + 10, color_red, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	
		surface.DrawLine( MissilePos.x, MissilePos.y, TargetPos.x, TargetPos.y )
	end
end

local function FlareHUD()
	for _, Flare in pairs( LVS:GetFlares() ) do
		local FlarePos = Flare:GetPos():ToScreen()

		if not FlarePos.visible then continue end

		DrawDiamond( FlarePos.x, FlarePos.y, 8, 0 )
	end
end

local function HUD()
	MissileHUD()
	FlareHUD()
end

hook.Add( "LVS.PlayerEnteredVehicle", "!!!!lvs_missile_hud", function( ply, veh, pod )
	hook.Add( "HUDPaint", "!!!!lvs_flare_hud", HUD )
end )

hook.Add( "LVS.PlayerLeaveVehicle", "!!!!lvs_missile_hud", function( ply, veh, pod )
	hook.Remove( "HUDPaint", "!!!!lvs_flare_hud" )
end )
