
GM._TempEnts = {}

function GM:CreateGoalEntity( Pos )
	local ent = self:GameNetworkEntity()

	if not IsValid( ent ) then return end

	if IsValid( ent:GetGoalEntity() ) then
		ent:GetGoalEntity():Remove()
	end

	local goalEnt = ents.Create( "lvs_objective" )
	goalEnt:SetPos( Pos )
	goalEnt:Spawn()
	goalEnt:Activate()

	ent:SetGoalEntity( goalEnt )
end

function GM:SpawnRandomGoal()
	local SelectedTarget
	local SelectedTargetDistance = 0

	local AllPlayers = player.GetAll()

	for id, ent in pairs( self._TempEnts ) do
		if not IsValid( ent ) then continue end

		local StartPos = ent:GetPos()
		local EndPos = StartPos - Vector(0,0,500000)
		local trace = util.TraceLine( {
			start = StartPos,
			endpos = EndPos,
			filter = ent,
			mask = MASK_SOLID_BRUSHONLY,
		} )

		local Hit = trace.HitSky

		local traceUp = util.TraceLine( {
			start = StartPos,
			endpos = StartPos + Vector(0,0,16),
			filter = ent,
		} )

		local traceDn = util.TraceLine( {
			start = StartPos,
			endpos = StartPos - Vector(0,0,16),
			filter = ent,
		} )

		-- both up and down trace are hitting. The spawnpoint must be stuck in a brush or prop.
		if traceUp.Hit and traceDn.Hit then Hit = true end

		if Hit then continue end

		for _, ply in pairs( AllPlayers ) do
			local DistToPlayer = (ent:GetPos() - ply:GetPos()):LengthSqr()

			if DistToPlayer < SelectedTargetDistance then continue end

			SelectedTarget = ent
			SelectedTargetDistance = DistToPlayer
		end
	end

	if not IsValid( SelectedTarget ) then
		print("[LVS] - ERROR can not start gamemode! Couldn't find suitable goal position!\n\n")

		return
	end

	self:CreateGoalEntity( SelectedTarget:GetPos() )

	self:ClearTempEnts()
end

function GM:ClearTempEnts()
	for id, ent in pairs( self._TempEnts ) do
		self._TempEnts[ id ] = nil

		if not IsValid( ent ) then continue end

		ent:Remove()
	end
end

function GM:SpawnTempEnts()
	local Index = 0

	-- copy table, so we dont clog it up if this is called again
	local SpawnPoints = table.Copy( self:FindSpawnPoints() )

	if not istable( SpawnPoints ) then SpawnPoints = {} end

	-- add player spawns for more variation to maps that have a spawn room
	table.Add( SpawnPoints, ents.FindByClass( "lvs_spawnpoint" ) )

	-- add players as possible spawnpoints aswell
	table.Add( SpawnPoints, self:GameGetPlayersTeam1() )
	table.Add( SpawnPoints, self:GameGetPlayersTeam2() )

	while Index < 16 do
		for _, point in pairs( SpawnPoints ) do
			if math.random(1,#SpawnPoints) ~= 1 then continue end

			local Ent = ents.Create( "lvs_objective_spawnpoint" )
			Ent:SetPos( point:GetPos() + Vector(0,0,16) )
			Ent:Spawn()
			Ent:Activate()

			timer.Simple(0, function()
				if not IsValid( Ent ) then return end

				local PhysObj = Ent:GetPhysicsObject()

				if IsValid( PhysObj ) then
					PhysObj:SetVelocityInstantaneous( VectorRand() * 1000 )
				end
			end)

			Index = Index + 1

			table.insert( self._TempEnts, Ent )

			if Index > 16 then break end
		end
	end
end
