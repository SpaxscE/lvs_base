
local function CalcViewDirectInput( ply, pos, angles, fov, pod, vehicle )
	local view = {}
	view.fov = fov
	view.drawviewer = true

	pod._lerpPos = pod._lerpPos or vehicle:GetPos()

	local Delta = RealFrameTime()

	local TargetPos = vehicle:LocalToWorld( Vector(500,0,250) )

	local Sub = TargetPos - pod._lerpPos
	local Dir = Sub:GetNormalized()
	local Dist = Sub:Length()

	pod._lerpPos = pod._lerpPos + (TargetPos - vehicle:GetForward() * 900 - Dir * 100 - pod._lerpPos) * Delta * 12

	local vel = vehicle:GetVelocity()

	view.origin = pod._lerpPos
	view.angles = vehicle:GetAngles()

	return vehicle:LVSCalcViewThirdPerson( view, ply )
end

local smTran = 0
local function CalcViewMouseAim( ply, pos, angles, fov, pod, vehicle )
	if ply:GetViewEntity() ~= ply then return end

	local Pod = ply:GetVehicle()
	local Parent = ply:lvsGetVehicle()

	if not IsValid( Pod ) or not IsValid( Parent ) then return end

	local LockedView = Parent:GetLockView() 

	local cvarFocus = 0 --math.Clamp( cvarCamFocus:GetFloat() , -1, 1 )

	smTran = smTran + ((ply:KeyDown( IN_WALK ) and 0 or 1) - smTran) * FrameTime() * 10

	local view = {}
	view.origin = pos
	view.fov = fov
	view.drawviewer = true
	view.angles = (Parent:GetForward() * (1 + cvarFocus) * smTran * 0.8 + ply:EyeAngles():Forward() * math.max(1 - cvarFocus, 1 - smTran)):Angle()

	if cvarFocus >= 1 then
		view.angles = LerpAngle( smTran, ply:EyeAngles(), Parent:GetAngles() )
	else
		view.angles.r = 0
	end

	if Parent:GetDriverSeat() ~= Pod then
		view.angles = ply:EyeAngles()
	end

	if not Pod:GetThirdPersonMode() then

		view.drawviewer = false

		return Parent:LVSCalcViewFirstPerson( view, ply )
	end

	local radius = 550
	radius = radius + radius * Pod:GetCameraDistance()

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
end

local function CalcViewDriver( ply, pos, angles, fov, pod, vehicle )
	if vehicle:GetLockView() then
		return CalcViewDirectInput( ply, pos, angles, fov, pod, vehicle )
	else
		return CalcViewMouseAim( ply, pos, angles, fov, pod, vehicle )
	end
end

local function CalcViewPassenger( ply, pos, angles, fov, pod, vehicle )
	local view = {}
	view.origin = pos
	view.angles = angles
	view.fov = fov
	view.drawviewer = false

	if not pod:GetThirdPersonMode() then return vehicle:LVSCalcViewFirstPerson( view, ply ) end

	local mn, mx = vehicle:GetRenderBounds()
	local radius = ( mn - mx ):Length()
	local radius = radius + radius * pod:GetCameraDistance()

	local TargetOrigin = view.origin + ( view.angles:Forward() * -radius )
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
	view.drawviewer = true

	if tr.Hit and  not tr.StartSolid then
		view.origin = view.origin + tr.HitNormal * WallOffset
	end

	return vehicle:LVSCalcViewThirdPerson( view, ply )
end

hook.Add( "CalcView", "!!!!LVS_calcview", function(ply, pos, angles, fov)
	local Pod = ply:GetVehicle()
	local Parent = ply:lvsGetVehicle()

	if not IsValid( Pod ) or not IsValid( Parent ) then return end

	if Parent:GetDriverSeat() == Pod then
		return CalcViewDriver( ply, pos, angles, fov, Pod, Parent )
	else
		return CalcViewPassenger( ply, pos, angles, fov, Pod, Parent )
	end
end )
