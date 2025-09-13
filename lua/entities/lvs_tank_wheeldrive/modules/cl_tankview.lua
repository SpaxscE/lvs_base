if SERVER then return end

function ENT:TankViewOverride( ply, pos, angles, fov, pod )
	return pos, angles, fov
end

function ENT:CalcTankView( ply, original_pos, original_ang, original_fov, pod )
	local pos, angles, fov = self:TankViewOverride( ply, original_pos, original_ang, original_fov, pod )

	local view = {}
	view.origin = pos
	view.angles = angles
	view.fov = fov
	view.drawviewer = false

	if not pod:GetThirdPersonMode() then return view end

	local mn = self:OBBMins()
	local mx = self:OBBMaxs()
	local radius = ( mn - mx ):Length()
	local radius = radius + radius * pod:GetCameraDistance()

	local clamped_angles = pod:WorldToLocalAngles( angles )
	clamped_angles.p = math.max( clamped_angles.p, -20 )
	clamped_angles = pod:LocalToWorldAngles( clamped_angles )

	local StartPos = pos
	local EndPos = StartPos - clamped_angles:Forward() * radius + clamped_angles:Up() * (radius * pod:GetCameraHeight())

	local WallOffset = 4

	local tr = util.TraceHull( {
		start = StartPos,
		endpos = EndPos,
		filter = function( e )
			local c = e:GetClass()
			local collide = not c:StartWith( "prop_physics" ) and not c:StartWith( "prop_dynamic" ) and not c:StartWith( "prop_ragdoll" ) and not e:IsVehicle() and not c:StartWith( "gmod_" ) and not c:StartWith( "lvs_" ) and not c:StartWith( "player" ) and not e.LVS

			return collide
		end,
		mins = Vector( -WallOffset, -WallOffset, -WallOffset ),
		maxs = Vector( WallOffset, WallOffset, WallOffset ),
	} )

	view.angles = angles + Angle(5,0,0)
	view.origin = tr.HitPos + pod:GetUp() * 65
	view.drawviewer = true

	if tr.Hit and  not tr.StartSolid then
		view.origin = view.origin + tr.HitNormal * WallOffset
	end

	return view
end

function ENT:CalcViewDirectInput( ply, pos, angles, fov, pod )
	if not pod:GetThirdPersonMode() then
		angles = pod:LocalToWorldAngles( ply:EyeAngles() )
	end

	return self:CalcTankView( ply, pos, angles, fov, pod )
end

function ENT:CalcViewMouseAim( ply, pos, angles, fov, pod )
	return self:CalcTankView( ply, pos, angles, fov, pod )
end

function ENT:CalcViewPassenger( ply, pos, angles, fov, pod )
	if not pod:GetThirdPersonMode() then
		angles = pod:LocalToWorldAngles( ply:EyeAngles() )
	end

	return self:CalcTankView( ply, pos, angles, fov, pod )
end
