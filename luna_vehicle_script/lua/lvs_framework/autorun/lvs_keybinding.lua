
hook.Add( "LVS:Initialize", "!!!!lvs_addkeys", function()
	table.Empty( LVS.KEYS_CATEGORIES )

	local KEYS = {
		{
			name = "ATTACK",
			category = "Armament",
			name_menu = "Attack",
			default = "+attack",
			cmd = "lvs_attack"
		},
		{
			name = "ZOOM",
			category = "Armament",
			name_menu = "Zoom",
			default = "+attack2",
			cmd = "lvs_zoom"
		},
		{
			name = "WEAPON1",
			category = "Armament",
			name_menu = "Select Weapon 1",
			cmd = "lvs_select_weapon1"
		},
		{
			name = "WEAPON2",
			category = "Armament",
			name_menu = "Select Weapon 2",
			cmd = "lvs_select_weapon2"
		},
		{
			name = "WEAPON3",
			category = "Armament",
			name_menu = "Select Weapon 3",
			cmd = "lvs_select_weapon3"
		},
		{
			name = "WEAPON4",
			category = "Armament",
			name_menu = "Select Weapon 4",
			cmd = "lvs_select_weapon4"
		},
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
		{
			name = "+THROTTLE",
			category = "LFS-Plane",
			name_menu = "Throttle Increase",
			default = "+forward",
			cmd = "lvs_throttle_up"
		},
		{
			name = "-THROTTLE",
			category = "LFS-Plane",
			name_menu = "Throttle Decrease",
			default = "+back",
			cmd = "lvs_throttle_down"
		},
		{
			name = "+PITCH",
			category = "LFS-Plane",
			name_menu = "Pitch Up",
			default = "+speed",
			cmd = "lvs_pitch_up"
		},
		{
			name = "-PITCH",
			category = "LFS-Plane",
			name_menu = "Pitch Down",
			cmd = "lvs_pitch_down"
		},
		{
			name = "-YAW",
			category = "LFS-Plane",
			name_menu = "Yaw Left",
			cmd = "lvs_yaw_left"
		},
		{
			name = "+YAW",
			category = "LFS-Plane",
			name_menu = "Yaw Right",
			cmd = "lvs_yaw_right"
		},
		{
			name = "-ROLL",
			category = "LFS-Plane",
			name_menu = "Roll Left",
			default = "+moveleft",
			cmd = "lvs_roll_left"
		},
		{
			name = "+ROLL",
			category = "LFS-Plane",
			name_menu = "Roll Right",
			default = "+moveright",
			cmd = "lvs_roll_right"
		},
	}

	for _, v in pairs( KEYS ) do
		LVS:AddKey( v.name, v.category, v.name_menu, v.cmd, v.default )
	end
end )

if SERVER then return end

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
