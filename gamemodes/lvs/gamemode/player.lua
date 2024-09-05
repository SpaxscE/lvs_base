
function GM:DoPlayerDeath( ply, attacker, dmginfo )
	if not dmginfo:IsDamageType( DMG_REMOVENORAGDOLL ) then
		if dmginfo:GetDamageForce():Length() > 10000 or dmginfo:IsDamageType( DMG_ALWAYSGIB ) then
			ply:CreateGibs( dmginfo )
		else
			ply:CreateRagdoll( )
		end
	end

	ply:AddDeaths( 1 )

	if attacker:IsValid() and attacker:IsPlayer() then

		if attacker == ply then
			attacker:AddFrags( -1 )
		else
			attacker:AddFrags( 1 )
		end

	end
end

function GM:PlayerDeathSound( ply )
	return true
end

function GM:OnDamagedByExplosion( ply, dmginfo )
end

function GM:CanPlayerSuicide( ply )
	return ply:Team() ~= TEAM_SPECTATOR
end

function GM:PlayerDisconnected( ply )
	ply:ClearEntityList()
end

function GM:PlayerSpawn( ply, transiton )

	if ply:Team() == TEAM_SPECTATOR then

		self:PlayerSpawnAsSpectator( ply )

		return

	end

	ply:UnSpectate()

	player_manager.SetPlayerClass( ply, "player_lvs" )
	player_manager.OnPlayerSpawn( ply, transiton )
	player_manager.RunClass( ply, "Spawn" )

	hook.Call( "PlayerLoadout", GAMEMODE, ply )

	hook.Call( "PlayerSetModel", GAMEMODE, ply )

	ply:SetupHands()

end

function GM:PlayerInitialSpawn( ply, transiton )

	local NumTeam1 = #self:GameGetPlayersTeam1()
	local NumTeam2 = #self:GameGetPlayersTeam2()

	ply:SetTeam( TEAM_UNASSIGNED )

	if NumTeam1 == NumTeam2 then
		local team = math.random(1,2)
		ply:SetTeam( team )
		ply:lvsSetAITeam( team )
	else
		if NumTeam1 < NumTeam2 then
			ply:SetTeam( 1 )
			ply:lvsSetAITeam( 1 )
		else
			ply:SetTeam( 2 )
			ply:lvsSetAITeam( 2 )
		end
	end

	ply:ResetMoney()
end

function GM:PlayerSpawnAsSpectator( ply )
	ply:StripWeapons()
	ply:ClearEntityList()

	ply:lvsSetAITeam( 0 )
	ply:SetTeam( TEAM_SPECTATOR )
	ply:Spectate( OBS_MODE_ROAMING )

end

function GM:PlayerCanJoinTeam( ply, teamid )
	if teamid ~= 1 and teamid ~= 2 and teamid ~= TEAM_SPECTATOR then ply:ChatPrint( "You can't join that team" ) return false end

	local TimeBetweenSwitches = GAMEMODE.SecondsBetweenTeamSwitches or 10

	if ply.LastTeamSwitch and RealTime() - ply.LastTeamSwitch < TimeBetweenSwitches then

		ply.LastTeamSwitch = ply.LastTeamSwitch + 1

		ply:ChatPrint( Format( "Please wait %i more seconds before trying to change team again", ( TimeBetweenSwitches - ( RealTime() - ply.LastTeamSwitch ) ) + 1 ) )

		return false
	end

	if ply:lvsGetAITeam() == teamid then
		ply:ChatPrint( "You're already on that team" )

		return false
	end

	return true
end

function GM:PlayerRequestTeam( ply, teamid )

	if not self:PlayerCanJoinTeam( ply, teamid ) then return end

	self:PlayerJoinTeam( ply, teamid )
end

function GM:PlayerJoinTeam( ply, teamid )
	local iOldTeam = ply:Team()

	if ply:Alive() then
		if iOldTeam == TEAM_SPECTATOR then
			ply:KillSilent()
		else
			ply:Kill()
		end
	end

	if teamid == TEAM_SPECTATOR then
		ply:ClearEntityList()
		ply:SetTeam( TEAM_SPECTATOR )
		ply:lvsSetAITeam( 0 )
	else
		ply:SetTeam( teamid )
		ply:lvsSetAITeam( teamid )
	end

	ply.LastTeamSwitch = RealTime()

	self:OnPlayerChangedTeam( ply, iOldTeam, teamid )
end

function GM:OnPlayerChangedTeam( ply, oldteam, newteam )

	ply:ClearEntityList()
	ply:ResetMoney()

	-- reset buymenu everytime they change team
	ply:SendLua( "GAMEMODE:ResetBuyMenu()" )

	if newteam == TEAM_SPECTATOR then

		local Pos = ply:EyePos()
		ply:Spawn()
		ply:SetPos( Pos )

	elseif oldteam == TEAM_SPECTATOR then

		ply:Spawn()

	end
end
