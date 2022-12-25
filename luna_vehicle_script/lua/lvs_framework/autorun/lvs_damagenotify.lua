
if CLIENT then 
	net.Receive( "lvs_hitmarker", function( len )
		if not LVS.ShowHitMarker then return end

		local ply = LocalPlayer()

		local vehicle = ply:lvsGetVehicle()
		if not IsValid( vehicle ) then return end

		if net.ReadBool() then
			vehicle:CritMarker()
		else
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