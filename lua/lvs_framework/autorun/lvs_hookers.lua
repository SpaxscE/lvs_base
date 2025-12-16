hook.Add( "PhysgunPickup", "!!!!lvs_physgun_pickup", function( ply, ent )
	if ent._lvsNoPhysgunInteraction then return false end
end )

hook.Add( "InitPostEntity", "!!!lvsBullshitFixer", function()
	timer.Simple(1, function()
		LVS.MapDoneLoading = true
	end)

	if SERVER then return end

	local Defaults = {
		["lvs_mouseaim_type_tank"] = 0,
		["lvs_mouseaim_type_car"] = 0,
		["lvs_mouseaim_type_repulsorlift"] = 1,
		["lvs_mouseaim_type_helicopter"] = 1,
		["lvs_mouseaim_type_plane"] = 1,
		["lvs_mouseaim_type_walker"] = 0,
		["lvs_mouseaim_type_starfighter"] = 1,
		["lvs_mouseaim_type_fakehover"] = 0,
	}

	-- this needs to be here to make sure all sents are registered
	for _, vehicletype in ipairs( LVS:GetVehicleTypes() ) do
		local name = "lvs_mouseaim_type_"..vehicletype
		local default = Defaults[ name ] or 0

		CreateClientConVar( name, default, true, false)
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
		["CHudSecondaryAmmo"] = true,
	}
	local function HUDShouldDrawLVS( name )
		if hide[ name ] then return false end
	end

	local CurVehicle
	local function InputMouseApplyLVS( cmd, x, y, ang )
		local ply = LocalPlayer()

		if not IsValid( CurVehicle ) then return end

		return CurVehicle:InputMouseApply( ply, cmd, x, y, ang )
	end

	hook.Add( "LVS.PlayerEnteredVehicle", "!!!!lvs_player_enter", function( ply, veh )
		hook.Add( "HUDShouldDraw", "!!!!lvs_hidehud", HUDShouldDrawLVS )
		hook.Add( "InputMouseApply", "!!!!lvs_inputmouseapply", InputMouseApplyLVS )

		if not IsValid( veh ) then return end

		CurVehicle = veh

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
		hook.Remove( "InputMouseApply", "!!!!lvs_inputmouseapply" )

		CurVehicle = nil
	end )

	hook.Add( "InitPostEntity", "!!!lvs_infmap_velocity_fixer", function()
		if not InfMap then

			hook.Remove( "InitPostEntity", "!!!lvs_infmap_velocity_fixer" )

			return
		end

		local meta = FindMetaTable( "Entity" )

		if not InfMapOriginalGetVelocity then
			InfMapOriginalGetVelocity = meta.GetVelocity
		end

		function meta:GetVelocity()
			local Velocity = InfMapOriginalGetVelocity( self )

			local EntTable = self:GetTable()

			if not EntTable.LVS and not EntTable._lvsRepairToolLabel then return Velocity end

			local Speed = Velocity:LengthSqr()

			local T = CurTime()

			if Speed > 10 then
				EntTable._infmapEntityVelocity = Velocity
				EntTable._infmapEntityVelocityTime = T + 0.6
			else
				if (EntTable._infmapEntityVelocityTime or 0) > T then
					return EntTable._infmapEntityVelocity or vector_origin
				end
			end

			return Velocity
		end
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

		if istable( veh.PlayerBoneManipulate ) then
			local ID = Pod:lvsGetPodIndex()
			local BoneManipulate = veh.PlayerBoneManipulate[ ID ]

			if BoneManipulate then
				ply._lvsStopBoneManipOnExit = true
				ply:lvsStartBoneManip()
			end
		end

		if LVS.FreezeTeams then
			local nTeam = ply:lvsGetAITeam()

			if veh:GetAITEAM() ~= nTeam then
				veh:SetAITEAM( nTeam )

				ply:PrintMessage( HUD_PRINTTALK, "[LVS] This Vehicle's AI-Team has been updated to: "..(LVS.TEAMS[ nTeam ] or "") )
			end
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
			net.WriteEntity( Pod:lvsGetVehicle() )
		net.Send( ply )

		ply._lvsIsInVehicle = nil

		if ply._lvsStopBoneManipOnExit then
			ply._lvsStopBoneManipOnExit = nil

			ply:lvsStopBoneManip()
		end
	end

	if not Pod.HidePlayer then return end

	ply:SetNoDraw( false )

	if pac then pac.TogglePartDrawing( ply, 1 ) end
end )

hook.Add( "PlayerDisconnected", "!!!!lvs_player_reset_bonemanip_client", function(ply)
	if not ply._lvsStopBoneManipOnExit then return end

	ply._lvsStopBoneManipOnExit = nil

	ply:lvsStopBoneManip()
end )