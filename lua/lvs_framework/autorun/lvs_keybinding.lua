
hook.Add( "LVS:Initialize", "!!11lvs_default_keys", function()
	local KEYS = {
		{
			name = "ATTACK",
			category = "Armament",
			name_menu = "Attack",
			default = MOUSE_LEFT,
			cmd = "lvs_lmb"
		},
		{
			name = "ZOOM",
			category = "Armament",
			name_menu = "Zoom",
			default = MOUSE_RIGHT,
			cmd = "lvs_rmb"
		},
		{
			name = "~SELECT~WEAPON#1",
			category = "Armament",
			name_menu = "Select Weapon 1",
			cmd = "lvs_select_weapon1"
		},
		{
			name = "~SELECT~WEAPON#2",
			category = "Armament",
			name_menu = "Select Weapon 2",
			cmd = "lvs_select_weapon2"
		},
		{
			name = "~SELECT~WEAPON#3",
			category = "Armament",
			name_menu = "Select Weapon 3",
			cmd = "lvs_select_weapon3"
		},
		{
			name = "~SELECT~WEAPON#4",
			category = "Armament",
			name_menu = "Select Weapon 4",
			cmd = "lvs_select_weapon4"
		},
		--[[ only adding 4 because i dont want to bloat the menu. There can be added as many keys as neededed the system should figure it out by itself
		{
			name = "~SELECT~WEAPON#5",
			category = "Armament",
			name_menu = "Select Weapon 5",
			cmd = "lvs_select_weapon5"
		},
		]]
		{
			name = "EXIT",
			category = "Misc",
			name_menu = "Exit Vehicle",
			default = "+use",
			cmd = "lvs_exit"
		},
		{
			name = "VIEWDIST",
			category = "Misc",
			name_menu = "Enable Mouse-Wheel Set-Camera-Distance",
			default = MOUSE_MIDDLE,
			cmd = "lvs_viewzoom"
		},
		{
			name = "VIEWHEIGHT",
			category = "Misc",
			name_menu = "Set-Camera-Distance => Set-Camera-Height",
			default = "phys_swap",
			cmd = "lvs_viewheight"
		},
		{
			name = "THIRDPERSON",
			category = "Misc",
			name_menu = "Toggle Thirdperson",
			default = "+duck",
			cmd = "lvs_thirdperson"
		},
		{
			name = "FREELOOK",
			category = "Misc",
			name_menu = "Freelook (Hold)",
			default = "+walk",
			cmd = "lvs_freelook"
		},
		{
			name = "ENGINE",
			category = "Misc",
			name_menu = "Toggle Engine",
			default = "+reload",
			cmd = "lvs_startengine"
		},
		{
			name = "VSPEC",
			category = "Misc",
			name_menu = "Toggle Vehicle-specific Function",
			default = "+jump",
			cmd = "lvs_special"
		},
	}

	for _, v in pairs( KEYS ) do
		LVS:AddKey( v.name, v.category, v.name_menu, v.cmd, v.default )
	end
end )

hook.Add( "LVS:Initialize", "[LVS] - Cars - Keys", function()
	local KEYS = {
		{
			name = "CAR_THROTTLE",
			category = "LVS-Car",
			name_menu = "Throttle",
			default = "+forward",
			cmd = "lvs_car_throttle"
		},
		{
			name = "CAR_THROTTLE_MOD",
			category = "LVS-Car",
			name_menu = "Throttle Modifier",
			default = "+speed",
			cmd = "lvs_car_speed"
		},
		{
			name = "CAR_BRAKE",
			category = "LVS-Car",
			name_menu = "Brake",
			default = "+back",
			cmd = "lvs_car_brake"
		},
		{
			name = "CAR_HANDBRAKE",
			category = "LVS-Car",
			name_menu = "Handbrake",
			default = "+jump",
			cmd = "lvs_car_handbrake"
		},
		{
			name = "CAR_STEER_LEFT",
			category = "LVS-Car",
			name_menu = "Steer Left",
			default = "+moveleft",
			cmd = "lvs_car_turnleft"
		},
		{
			name = "CAR_STEER_RIGHT",
			category = "LVS-Car",
			name_menu = "Steer Right",
			default = "+moveright",
			cmd = "lvs_car_turnright"
		},
		{
			name = "CAR_LIGHTS_TOGGLE",
			category = "LVS-Car",
			name_menu = "Toggle Lights",
			default = "phys_swap",
			cmd = "lvs_car_toggle_lights"
		},
		{
			name = "CAR_MENU",
			category = "LVS-Car",
			name_menu = "Turn Signals",
			default = "+zoom",
			cmd = "lvs_car_menu"
		},
		{
			name = "CAR_SIREN",
			category = "LVS-Car",
			name_menu = "Siren",
			default = "phys_swap",
			cmd = "lvs_car_siren"
		},
		{
			name = "CAR_SWAP_AMMO",
			category = "LVS-Car",
			name_menu = "Change Ammo Type",
			default = "+walk",
			cmd = "lvs_car_swap_ammo"
		},
				{
			name = "CAR_HYDRAULIC",
			category = "LVS-Car",
			name_menu = "Hydraulic",
			default = KEY_PAD_5,
			cmd = "lvs_hydraulic"
		},
		{
			name = "CAR_HYDRAULIC_FRONT",
			category = "LVS-Car",
			name_menu = "Hydraulic Front",
			default = KEY_PAD_8,
			cmd = "lvs_hydraulic_front"
		},
		{
			name = "CAR_HYDRAULIC_REAR",
			category = "LVS-Car",
			name_menu = "Hydraulic Rear",
			default = KEY_PAD_2,
			cmd = "lvs_hydraulic_rear"
		},
		{
			name = "CAR_HYDRAULIC_LEFT",
			category = "LVS-Car",
			name_menu = "Hydraulic Left",
			default = KEY_PAD_4,
			cmd = "lvs_hydraulic_left"
		},
		{
			name = "CAR_HYDRAULIC_RIGHT",
			category = "LVS-Car",
			name_menu = "Hydraulic Right",
			default = KEY_PAD_6,
			cmd = "lvs_hydraulic_right"
		},
		{
			name = "CAR_SHIFT_UP",
			category = "LVS-Car",
			name_menu = "Shift Up",
			cmd = "lvs_car_shift_up"
		},
		{
			name = "CAR_SHIFT_DN",
			category = "LVS-Car",
			name_menu = "Shift Down",
			cmd = "lvs_car_shift_dn"
		},
		{
			name = "CAR_CLUTCH",
			category = "LVS-Car",
			name_menu = "Shift Menu",
			cmd = "lvs_car_clutch"
		},
	}

	for _, v in pairs( KEYS ) do
		LVS:AddKey( v.name, v.category, v.name_menu, v.cmd, v.default )
	end
end )


hook.Add( "LVS:Initialize", "[LVS] - Helicopter - Keys", function()
	local KEYS = {
		{
			name = "+THRUST_HELI",
			category = "LVS-Helicopter",
			name_menu = "Throttle Increase",
			default = "+forward",
			cmd = "lvs_helicopter_throttle_up"
		},
		{
			name = "-THRUST_HELI",
			category = "LVS-Helicopter",
			name_menu = "Throttle Decrease",
			default = "+back",
			cmd = "lvs_helicopter_throttle_down"
		},
		{
			name = "+PITCH_HELI",
			category = "LVS-Helicopter",
			name_menu = "Pitch Up",
			cmd = "lvs_helicopter_pitch_up"
		},
		{
			name = "-PITCH_HELI",
			category = "LVS-Helicopter",
			name_menu = "Pitch Down",
			cmd = "lvs_helicopter_pitch_down"
		},
		{
			name = "-YAW_HELI",
			category = "LVS-Helicopter",
			name_menu = "Yaw Left [Roll in Direct Input]",
			cmd = "lvs_helicopter_yaw_left"
		},
		{
			name = "+YAW_HELI",
			category = "LVS-Helicopter",
			name_menu = "Yaw Right [Roll in Direct Input]",
			cmd = "lvs_helicopter_yaw_right"
		},
		{
			name = "-ROLL_HELI",
			category = "LVS-Helicopter",
			name_menu = "Roll Left [Yaw in Direct Input]",
			default = "+moveleft",
			cmd = "lvs_helicopter_roll_left"
		},
		{
			name = "+ROLL_HELI",
			category = "LVS-Helicopter",
			name_menu = "Roll Right [Yaw in Direct Input]",
			default = "+moveright",
			cmd = "lvs_helicopter_roll_right"
		},
		{
			name = "HELI_HOVER",
			category = "LVS-Helicopter",
			name_menu = "Hover",
			default = "+speed",
			cmd = "lvs_helicopter_hover"
		},
	}

	for _, v in pairs( KEYS ) do
		LVS:AddKey( v.name, v.category, v.name_menu, v.cmd, v.default )
	end
end )

hook.Add( "LVS:Initialize", "[LVS] - Planes - Keys", function()
	local KEYS = {
		{
			name = "+THROTTLE",
			category = "LVS-Plane",
			name_menu = "Throttle Increase",
			default = "+forward",
			cmd = "lvs_plane_throttle_up"
		},
		{
			name = "-THROTTLE",
			category = "LVS-Plane",
			name_menu = "Throttle Decrease",
			default = "+back",
			cmd = "lvs_plane_throttle_down"
		},
		{
			name = "+PITCH",
			category = "LVS-Plane",
			name_menu = "Pitch Up",
			default = "+speed",
			cmd = "lvs_plane_pitch_up"
		},
		{
			name = "-PITCH",
			category = "LVS-Plane",
			name_menu = "Pitch Down",
			cmd = "lvs_plane_pitch_down"
		},
		{
			name = "-YAW",
			category = "LVS-Plane",
			name_menu = "Yaw Left [Roll in Direct Input]",
			cmd = "lvs_plane_yaw_left"
		},
		{
			name = "+YAW",
			category = "LVS-Plane",
			name_menu = "Yaw Right [Roll in Direct Input]",
			cmd = "lvs_plane_yaw_right"
		},
		{
			name = "-ROLL",
			category = "LVS-Plane",
			name_menu = "Roll Left [Yaw in Direct Input]",
			default = "+moveleft",
			cmd = "lvs_plane_roll_left"
		},
		{
			name = "+ROLL",
			category = "LVS-Plane",
			name_menu = "Roll Right [Yaw in Direct Input]",
			default = "+moveright",
			cmd = "lvs_plane_roll_right"
		},
	}

	for _, v in pairs( KEYS ) do
		LVS:AddKey( v.name, v.category, v.name_menu, v.cmd, v.default )
	end
end )

hook.Add( "LVS:Initialize", "[LVS] - Star Wars - Keys", function()
	local KEYS = {
		{
			name = "+THRUST_SF",
			category = "LVS-Starfighter",
			name_menu = "Thrust Increase",
			default = "+forward",
			cmd = "lvs_starfighter_throttle_up"
		},
		{
			name = "-THRUST_SF",
			category = "LVS-Starfighter",
			name_menu = "Thrust Decrease",
			default = "+back",
			cmd = "lvs_starfighter_throttle_down"
		},
		{
			name = "+PITCH_SF",
			category = "LVS-Starfighter",
			name_menu = "Pitch Up",
			default = "+speed",
			cmd = "lvs_starfighter_pitch_up"
		},
		{
			name = "-PITCH_SF",
			category = "LVS-Starfighter",
			name_menu = "Pitch Down",
			cmd = "lvs_starfighter_pitch_down"
		},
		{
			name = "-YAW_SF",
			category = "LVS-Starfighter",
			name_menu = "Yaw Left [Roll in Direct Input]",
			cmd = "lvs_starfighter_yaw_left"
		},
		{
			name = "+YAW_SF",
			category = "LVS-Starfighter",
			name_menu = "Yaw Right [Roll in Direct Input]",
			cmd = "lvs_starfighter_yaw_right"
		},
		{
			name = "-ROLL_SF",
			category = "LVS-Starfighter",
			name_menu = "Roll Left [Yaw in Direct Input]",
			default = "+moveleft",
			cmd = "lvs_starfighter_roll_left"
		},
		{
			name = "+ROLL_SF",
			category = "LVS-Starfighter",
			name_menu = "Roll Right [Yaw in Direct Input]",
			default = "+moveright",
			cmd = "lvs_starfighter_roll_right"
		},
		{
			name = "+VTOL_Z_SF",
			category = "LVS-Starfighter",
			name_menu = "VTOL Up",
			cmd = "lvs_starfighter_vtol_up"
		},
		{
			name = "-VTOL_Z_SF",
			category = "LVS-Starfighter",
			name_menu = "VTOL Down",
			cmd = "lvs_starfighter_vtol_dn"
		},
		{
			name = "-VTOL_Y_SF",
			category = "LVS-Starfighter",
			name_menu = "VTOL Right",
			cmd = "lvs_starfighter_vtol_right"
		},
		{
			name = "+VTOL_Y_SF",
			category = "LVS-Starfighter",
			name_menu = "VTOL Left",
			cmd = "lvs_starfighter_vtol_left"
		},
		{
			name = "-VTOL_X_SF",
			category = "LVS-Starfighter",
			name_menu = "VTOL Reverse",
			default = "+back",
			cmd = "lvs_starfighter_vtol_reverse"
		},
	}

	for _, v in pairs( KEYS ) do
		LVS:AddKey( v.name, v.category, v.name_menu, v.cmd, v.default )
	end
end )

if SERVER then return end

concommand.Add( "lvs_mouseaim_toggle", function( ply, cmd, args )
	local OldVar = GetConVar( "lvs_mouseaim" ):GetInt()

	if OldVar == 0 then
		ply:PrintMessage( HUD_PRINTTALK, "[LVS] Mouse-Aim: Enabled" )
		RunConsoleCommand( "lvs_mouseaim", "1" )

	else
		ply:PrintMessage( HUD_PRINTTALK, "[LVS] Mouse-Aim: Disabled" )
		RunConsoleCommand( "lvs_mouseaim", "0" )
	end
end )

hook.Add( "PlayerBindPress", "!!!!_LVS_PlayerBindPress", function( ply, bind, pressed )
	if not ply.lvsGetVehicle then return end

	local vehicle = ply:lvsGetVehicle()

	if not IsValid( vehicle ) then return end

	if not ply:lvsKeyDown( "VIEWDIST" ) then
		if string.find( bind, "invnext" ) then
			vehicle:NextWeapon()
		end
		if string.find( bind, "invprev" ) then
			vehicle:PrevWeapon()
		end
	end

	if string.find( bind, "+zoom" ) then
		if vehicle.lvsDisableZoom then
			return true
		end
	end
end )

hook.Add( "SpawnMenuOpen", "!!!lvs_spawnmenudisable", function()
	local ply = LocalPlayer() 

	if not ply._lvsDisableSpawnMenu or not IsValid( ply:lvsGetVehicle() ) then return end

	return false
end )

hook.Add( "ContextMenuOpen", "!!!lvs_contextmenudisable", function()
	local ply = LocalPlayer() 

	if not ply._lvsDisableContextMenu or not IsValid( ply:lvsGetVehicle() ) then return end

	return false
end )
