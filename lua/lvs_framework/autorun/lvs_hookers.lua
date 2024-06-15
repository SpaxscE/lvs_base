
hook.Add( "InitPostEntity", "!!!lvsBullshitFixer", function()
	timer.Simple(1, function()
		LVS.MapDoneLoading = true
	end)

	if SERVER then return end

	-- this needs to be here to make sure all sents are registered
	for _, vehicletype in ipairs( LVS:GetVehicleTypes() ) do
		CreateClientConVar( "lvs_mouseaim_type_"..vehicletype, 0, true, false)
	end
end )

local function SetDistance( vehicle, ply )
	local iWheel = ply:GetCurrentCommand():GetMouseWheel()

	if iWheel == 0 or not vehicle.SetCameraDistance then return end

	local newdist = math.Clamp( vehicle:GetCameraDistance() - iWheel * 0.03 * ( 1.1 + vehicle:GetCameraDistance() ), -1, 10 )

	vehicle:SetCameraDistance( newdist )
end

local function SetHeight( vehicle, ply )
	local iWheel = ply:GetCurrentCommand():GetMouseWheel()

	if iWheel == 0 or not vehicle.SetCameraHeight then return end

	local newdist = math.Clamp( vehicle:GetCameraHeight() - iWheel * 0.03 * ( 1.1 + vehicle:GetCameraHeight() ), -1, 10 )

	vehicle:SetCameraHeight( newdist )
end

hook.Add( "VehicleMove", "!!!!lvs_vehiclemove", function( ply, vehicle, mv )
	if not ply.lvsGetVehicle then return end

	local veh = ply:lvsGetVehicle()

	if not IsValid( veh ) then return end

	if SERVER and ply:lvsKeyDown( "VIEWDIST" ) then
		if ply:lvsKeyDown( "VIEWHEIGHT" ) then
			SetHeight( vehicle, ply )
		else
			SetDistance( vehicle, ply )
		end
	end

	if CLIENT and not IsFirstTimePredicted() then return end
	
	local KeyThirdPerson = ply:lvsKeyDown("THIRDPERSON")

	if ply._lvsOldThirdPerson ~= KeyThirdPerson then
		ply._lvsOldThirdPerson = KeyThirdPerson

		if KeyThirdPerson and vehicle.SetThirdPersonMode then
			vehicle:SetThirdPersonMode( not vehicle:GetThirdPersonMode() )
		end
	end

	return true
end )

hook.Add("CalcMainActivity", "!!!lvs_playeranimations", function(ply)
	if not ply.lvsGetVehicle then return end

	local Ent = ply:lvsGetVehicle()

	if IsValid( Ent ) then
		local A,B = Ent:CalcMainActivity( ply )

		if A and B then
			return A, B
		end
	end
end)

hook.Add("UpdateAnimation", "!!!lvs_playeranimations", function( ply, velocity, maxseqgroundspeed )
	if not ply.lvsGetVehicle then return end

	local Ent = ply:lvsGetVehicle()

	if not IsValid( Ent ) then return end

	return Ent:UpdateAnimation( ply, velocity, maxseqgroundspeed )
end)

hook.Add( "StartCommand", "!!!!LVS_grab_command", function( ply, cmd )
	if not ply.lvsGetVehicle then return end

	local veh = ply:lvsGetVehicle()

	if not IsValid( veh ) then return end

	veh:StartCommand( ply, cmd )
end )

hook.Add( "CanProperty", "!!!!lvsEditPropertiesDisabler", function( ply, property, ent )
	if ent.LVS and not ply:IsAdmin() and property == "editentity" then return false end
end )

LVS.ToolsDisable = {
	["rb655_easy_animation"] = true,
	["rb655_easy_bonemerge"] = true,
	["rb655_easy_inspector"] = true,
}
hook.Add( "CanTool", "!!!!lvsCanToolDisabler", function( ply, tr, toolname, tool, button )
	if LVS.ToolsDisable[ toolname ] and IsValid( tr.Entity ) and tr.Entity.LVS then return false end
end )

if CLIENT then
	local hide = {
		["CHudHealth"] = true,
		["CHudBattery"] = true,
		["CHudAmmo"] = true,
	}
	local function HUDShouldDrawLVS( name )
		if hide[ name ] then return false end
	end

	hook.Add( "LVS.PlayerEnteredVehicle", "!!!!lvs_player_enter", function( ply, veh )
		hook.Add( "HUDShouldDraw", "!!!!lvs_hidehud", HUDShouldDrawLVS )

		local cvar = GetConVar( "lvs_mouseaim_type" )

		if not cvar or cvar:GetInt() ~= 1 or not veh.GetVehicleType then return end

		local vehicletype = veh:GetVehicleType()

		local cvar_type = GetConVar( "lvs_mouseaim_type_"..vehicletype )
		local cvar_mouseaim = GetConVar( "lvs_mouseaim" )

		if not cvar_type or not cvar_mouseaim then return end

		cvar_mouseaim:SetInt( cvar_type:GetInt() )
	end )

	hook.Add( "LVS.PlayerLeaveVehicle", "!!!!lvs_player_exit", function( ply, veh )
		hook.Remove( "HUDShouldDraw", "!!!!lvs_hidehud" )
	end )

	return
end

local DamageFix = {
	["npc_hunter"] = true,
	["npc_stalker"] = true,
	["npc_strider"] = true,
	["npc_combinegunship"] = true,
	["npc_helicopter"] = true,
}

hook.Add( "EntityTakeDamage", "!!!_lvs_fix_vehicle_explosion_damage", function( target, dmginfo )
	if not target:IsPlayer() then
		if target.LVS then
			local attacker = dmginfo:GetAttacker()

			if IsValid( attacker ) and DamageFix[ attacker:GetClass() ] then
				dmginfo:SetDamageType( DMG_AIRBOAT )
				dmginfo:SetDamageForce( dmginfo:GetDamageForce():GetNormalized() * 15000 )
			end
		end

		return
	end

	local veh = target:lvsGetVehicle()

	if not IsValid( veh ) or dmginfo:IsDamageType( DMG_DIRECT ) then return end

	if target:GetCollisionGroup() == COLLISION_GROUP_PLAYER then return end

	dmginfo:SetDamage( 0 )
end )

hook.Add( "PlayerEnteredVehicle", "!!!!lvs_player_enter", function( ply, Pod )
	local veh = ply:lvsGetVehicle()

	if IsValid( veh ) then
		net.Start( "lvs_player_enterexit" )
			net.WriteBool( true )
			net.WriteEntity( veh )
		net.Send( ply )

		ply._lvsIsInVehicle = true

		if not ply:IsFlagSet( FL_NOTARGET ) then
			ply:AddFlags( FL_NOTARGET )
			ply._lvsRemoveNoTargetOnExit = true
		end
	end

	if not Pod.HidePlayer then return end

	ply:SetNoDraw( true )

	if pac then pac.TogglePartDrawing( ply, 0 ) end
end )

hook.Add( "PlayerLeaveVehicle", "!!!!lvs_player_exit", function( ply, Pod )
	if ply._lvsIsInVehicle then
		net.Start( "lvs_player_enterexit" )
			net.WriteBool( false )
			net.WriteEntity( ply:lvsGetVehicle() )
		net.Send( ply )

		ply._lvsIsInVehicle = nil

		if ply._lvsRemoveNoTargetOnExit then
			ply._lvsRemoveNoTargetOnExit = nil
			ply:RemoveFlags( FL_NOTARGET )
		end
	end

	if not Pod.HidePlayer then return end

	ply:SetNoDraw( false )

	if pac then pac.TogglePartDrawing( ply, 1 ) end
end )