
=========================================
============= PLAYER SHARED =============
=========================================

lvsEntity = ply:lvsGetVehicle() -- returns the lvs entity the player is currently driving or sitting in
entity = ply:lvsGetWeaponHandler() -- returns the current weapon handler. As driver this is always equal to ply:lvsGetVehicle()

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



table = lvsEntity:GetActiveWeapon() -- returns current active weapon data

number = lvsEntity:GetSelectedWeapon() -- returns current selected weapon ID

number = lvsEntity:GetMaxAmmo()-- returns max ammo of current weapon

bool = lvsEntity:HitGround() -- is the vehicle near ground?

number = lvsEntity:GetShield()
number = lvsEntity:GetMaxShield()
number = lvsEntity:GetShieldPercent()

number = lvsEntity:GetHP()
number = lvsEntity:GetMaxHP()

bool = lvsEntity:IsInitialized()

table = lvsEntity:GetPassengerSeats()

bool = lvsEntity:HasActiveSoundEmitters()

entity = ply:GetPassenger( num )

table = lvsEntity:GetEveryone()

number = lvsEntity:GetPodIndex() -- this works on the WeaponHandler aswell

entity = ply:GetVehicle() -- this works on the WeaponHandler aswell


-- math stuff -- can be called on both lvsEntity or the WeaponHandler Entity
number = lvsEntity:Sign( number )
vector = lvsEntity:VectorSubtractNormal( Normal, Vector )
vector = lvsEntity:VectorSplitNormal( Normal, Vector )
number = lvsEntity:AngleBetweenNormal( Normal1, Normal2 )


========================================
=============== LVS SERVER =============
========================================

lvsEntity:TakeAmmo( num ) -- take <num> amount of ammo from current weapon

lvsEntity:SetHeat( num ) -- set heat to <num>, num should be 0 to 1

lvsEntity:SetOverheated( overheat ) -- set the current weapon to be overheated

lvsEntity:SetNextAttack( num ) -- set next allowed attack

lvsEntity:WeaponRestoreAmmo() -- refill all ammo



number = lvsEntity:GetAmmo() -- returns amount of ammo in current weapon

number = lvsEntity:GetHeat() -- returns the heat from current weapon

bool = lvsEntity:GetOverheated() -- returns if the current weapon is overheated

bool = lvsEntity:CanAttack() -- return if the weapon can fire

bool = lvsEntity:WeaponsShouldFire() -- returns if player is pressing attack key, or if AI is attempting to shoot




========================================
=============== LVS CLIENT =============
========================================

number = lvsEntity:GetNWAmmo() -- returns amount of ammo in current weapon
number = lvsEntity:GetNWHeat() -- returns the heat from current weapon

number = lvsEntity:GetAmmoID( ID ) -- returns amount of ammo in given ID's weapon
