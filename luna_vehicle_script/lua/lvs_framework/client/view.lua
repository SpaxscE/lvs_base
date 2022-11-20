hook.Add( "CalcView", "!!!!LVS_calcview", function(ply, pos, angles, fov)
	if ply:GetViewEntity() ~= ply then return end
	
	local Pod = ply:GetVehicle()
	local Parent = ply:lvsGetVehicle()
	
	if not IsValid( Pod ) or not IsValid( Parent ) then return end

	local view = {}
	view.origin = pos
	view.fov = fov
	view.drawviewer = true
	view.angles = ply:EyeAngles()

	if not Pod:GetThirdPersonMode() then
		
		view.drawviewer = false
		
		return Parent:LVSCalcViewFirstPerson( view, ply )
	end

	local radius = 500

	local TargetOrigin = view.origin - view.angles:Forward() * radius  + view.angles:Up() * radius * 0.2
	local WallOffset = 4

	local tr = util.TraceHull( {
		start = view.origin,
		endpos = TargetOrigin,
		filter = function( e )
			local c = e:GetClass()
			local collide = not c:StartWith( "prop_physics" ) and not c:StartWith( "prop_dynamic" ) and not c:StartWith( "prop_ragdoll" ) and not e:IsVehicle() and not c:StartWith( "gmod_" ) and not c:StartWith( "player" ) and not e.LVS

			return collide
		end,
		mins = Vector( -WallOffset, -WallOffset, -WallOffset ),
		maxs = Vector( WallOffset, WallOffset, WallOffset ),
	} )
	
	view.origin = tr.HitPos

	if tr.Hit and not tr.StartSolid then
		view.origin = view.origin + tr.HitNormal * WallOffset
	end

	return Parent:LVSCalcViewThirdPerson( view, ply )
end )
