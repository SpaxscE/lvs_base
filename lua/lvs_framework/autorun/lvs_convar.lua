-- 2022 and i still havent bothered creating a system that does this automatically

LVS.FreezeTeams = CreateConVar( "lvs_freeze_teams", "0", {FCVAR_REPLICATED , FCVAR_ARCHIVE},"enable/disable auto ai-team switching" )
LVS.TeamPassenger = CreateConVar( "lvs_teampassenger", "0", {FCVAR_REPLICATED , FCVAR_ARCHIVE},"only allow players of matching ai-team to enter the vehicle? 1 = team only, 0 = everyone can enter" )
LVS.PlayerDefaultTeam = CreateConVar( "lvs_default_teams", "0", {FCVAR_REPLICATED , FCVAR_ARCHIVE},"set default player ai-team" )

LVS.cVar_IgnoreNPCs = CreateConVar( "lvs_ai_ignorenpcs", "0", {FCVAR_REPLICATED , FCVAR_ARCHIVE},"should LVS-AI ignore NPCs?" )
LVS.IgnoreNPCs = LVS.cVar_IgnoreNPCs and LVS.cVar_IgnoreNPCs:GetBool() or false
cvars.AddChangeCallback( "lvs_ai_ignoreplayers", function( convar, oldValue, newValue ) 
	LVS.IgnorePlayers = tonumber( newValue ) ~=0
end)

LVS.cVar_playerignore = CreateConVar( "lvs_ai_ignoreplayers", "0", {FCVAR_REPLICATED , FCVAR_ARCHIVE},"should LVS-AI ignore Players?" )
LVS.IgnorePlayers = LVS.cVar_playerignore and LVS.cVar_playerignore:GetBool() or false
cvars.AddChangeCallback( "lvs_ai_ignorenpcs", function( convar, oldValue, newValue ) 
	LVS.IgnoreNPCs = tonumber( newValue ) ~=0
end)

if SERVER then
	util.AddNetworkString( "lvs_admin_setconvar" )

	net.Receive( "lvs_admin_setconvar", function( length, ply )
		if not IsValid( ply ) or not ply:IsSuperAdmin() then return end

		local ConVar = net.ReadString()
		local Value = tonumber( net.ReadString() )

		RunConsoleCommand( ConVar, Value ) 
	end)

	return
end

CreateClientConVar( "lvs_mouseaim", 0, true, true)
CreateClientConVar( "lvs_mouseaim_type", 0, true, false)
CreateClientConVar( "lvs_edit_hud", 1, true, false)
CreateClientConVar( "lvs_sensitivity_x", 1, true, true)
CreateClientConVar( "lvs_sensitivity_y", 1, true, true)
CreateClientConVar( "lvs_return_delta", 1, true, true)

LVS.cvarCamFocus = CreateClientConVar( "lvs_camerafocus", 0, true, false)

local cvarVolume = CreateClientConVar( "lvs_volume", 0.5, true, false)
LVS.EngineVolume = cvarVolume and cvarVolume:GetFloat() or 0.5
cvars.AddChangeCallback( "lvs_volume", function( convar, oldValue, newValue ) 
	LVS.EngineVolume = math.Clamp( tonumber( newValue ), 0, 1 )
end)

local cvarTrail = CreateClientConVar( "lvs_show_traileffects", 1, true, false)
LVS.ShowTraileffects = cvarTrail and cvarTrail:GetBool() or true
cvars.AddChangeCallback( "lvs_show_traileffects", function( convar, oldValue, newValue ) 
	LVS.ShowTraileffects = tonumber( newValue ) ~=0
end)

local cvarEffects = CreateClientConVar( "lvs_show_effects", 1, true, false)
LVS.ShowEffects = cvarEffects and cvarEffects:GetBool() or true
cvars.AddChangeCallback( "lvs_show_effects", function( convar, oldValue, newValue ) 
	LVS.ShowEffects = tonumber( newValue ) ~=0
end)

local cvarPhysEffects = CreateClientConVar( "lvs_show_physicseffects", 1, true, false)
LVS.ShowPhysicsEffects = cvarPhysEffects and cvarPhysEffects:GetBool() or true
cvars.AddChangeCallback( "lvs_show_physicseffects", function( convar, oldValue, newValue ) 
	LVS.ShowPhysicsEffects = tonumber( newValue ) ~=0
end)

local cvarShowIdent = CreateClientConVar( "lvs_show_identifier", 1, true, false)
LVS.ShowIdent = cvarShowIdent and cvarShowIdent:GetBool() or true
cvars.AddChangeCallback( "lvs_show_identifier", function( convar, oldValue, newValue ) 
	LVS.ShowIdent = tonumber( newValue ) ~=0
end)

local cvarHitMarker = CreateClientConVar( "lvs_hitmarker", 1, true, false)
LVS.ShowHitMarker = cvarHitMarker and cvarHitMarker:GetBool() or false
cvars.AddChangeCallback( "lvs_hitmarker", function( convar, oldValue, newValue ) 
	LVS.ShowHitMarker = tonumber( newValue ) ~=0
end)

local cvarAntiAlias = GetConVar( "mat_antialias" )
LVS.AntiAliasingEnabled = cvarAntiAlias and (cvarAntiAlias:GetInt() > 3) or false
cvars.AddChangeCallback( "mat_antialias", function( convar, oldValue, newValue ) 
	LVS.AntiAliasingEnabled = tonumber( newValue ) > 3
end)

local cvarBulletSFX = CreateClientConVar( "lvs_bullet_nearmiss", 1, true, false)
LVS.EnableBulletNearmiss = cvarBulletSFX and cvarBulletSFX:GetBool() or true
cvars.AddChangeCallback( "lvs_bullet_nearmiss", function( convar, oldValue, newValue ) 
	LVS.EnableBulletNearmiss = tonumber( newValue ) ~=0
end)

local cvarDev = GetConVar( "developer" )
LVS.DeveloperEnabled = cvarDev and (cvarDev:GetInt() >= 1) or false
cvars.AddChangeCallback( "developer", function( convar, oldValue, newValue )
	LVS.DeveloperEnabled = (tonumber( newValue ) or 0) >= 1
end)

cvars.AddChangeCallback( "lvs_mouseaim", function( convar, oldValue, newValue )
	LocalPlayer():lvsBuildControls()

	net.Start("lvs_toggle_mouseaim")
	net.SendToServer()
end)
