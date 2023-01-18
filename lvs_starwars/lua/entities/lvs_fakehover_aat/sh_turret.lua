
function ENT:SetPoseParameterTurret( weapon )
	if self:GetIsCarried() then
		self:SetPoseParameter("turret_pitch", 0 )
		self:SetPoseParameter("turret_yaw",  0 )

		if self.TurretWasSet then
			self.TurretWasSet = nil

			self:SetTurretPitch( 0 )
			self:SetTurretYaw( 0 )
		end

		return
	end

	self.TurretWasSet = true

	if not IsValid( weapon:GetDriver() ) and not weapon:GetAI() then return end

	local AimAng = weapon:WorldToLocal( weapon:GetPos() + weapon:GetAimVector() ):Angle()
	AimAng:Normalize()

	local AimRate = self.TurretTurnRate * FrameTime() 

	self:SetTurretPitch( math.ApproachAngle( self:GetTurretPitch(), AimAng.p, AimRate ) )
	self:SetTurretYaw( math.ApproachAngle( self:GetTurretYaw(), AimAng.y, AimRate ) )

	self:SetPoseParameter("turret_pitch", self:GetTurretPitch() )
	self:SetPoseParameter("turret_yaw", self:GetTurretYaw() )
end

function ENT:TraceTurret()
	local ID = self:LookupAttachment( "muzzle" )
	local Muzzle = self:GetAttachment( ID )

	if not Muzzle then return end

	local dir = Muzzle.Ang:Up()
	local pos = Muzzle.Pos

	local trace = util.TraceLine( {
		start = pos,
		endpos = (pos + dir * 50000),
	} )

	return trace
end

function ENT:InitTurret()
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/laserbeam.png")
	weapon.Ammo = -1
	weapon.Delay = 0
	weapon.HeatRateUp = 0.25
	weapon.HeatRateDown = 0.3
	weapon.OnOverheat = function( ent )
		ent:EmitSound("lvs/overheat.wav")
	end
	weapon.Attack = function( ent )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		if base:GetIsCarried() then return true end
	end
	weapon.OnThink = function( ent, active )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		base:SetPoseParameterTurret( ent )
	end
	weapon.CalcView = function( ent, ply, pos, angles, fov, pod )
		local base = ent:GetVehicle()

		local view = {}
		view.origin = pos
		view.angles = angles
		view.fov = fov
		view.drawviewer = false

		if not IsValid( base ) then return view end

		local ID = base:LookupAttachment( "turret_view" )
		local Att = base:GetAttachment( ID )

		if Att then
			local Pos,_= LocalToWorld( Vector(0,12,30), Angle(0,0,0), Att.Pos, Att.Ang )
			view.origin = Pos
		end

		if not pod:GetThirdPersonMode() then
			return view
		end

		local mn = self:OBBMins()
		local mx = self:OBBMaxs()
		local radius = ( mn - mx ):Length()
		local radius = radius + radius * pod:GetCameraDistance()

		local clamped_angles = pod:WorldToLocalAngles( angles )
		clamped_angles.p = math.max( clamped_angles.p, -20 )
		clamped_angles = pod:LocalToWorldAngles( clamped_angles )

		local StartPos = self:LocalToWorld( Vector(-75,0,140) )
		local EndPos = StartPos - clamped_angles:Forward() * radius + clamped_angles:Up() * radius * 0.2

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
		view.origin = tr.HitPos

		if tr.Hit and  not tr.StartSolid then
			view.origin = view.origin + tr.HitNormal * WallOffset
		end

		return view
	end
	weapon.HudPaint = function( ent, X, Y, ply )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		if base:GetIsCarried() then return end

		local Pos2D = base:TraceTurret().HitPos:ToScreen()

		base:PaintCrosshairCenter( Pos2D, color_white )
		base:PaintCrosshairOuter( Pos2D, color_white )
		base:LVSPaintHitMarker( Pos2D )
	end
	self:AddWeapon( weapon, 2 )
end
