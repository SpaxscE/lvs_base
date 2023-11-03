
hook.Add( "PlayerUse", "!!!LVS_FIX_RE_ENTER", function( ply, ent )
	if ent.LVS and (ply._lvsNextUse or 0) > CurTime() then return false end
end )

hook.Add( "PlayerLeaveVehicle", "!!LVS_Exit", function( ply, Pod )
	if not ply:IsPlayer() then return end

	local Vehicle = ply:lvsGetVehicle()

	if not IsValid( Vehicle ) then return end

	if not LVS.FreezeTeams:GetBool() then
		ply:lvsSetAITeam( Vehicle:GetAITEAM() )
	end

	ply._lvsNextUse = CurTime() + 0.25

	local Center = Vehicle:LocalToWorld( Vehicle:OBBCenter() )
	local Vel = Vehicle:GetVelocity()
	local radius = Vehicle:BoundingRadius()

	local HullMin, HullMax = ply:GetHull()
	local FilterPlayer = { Pod, ply }
	local FilterAll = { Pod, ply, Vehicle }

	for _, filterEntity in pairs( constraint.GetAllConstrainedEntities( Vehicle ) ) do
		if IsValid( filterEntity ) then
			table.insert( FilterAll, filterEntity )
		end
	end

	if Vel:Length() > (Pod.PlaceBehindVelocity or 100) then
		local tr = util.TraceHull( {
			start = Center,
			endpos = Center - Vel:GetNormalized() *  (radius + 50),
			maxs = HullMax,
			mins = HullMin,
			filter = FilterAll
		} )

		local exitpoint = tr.HitPos + Vector(0,0,10)

		if util.IsInWorld( exitpoint ) then
			ply:SetPos( exitpoint )
			ply:SetEyeAngles( (Center - exitpoint):Angle() )
		end
	else
		if isvector( Pod.ExitPos ) then 
			local exitpoint = Vehicle:LocalToWorld( Pod.ExitPos )

			if util.IsInWorld( exitpoint ) then
				ply:SetPos( exitpoint )
				ply:SetEyeAngles( (Pod:GetPos() - exitpoint):Angle() )

				return
			end
		end

		local PodPos = Pod:LocalToWorld( Vector(0,0,10) )

		local PodDistance = 130
		local AngleStep = 45

		local StartAngle = 135

		local W = ply:KeyDown( IN_FORWARD )
		local A = ply:KeyDown( IN_MOVELEFT ) or ply:KeyDown( IN_BACK )
		local D = ply:KeyDown( IN_MOVERIGHT )

		if W or A or D then
			if A then StartAngle = 180 end
			if D then StartAngle = 0 end
			if W then if D then StartAngle = -45 else StartAngle = 225 end end
		end

		for ang = StartAngle, (StartAngle + 360 - AngleStep), AngleStep do
			local X = math.Round( math.cos( math.rad( -ang ) ) * PodDistance )
			local Y = math.Round( math.sin( math.rad( -ang ) ) * PodDistance )
			local Z = Pod:WorldToLocal( Center ).z

			local EndPos = Pod:LocalToWorld( Vector(X,Y,Z) )

			local HitWall = util.TraceLine( {start = PodPos,endpos = EndPos,filter = FilterAll} ).Hit

			if not util.IsInWorld( EndPos ) then continue end

			if HitWall then continue end

			local HitVehicle = util.TraceHull( {
				start = EndPos,
				endpos = EndPos + Vector(0,0,1),
				maxs = HullMax,
				mins = HullMin,
				filter = FilterPlayer
			} ).Hit

			if HitVehicle then continue end

			ply:SetPos( EndPos )
			ply:SetEyeAngles( (Pod:GetPos() - EndPos):Angle() )

			return
		end

		local tr = util.TraceHull( {
			start = PodPos,
			endpos = PodPos - Vector(0,0,PodDistance + HullMax.z),
			maxs = Vector(HullMax.x,HullMax.y,0),
			mins = HullMin,
			filter = FilterAll
		} )

		local exitpoint = tr.HitPos

		if not tr.Hit and util.IsInWorld( exitpoint ) then
			ply:SetPos( exitpoint )
			ply:SetEyeAngles( (PodPos - exitpoint):Angle() )
		else
			local exitpoint = util.TraceHull( {
				start = PodPos,
				endpos = PodPos + Vector(0,0,PodDistance),
				maxs = HullMax,
				mins = HullMin,
				filter = FilterAll
			} ).HitPos

			if util.IsInWorld( exitpoint ) then
				ply:SetPos( exitpoint )
				ply:SetEyeAngles( (PodPos - exitpoint):Angle() )
			else
				ply:SetPos( PodPos )
			end
		end
	end
end )