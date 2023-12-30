
local cVar_forcedirect = CreateConVar( "lvs_force_directinput", "0", {FCVAR_REPLICATED , FCVAR_ARCHIVE},"Force Direct Input Steering Method?" )
local cVar_forceindicator = CreateConVar( "lvs_force_forceindicator", "0", {FCVAR_REPLICATED , FCVAR_ARCHIVE},"Force Direct Input Steering Method?" )

function LVS:IsDirectInputForced()
	return LVS.ForceDirectInput == true
end

function LVS:IsIndicatorForced()
	return LVS.ForceIndicator == true
end

if SERVER then
	util.AddNetworkString( "lvs_forced_input_getter" )

	local function UpdateForcedSettings( ply )
		net.Start( "lvs_forced_input_getter" )

		net.WriteBool( LVS:IsDirectInputForced() )
		net.WriteBool( LVS:IsIndicatorForced() )

		if IsValid( ply ) then
			net.Send( ply )
		else
			net.Broadcast()
		end
	end

	LVS.ForceDirectInput = cVar_forcedirect and cVar_forcedirect:GetBool() or false
	cvars.AddChangeCallback( "lvs_force_directinput", function( convar, oldValue, newValue ) 
		LVS.ForceDirectInput = tonumber( newValue ) ~=0

		UpdateForcedSettings()
	end)

	LVS.ForceIndicator = cVar_forceindicator and cVar_forceindicator:GetBool() or false
	cvars.AddChangeCallback( "lvs_force_forceindicator", function( convar, oldValue, newValue ) 
		LVS.ForceIndicator = tonumber( newValue ) ~=0

		UpdateForcedSettings()
	end)

	net.Receive( "lvs_forced_input_getter", function( length, ply )
		UpdateForcedSettings( ply )
	end)
else
	net.Receive( "lvs_forced_input_getter", function( length )
		LVS.ForceDirectInput = net.ReadBool()
		LVS.ForceIndicator = net.ReadBool()
	end )

	hook.Add( "InitPostEntity", "!11!!!lvsIsPlayerReady", function()
		net.Start( "lvs_forced_input_getter" )
		net.SendToServer()
	end )
end