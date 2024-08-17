
local meta = FindMetaTable( "Player" )

function meta:GetSpawnPoint()
	if CLIENT then return self:GetNWEntity( "spawnpoint" ) end

	return self._CurSpawnPoint
end

if CLIENT then
	-- info spawn points dont exist clientside
	-- TODO: network positions to client
	function GM:FindSpawnPoints()
		return {}
	end

	return
end

function meta:SetSpawnPoint( ent )
	self._CurSpawnPoint = ent

	self:SetNWEntity( "spawnpoint", ent )
end

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

	self:SetSpawnPoint( ent )

	GAMEMODE:GameSpawnPointCreated( self, ent )

	return ent
end

function GM:PlayerSelectSpawn( pl, transiton )

	-- If we are in transition, do not reset player's position
	if ( transiton ) then return end

	local GoalEnt = self:GetGoalEntity()
	local SpawnPoint = pl:GetSpawnPoint()

	if IsValid( SpawnPoint ) and not (IsValid( GoalEnt ) and GoalEnt:GetLinkedSpawnPoint() == SpawnPoint) then

		hook.Call( "IsSpawnpointSuitable", GAMEMODE, pl, SpawnPoint, true )

		return SpawnPoint
	end

	self:FindSpawnPoints()

	local Count = table.Count( self.SpawnPoints )

	if ( Count == 0 ) then
		Msg("[PlayerSelectSpawn] Error! No spawn points!\n")
		return nil
	end

	-- If any of the spawnpoints have a MASTER flag then only use that one.
	-- This is needed for single player maps.
	for k, v in pairs( self.SpawnPoints ) do

		if ( v:HasSpawnFlags( 1 ) && hook.Call( "IsSpawnpointSuitable", GAMEMODE, pl, v, true ) ) then
			return v
		end

	end

	local ChosenSpawnPoint = nil

	-- Try to work out the best, random spawnpoint
	for i = 1, Count do

		ChosenSpawnPoint = table.Random( self.SpawnPoints )

		if ( IsValid( ChosenSpawnPoint ) && ChosenSpawnPoint:IsInWorld() ) then
			if ( ( ChosenSpawnPoint == pl:GetVar( "LastSpawnpoint" ) || ChosenSpawnPoint == self.LastSpawnPoint ) && Count > 1 ) then continue end

			if ( hook.Call( "IsSpawnpointSuitable", GAMEMODE, pl, ChosenSpawnPoint, i == Count ) ) then

				self.LastSpawnPoint = ChosenSpawnPoint
				pl:SetVar( "LastSpawnpoint", ChosenSpawnPoint )
				return ChosenSpawnPoint

			end

		end

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