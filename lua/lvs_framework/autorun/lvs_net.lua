
if SERVER then
	util.AddNetworkString( "lvs_player_request_filter" )
	util.AddNetworkString( "lvs_player_enterexit" )
	util.AddNetworkString( "lvs_toggle_mouseaim" )

	net.Receive( "lvs_toggle_mouseaim", function( length, ply )
		ply:lvsBuildControls()

		local veh = ply:lvsGetVehicle()

		if not IsValid( veh ) then return end

		veh:AlignView( ply )
	end)

	net.Receive( "lvs_player_request_filter", function( length, ply )
		if not IsValid( ply ) then return end

		local ent = net.ReadEntity()

		if not IsValid( ent ) or not ent.GetCrosshairFilterEnts then return end -- TODO: Make this loop around and wait for ent.IsInitialized to exist and ent:IsInitialized() to return true

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

	net.Receive( "lvs_player_enterexit", function( len )
		local Enable = net.ReadBool()
		local Vehicle = net.ReadEntity()

		if not IsValid( Vehicle ) then return end

		if Enable then
			hook.Run( "LVS.PlayerEnteredVehicle", LocalPlayer(), Vehicle )
		else
			hook.Run( "LVS.PlayerLeaveVehicle", LocalPlayer(), Vehicle )
		end
	end )
end