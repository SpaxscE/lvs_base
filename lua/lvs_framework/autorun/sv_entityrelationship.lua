
local function ApplyTeamRules( teamVeh, IsEnemy )
	if teamVeh == 0 then
		IsEnemy = false
	end

	if teamVeh == 3 then
		IsEnemy = true
	end

	return IsEnemy
end

function LVS:SetNPCRelationship( NPC )
	for _, lvsVeh in pairs( LVS:GetVehicles() ) do
		local teamVeh = lvsVeh:GetAITEAM()

		local IsEnemy = ApplyTeamRules( teamVeh, lvsVeh:IsEnemy( NPC ) )

		local IsActive = (lvsVeh:GetAI() or #lvsVeh:GetEveryone() > 0) and not lvsVeh:IsDestroyed()

		if IsActive and IsEnemy then
			NPC:AddEntityRelationship( lvsVeh, D_HT, 10 )
			NPC:UpdateEnemyMemory( lvsVeh, lvsVeh:GetPos() )
		else
			local D_, _ = NPC:Disposition( lvsVeh )

			if D_ ~= D_NU then
				NPC:AddEntityRelationship( lvsVeh, D_NU )
				NPC:ClearEnemyMemory( lvsVeh )
			end
		end
	end
end

function LVS:SetVehicleRelationship( lvsVeh )
	local teamVeh = lvsVeh:GetAITEAM()

	local Pos = lvsVeh:GetPos()
	local IsActive = (lvsVeh:GetAI() or #lvsVeh:GetEveryone() > 0) and not lvsVeh:IsDestroyed()

	for _, NPC in pairs( LVS:GetNPCs() ) do
		local IsEnemy = ApplyTeamRules( teamVeh, lvsVeh:IsEnemy( NPC ) )

		if IsActive and IsEnemy then
			NPC:AddEntityRelationship( lvsVeh, D_HT, 10 )
			NPC:UpdateEnemyMemory( lvsVeh, Pos )
		else
			local D_, _ = NPC:Disposition( lvsVeh )

			if D_ ~= D_NU then
				NPC:AddEntityRelationship( lvsVeh, D_NU )
				NPC:ClearEnemyMemory( lvsVeh )
			end
		end
	end
end

hook.Add( "LVS.UpdateRelationship", "!!!!lvsEntityRelationship", function( ent )
	timer.Simple(0.1, function()
		if not IsValid( ent ) then return end

		if isfunction( ent.IsNPC ) and ent:IsNPC() then
			LVS:SetNPCRelationship( ent )
		else
			LVS:SetVehicleRelationship( ent )
		end
	end)
end )