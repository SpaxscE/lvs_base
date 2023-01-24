
hook.Add( "PlayerEnteredVehicle", "!!LVS_HideDriver", function( ply, Pod )
	if not Pod.HidePlayer then return end

	ply:SetNoDraw( true )
end )

hook.Add( "PlayerLeaveVehicle", "!!LVS_HideDriver", function( ply, Pod )
	if not Pod.HidePlayer then return end

	ply:SetNoDraw( false )
end )