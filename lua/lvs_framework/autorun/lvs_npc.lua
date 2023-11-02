
local Teams = {
	["npc_kleiner"] = 0,
	["npc_monk"] = 0,
	["npc_mossman"] = 0,
	["npc_vortigaunt"] = 0,
	["npc_alyx"] = 0,
	["npc_barney"] = 0,
	["npc_citizen"] = 0,
	["npc_dog"] = 0,
	["npc_eli"] = 0,

	["npc_breen"] = 3,
	["npc_combine_s"] = 3,
	["npc_combinedropship"] = 3,
	["npc_combinegunship"] = 3,
	["npc_crabsynth"] = 3,
	["npc_cscanner"] = 3,
	["npc_clawscanner"] = 3,
	["npc_helicopter"] = 3,
	["npc_manhack"] = 3,
	["npc_metropolice"] = 3,
	["npc_mortarsynth"] = 3,
	["npc_sniper"] = 3,
	["npc_stalker"] = 3,
	["npc_strider"] = 3,
	["npc_hunter"] = 3,
	["npc_headcrab"] = 3,
	["npc_headcrab_black"] = 3,
	["npc_headcrab_fast"] = 3,
	["npc_antlion"] = 3,
	["npc_antlionguard"] = 3,
	["npc_antlion_worker"] = 3,
	["npc_zombine"] = 3,
	["npc_zombie"] = 3,
	["npc_zombie_torso"] = 3,
	["npc_poisonzombie"] = 3,
	["npc_fastzombie"] = 3,
	["npc_fastzombie_torso"] = 3,
	["npc_portal_turret_floor"] = 3,
	["npc_rocket_turret"] = 3,
	["npc_rollermine"] = 3,
	["npc_turret_floor"] = 3,
	["npc_turret_ceiling"] = 3,

	["monster_scientist"] = 0,
	["monster_barney"] = 0,

	["monster_human_grunt"] = 3,
	["monster_human_assassin"] = 3,
	["monster_sentry"] = 3,
	["monster_alien_controller"] = 3,
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
	["monster_turret"] = 3,
	["monster_sentry"] = 3,
}

function LVS:GetNPCRelationship( npc_class )
	return Teams[ npc_class ] or 0
end

if CLIENT then return end

function LVS:SetNPCRelationship( npc )
	if not IsValid( npc ) then return end

	for _, veh in pairs( LVS:GetVehicles() ) do
		if not veh:IsInitialized() or veh:IsDestroyed() or not veh:IsEnemy( npc ) then continue end

		npc:AddEntityRelationship( veh, (veh:GetActive() and D_HT or D_LI), 98 )
	end
end

function LVS:SetVehicleRelationship( veh )
	if not IsValid( veh ) or not veh:IsInitialized() or veh:IsDestroyed() then return end

	local D_ = veh:GetActive() and D_HT or D_LI

	for _, npc in pairs( LVS:GetNPCs() ) do
		if not isfunction( npc.GetEnemy ) or npc:GetEnemy() ~= veh then continue end

		npc:AddEntityRelationship( veh, D_, 98 )
	end
end

function LVS:ClearVehicleRelationship( veh )
	if not IsValid( veh ) then return end

	veh:RemoveFlags( FL_OBJECT )

	for _, npc in pairs( LVS:GetNPCs() ) do
		if not isfunction( npc.GetEnemy ) or npc:GetEnemy() ~= veh then continue end

		npc:ClearEnemyMemory()
	end
end
