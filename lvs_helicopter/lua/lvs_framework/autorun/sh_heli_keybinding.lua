
hook.Add( "LVS:Initialize", "[LVS] - Helicopter - Keys", function()
	local KEYS = {
		{
			name = "+THROTTLE_HELI",
			category = "LVS-Helicopter",
			name_menu = "Throttle Increase",
			default = "+forward",
			cmd = "lvs_heli_throttle_up"
		},
		{
			name = "-THROTTLE_HELI",
			category = "LVS-Helicopter",
			name_menu = "Throttle Decrease",
			default = "+back",
			cmd = "lvs_heli_throttle_down"
		},
		{
			name = "+PITCH_HELI",
			category = "LVS-Helicopter",
			name_menu = "Pitch Up",
			default = "+speed",
			cmd = "lvs_heli_pitch_up"
		},
		{
			name = "-PITCH_HELI",
			category = "LVS-Helicopter",
			name_menu = "Pitch Down",
			cmd = "lvs_heli_pitch_down"
		},
		{
			name = "-YAW_HELI",
			category = "LVS-Helicopter",
			name_menu = "Yaw Left",
			cmd = "lvs_heli_yaw_left"
		},
		{
			name = "+YAW_HELI",
			category = "LVS-Helicopter",
			name_menu = "Yaw Right",
			cmd = "lvs_heli_yaw_right"
		},
		{
			name = "-ROLL_HELI",
			category = "LVS-Helicopter",
			name_menu = "Roll Left",
			default = "+moveleft",
			cmd = "lvs_heli_roll_left"
		},
		{
			name = "+ROLL_HELI",
			category = "LVS-Helicopter",
			name_menu = "Roll Right",
			default = "+moveright",
			cmd = "lvs_heli_roll_right"
		},
	}

	for _, v in pairs( KEYS ) do
		LVS:AddKey( v.name, v.category, v.name_menu, v.cmd, v.default )
	end
end )

if CLIENT then return end

--resource.AddWorkshop("2912826012")