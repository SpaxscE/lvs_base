
function ENT:FireTurret( weapon )
	local T = CurTime()

	if (weapon._NextFire or 0) > T then return end

	weapon._NextFire = T + 0.1

	local ID = self:LookupAttachment( "muzzle_ballturret_left" )
	local Muzzle = self:GetAttachment( ID )

	if not Muzzle then return end

	local dir = Muzzle.Ang:Up()
	local pos = Muzzle.Pos

	local bullet = {}
	bullet.Src 	= pos
	bullet.Dir 	= dir
	bullet.Spread 	= Vector( 0.035,  0.035, 0.035 )
	bullet.TracerName = "lvs_laser_blue_short"
	bullet.Force	= 100
	bullet.HullSize 	= 10
	bullet.Damage	= 10
	bullet.Velocity = 8000
	bullet.Attacker 	= weapon:GetDriver()
	bullet.Callback = function(att, tr, dmginfo)
		local effectdata = EffectData()
			effectdata:SetStart( Vector(50,50,255) ) 
			effectdata:SetOrigin( tr.HitPos )
			effectdata:SetNormal( tr.HitNormal )
		util.Effect( "lvs_laser_impact", effectdata )
	end
	weapon:LVSFireBullet( bullet )

	weapon:EmitSound("lvs/vehicles/iftx/fire_turret.mp3", 85, 100 + math.cos( CurTime() * 0.5 + self:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1, CHAN_WEAPON )

	local effectdata = EffectData()
	effectdata:SetStart( Vector(50,50,255) )
	effectdata:SetOrigin( bullet.Src )
	effectdata:SetNormal( dir )
	effectdata:SetEntity( weapon )
	util.Effect( "lvs_muzzle_colorable", effectdata )
end

function ENT:CanUseBTL()
	return self:GetBodygroup(1) == 0
end

function ENT:TraceBTL()
	local ID = self:LookupAttachment( "muzzle_ballturret_left" )
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

function ENT:SetPoseParameterBTL( weapon )
	if self:GetIsCarried() then
		self:SetPoseParameter("turret_pitch", 0 )
		self:SetPoseParameter("turret_yaw",  0 )

		return
	end

	if not IsValid( weapon:GetDriver() ) and not weapon:GetAI() then return end

	local AimAng = weapon:WorldToLocal( weapon:GetPos() + weapon:GetAimVector() ):Angle()
	AimAng:Normalize()

	self:SetPoseParameter("turret_pitch", AimAng.p )
	self:SetPoseParameter("turret_yaw",  AimAng.y )
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

		if not base:CanUseBTL() then base:FireTurret( ent ) return end

		local trace = base:TraceBTL()

		base:BallturretDamage( trace.Entity, ent:GetDriver(), trace.HitPos, (trace.HitPos - ent:GetPos()):GetNormalized() )
	end
	weapon.StartAttack = function( ent )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		if base:GetIsCarried() then return end

		if not base:CanUseBTL() then return end

		base:SetBTLFire( true )

		if not IsValid( self.sndBTL ) then return end

		self.sndBTL:Play()
		self.sndBTL:EmitSound( "lvs/vehicles/laat/ballturret_fire.mp3", 110 )
	end
	weapon.FinishAttack = function( ent )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		base:SetBTLFire( false )

		if not IsValid( self.sndBTL ) then return end

		self.sndBTL:Stop()
	end
	weapon.OnThink = function( ent, active )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		base:SetPoseParameterBTL( ent )
	end
	weapon.HudPaint = function( ent, X, Y, ply )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		if base:GetIsCarried() then return end

		local Pos2D = base:TraceBTL().HitPos:ToScreen()

		base:PaintCrosshairCenter( Pos2D, color_white )
		base:PaintCrosshairOuter( Pos2D, color_white )
		base:LVSPaintHitMarker( Pos2D )
	end
	self:AddWeapon( weapon, 2 )
end
