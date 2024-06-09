
if CLIENT then 
	net.Receive( "lvs_hurtmarker", function( len )
		if not LVS.ShowHitMarker then return end

		local ply = LocalPlayer()

		local vehicle = ply:lvsGetVehicle()

		if not IsValid( vehicle ) then return end

		vehicle:HurtMarker( net.ReadFloat() )
	end )

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

		if not IsValid( vehicle ) then return end

		vehicle:KillMarker()
	end )

	local LastMarker = 0
	net.Receive( "lvs_armormarker", function( len )
		if not LVS.ShowHitMarker then return end

		local ply = LocalPlayer()

		local vehicle = ply:lvsGetVehicle()

		if not IsValid( vehicle ) then return end

		local T = CurTime()

		local IsDamage = net.ReadBool()

		local DontHurtEars = math.Clamp( T - LastMarker, 0, 1 ) ^ 2

		LastMarker = T

		local ArmorFailed = IsDamage and "takedamage" or "pen"
		local Volume = IsDamage and (0.3 * DontHurtEars) or 1

		ply:EmitSound( "lvs/armor_"..ArmorFailed.."_"..math.random(1,3)..".wav", 85, math.random(95,105), Volume, CHAN_ITEM2 )
	end )

	return
end

util.AddNetworkString( "lvs_hitmarker" )
util.AddNetworkString( "lvs_hurtmarker" )
util.AddNetworkString( "lvs_killmarker" )
util.AddNetworkString( "lvs_armormarker" )