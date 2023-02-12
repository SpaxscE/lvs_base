
function LVS:CalcView( vehicle, ply, pos, angles, fov, pod )
	local view = {}
	view.origin = pos
	view.angles = angles
	view.fov = fov
	view.drawviewer = false

	if not pod:GetThirdPersonMode() then return view end

	local mn = vehicle:OBBMins()
	local mx = vehicle:OBBMaxs()
	local radius = ( mn - mx ):Length()
	local radius = radius + radius * pod:GetCameraDistance()

	local TargetOrigin = view.origin + ( view.angles:Forward() * -radius ) + view.angles:Up() * radius * pod:GetCameraHeight()
	local WallOffset = 4

	local tr = util.TraceHull( {
		start = view.origin,
		endpos = TargetOrigin,
		filter = function( e )
			local c = e:GetClass()
			local collide = not c:StartWith( "prop_physics" ) and not c:StartWith( "prop_dynamic" ) and not c:StartWith( "prop_ragdoll" ) and not e:IsVehicle() and not c:StartWith( "gmod_" ) and not c:StartWith( "lvs_" ) and not c:StartWith( "player" ) and not e.LVS

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

	return view
end

local Zoom = 0
hook.Add( "CalcView", "!!!!LVS_calcview", function(ply, pos, angles, fov)
	if ply:GetViewEntity() ~= ply then return end

	local pod = ply:GetVehicle()
	local vehicle = ply:lvsGetVehicle()

	if not IsValid( pod ) or not IsValid( vehicle ) then return end

	local TargetZoom = ply:lvsKeyDown( "ZOOM" ) and 0 or 1

	Zoom = Zoom + (TargetZoom - Zoom) * RealFrameTime() * 10

	local newfov = fov * Zoom + 40 * (1 - Zoom)

	local base = pod:lvsGetWeapon()

	if IsValid( base ) then
		local weapon = base:GetActiveWeapon()

		if weapon and weapon.CalcView then
			return weapon.CalcView( base, ply, pos, angles, newfov, pod )
		else
			return vehicle:LVSCalcView( ply, pos, angles, newfov, pod )
		end
	else
		local weapon = vehicle:GetActiveWeapon()

		if weapon and weapon.CalcView then
			return weapon.CalcView( vehicle, ply, pos, angles, newfov, pod )
		else
			return vehicle:LVSCalcView( ply, pos, angles, newfov, pod )
		end
	end
end )
