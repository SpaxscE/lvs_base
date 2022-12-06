LVS.VehiclesStored = LVS.VehiclesStored or {}
LVS.NPCsStored = LVS.NPCsStored or {}

function LVS:GetNPCs()
	for index, ent in pairs( LVS.NPCsStored ) do
		if not IsValid( ent ) then
			LVS.NPCsStored[ index ] = nil
		end
	end

	return LVS.NPCsStored
end

function LVS:GetVehicles()
	for index, ent in pairs( LVS.VehiclesStored ) do
		if not IsValid( ent ) then
			LVS.VehiclesStored[ index ] = nil
		end
	end

	return LVS.VehiclesStored
end

local Teams = {
	["npc_breen"] = 1,
	["npc_combine_s"] = 1,
	["npc_combinedropship"] = 1,
	["npc_combinegunship"] = 1,
	["npc_crabsynth"] = 1,
	["npc_cscanner"] = 1,
	["npc_helicopter"] = 1,
	["npc_manhack"] = 1,
	["npc_metropolice"] = 1,
	["npc_mortarsynth"] = 1,
	["npc_sniper"] = 1,
	["npc_stalker"] = 1,
	["npc_strider"] = 1,
	["monster_human_grunt"] = 1,
	["monster_human_assassin"] = 1,
	["monster_sentry"] = 1,

	["npc_kleiner"] = 2,
	["npc_monk"] = 2,
	["npc_mossman"] = 2,
	["npc_vortigaunt"] = 2,
	["npc_alyx"] = 2,
	["npc_barney"] = 2,
	["npc_citizen"] = 2,
	["npc_dog"] = 2,
	["npc_eli"] = 2,
	["monster_scientist"] = 2,
	["monster_barney"] = 2,

	["npc_fastzombie"] = 3,
	["npc_headcrab"] = 3,
	["npc_headcrab_black"] = 3,
	["npc_headcrab_fast"] = 3,
	["npc_antlion"] = 3,
	["npc_antlionguard"] = 3,
	["npc_zombie"] = 3,
	["npc_zombie_torso"] = 3,
	["npc_poisonzombie"] = 3,
	["monster_alien_grunt"] = 3,
	["monster_alien_slave"] = 3,
	["monster_gargantua"] = 3,
	["monster_bullchicken"] = 3,
	["monster_headcrab"] = 3,
	["monster_babycrab"] = 3,
	["monster_zombie"] = 3,
	["monster_houndeye"] = 3,
	["monster_nihilanth"] = 3,
	["monster_bigmomma"] = 3,
	["monster_babycrab"] = 3,
}
function LVS:GetNPCRelationship( npc_class )
	return Teams[ npc_class ] or "0"
end

hook.Add( "OnEntityCreated", "!!!!lvsEntitySorter", function( ent )
	timer.Simple( FrameTime(), function() 
		if not IsValid( ent ) then return end

		if isfunction( ent.IsNPC ) and ent:IsNPC() then
			table.insert( LVS.NPCsStored, ent )
		end

		if ent.LVS then 
			if CLIENT and ent.PrintName then
				language.Add( ent:GetClass(), ent.PrintName)
			end

			table.insert( LVS.VehiclesStored, ent )
		end
	end )
end )