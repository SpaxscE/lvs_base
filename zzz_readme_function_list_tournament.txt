
========================================
===============  SHARED  ===============
========================================

local GameState = GAMEMODE:GetGameState()

-- gamestates are:
0 = GAMESTATE_WAIT_FOR_PLAYERS
1 = GAMESTATE_BUILD
2 = GAMESTATE_START
3 = GAMESTATE_MAIN
4 = GAMESTATE_END




local GoalEnt = GAMEMODE:GetGoalEntity() -- gets the goal entity, returns NULL when not spawned

local GoalPos = GAMEMODE:GetGoalPos() -- returns the goal pos


local table_players_team1 = GAMEMODE:GameGetPlayersTeam1() -- returns all players in team 1

local table_players_team2 = GAMEMODE:GameGetPlayersTeam2() -- returns all players in team 2

local table_players_both_teams = GAMEMODE:GameGetPlayers() -- returns all players, except spectators

local table_players_both_teams_alive = GAMEMODE:GameGetAlivePlayers()  -- returns all players of both teams that are alive


list.Set( "VehiclePrices", "lvs_wheeldrive_dodtiger", 9999 ) -- set price for tiger tank to 9999



hook.Add( "LVS.OnPlayerSelectVehicle", "any_name_you_want", function( ply, class )
	if class == "lvs_trailer_flak" then  -- disallow spawning of flak
		return true   -- return true to prevent
	end
end )


hook.Add( "LVS.PlayerVehicleClassAllowed", "any_name_you_want", function( ply, class )

	if class == "lvs_wheeldrive_montreal" then return false end -- this will hide the montreal from the buylist for this specific player and prevent it from being spawned

end)



========================================
===============  SERVER  ===============
========================================

player:ReapplyLoadout() -- reapplys the loadout, restocks ammo, makes sure the tools/weapons you have are allowed to be used in current game state

local table_list_entities = player:GetEntityList() -- returns a list of all entities the player has spawned, such as fortifications, spawnpoints, vehicles

player:ClearEntityList( keep_spawnpoints ) -- removes all entities in the list, it wont delete spawnpoints if keep_spawnpoints == true

player:AddEntityList( entity ) -- adds a entity to players entity list

player:SendGameNotify( text, color, lifetime ) -- send a notification to player in the center of the screen

GAMEMODE:SendGameNotify( text, color, lifetime ) -- send a notification to all player in the center of the screen

GAMEMODE:CreateGoalEntity( Pos ) -- spawn goal at given position

GAMEMODE:RemoveGoalEntity() -- removes the goal entity

GAMEMODE:GameReset() -- resets the entire game


hook.Add( "LVS.OnGameStateChanged", "any_name_you_want", function( oldstate, newstate )
	print( newstate )
end )

-- gamestates are:
0 = GAMESTATE_WAIT_FOR_PLAYERS
1 = GAMESTATE_BUILD
2 = GAMESTATE_START
3 = GAMESTATE_MAIN
4 = GAMESTATE_END



hook.Add( "LVS.PlayerLoadoutWeapons", "any_name_you_want", function( ply, class )

	-- give custom sweps here
	ply:Give("weapon_ar2")
	ply:Give("weapon_crowbar")

	--return true  -- return true prevent giving of standard weapons
end )



hook.Add( "LVS.PlayerLoadoutTools", "any_name_you_want", function( ply, class )

	-- give custom tools here
	ply:Give("weapon_physgun")

	--return true  -- return true prevent giving of standard tools
end )



========================================
===============  CLIENT  ===============
========================================

local hide = {
	["LVSHudHealth"] = true, -- disable default player health hud
	["LVSHudAmmo"] = true, -- disable default player armor hud
	["LVSHudMoney"] = true, -- disable showing money info
}
hook.Add( "HUDShouldDraw", "HideHUD", function( name )
	if hide[ name ] then
		return false
	end
end )
