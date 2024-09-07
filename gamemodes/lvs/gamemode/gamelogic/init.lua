
GAMESTATE_WAIT_FOR_PLAYERS = 0
GAMESTATE_BUILD = 1
GAMESTATE_START = 2
GAMESTATE_MAIN = 3
GAMESTATE_END = 4
GAMESTATE_DEBUG = 5

function GM:GetGameProgression()
	local ent = self:GameNetworkEntity()

	if not IsValid( ent ) then return NULL end

	return ent:GetTimeLeftTeam1(), ent:GetTimeLeftTeam2()
end

function GM:RemoveGoalEntity()
	local ent = self:GetGoalEntity()

	if not IsValid( ent ) then return end

	ent:Remove()
end

function GM:GetGoalEntity()
	local ent = self:GameNetworkEntity()

	if not IsValid( ent ) then return NULL end

	return ent:GetGoalEntity()
end

function GM:GetGoalPos()
	local ent = self:GameNetworkEntity()

	if not IsValid( ent ) then return vector_origin end

	return ent:GetGoalPos()
end

function GM:GetGameState()
	local ent = self:GameNetworkEntity()

	if not IsValid( ent ) then return GAMESTATE_DEBUG end

	return ent:GetGameState()
end

function GM:GetGameTime()
	local ent = self:GameNetworkEntity()

	if not IsValid( ent ) then return 0 end

	return ent:GetGameTime(), ent:GetGameTimeAdd()
end

function GM:GameGetEnemyPlayersTeam( Team )
	if Team == 1 then
		return self:GameGetPlayersTeam2()
	end

	if Team == 2 then
		return self:GameGetPlayersTeam1()
	end

	return {}
end

function GM:GameGetPlayersTeam( Team )
	if Team == 1 then
		return self:GameGetPlayersTeam1()
	end

	if Team == 2 then
		return self:GameGetPlayersTeam2()
	end

	local players = {}

	for _, ply in ipairs( player.GetAll() ) do
		if ply:lvsGetAITeam() ~= Team then continue end

		table.insert( players, ply )
	end

	return players
end

function GM:GameGetPlayersTeam1()
	local players = {}

	for _, ply in ipairs( player.GetAll() ) do
		if ply:lvsGetAITeam() ~= 1 then continue end

		table.insert( players, ply )
	end

	return players
end

function GM:GameGetPlayersTeam2()
	local players = {}

	for _, ply in ipairs( player.GetAll() ) do
		if ply:lvsGetAITeam() ~= 2 then continue end

		table.insert( players, ply )
	end

	return players
end

function GM:GameGetPlayers()
	local players = {}

	for _, ply in ipairs( player.GetAll() ) do
		local Team = ply:lvsGetAITeam()

		if Team ~= 1 and Team ~= 2 then continue end

		table.insert( players, ply )
	end

	return players
end

function GM:GameGetAlivePlayers()
	local players = {}

	for _, ply in ipairs( player.GetAll() ) do
		local Team = ply:lvsGetAITeam()

		if Team ~= 1 and Team ~= 2 then continue end

		if not ply:Alive() then continue end

		table.insert( players, ply )
	end

	return players
end

include("sh_notify.lua")

if CLIENT then
	function GM:GameNetworkEntity()
		return self._NetworkEntity
	end

	include("cl_hud.lua")

	return
end

include("sv_logic.lua")
AddCSLuaFile( "cl_hud.lua" )
AddCSLuaFile("sh_notify.lua")

function GM:SetGameState( gamestate )
	local ent = self:GameNetworkEntity()

	if not IsValid( ent ) then return end

	local oldstate = self:GetGameState()

	if oldstate ~= gamestate then
		ent:SetGameState( gamestate )

		self:OnGameStateChanged( oldstate, gamestate )
	end
end

function GM:SetGameTime( time, time_add )
	local ent = self:GameNetworkEntity()

	if not IsValid( ent ) then return end

	ent:SetGameTime( time )
	ent:SetGameTimeAdd( time_add )
end

function GM:GameNetworkEntity()
	if IsValid( self._NetworkEntity ) then return self._NetworkEntity end

	self._NetworkEntity = ents.Create( "lvs_gamemode_network" )
	self._NetworkEntity:Spawn()
	self._NetworkEntity:Activate()

	return self._NetworkEntity
end

function GM:GameInitialize()
	self:GameNetworkEntity()

	local music = ents.Create( "lvs_gamemode_music" )
	music:Spawn()
	music:Activate()
end

function GM:GameSpawnPointCreated( ply, spawnpoint )
	self:CalcGameStart()
end

function GM:GameSpawnPointRemoved( ply, spawnpoint )
	timer.Simple(0.1, function() self:CalcGameStart() end )
end

function GM:GameReset()
	for id, ply in ipairs( player.GetAll() ) do
		ply:ConCommand( "r_cleardecals" )

		if ply:Team() == TEAM_SPECTATOR then continue end

		if ply:InVehicle() then
			ply:ExitVehicle()
		end

		ply:Spawn()
	end

	game.CleanUpMap()

	RunConsoleCommand("g_ragdoll_maxcount", 0 )

	timer.Simple(2, function() RunConsoleCommand("g_ragdoll_maxcount", 32 ) end )
end
