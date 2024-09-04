
local meta = FindMetaTable( "Player" )

function meta:GetSpawnPoint()
	if CLIENT then return self:GetNWEntity( "spawnpoint" ) end

	return self._CurSpawnPoint
end

if CLIENT then
	function GM:FindSpawnPoints()
		if not istable( self.SpawnPoints ) then
			self.SpawnPoints = {}

			net.Start( "lvs_request_spawnpoint_locations" )
			net.SendToServer()
		end

		return self.SpawnPoints
	end

	local FakeSpawnPointEntity = {}
	FakeSpawnPointEntity.__index = FakeSpawnPointEntity

	function FakeSpawnPointEntity:SetPos( pos )
		self.curpos = pos or vector_origin
	end

	function FakeSpawnPointEntity:GetPos()
		if not self.curpos then return vector_origin end

		return self.curpos
	end

	function FakeSpawnPointEntity:GetAngles()
		return angle_zero
	end

	function FakeSpawnPointEntity:IsValid()
		return true
	end

	net.Receive( "lvs_request_spawnpoint_locations", function( len )
		GAMEMODE.SpawnPoints = {}

		local Num = net.ReadInt( 10 )

		if Num <= 0 then return end

		for i = 1, Num do
			local SpawnPoint = {}

			setmetatable( SpawnPoint, FakeSpawnPointEntity )

			SpawnPoint:SetPos( net.ReadVector() )

			table.insert( GAMEMODE.SpawnPoints, SpawnPoint )
		end
	end )

	return
end

util.AddNetworkString( "lvs_request_spawnpoint_locations" )

net.Receive( "lvs_request_spawnpoint_locations", function( len, ply )
	if ply._lvsHasSpawnPointRequested then return end

	ply._lvsHasSpawnPointRequested = true

	local SpawnPoints = GAMEMODE:FindSpawnPoints()

	net.Start( "lvs_request_spawnpoint_locations" )
		net.WriteInt( table.Count( SpawnPoints ), 10 )

		for _, ent in pairs( SpawnPoints ) do
			local pos = vector_origin

			if IsValid( ent ) then pos = ent:GetPos() end

			net.WriteVector( pos )
		end

	net.Send( ply )
end )

function meta:SetSpawnPoint( ent )
	self._CurSpawnPoint = ent

	self:SetNWEntity( "spawnpoint", ent )
end

local BlockedClasses = {
	["func_lod"] = true,
}

function meta:CreateSpawnPoint()
	if IsValid( self:GetSpawnPoint() ) then
		return self:GetSpawnPoint()
	end

	if not self:Alive() then
		self:Spawn()
	end

	local StartPos = self:GetShootPos()
	local EndPos = StartPos - Vector(0,0,60000)

	local trace = util.TraceLine( {
		start = StartPos,
		endpos = EndPos,
		filter = self,
		mask = MASK_PLAYERSOLID
	} )

	local ent = ents.Create( "lvs_spawnpoint" )
	ent:SetPos( trace.HitPos + trace.HitNormal )
	ent:SetAngles( Angle(0,self:EyeAngles().y,0) )
	ent:Spawn()
	ent:Activate()
	ent:SetCreatedBy( self )

	self:AddEntityList( ent )

	-- parent to elevators
	if IsValid( trace.Entity ) and not trace.Entity:IsWorld() and trace.Entity:GetMoveType() ~= MOVETYPE_VPHYSICS and not BlockedClasses[ trace.Entity:GetClass() ] then
		ent:SetParent( trace.Entity )
	end

	self:SetSpawnPoint( ent )

	GAMEMODE:GameSpawnPointCreated( self, ent )

	return ent
end

function GM:PlayerSelectSpawn( pl, transiton, dont_filter )
	local GoalEnt = self:GetGoalEntity()
	local SpawnPoint = pl:GetSpawnPoint()

	local Team = pl:lvsGetAITeam()

	if IsValid( SpawnPoint ) then

		local Pos = SpawnPoint:GetPos()

		local EnemyNearby = false

		for _, enemy in pairs( self:GameGetEnemyPlayersTeam( Team ) ) do
			if not IsValid( enemy ) or enemy:InVehicle() then continue end

			if (enemy:GetPos() - Pos):Length() < 1000 then
				EnemyNearby = true

				break
			end
		end

		if not EnemyNearby then
			hook.Call( "IsSpawnpointSuitable", GAMEMODE, pl, SpawnPoint, true )

			return SpawnPoint
		end
	end

	self:FindSpawnPoints()

	local SpawnPoints = table.Copy( self.SpawnPoints )

	if not dont_filter then
		-- add team members as spawnpoint
		for _, target in pairs( self:GameGetPlayersTeam( Team ) ) do
			if target == pl or not target:Alive() or target:InVehicle() or not target:OnGround() then continue end

			table.insert( SpawnPoints,  target )
		end

		-- remove all spawns too close to the goal
		if IsValid( GoalEnt ) then
			local GoalPos = GoalEnt:GetPos()

			for id, target in pairs( SpawnPoints ) do
				if not IsValid( target ) then continue end

				local MaxDist = target:IsPlayer() and 4000 or 1500

				if (target:GetPos() - GoalPos):Length() < MaxDist then
					SpawnPoints[ id ] = nil
				end
			end
		end

		-- remove all spawns too close to enemies
		for id, target in pairs( SpawnPoints ) do
			if not IsValid( target ) then continue end

			local Pos = target:GetPos()

			for _, enemy in pairs( self:GameGetEnemyPlayersTeam( Team ) ) do
				if not IsValid( enemy ) or enemy:InVehicle() then continue end

				if (enemy:GetPos() - Pos):Length() < 1000 then
					SpawnPoints[ id ] = nil
				end
			end
		end
	end

	local Count = table.Count( SpawnPoints )

	local ChosenSpawnPoint = nil

	for i = 1, Count do

		ChosenSpawnPoint = table.Random( SpawnPoints )

		if IsValid( ChosenSpawnPoint ) and ChosenSpawnPoint:IsInWorld() then
			if ( ChosenSpawnPoint == pl:GetVar( "LastSpawnpoint" ) or ChosenSpawnPoint == self.LastSpawnPoint ) and Count > 1 then continue end

			if ChosenSpawnPoint:IsPlayer() or hook.Call( "IsSpawnpointSuitable", GAMEMODE, pl, ChosenSpawnPoint, (i == Count) ) then

				self.LastSpawnPoint = ChosenSpawnPoint
				pl:SetVar( "LastSpawnpoint", ChosenSpawnPoint )

				return ChosenSpawnPoint

			end

		end

	end

	-- all spawnpoints are too close to something. Just select a random one we dont care at this point...
	if not dont_filter then
		return self:PlayerSelectSpawn( pl, transiton, true )
	end

	return ChosenSpawnPoint
end

function GM:FindSpawnPoints()
	if IsTableOfEntitiesValid( self.SpawnPoints ) then return self.SpawnPoints end

	self.LastSpawnPoint = 0
	self.SpawnPoints = ents.FindByClass( "info_player_start" )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_deathmatch" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_combine" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_rebel" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_counterterrorist" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_terrorist" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_axis" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_allies" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "gmod_player_start" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_teamspawn" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "ins_spawnpoint" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "aoc_spawnpoint" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "dys_spawn_point" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_pirate" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_viking" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_knight" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "diprip_start_team_blue" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "diprip_start_team_red" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_red" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_blue" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_coop" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_human" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_zombie" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_zombiemaster" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_fof" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_desperado" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_vigilante" ) )
	self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_survivor_rescue" ) )

	return self.SpawnPoints
end