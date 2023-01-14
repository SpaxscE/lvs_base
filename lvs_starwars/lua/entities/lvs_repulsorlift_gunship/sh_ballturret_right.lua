
function ENT:SetPosBTR()
	local BTR = self:GetBTPodR()

	if not IsValid( BTR ) then return end

	local ID = self:LookupAttachment( "muzzle_ballturret_right" )
	local Muzzle = self:GetAttachment( ID )

	if Muzzle then
		local PosL = self:WorldToLocal( Muzzle.Pos + Muzzle.Ang:Right() * 28 - Muzzle.Ang:Up() * 65 )
		BTR:SetLocalPos( PosL )
	end
end

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
	if not IsValid( weapon:GetDriver() ) and not weapon:GetAI() then return end

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
	weapon.HeatRateUp = 0.25
	weapon.HeatRateDown = 0.3
	weapon.OnOverheat = function( ent )
		if ent:GetAI() then return end
		ent:EmitSound("lvs/overheat.wav")
	end
	weapon.Attack = function( ent )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		if not base._CanUseBT then return end

		local trace = base:TraceBTR()

		base:BallturretDamage( trace.Entity, ent:GetDriver(), trace.HitPos, (trace.HitPos - ent:GetPos()):GetNormalized() )
	end
	weapon.StartAttack = function( ent )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		if not base._CanUseBT then return end

		base:SetBTRFire( true )

		if not IsValid( self.sndBTR ) then return end

		self.sndBTR:Play()
		self.sndBTR:EmitSound( "lvs/vehicles/laat/ballturret_fire.mp3", 110 )
	end
	weapon.FinishAttack = function( ent )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		base:SetBTRFire( false )

		if not IsValid( self.sndBTR ) then return end

		self.sndBTR:Stop()
	end
	weapon.OnThink = function( ent, active )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		base:SetPoseParameterBTR( ent )
		base:SetPosBTR()

		if not ent:GetAI() then return end

		local ID = base:LookupAttachment( "muzzle_ballturret_right" )
		local Muzzle = base:GetAttachment( ID )
		if not Muzzle then return end

		if ent:AngleBetweenNormal(Muzzle.Ang:Up(),ent:GetAimVector()) > 5 then
			ent:SetHeat( 1 )
			ent:SetOverheated( true )
		end
	end
	weapon.CalcView = function( ent, ply, pos, angles, fov, pod )
		local base = ent:GetVehicle()

		local view = {}
		view.origin = pos
		view.angles = angles
		view.fov = fov
		view.drawviewer = false

		if not IsValid( base ) then return view end

		local ID = base:LookupAttachment( "muzzle_ballturret_right" )
		local Muzzle = base:GetAttachment( ID )

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