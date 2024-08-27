
hook.Add( "PlayerUse", "!!!LVS_FIX_RE_ENTER", function( ply, ent )
	if ent.LVS and (ply._lvsNextUse or 0) > CurTime() then return false end
end )

hook.Add( "PlayerLeaveVehicle", "!!LVS_Exit", function( ply, Pod )
	if not ply:IsPlayer() then return end

	local Vehicle = ply:lvsGetVehicle()

	if not IsValid( Vehicle ) then return end

	if not LVS.FreezeTeams then
		ply:lvsSetAITeam( Vehicle:GetAITEAM() )
	end

	ply._lvsNextUse = CurTime() + 0.25

	hook.Run( "LVS.UpdateRelationship", Vehicle )

	local pos = Vehicle:LocalToWorld( Vehicle:OBBCenter() )
	local vel = Vehicle:GetVelocity()
	local radius = Vehicle:BoundingRadius()

	local mins, maxs = ply:GetHull()

	local PosCenter = Pod:OBBCenter()
	local StartPos = Pod:LocalToWorld( PosCenter )

	local FilterPlayer = { ply }
	local Filter = table.Copy( Vehicle:GetCrosshairFilterEnts() )
	table.insert( Filter, ply )

	local zOffset = 15
	local ValidPositions = {}

	if isvector( Pod.ExitPos ) and Vehicle:GetUp().z > 0.9 then 
		local data = {
			pos = Vehicle:LocalToWorld( Pod.ExitPos ),
			dist = 1,
		}

		table.insert( ValidPositions, data )
	end

	local LocalDesiredExitPosition = Vehicle:WorldToLocal( Pod:GetPos() )

	if vel:Length() > (Pod.PlaceBehindVelocity or 100) then
		LocalDesiredExitPosition.y = LocalDesiredExitPosition.y - radius

		local traceBehind = util.TraceLine( {
			start = pos,
			endpos = pos - vel:GetNormalized() * (radius + 50),
			filter = Filter,
		} )

		local tracePlayer = util.TraceHull( {
			start = traceBehind.HitPos + Vector(0,0,maxs.z + zOffset),
			endpos = traceBehind.HitPos + Vector(0,0,zOffset),
			maxs = Vector( maxs.x, maxs.y, 0 ),
			mins = Vector( mins.x, mins.y, 0 ),
			filter = FilterPlayer,
		} )

		if not tracePlayer.Hit and util.IsInWorld( tracePlayer.HitPos ) then
			local data = {
				pos = traceBehind.HitPos,
				dist = 0,
			}

			table.insert( ValidPositions, data )
		end
	end

	local DesiredExitPosition = Pod:LocalToWorld( LocalDesiredExitPosition )

	for ang = 0, 360, 15 do
		local X = math.cos( math.rad( ang ) ) * radius
		local Y = math.sin( math.rad( ang ) ) * radius
		local Z = Pod:OBBCenter().z

		local EndPos = StartPos + Vector(X,Y,Z)

		local traceWall = util.TraceLine( {start = StartPos,endpos = EndPos,filter = Filter} )
		local traceVehicle = util.TraceLine( {
			start = traceWall.HitPos,
			endpos = StartPos,
			filter = FilterPlayer,
		} )

		local CenterWallVehicle = (traceWall.HitPos + traceVehicle.HitPos) * 0.5

		if traceWall.Hit or not util.IsInWorld( CenterWallVehicle ) then continue end

		local GoundPos = CenterWallVehicle - Vector(0,0,radius)

		local traceGround = util.TraceLine( {start = CenterWallVehicle,endpos = GoundPos,filter = Filter} )

		if not traceGround.Hit or not util.IsInWorld( traceGround.HitPos ) then continue end

		local tracePlayerRoof = util.TraceHull( {
			start = traceGround.HitPos + Vector(0,0,zOffset),
			endpos = traceGround.HitPos + Vector(0,0,maxs.z + zOffset),
			maxs = Vector( maxs.x, maxs.y, 0 ),
			mins = Vector( mins.x, mins.y, 0 ),
			filter = FilterPlayer,
		} )

		if tracePlayerRoof.Hit or not util.IsInWorld( tracePlayerRoof.HitPos ) then continue end

		local tracePlayer = util.TraceHull( {
			start = traceGround.HitPos + Vector(0,0,maxs.z + zOffset),
			endpos = traceGround.HitPos + Vector(0,0,zOffset),
			maxs = Vector( maxs.x, maxs.y, 0 ),
			mins = Vector( mins.x, mins.y, 0 ),
			filter = FilterPlayer,
		} )

		if tracePlayer.Hit then continue end

		local traceBack = util.TraceLine( {
			start = tracePlayer.HitPos + Vector(0,0,zOffset),
			endpos = StartPos,
			filter = FilterPlayer,
		} )

		local data = {
			pos = tracePlayer.HitPos,
			dist = (traceBack.HitPos - DesiredExitPosition):Length(),
		}

		table.insert( ValidPositions, data )
	end

	local ExitPos
	local ExitDist

	for _, data in pairs( ValidPositions ) do
		if not ExitPos or not ExitDist or ExitDist > data.dist then
			ExitPos = data.pos
			ExitDist = data.dist
		end
	end

	-- all my plans failed, lets just let source do its thing
	if not ExitPos then return end

	local ViewAngles = (StartPos - ExitPos):Angle()
	ViewAngles.p = 0
	ViewAngles.r = 0

	ply:SetPos( ExitPos )
	ply:SetEyeAngles( ViewAngles )
end )