
LVS = istable( LVS ) and LVS or {}

LVS.VERSION = 285
LVS.VERSION_GITHUB = 0
LVS.VERSION_TYPE = ".GIT"
LVS.VERSION_ADDONS_OUTDATED = false

LVS.KEYS_CATEGORIES = {}
LVS.KEYS_REGISTERED = {}
LVS.pSwitchKeys = {[KEY_1] = 1,[KEY_2] = 2,[KEY_3] = 3,[KEY_4] = 4,[KEY_5] = 5,[KEY_6] = 6,[KEY_7] = 7,[KEY_8] = 8,[KEY_9] = 9,[KEY_0] = 10}
LVS.pSwitchKeysInv = {[1] = KEY_1,[2] = KEY_2,[3] = KEY_3,[4] = KEY_4,[5] = KEY_5,[6] = KEY_6,[7] = KEY_7,[8] = KEY_8,[9] = KEY_9,[10] = KEY_0}

LVS.ThemeColor = Color(127,0,0,255)

LVS.WHEEL_BRAKE = 1
LVS.WHEEL_STEER_NONE = 2
LVS.WHEEL_STEER_FRONT = 3
LVS.WHEEL_STEER_REAR = 4

LVS.WEAPONS = {
	["DEFAULT"] = {
		Icon = Material("lvs/weapons/bullet.png"),
		Ammo = 9999,
		Delay = 0,
		HeatRateUp = 0.2,
		HeatRateDown = 0.25,
		Attack = function( ent ) end,
		StartAttack = function( ent ) end,
		FinishAttack = function( ent ) end,
		OnSelect = function( ent, old ) end,
		OnDeselect = function( ent, new ) end,
		OnThink = function( ent, active ) end,
		OnOverheat = function( ent ) end,
		OnRemove = function( ent ) end,
	},
}

function LVS:GetVersion()
	return LVS.VERSION
end

function LVS:AddKey(name, category, printname, cmd, default)
	local data = {
		printname = printname,
		id = name,
		category = category,
		cmd = cmd,
	}

	if not LVS.KEYS_CATEGORIES[ category ] then
		LVS.KEYS_CATEGORIES[ category ] = {}
	end

	if SERVER then
		table.insert( LVS.KEYS_REGISTERED, data )
	else
		if default then
			if isstring( default ) then
				local Key = input.LookupBinding( default )

				if Key then
					default = input.GetKeyCode( Key )
				else
					default = 0
				end
			end
		else
			default = 0
		end

		data.default = default

		table.insert( LVS.KEYS_REGISTERED, data )

		CreateClientConVar( cmd, default, true, true )
	end
end

function LVS:CheckUpdates()
	http.Fetch("https://raw.githubusercontent.com/SpaxscE/lvs_base/main/lua/autorun/lvs_init.lua", function(contents,size) 
		local Entry = string.match( contents, "LVS.VERSION%s=%s%d+" )

		if Entry then
			LVS.VERSION_GITHUB = tonumber( string.match( Entry , "%d+" ) ) or 0
		else
			LVS.VERSION_GITHUB = 0
		end

		if LVS.VERSION_GITHUB == 0 then
			print("[LVS] - Framework: latest version could not be detected, You have Version: "..LVS:GetVersion())
		else
			if LVS:GetVersion() >= LVS.VERSION_GITHUB then
				print("[LVS] - Framework is up to date, Version: "..LVS:GetVersion())
			else
				print("[LVS] - Framework: a newer version is available! Version: "..LVS.VERSION_GITHUB..", You have Version: "..LVS:GetVersion())

				if LVS.VERSION_TYPE == ".GIT" then
					print("[LVS] - Framework: get the latest version at https://github.com/SpaxscE/lvs_base")
				else
					print("[LVS] - Framework: restart your game/server to get the latest version!")
				end

				if CLIENT then 
					timer.Simple(18, function() 
						chat.AddText( Color( 255, 0, 0 ), "[LVS] - Framework: a newer version is available!" )
					end)
				end
			end
		end

		local Delay = 0
		local addons = file.Find( "data_static/lvs/*", "GAME" )

		for _, addonFile in pairs( addons ) do
			local addonInfo = file.Read( "data_static/lvs/"..addonFile, "GAME" )

			if not addonInfo then continue end

			local data = string.Explode( "\n", addonInfo )

			local wsid = string.Replace( addonFile, ".txt", "" )
			local addon_name = wsid
			local addon_url
			local addon_version

			for _, entry in pairs( data ) do
				if string.StartsWith( entry, "url=" ) then
					addon_url = string.Replace( entry, "url=", "" )
				end

				if string.StartsWith( entry, "version=" ) then
					addon_version = string.Replace( entry, "version=", "" )
				end

				if string.StartsWith( entry, "name=" ) then
					addon_name = string.Replace( entry, "name=", "" )
				end
			end

			if not addon_url or not addon_version then continue end

			addon_version = tonumber( addon_version )

			Delay = Delay + 1.5

			timer.Simple( Delay, function()
				http.Fetch(addon_url, function(con,_) 
					local addon_entry = string.match( con, "version=%d+" )

					local addon_version_git = 0

					if addon_entry then
						addon_version_git = tonumber( string.match( addon_entry, "%d+" ) ) or 0
					end

					local wsurl = "https://steamcommunity.com/sharedfiles/filedetails/?id="..wsid

					if addon_version_git == 0 then
						print("[LVS] latest version of "..addon_name.." ( "..wsurl.." ) could not be detected, You have Version: "..addon_version)
					else
						if addon_version_git > addon_version then
							print("[LVS] - "..addon_name.." ( "..wsurl.." ) is out of date!")

							if CLIENT then 
								timer.Simple(18, function() 
									chat.AddText( Color( 255, 0, 0 ),"[LVS] - "..addon_name.." is out of date!" )
								end)
							end

							LVS.VERSION_ADDONS_OUTDATED = true

						else
							print("[LVS] - "..addon_name.." is up to date, Version: "..addon_version)
						end
					end
				end)
			end )
		end
	end)
end

function LVS:GetWeaponPreset( name )
	if not LVS.WEAPONS[ name ] then return table.Copy( LVS.WEAPONS["DEFAULT"] ) end

	return table.Copy( LVS.WEAPONS[ name ] )
end

function LVS:AddWeaponPreset( name, data )
	if not isstring( name ) or not istable( data ) then return end

	LVS.WEAPONS[ name ] = data
end

function LVS:GetVehicleTypes()
	local VehicleTypes = {}

	for s, v in pairs( scripted_ents.GetList() ) do
		if not v.t or not isfunction( v.t.GetVehicleType ) then continue end

		local vehicletype = v.t:GetVehicleType()

		if not isstring( vehicletype ) or string.StartsWith( vehicletype, "LBase" ) or table.HasValue( VehicleTypes, vehicletype ) then continue end

		table.insert( VehicleTypes, vehicletype )
	end

	return VehicleTypes
end

AddCSLuaFile("lvs_framework/init.lua")
include("lvs_framework/init.lua")