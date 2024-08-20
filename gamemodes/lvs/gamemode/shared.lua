GM.Name = "LVS-Tournament"
GM.Author = "Luna"
GM.Email = "juliewerding@gmx.de"
GM.Website = "https://discord.gg/BeVtn7uwNH"

GM.ScrambleTime = 40
GM.FinishTime = 20

GM.ColorFriend = Color(0,127,255,255)
GM.ColorEnemy = Color(255,0,0,255)
GM.ColorNeutral = Color(0,255,255,255)

GM.ColorFriendDark = Color(0,50,100,255)
GM.ColorEnemyDark = Color(100,0,0,255)

DeriveGamemode( "base" )

include( "player_class/player_lvs.lua" )
include( "sh_moneysystem.lua" )
include( "sh_vehicles.lua" )
include( "sh_spectator.lua" )
include( "gamelogic/init.lua" )
include( "sh_spawnpoint.lua" )
include( "sh_damagenotify.lua" )
include( "sh_taunts.lua" )
include( "sh_notify.lua" )

function GM:Initialize()
	LVS.HudForceDefault = true
	LVS.FreezeTeams = true
	LVS.TeamPassenger = true

	cvars.RemoveChangeCallback( "lvs_freeze_teams", "lvs_freezeteams_callback" )
	cvars.RemoveChangeCallback( "lvs_teampassenger", "lvs_teampassenger_callback" )
end

function GM:CreateTeams()
end
