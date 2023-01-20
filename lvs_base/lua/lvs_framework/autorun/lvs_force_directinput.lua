
LVS.cVar_forcedirect = CreateConVar( "lvs_force_directinput", "0", {FCVAR_REPLICATED , FCVAR_ARCHIVE},"Force Direct Input Steering Method?" )

if SERVER then
	util.AddNetworkString( "lvs_forced_input_getter" )

	LVS.ForceDirectInput = cVar_forcedirect and cVar_forcedirect:GetBool() or false
	cvars.AddChangeCallback( "lvs_force_directinput", function( convar, oldValue, newValue ) 
		LVS.ForceDirectInput = tonumber( newValue ) ~=0

		net.Start( "lvs_forced_input_getter" )
			net.WriteBool( LVS:IsDirectInputForced() )
		net.Broadcast()
	end)

	function LVS:IsDirectInputForced()
		return LVS.ForceDirectInput == true
	end

	net.Receive( "lvs_forced_input_getter", function( length, ply )
		net.Start( "lvs_forced_input_getter" )
			net.WriteBool( LVS:IsDirectInputForced() )
		net.Send( ply )
	end)
else
	net.Receive( "lvs_forced_input_getter", function( length )
		LVS.ForceDirectInput = net.ReadBool()
	end )
	
	function LVS:IsDirectInputForced()
		if not isbool( LVS.ForceDirectInput ) then
			LVS.ForceDirectInput = false

			net.Start( "lvs_forced_input_getter" )
			net.SendToServer()
		end

		return LVS.ForceDirectInput
	end
end