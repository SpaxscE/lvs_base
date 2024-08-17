
function GM:OnPlayerKillOtherPlayer( attacker, victim, is_teamkill )
	self:HandlePlayerTaunt( attacker, victim, is_teamkill )

	if self:GetGameState() == GAMESTATE_WAIT_FOR_PLAYERS then return end

	if victim:InVehicle() then
		return
	end

	if is_teamkill then
		attacker:TakeMoney( self.MoneyPerTeamKill )
	else
		attacker:AddMoney( self.MoneyPerKill )
	end
end

function GM:OnPlayerDestroyFortification( attacker, fortification, is_teamkill )
	if self:GetGameState() == GAMESTATE_WAIT_FOR_PLAYERS then return end

	if is_teamkill then
		attacker:TakeMoney( self.MoneyPerFortificationTeamKill )
	else
		if fortification._lvsPlayerSpawnPoint then
			attacker:AddMoney( self.MoneyPerSpawnPointKill )
		else
			attacker:AddMoney( self.MoneyPerFortificationKill )
		end
	end
end

hook.Add( "LVS.OnVehicleDestroyed", "!!!!lvs_kill_vehicle_money", function( vehicle, attacker, inflictor )
	if GAMEMODE:GetGameState() == GAMESTATE_WAIT_FOR_PLAYERS then return end

	if not IsValid( vehicle ) or not IsValid( attacker ) or not attacker:IsPlayer() then return end

	local is_teamkill = attacker:lvsGetAITeam() == vehicle:GetAITEAM()

	local price = GAMEMODE:GetVehiclePrice( vehicle:GetClass() )

	if is_teamkill then
		local add  = GAMEMODE.MoneyPerTeamKill * #vehicle:GetEveryone()

		attacker:TakeMoney( price * GAMEMODE.MoneyPerTeamKillVehicleMultiplier + add )
	else
		local add = GAMEMODE.MoneyPerKill * #vehicle:GetEveryone()

		attacker:AddMoney( price * GAMEMODE.MoneyPerKillVehicleMultiplier + add )
	end
end )
