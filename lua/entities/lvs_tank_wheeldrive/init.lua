AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")
include("sv_tracksystem.lua")

AddCSLuaFile( "modules/cl_tankview.lua" )
AddCSLuaFile( "modules/cl_attachable_playermodels.lua" )
AddCSLuaFile( "modules/sh_turret.lua" )
AddCSLuaFile( "modules/sh_turret_ballistics.lua" )
AddCSLuaFile( "modules/sh_turret_splitsound.lua" )

ENT.DSArmorDamageReductionType = DMG_CLUB
ENT.DSArmorIgnoreDamageType = DMG_BULLET + DMG_SONIC + DMG_ENERGYBEAM
