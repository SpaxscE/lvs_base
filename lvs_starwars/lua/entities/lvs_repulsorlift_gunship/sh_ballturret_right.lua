
function ENT:TraceBTR()
	local ID = self:LookupAttachment( "muzzle_ballturret_right" )
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

function ENT:SetPoseParameterBTR( weapon )
	if not IsValid( weapon:GetDriver() ) and not weapon:GetAI() then
		self:SetPoseParameter("ballturret_right_pitch", 0 )
		self:SetPoseParameter("ballturret_right_yaw", -70 )

		return
	end

	local AimAng = weapon:WorldToLocal( weapon:GetPos() + weapon:GetAimVector() ):Angle()
	AimAng:Normalize()

	self:SetPoseParameter("ballturret_right_pitch", AimAng.p )
	self:SetPoseParameter("ballturret_right_yaw", -AimAng.y )
end

function ENT:InitWeaponBTR()
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/laserbeam.png")
	weapon.Ammo = -1
	weapon.Delay = 0
	weapon.HeatRateUp = 0
	weapon.HeatRateDown = 0
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	weapon.StartAttack = function( ent )
	end
	weapon.FinishAttack = function( ent )
	end
	weapon.OnThink = function( ent, active )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		local BTR = base:GetBTPodR()

		if not IsValid( BTR ) then return end

		local ID = base:LookupAttachment( "muzzle_ballturret_right" )
		local Muzzle = base:GetAttachment( ID )

		if Muzzle then
			local PosL = base:WorldToLocal( Muzzle.Pos + Muzzle.Ang:Right() * 28 - Muzzle.Ang:Up() * 65 )
			BTR:SetLocalPos( PosL )
		end

		base:SetPoseParameterBTR( ent )
	end
	weapon.CalcView = function( ent, ply, pos, angles, fov, pod )
		local view = {}
		view.origin = pos
		view.angles = angles
		view.fov = fov
		view.drawviewer = false

		local ID = ent:LookupAttachment( "muzzle_ballturret_right" )
		local Muzzle = ent:GetAttachment( ID )

		if Muzzle then
			local Pos,Ang = LocalToWorld( Vector(0,25,-45), Angle(270,0,-90), Muzzle.Pos, Muzzle.Ang )

			view.origin = Pos
		end

		return view
	end
	weapon.HudPaint = function( ent, X, Y, ply )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		local Pos2D = base:TraceBTR().HitPos:ToScreen()

		base:PaintCrosshairCenter( Pos2D, color_white )
		base:PaintCrosshairOuter( Pos2D, color_white )
		base:LVSPaintHitMarker( Pos2D )
	end
	self:AddWeapon( weapon, 4 )
end