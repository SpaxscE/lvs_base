
function ENT:SetNextRearGunFire( delay )
	self._NextRGFire = CurTime() + delay
end

function ENT:CanFireRearGun()
	return (self._NextRGFire or 0) < CurTime()
end

function ENT:GetRearGunInRange( ent )
	return ent:AngleBetweenNormal( ent:GetAimVector(), -ent:GetForward() ) < 35
end

function ENT:HandleRearGun( ent, ShouldFire )
	local trace = ent:GetEyeTrace()

	local Pos,Ang = WorldToLocal( Vector(0,0,0), (trace.HitPos - self:LocalToWorld( Vector(-400,0,158.5)) ):GetNormalized():Angle(), Vector(0,0,0), self:LocalToWorldAngles( Angle(0,180,0) ) )

	if not self:GetRearGunInRange( ent ) then 
		self:SetPoseParameter("reargun_yaw", 0 )

		return false
	end

	self:SetPoseParameter("reargun_pitch", -Ang.p )
	self:SetPoseParameter("reargun_yaw", -Ang.y )

	if not ShouldFire or not self:CanFireRearGun() then self:GetRearGunInRange( ent ) return end

	local ID = self:LookupAttachment( "muzzle_reargun" )
	local Muzzle = self:GetAttachment( ID )

	if not Muzzle then return self:GetRearGunInRange( ent ) end

	self:SetNextRearGunFire( 0.3 )

	local bullet = {}
	bullet.Src 	= Muzzle.Pos
	bullet.Dir 	= (trace.HitPos - Muzzle.Pos):GetNormalized()
	bullet.Spread 	= Vector( 0.03,  0.03, 0.03 )
	bullet.TracerName = "lvs_laser_green"
	bullet.Force	= 10
	bullet.HullSize 	= 25
	bullet.Damage	= 65
	bullet.Velocity = 30000
	bullet.Attacker 	= ent:GetDriver()
	bullet.Callback = function(att, tr, dmginfo)
		local effectdata = EffectData()
			effectdata:SetStart( Vector(50,255,50) ) 
			effectdata:SetOrigin( tr.HitPos )
			effectdata:SetNormal( tr.HitNormal )
		util.Effect( "lvs_laser_impact", effectdata )
	end
	ent:LVSFireBullet( bullet )

	local NewHeat = ent:GetHeat() + 0.4


	ent:SetHeat( NewHeat )
	if NewHeat >= 1 then
		ent:SetOverheated( true )
	end

	if not IsValid( self.SNDTail ) then return end

	self.SNDTail:PlayOnce( 100 + math.Rand(-3,3), 1 )
end

function ENT:InitWeaponGunner()
	local COLOR_RED = Color(255,0,0,255)
	local COLOR_WHITE = Color(255,255,255,255)
	local MaxRange = 60
	local MaxTailRange = 35

	local weapon = {}
	weapon.Icon = Material("lvs/weapons/laserbeam.png")
	weapon.Ammo = -1
	weapon.Delay = 0
	weapon.HeatRateUp = 0
	weapon.HeatRateDown = 0
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	weapon.StartAttack = function( ent )
		ent.ShouldFire = true
	end
	weapon.FinishAttack = function( ent )
		ent.ShouldFire = false

		local base = ent:GetVehicle()

		local snd = {
			[-1] = base.WingLeftSND,
			[1] = base.WingRightSND,
		}

		for _, sound in pairs( snd ) do
			if not IsValid( sound ) then continue end

			sound:Stop()
		end
	end
	weapon.OnThink = function( ent, active )
		local base = ent:GetVehicle()

		local ShouldFire = (ent.ShouldFire == true) and ent:AngleBetweenNormal( ent:GetAimVector(), ent:GetForward() ) < MaxRange
	
		if base:HandleRearGun( ent, ent.ShouldFire ) then
			ShouldFire = false
		end

		if base:SetWingTurretFire() ~= ShouldFire then
			base:SetWingTurretFire( ShouldFire ) 
		end

		local snd = {
			[-1] = base.WingLeftSND,
			[1] = base.WingRightSND,
		}

		if ent._oldShouldFire ~= ShouldFire then
			ent._oldShouldFire = ShouldFire
			if ShouldFire then
				for _, sound in pairs( snd ) do
					if not IsValid( sound ) then continue end

					sound:EmitSound( "lvs/vehicles/laat/ballturret_fire.mp3", 110 )
				end
			end
		end

		if not ShouldFire then
			for _, sound in pairs( snd ) do
				if not IsValid( sound ) then continue end
				sound:Stop()
			end

			ent:SetHeat( ent:GetHeat() - FrameTime() )

			return
		end
	
		if not active then
			return
		end

		local trace = ent:GetEyeTrace()
		local DesEndPos = trace.HitPos

		base:SetWingTurretTarget( DesEndPos )

		if not base:GetWingTurretFire() then return end

		local DesStartPos

		if base:WorldToLocal( DesEndPos ).z < 0 then
			DesStartPos = Vector(-172.97,334.04,93.25)
		else
			DesStartPos = Vector(-174.79,350.05,125.98)
		end

		local NewHeat = ent:GetHeat()

		for i = -1,1,2 do
			local StartPos = self:LocalToWorld( DesStartPos * Vector(1,i,1) )
			local beam = util.TraceLine( { start = StartPos, endpos = DesEndPos} )

			self:BallturretDamage( beam.Entity, ent:GetDriver(), trace.HitPos, (trace.HitPos - StartPos):GetNormalized() )

			if not IsValid( snd[i] ) then continue end

			if beam.Entity ~= base then
				snd[i]:Play()
				NewHeat = NewHeat + FrameTime() * 0.25
			else
				snd[i]:Stop()
			end
		end

		ent:SetHeat( NewHeat )
		if NewHeat >= 1 then
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

		local radius = 800
		radius = radius + radius * pod:GetCameraDistance()

		local clamped_angles = pod:WorldToLocalAngles( angles )
		clamped_angles.p = math.max( clamped_angles.p, -20 )
		clamped_angles = pod:LocalToWorldAngles( clamped_angles )

		local StartPos = base:LocalToWorld( base:OBBCenter() ) + clamped_angles :Up() * 250
		local EndPos = StartPos - clamped_angles:Forward() * radius

		local WallOffset = 4

		local tr = util.TraceHull( {
			start = StartPos,
			endpos = EndPos,
			filter = function( e )
				local c = e:GetClass()
				local collide = not c:StartWith( "prop_physics" ) and not c:StartWith( "prop_dynamic" ) and not c:StartWith( "prop_ragdoll" ) and not e:IsVehicle() and not c:StartWith( "gmod_" ) and not c:StartWith( "player" ) and not e.LVS
				
				return collide
			end,
			mins = Vector( -WallOffset, -WallOffset, -WallOffset ),
			maxs = Vector( WallOffset, WallOffset, WallOffset ),
		} )

		view.drawviewer = true
		view.origin = tr.HitPos

		if tr.Hit and not tr.StartSolid then
			view.origin = view.origin + tr.HitNormal * WallOffset
		end

		return view
	end
	weapon.HudPaint = function( ent, X, Y, ply )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		local WingInRange = ent:AngleBetweenNormal( ent:GetAimVector(), ent:GetForward() ) >= MaxRange
		local RearGunInRange = not base:GetRearGunInRange( ent )

		local Col = (WingInRange and RearGunInRange) and COLOR_RED or COLOR_WHITE

		local Pos2D = ent:GetEyeTrace().HitPos:ToScreen() 

		base:PaintCrosshairCenter( Pos2D, Col )
		base:PaintCrosshairOuter( Pos2D, Col )
		base:LVSPaintHitMarker( Pos2D )
	end
	self:AddWeapon( weapon, 2 )
end