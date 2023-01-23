
hook.Add( "LVS:Initialize", "[LVS] - Helicopter - Keys", function()
	local KEYS = {
		{
			name = "+THRUST_HELI",
			category = "LVS-Helicopter",
			name_menu = "Throttle Increase",
			default = "+forward",
			cmd = "lvs_heli_throttle_up"
		},
		{
			name = "-THRUST_HELI",
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
			name_menu = "Yaw Left [Roll in Direct Input]",
			cmd = "lvs_heli_yaw_left"
		},
		{
			name = "+YAW_HELI",
			category = "LVS-Helicopter",
			name_menu = "Yaw Right [Roll in Direct Input]",
			cmd = "lvs_heli_yaw_right"
		},
		{
			name = "-ROLL_HELI",
			category = "LVS-Helicopter",
			name_menu = "Roll Left [Yaw in Direct Input]",
			default = "+moveleft",
			cmd = "lvs_heli_roll_left"
		},
		{
			name = "+ROLL_HELI",
			category = "LVS-Helicopter",
			name_menu = "Roll Right [Yaw in Direct Input]",
			default = "+moveright",
			cmd = "lvs_heli_roll_right"
		},
		{
			name = "HELI_HOVER",
			category = "LVS-Helicopter",
			name_menu = "Hover",
			default = "+jump",
			cmd = "lvs_heli_hover"
		},
	}

	for _, v in pairs( KEYS ) do
		LVS:AddKey( v.name, v.category, v.name_menu, v.cmd, v.default )
	end
end )

if CLIENT then return end

--resource.AddWorkshop("2912826012")