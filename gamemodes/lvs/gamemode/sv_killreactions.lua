
function GM:OnPlayerKillOtherPlayer( attacker, victim, is_teamkill )
	self:HandlePlayerTaunt( attacker, victim, is_teamkill )

	if self:GetGameState() == GAMESTATE_WAIT_FOR_PLAYERS then return end

	if victim:InVehicle() then

		if is_teamkill then
			attacker:TakeMoney( self.MoneyPerTeamKillVehicle )
		else
			attacker:AddMoney( self.MoneyPerKillVehicle )
		end

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
