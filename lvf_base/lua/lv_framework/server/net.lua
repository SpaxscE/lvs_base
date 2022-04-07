
util.AddNetworkString( "lvf_player_request_filter" )

net.Receive( "lvf_player_request_filter", function( length, ply )
	if not IsValid( ply ) then return end

	local LVFent = net.ReadEntity()

	if not IsValid( LVFent ) then return end

	if not istable( LVFent.CrosshairFilterEnts ) then
		LVFent.CrosshairFilterEnts = {}

		for _, Entity in pairs( constraint.GetAllConstrainedEntities( LVFent ) ) do
			if IsValid( Entity ) then
				if not Entity:GetNoDraw() then
					table.insert( LVFent.CrosshairFilterEnts, Entity )
				end
			end
		end

		for _, Parent in pairs( LVFent.CrosshairFilterEnts ) do
			local Childs = Parent:GetChildren()
			for _, Child in pairs( Childs ) do
				if IsValid( Child ) then
					table.insert( LVFent.CrosshairFilterEnts, Child )
				end
			end
		end
	end

	net.Start( "lvf_player_request_filter" )
		net.WriteEntity( LVFent )
		net.WriteTable( LVFent.CrosshairFilterEnts )
	net.Send( ply )
end)
