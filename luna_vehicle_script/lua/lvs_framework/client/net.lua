
net.Receive( "lvs_player_request_filter", function( length )
	local LVSent = net.ReadEntity()

	if not IsValid( LVSent ) then return end

	local Filter = net.ReadTable()

	LVSent.CrosshairFilterEnts = Filter
end )
