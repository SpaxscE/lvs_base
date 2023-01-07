
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
			name_menu = "Yaw Left",
			cmd = "lvs_starfighter_yaw_left"
		},
		{
			name = "+YAW_SF",
			category = "LVS-Starfighter",
			name_menu = "Yaw Right",
			cmd = "lvs_starfighter_yaw_right"
		},
		{
			name = "-ROLL_SF",
			category = "LVS-Starfighter",
			name_menu = "Roll Left",
			default = "+moveleft",
			cmd = "lvs_starfighter_roll_left"
		},
		{
			name = "+ROLL_SF",
			category = "LVS-Starfighter",
			name_menu = "Roll Right",
			default = "+moveright",
			cmd = "lvs_starfighter_roll_right"
		},
		{
			name = "+VTOL_Z_SF",
			category = "LVS-Starfighter",
			name_menu = "VTOL Up",
			default = "+jump",
			cmd = "lvs_starfighter_vtol_up"
		},
		{
			name = "-VTOL_Z_SF",
			category = "LVS-Starfighter",
			name_menu = "VTOL Down",
			default = "+back",
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
	}

	for _, v in pairs( KEYS ) do
		LVS:AddKey( v.name, v.category, v.name_menu, v.cmd, v.default )
	end
end )

if CLIENT then return end

--resource.AddWorkshop("ID HERE")