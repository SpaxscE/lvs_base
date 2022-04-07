
net.Receive( "lvf_player_request_filter", function( length )
	local LVFent = net.ReadEntity()

	if not IsValid( LVFent ) then return end

	local Filter = net.ReadTable()

	LVFent.CrosshairFilterEnts = Filter
end )
