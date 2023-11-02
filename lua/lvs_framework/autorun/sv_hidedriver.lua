
hook.Add( "PlayerEnteredVehicle", "!!LVS_HideDriver", function( ply, Pod )
	if not Pod.HidePlayer then return end

	ply:SetNoDraw( true )

	if pac then pac.TogglePartDrawing( ply, 0 ) end
end )

hook.Add( "PlayerLeaveVehicle", "!!LVS_HideDriver", function( ply, Pod )
	if not Pod.HidePlayer then return end

	ply:SetNoDraw( false )

	if pac then pac.TogglePartDrawing( ply, 1 ) end
end )