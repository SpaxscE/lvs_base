
if SERVER then
	util.AddNetworkString( "lvs_missile_hud" )

	local function MissileChase( vehicle, missile )
		if not IsValid( vehicle ) or not isfunction( vehicle.GetEveryone ) or not IsValid( missile ) or not isfunction( missile.GetLockTarget ) then return end

		if missile:GetLockTarget() ~= vehicle then

			vehicle._ChasingMissiles[ missile ] = nil

			return
		end

		local EntTable = vehicle:GetTable()
	
		EntTable._ChasingMissiles[ missile ] = true

		local players = vehicle:GetEveryone()

		local mPos = missile:GetPos()
		local vPos = vehicle:GetPos()

		local beepDelay = math.Clamp((mPos - vPos):Length() / EntTable.MissileAlertDistance,EntTable.MissileAlertDelayMin,EntTable.MissileAlertDelayMax)

		if table.Count( players ) > 0 then
			local soundLevel = 0
			local pitchPercent = 100
			local volume = 1
			local channel = CHAN_STATIC
			local soundFlags = 0
			local dsp = 1
			local CRecipientFilter = RecipientFilter()
			CRecipientFilter:AddPlayers( players )

			local dist = (mPos - vPos):LengthSqr()
			local isClosest = true

			for otherMissile, _ in pairs( EntTable._ChasingMissiles ) do
				if otherMissile == missile or not IsValid( otherMissile ) then continue end

				if (otherMissile:GetPos() - vPos):LengthSqr() < dist then
					isClosest = false
					break
				end
			end

			if isClosest then
				vehicle:EmitSound("lvs/missile_chase.wav", soundLevel, pitchPercent, volume , channel, soundFlags, dsp, CRecipientFilter )
			end
		end

		timer.Simple(beepDelay, function()
			MissileChase( vehicle, missile )
		end)
	end

	function LVS:SendMissileAlert( vehicle, missile )
		if not IsValid( vehicle ) or not vehicle.MissileAlert or not IsValid( missile ) or not isfunction( missile.GetActive ) or not isfunction( missile.GetLockTarget ) then return end

		local Active = missile:GetActive()

		if Active then
			if not istable( vehicle._ChasingMissiles ) then
				vehicle._ChasingMissiles = {}
			end

			MissileChase( vehicle, missile )

			return
		end

		local T = CurTime()

		if (vehicle._lvsNextMissileAlert or 0) > T then return end

		vehicle._lvsNextMissileAlert = T + 0.28

		local players = vehicle:GetEveryone()
		if table.Count( players ) <= 0 then return end

		local soundLevel = 0
		local pitchPercent = 100
		local volume = 1
		local channel = CHAN_STATIC
		local soundFlags = 0
		local dsp = 1
		local CRecipientFilter = RecipientFilter()
		CRecipientFilter:AddPlayers( players )

		vehicle:EmitSound("lvs/missile_seek.wav", soundLevel, pitchPercent, volume , channel, soundFlags, dsp, CRecipientFilter )
	end

	local meta = FindMetaTable( "Player" )
	function meta:lvsAddMissileToHud( missile )
		net.Start( "lvs_missile_hud", true )
			net.WriteEntity( missile )
		net.Send( self )
	end

	local HudTargetsFlare = {}
	function LVS:AddFlare( flare )
		if not IsValid( flare ) then return end

		table.insert( HudTargetsFlare, flare )
	end

	function LVS:GetFlares()
		local Flares = {}

		for ID, Flare in pairs( HudTargetsFlare ) do
			if not IsValid( Flare ) or not Flare.lvsFlare then
				HudTargetsFlare[ ID ] = nil

				continue
			end

			table.insert( Flares, Flare )
		end

		return Flares
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

		if not IsValid( Missile ) or not Missile.lvsProjectile then
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

		if not IsValid( Flare ) or not Flare.lvsFlare or not isfunction( Flare.IsVisible ) or not isfunction( Flare.GetVehicle ) then
			HudTargetsFlare[ ID ] = nil

			continue
		end

		table.insert( Flares, Flare )
	end

	return Flares
end

function LVS:AddMissileToHUD( missile )
	if not IsValid( missile ) then return end

	LVS:GetMissiles()

	HudTargetsMissile[ missile:EntIndex() ] = true
end

function LVS:AddFlareToHUD( flare )
	if not IsValid( flare ) then return end

	LVS:GetFlares()

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
	local ply = LocalPlayer()

	if not IsValid( ply ) then return end

	local MyVehicle = ply:lvsGetVehicle()

	for _, Flare in pairs( LVS:GetFlares() ) do
		if not Flare:IsVisible() then continue end

		local FlarePos = Flare:GetPos():ToScreen()

		if not FlarePos.visible then continue end

		if Flare:GetVehicle() == MyVehicle then continue end

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
