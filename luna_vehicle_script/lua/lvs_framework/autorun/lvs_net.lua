
if SERVER then
	util.AddNetworkString( "lvs_player_request_filter" )

	net.Receive( "lvs_player_request_filter", function( length, ply )
		if not IsValid( ply ) then return end

		local ent = net.ReadEntity()

		if not IsValid( ent ) then return end

		local CrosshairFilterEnts = table.Copy( ent:GetCrosshairFilterEnts() )

		for id, entity in pairs( CrosshairFilterEnts ) do
			if not IsValid( entity ) or entity:GetNoDraw() then
				CrosshairFilterEnts[ id ] = nil
			end
		end

		net.Start( "lvs_player_request_filter" )
			net.WriteEntity( ent )
			net.WriteTable( CrosshairFilterEnts )
		net.Send( ply )
	end)
else
	net.Receive( "lvs_player_request_filter", function( length )
		local LVSent = net.ReadEntity()

		if not IsValid( LVSent ) then return end

		local Filter = {}

		for _, entity in pairs( net.ReadTable() ) do
			if not IsValid( entity ) then continue end
			table.insert( Filter, entity )
		end

		LVSent.CrosshairFilterEnts = Filter
	end )
end