if SERVER then
	util.AddNetworkString( "lvs_hudshoulddraw" )

	hook.Add( "PlayerEnteredVehicle", "!!!!lvs_hudshoulddraw_hookadd", function( ply, veh, role )
		if not IsValid( ply:lvsGetVehicle() ) then return end

		net.Start( "lvs_hudshoulddraw" )
			net.WriteBool( true )
		net.Send( ply )

		ply._lvsShouldDrawDisabled = true
	end )
 
	hook.Add( "PlayerLeaveVehicle", "!!!!lvs_hudshoulddraw_hookremove", function( ply, veh )
		if not ply._lvsShouldDrawDisabled then return end

		net.Start( "lvs_hudshoulddraw" )
			net.WriteBool( false )
		net.Send( ply )

		ply._lvsShouldDrawDisabled = nil
	end )

	return
end

local hide = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudAmmo"] = true,
}
local function HUDShouldDrawLVS( name )
	if hide[ name ] then return false end
end

net.Receive( "lvs_hudshoulddraw" , function( len )
	local Enable = net.ReadBool()

	if Enable then
		hook.Add( "HUDShouldDraw", "!!!!lvs_hidehud", HUDShouldDrawLVS )
	else
		hook.Remove( "HUDShouldDraw", "!!!!lvs_hidehud" )
	end
end )
