
util.AddNetworkString( "lvs_player_request_filter" )

net.Receive( "lvs_player_request_filter", function( length, ply )
	if not IsValid( ply ) then return end

	local LVSent = net.ReadEntity()

	if not IsValid( LVSent ) then return end

	if not istable( LVSent.CrosshairFilterEnts ) then
		LVSent.CrosshairFilterEnts = {}

		for _, Entity in pairs( constraint.GetAllConstrainedEntities( LVSent ) ) do
			if IsValid( Entity ) then
				if not Entity:GetNoDraw() then
					table.insert( LVSent.CrosshairFilterEnts, Entity )
				end
			end
		end

		for _, Parent in pairs( LVSent.CrosshairFilterEnts ) do
			local Childs = Parent:GetChildren()
			for _, Child in pairs( Childs ) do
				if IsValid( Child ) then
					table.insert( LVSent.CrosshairFilterEnts, Child )
				end
			end
		end
	end

	net.Start( "lvs_player_request_filter" )
		net.WriteEntity( LVSent )
		net.WriteTable( LVSent.CrosshairFilterEnts )
	net.Send( ply )
end)
