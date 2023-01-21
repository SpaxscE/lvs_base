
local cVar_forcedirect = CreateConVar( "lvs_force_directinput", "0", {FCVAR_REPLICATED , FCVAR_ARCHIVE},"Force Direct Input Steering Method?" )

function LVS:IsDirectInputForced()
	return LVS.ForceDirectInput == true
end

if SERVER then
	util.AddNetworkString( "lvs_forced_input_getter" )

	LVS.ForceDirectInput = cVar_forcedirect and cVar_forcedirect:GetBool() or false
	cvars.AddChangeCallback( "lvs_force_directinput", function( convar, oldValue, newValue ) 
		LVS.ForceDirectInput = tonumber( newValue ) ~=0

		net.Start( "lvs_forced_input_getter" )
			net.WriteBool( LVS:IsDirectInputForced() )
		net.Broadcast()
	end)

	net.Receive( "lvs_forced_input_getter", function( length, ply )
		net.Start( "lvs_forced_input_getter" )
			net.WriteBool( LVS:IsDirectInputForced() )
		net.Send( ply )
	end)
else
	net.Receive( "lvs_forced_input_getter", function( length )
		LVS.ForceDirectInput = net.ReadBool()
	end )

	hook.Add( "InitPostEntity", "!11!!!lvsIsPlayerReady", function()
		net.Start( "lvs_forced_input_getter" )
		net.SendToServer()
	end )
end