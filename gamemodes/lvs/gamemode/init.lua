include( "sv_rewards.lua" )
include( "shared.lua" )
include( "player.lua" )
include( "player_extension.lua" )
include( "buymenu/sv_buymenu.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_hud.lua" )
AddCSLuaFile( "cl_join.lua" )
AddCSLuaFile( "cl_scoreboard.lua" )
AddCSLuaFile( "cl_playereditor.lua" )
AddCSLuaFile( "buymenu/cl_buymenu.lua" )
AddCSLuaFile( "buymenu/cl_buymenu_button.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "player_class/player_lvs.lua" )
AddCSLuaFile( "sh_moneysystem.lua" )
AddCSLuaFile( "sh_vehicles.lua" )
AddCSLuaFile( "sh_spectator.lua" )
AddCSLuaFile( "gamelogic/init.lua" )
AddCSLuaFile( "sh_spawnpoint.lua" )
AddCSLuaFile( "sh_damagenotify.lua" )
AddCSLuaFile( "sh_taunts.lua" )
AddCSLuaFile( "sh_notify.lua" )

function GM:InitPostEntity()
	self:GameInitialize()
	self:BuildVehiclePrices()
end

function GM:PostCleanupMap()
	self:GameInitialize()
end

function GM:Tick()
	self:GameTick()
end

--F1
function GM:ShowHelp( ply )
	ply:SendLua( "GAMEMODE:OpenPlayerEditor()" )
end

--F2
function GM:ShowTeam( ply )
	ply:SendLua( "GAMEMODE:OpenJoinMenu()" )
end

--F3
function GM:ShowSpare1( ply )
	ply:SendLua( "LVS:OpenMenu()" )
end

--F4
function GM:ShowSpare2( ply )
	ply:SendLua( "GAMEMODE:OpenBuyMenu()" )
end