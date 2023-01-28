
LVS = istable( LVS ) and LVS or {}

LVS.VERSION = 74
LVS.VERSION_GITHUB = 0
LVS.VERSION_TYPE = ".GIT"

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
		OnSelect = function( ent ) end,
		OnDeselect = function( ent ) end,
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
	http.Fetch("https://raw.githubusercontent.com/Blu-x92/lvs_base/main/lua/autorun/lvs_init.lua", function(contents,size) 
		local Entry = string.match( contents, "LVS.VERSION%s=%s%d+" )

		if Entry then
			LVS.VERSION_GITHUB = tonumber( string.match( Entry , "%d+" ) ) or 0
		end

		if LVS.VERSION_GITHUB == 0 then
			print("[LVS] latest version could not be detected, You have Version: "..LVS:GetVersion())
		else
			if LVS:GetVersion() >= LVS.VERSION_GITHUB then
				print("[LVS] is up to date, Version: "..LVS:GetVersion())
			else
				print("[LVS] a newer version is available! Version: "..LVS.VERSION_GITHUB..", You have Version: "..LVS:GetVersion())
				print("[LVS] get the latest version at https://github.com/Blu-x92/LunasFlightSchool")

				if CLIENT then 
					timer.Simple(18, function() 
						chat.AddText( Color( 255, 0, 0 ), "[LVS] a newer version is available!" )
					end)
				end
			end
		end
	end)
end

hook.Add( "InitPostEntity", "!!!lvscheckupdates", function()
	timer.Simple(20, function() LVS.CheckUpdates() end)
end )

function LVS:GetWeaponPreset( name )
	if not LVS.WEAPONS[ name ] then return table.Copy( LVS.WEAPONS["DEFAULT"] ) end

	return table.Copy( LVS.WEAPONS[ name ] )
end

function LVS:AddWeaponPreset( name, data )
	if not isstring( name ) or not istable( data ) then return end

	LVS.WEAPONS[ name ] = data
end

AddCSLuaFile("lvs_framework/init.lua")
include("lvs_framework/init.lua")