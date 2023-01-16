
function ENT:GetGunnerAimAng( ent, base, RearEnt )
	local trace = ent:GetEyeTrace()

	local Pos = RearEnt:LocalToWorld( Vector(-208,0,170) )
	local wAng = (trace.HitPos - Pos):GetNormalized():Angle()

	local _, Ang = WorldToLocal( Pos, wAng, Pos, RearEnt:LocalToWorldAngles( Angle(0,180,0) ) )

	return Ang, trace.HitPos, (Ang.p < 30 and Ang.p > -10 and math.abs( Ang.y ) < 60)
end

local white = Color(255,255,255,255)
local red = Color(255,0,0,255)

function ENT:InitGunner()
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/hmg.png")
	weapon.Ammo = 400
	weapon.Delay = 0.3
	weapon.HeatRateUp = 0.2
	weapon.HeatRateDown = 0.2
	weapon.OnOverheat = function( ent ) end
	weapon.Attack = function( ent )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		if base:GetIsCarried() then base:SetHeat( 0 ) return true end

		local RearEnt = base:GetRearEntity()

		if not IsValid( RearEnt ) then return end

		local _, AimPos, InRange = base:GetGunnerAimAng( ent, base, RearEnt )

		if not InRange then return true end
	
		local ID1 = RearEnt:LookupAttachment( "muzzle_right" )
		local ID2 = RearEnt:LookupAttachment( "muzzle_left" )

		local Muzzle1 = RearEnt:GetAttachment( ID1 )
		local Muzzle2 = RearEnt:GetAttachment( ID2 )

		if not Muzzle1 or not Muzzle2 then return end

		local FirePos = { 
			[1] = Muzzle1,
			[2] = Muzzle2
		}

		ent.FireIndex = ent.FireIndex and ent.FireIndex + 1 or 1
	
		if ent.FireIndex > #FirePos then
			ent.FireIndex = 1
		end

		local Pos = FirePos[ent.FireIndex].Pos
		local Dir = (AimPos - Pos):GetNormalized()

		local bullet = {}
		bullet.Src 	= Pos
		bullet.Dir 	= Dir
		bullet.Spread 	= Vector( 0.01,  0.01, 0 )
		bullet.TracerName = "lvs_laser_green_short"
		bullet.Force	= 10
		bullet.HullSize 	= 30
		bullet.Damage	= 100
		bullet.SplashDamage = 200
		bullet.SplashDamageRadius = 200
		bullet.Velocity = 8000
		bullet.Attacker 	= ent:GetDriver()
		bullet.Callback = function(att, tr, dmginfo)
			local effectdata = EffectData()
				effectdata:SetStart( Vector(0,255,0) ) 
				effectdata:SetOrigin( tr.HitPos )
			util.Effect( "lvs_laser_explosion", effectdata )
		end
		ent:LVSFireBullet( bullet )

		local effectdata = EffectData()
		effectdata:SetStart( Vector(50,255,50) )
		effectdata:SetOrigin( bullet.Src )
		effectdata:SetNormal( Dir )
		effectdata:SetEntity( ent )
		util.Effect( "lvs_muzzle_colorable", effectdata )

		ent:TakeAmmo()

		base.SNDRear:PlayOnce( 100 + math.cos( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )
	end
	weapon.OnThink = function( ent, active )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		if base:GetIsCarried() then return end

		local RearEnt = base:GetRearEntity()

		if not IsValid( RearEnt ) then return end
	
		local Ang, HitPos, InRange = base:GetGunnerAimAng( ent, base, RearEnt )

		RearEnt:SetPoseParameter("gun_pitch", math.Clamp(Ang.p,-10,30) )
		RearEnt:SetPoseParameter("gun_yaw", Ang.y )
	end
	weapon.CalcView = function( ent, ply, pos, angles, fov, pod )
		local view = {}
		view.origin = pos
		view.angles = angles
		view.fov = fov
		view.drawviewer = false

		local mn = self:OBBMins()
		local mx = self:OBBMaxs()
		local radius = ( mn - mx ):Length()
		local radius = radius + radius * pod:GetCameraDistance()

		local clamped_angles = pod:WorldToLocalAngles( angles )
		clamped_angles.p = math.max( clamped_angles.p, -20 )
		clamped_angles = pod:LocalToWorldAngles( clamped_angles )

		local StartPos = self:LocalToWorld( Vector(-150,0,150) ) + clamped_angles:Up() * 150
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
		view.drawviewer = true

		if tr.Hit and  not tr.StartSolid then
			view.origin = view.origin + tr.HitNormal * WallOffset
		end

		return view
	end
	weapon.HudPaint = function( ent, X, Y, ply )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		if base:GetIsCarried() then return end

		local RearEnt = base:GetRearEntity()

		if not IsValid( RearEnt ) then return end
	
		local _,AimPos, InRange = base:GetGunnerAimAng( ent, base, RearEnt )

		local Pos2D = AimPos:ToScreen()

		local Col = InRange and white or red

		self:PaintCrosshairCenter( Pos2D, Col )
		self:PaintCrosshairOuter( Pos2D, Col )
		self:LVSPaintHitMarker( Pos2D )
	end
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end

	self:AddWeapon( weapon, 3 )
end