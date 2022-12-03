
hook.Add( "StartCommand", "!!!!LVS_grab_command", function( ply, cmd )
	local veh = ply:lvsGetVehicle()

	if not IsValid( veh ) then return end

	veh:StartCommand( ply, cmd )
end )