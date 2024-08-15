
include("sv_goalspawning.lua")

local NextAddPoints = 0
function GM:DeliveredGoalThink( ply, team, Mul )

	if not Mul then
		Mul = 1
	end

	local T = CurTime()

	if NextAddPoints > T then return end

	NextAddPoints = T + 1

	local Duration = 300

	local ConVar = GetConVar( "lvs_match_duration" )

	if ConVar then
		Duration = ConVar:GetInt() * Mul
	end

	self:AddGameProgression( team, 1 / Duration )
end

function GM:ResetGameProgression()
	local ent = self:GameNetworkEntity()

	if not IsValid( ent ) then return NULL end

	ent:SetTimeLeftTeam1( 0 )
	ent:SetTimeLeftTeam2( 0 )
end

function GM:AddGameProgression( team, amount )
	local ent = self:GameNetworkEntity()

	if not IsValid( ent ) then return NULL end

	if team == 1 then
		ent:SetTimeLeftTeam1( math.Clamp( ent:GetTimeLeftTeam1() + amount, 0, 1 ) )

		if ent:GetTimeLeftTeam1() >= 1 then
			self:OnGameFinish( team )
		end
	else
		ent:SetTimeLeftTeam2( math.Clamp( ent:GetTimeLeftTeam2() + amount, 0, 1 ) )

		if ent:GetTimeLeftTeam2() >= 1 then
			self:OnGameFinish( team )
		end
	end
end

function GM:OnGameStateChanged( oldstate, newstate )

	hook.Run( "LVS.OnGameStateChanged", oldstate, newstate )

	if newstate == GAMESTATE_WAIT_FOR_PLAYERS and oldstate == GAMESTATE_END then
		for _, ply in ipairs( self:GameGetAlivePlayers() ) do
			ply:ReapplyLoadout()
		end

		for _, ply in ipairs( player.GetAll() ) do
			ply:ResetMoney()
		end

		self:GameReset()

		return
	end

	if newstate == GAMESTATE_WAIT_FOR_PLAYERS and oldstate >= GAMESTATE_START then
		self:RemoveGoalEntity()
		self:ClearTempEnts()
		self:ResetGameProgression()
	end

	if newstate == GAMESTATE_START and oldstate < GAMESTATE_START then

		self:SetGameTime( CurTime(), self.ScrambleTime )
		self:SpawnTempEnts()

	end

	if oldstate == GAMESTATE_MAIN and newstate > GAMESTATE_MAIN then return end

	if oldstate ~= newstate then
		for _, ply in ipairs( self:GameGetAlivePlayers() ) do
			ply:ReapplyLoadout()
		end
	end
end

function GM:GameTick()
	local GameState = self:GetGameState()

	local Time = CurTime()
	local StartTime, Delay = self:GetGameTime()

	if GameState == GAMESTATE_END then
		if (StartTime + Delay) < Time then
			self:SetGameState( GAMESTATE_WAIT_FOR_PLAYERS )
		end

		return
	end

	if GameState ~= GAMESTATE_BUILD then
		if GameState == GAMESTATE_START then
			if (StartTime + Delay) < Time then
				self:SendGameNotify( "#lvs_notification_main" )
				self:SetGameState( GAMESTATE_MAIN )
				self:SpawnRandomGoal()
				self:NotifyMatchStart()
			end
		end
	
		return
	end

	if (StartTime + Delay) < Time then
		self:SendGameNotify( "#lvs_notification_warmup" )
		self:SetGameState( GAMESTATE_START )
	end
end

function GM:CalcGameStart()
	local GameState = self:GetGameState()

	if GameState > GAMESTATE_BUILD then
		if #self:GameGetPlayersTeam1() > 0 and #self:GameGetPlayersTeam2() > 0 then return end

		self:SetGameState( GAMESTATE_WAIT_FOR_PLAYERS )

		return
	end

	local Team1 = 0
	local Team2 = 0

	for _, spawnpoint in ipairs( ents.FindByClass( "lvs_spawnpoint" ) ) do
		if spawnpoint:GetAITEAM() == 1 then
			Team1 = Team1 + 1
		else
			Team2 = Team2 + 1
		end
	end

	if Team1 > 0 and Team2 > 0 then
		if GameState > GAMESTATE_WAIT_FOR_PLAYERS then return end

		for _, ply in pairs( player.GetAll() ) do
			ply:ClearEntityList( true )
			ply:ResetMoney()
			ply:SetFrags( 0 )
			ply:SetDeaths( 0 )
		end

		self:SendGameNotify( "#lvs_notification_build", Color(255,191,0,255) )
		self:SetGameState( GAMESTATE_BUILD )
		self:SetGameTime( CurTime(), GetConVar( "lvs_build_time" ):GetInt() )
	else
		self:SetGameState( GAMESTATE_WAIT_FOR_PLAYERS )
	end
end

function GM:OnGameFinish( team )
	self:OnTeamFinishedGoal( team )
	self:RemoveGoalEntity()

	for _, ply in pairs( player.GetAll() ) do
		if ply:Team() == TEAM_SPECTATOR then continue end

		if ply:lvsGetAITeam() == team then
			ply:SendGameNotify( "#lvs_notification_win", Color(0,255,0,255), self.FinishTime )
		else
			ply:SendGameNotify( "#lvs_notification_lose", Color(255,0,0,255), self.FinishTime )
		end
	end

	self:SetGameTime( CurTime(), self.FinishTime )
	self:SetGameState( GAMESTATE_END )
end
