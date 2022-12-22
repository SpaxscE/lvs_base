
if CLIENT then 
	local LastHitMarker = 0
	local LastKillMarker = 0

	net.Receive( "lvs_hitmarker", function( len )
		if not LVS.ShowHitMarker then return end

		local ply = LocalPlayer()

		local vehicle = ply:lvsGetVehicle()
		if IsValid( vehicle ) then 
			vehicle:HitMarker()
		end
	end )

	net.Receive( "lvs_killmarker", function( len )
		if not LVS.ShowHitMarker then return end

		local ply = LocalPlayer()

		local vehicle = ply:lvsGetVehicle()
		if IsValid( vehicle ) then 
			vehicle:KillMarker()
		end
	end )

	return
end

util.AddNetworkString( "lvs_hitmarker" )
util.AddNetworkString( "lvs_killmarker" )