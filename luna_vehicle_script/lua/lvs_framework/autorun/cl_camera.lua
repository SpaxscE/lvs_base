
local function CalcViewDirectInput( ply, pos, angles, fov, pod, vehicle )
	local view = {}
	view.fov = fov
	view.drawviewer = true
	view.angles = vehicle:GetAngles()

	local FreeLook = ply:lvsKeyDown( "FREELOOK" )

	if not pod:GetThirdPersonMode() then

		local velL = vehicle:WorldToLocal( vehicle:GetPos() + vehicle:GetVelocity() )

		local Dividor = math.abs( velL.x )
		local SideForce = math.Clamp( velL.y / Dividor, -1, 1)
		local UpForce = math.Clamp( velL.z / Dividor, -1, 1)

		local ViewPunch = Vector(0,SideForce * 10,UpForce * 10)
		ViewPunch.y = math.Clamp(ViewPunch.y,-1,1)
		ViewPunch.z = math.Clamp(ViewPunch.z,-1,1)

		pod._lerpPosOffset = pod._lerpPosOffset and pod._lerpPosOffset + (ViewPunch - pod._lerpPosOffset) * RealFrameTime() * 5 or Vector(0,0,0)
		pod._lerpPos = pos

		view.origin = pos + pod:GetForward() *  -pod._lerpPosOffset.y * 0.5 + pod:GetUp() *  pod._lerpPosOffset.z * 0.5
		view.angles.p = view.angles.p - pod._lerpPosOffset.z * 0.1
		view.angles.y = view.angles.y + pod._lerpPosOffset.y * 0.1
		view.drawviewer = false

		return vehicle:LVSCalcViewFirstPerson( view, ply )
	end

	pod._lerpPos = pod._lerpPos or vehicle:GetPos()

	local radius = 550
	radius = radius + radius * pod:GetCameraDistance()

	if FreeLook then
		local velL = vehicle:WorldToLocal( vehicle:GetPos() + vehicle:GetVelocity() )

		local SideForce = math.Clamp(velL.y / 10,-250,250)
		local UpForce = math.Clamp(velL.z / 10,-250,250)

		pod._lerpPosL = pod._lerpPosL and (pod._lerpPosL + (Vector(radius, SideForce,150 + radius * 0.1 + UpForce) - pod._lerpPosL) * RealFrameTime() * 12) or Vector(0,0,0)
		pod._lerpPos = vehicle:LocalToWorld( pod._lerpPosL )

		view.origin = pod._lerpPos
		view.angles = vehicle:LocalToWorldAngles( Angle(0,180,0) )
	else
		local TargetPos = vehicle:LocalToWorld( Vector(500,0,150 + radius * 0.1) )

		local Sub = TargetPos - pod._lerpPos
		local Dir = Sub:GetNormalized()
		local Dist = Sub:Length()

		pod._lerpPos = pod._lerpPos + (TargetPos - vehicle:GetForward() * (300 + radius) - Dir * 100 - pod._lerpPos) * RealFrameTime() * 12
		pod._lerpPosL = vehicle:WorldToLocal( pod._lerpPos )

		local vel = vehicle:GetVelocity()

		view.origin = pod._lerpPos
		view.angles = vehicle:GetAngles()
	end

	return vehicle:LVSCalcViewThirdPerson( view, ply )
end

local smTran = 0
local function CalcViewMouseAim( ply, pos, angles, fov, pod, vehicle )
	local cvarFocus = 0 --math.Clamp( cvarCamFocus:GetFloat() , -1, 1 )

	smTran = smTran + ((ply:lvsKeyDown( "FREELOOK" ) and 0 or 1) - smTran) * RealFrameTime() * 10

	local view = {}
	view.origin = pos
	view.fov = fov
	view.drawviewer = true
	view.angles = (vehicle:GetForward() * (1 + cvarFocus) * smTran * 0.8 + ply:EyeAngles():Forward() * math.max(1 - cvarFocus, 1 - smTran)):Angle()

	if cvarFocus >= 1 then
		view.angles = LerpAngle( smTran, ply:EyeAngles(), vehicle:GetAngles() )
	else
		view.angles.r = 0
	end

	if vehicle:GetDriverSeat() ~= pod then
		view.angles = ply:EyeAngles()
	end

	if not pod:GetThirdPersonMode() then

		view.drawviewer = false

		return vehicle:LVSCalcViewFirstPerson( view, ply )
	end

	local radius = 550
	radius = radius + radius * pod:GetCameraDistance()

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

	return vehicle:LVSCalcViewThirdPerson( view, ply )
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
	if ply:GetViewEntity() ~= ply then return end

	local Pod = ply:GetVehicle()
	local Parent = ply:lvsGetVehicle()

	if not IsValid( Pod ) or not IsValid( Parent ) then return end

	if Parent:GetDriverSeat() == Pod then
		return CalcViewDriver( ply, pos, angles, fov, Pod, Parent )
	else
		return CalcViewPassenger( ply, pos, angles, fov, Pod, Parent )
	end
end )
