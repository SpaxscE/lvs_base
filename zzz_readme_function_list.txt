
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
					Example usage: print( ply:lvsKeyDown("ATTACK") )
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


string = lvsEntity:GetVehicleType() -- returns the vehicle type

table = lvsEntity:GetActiveWeapon() -- returns current active weapon data

number = lvsEntity:GetSelectedWeapon() -- returns current selected weapon ID

number = lvsEntity:GetMaxAmmo()-- returns max ammo of current weapon

bool = lvsEntity:HitGround() -- is the vehicle near ground?

number = lvsEntity:GetShield()
number = lvsEntity:GetMaxShield()
number = lvsEntity:GetShieldPercent()

number = lvsEntity:GetHP()
number = lvsEntity:GetMaxHP()

vector_pos, angle_ang, vector_mins, vector_maxs = lvsEntity:GetBoneInfo( string_bone_name ) -- returns bone position, angle, mins and max for use with the PDS / DS system

bool = lvsEntity:IsInitialized()

table = lvsEntity:GetPassengerSeats()

bool = lvsEntity:HasActiveSoundEmitters()

entity = ply:GetPassenger( num )

table = lvsEntity:GetEveryone()

number = lvsEntity:GetPodIndex() -- this works on the WeaponHandler aswell

entity = ply:GetVehicle() -- this works on the WeaponHandler aswell

table = lvsEntity:GetCrosshairFilterEnts() -- returns all entities that are attached to this vehicle. This is used for the bullet + crosshair trace filter

-- math stuff -- can be called on both lvsEntity or the WeaponHandler Entity
number = lvsEntity:Sign( number )
vector = lvsEntity:VectorSubtractNormal( Normal, Vector )
vector = lvsEntity:VectorSplitNormal( Normal, Vector )
number = lvsEntity:AngleBetweenNormal( Normal1, Normal2 )


========================================
=============== LVS SERVER =============
========================================

lvsEntity:RebuildCrosshairFilterEnts() -- rebuild the crosshair filter and broadcast it to all players

lvsEntity:TakeAmmo( num ) -- take <num> amount of ammo from current weapon

lvsEntity:SetHeat( num ) -- set heat to <num>, num should be 0 to 1

lvsEntity:SetOverheated( overheat ) -- set the current weapon to be overheated

lvsEntity:SetNextAttack( num ) -- set next allowed attack

lvsEntity:WeaponRestoreAmmo() -- refill all ammo

lvsEntity:AddDS( data ) -- adds a DamageSystem handler. See discord wiki-slash-info for usage

lvsEntity:AddDSArmor( data ) -- adds a DamageSystemArmor handler. See discord wiki-slash-info for usage

lvsEntity:AddPDS( data ) -- adds a PhysicsVisualDamageSystem handler. See discord wiki-slash-info for usage

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




========================================
=========== LVS HOOKS SHARED ===========
========================================

hook.Add( "LVS:Initialize", "any_name_you_want", function()
	print("lvs has been initialized")
end )

hook.Add( "LVS.OnPlayerRequestSeatSwitch", "any_name_you_want", function( ply, vehicle, CurPod, NewPod )
	return false -- prevent player from changing seat
end )

========================================
=========== LVS HOOKS SERVER ===========
========================================

hook.Add( "LVS.PlayerKeyDown", "any_name_you_want", function( ply, keyname, pressed )
	print("test")
end )

hook.Add( "LVS.CanPlayerDrive", "any_name_you_want", function( ply, vehicle )
	return false -- prevent players from driving vehicles
end )

hook.Add( "LVS.OnPlayerCannotDrive", "any_name_you_want", function( ply, vehicle )
	print(ply:GetName().." can not drive :(")
end )

========================================
=========== LVS HOOKS CLIENT ===========
========================================

hook.Add( "LVS.PlayerEnteredVehicle", "any_name_you_want", function( ply, veh )
	print(ply:GetName().." entered a lvs vehicle")
end )

hook.Add( "LVS.PlayerLeaveVehicle", "any_name_you_want", function( ply, veh )
	print(ply:GetName().." exit a lvs vehicle")
end )

hook.Add( "LVS.PopulateVehicles", "any_name_you_want", function( lvsNode, pnlContent, tree )

	local node = lvsNode:AddNode( "PrintTest", "icon16/mouse.png" )

	node.DoClick = function( self )
		print("hi")
	end
end )
