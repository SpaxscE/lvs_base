
=========================================
============= PLAYER SHARED =============
=========================================

entity = ply:lvsGetVehicle() -- returns the lvs entity the player is currently driving or sitting in
entity = ly:lvsGetWeaponHandler() -- returns the current weapon handler. As driver this is always equal to ply:lvsGetVehicle()

number = ply:lvsGetAITeam() -- returns the player's AI-Team

ply:lvsSetAITeam( nTeam ) -- set a player's AI-Team. Valid teams are:
--[[
nTeam:
	0 = FRIENDLY TO EVERYONE
	1 = FRIENDLY TO TEAM 1 and 0
	2 = FRIENDLY TO TEAM 2 and 0
	3 = HOSTILE TO EVERYONE
]]


table = ply:lvsGetControls() -- returns ALL player controls in a table
bool = ply:lvsKeyDown( string_name ) -- returns current given key, default binding string_name's can be found in lvs_keybinding.lua
					Example usage: print( ply:lvsKeyDow("ATTACK") )
bool = ply:lvsMouseAim() -- returns if the player has mouse aim enabled
ply:lvsMouseSensitivity()

ply:lvsBuildControls() -- build player controls table

bool = ply:lvsGetInputEnabled() -- returns if inputs are disabled or not
ply:lvsSetInputDisabled( bool ) -- set inputs enabled/disabled (this has a auto-enable build in after 4 seconds and has to be called every 4 seconds to stay disabled)


========================================
=============== LVS SHARED =============
========================================

table = LVS:GetNPCs() -- returns all npc's the AI system has detected
nTeam = LVS:GetNPCRelationship( npc_class ) -- returns the ai team of given npc's class name. Valid teams are:
--[[
nTeam:
	0 = FRIENDLY TO EVERYONE
	1 = FRIENDLY TO TEAM 1 and 0
	2 = FRIENDLY TO TEAM 2 and 0
	3 = HOSTILE TO EVERYONE
]]

table = LVS:GetVehicles() -- returns all spawned LVS vehicles

bool = LVS:IsDirectInputForced() -- returns if mouse aim is force-disabled or not
