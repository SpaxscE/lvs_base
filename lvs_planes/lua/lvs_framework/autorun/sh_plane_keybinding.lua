
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

if CLIENT then return end

resource.AddWorkshop("2912826012")