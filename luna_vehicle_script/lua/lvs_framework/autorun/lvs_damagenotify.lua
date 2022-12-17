
if CLIENT then 
	local LastHitMarker = 0
	local LastKillMarker = 0

	net.Receive( "lvs_hitmarker", function( len )
		if not LVS.ShowHitMarker then return end

		if LastHitMarker - math.random(0.09,0.14) > CurTime() then return end

		LastHitMarker = CurTime() + 0.15

		local ply = LocalPlayer()

		local vehicle = ply:lvsGetVehicle()
		if IsValid( vehicle ) then 
			vehicle:HitMarker( LastHitMarker, net.ReadBool() )
		end
	end )

	net.Receive( "lvs_killmarker", function( len )
		if not LVS.ShowHitMarker then return end

		if LastKillMarker - 0.14 > CurTime() then return end

		LastKillMarker = CurTime() + 0.5

		local ply = LocalPlayer()

		local vehicle = ply:lvsGetVehicle()
		if IsValid( vehicle ) then 
			vehicle:KillMarker( LastKillMarker )
		end
	end )

	return
end

util.AddNetworkString( "lvs_hitmarker" )
util.AddNetworkString( "lvs_killmarker" )