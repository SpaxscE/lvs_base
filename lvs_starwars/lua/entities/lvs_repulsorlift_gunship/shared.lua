
ENT.Base = "lvs_base_repulsorlift"

ENT.PrintName = "LAAT/i"
ENT.Author = "Luna"
ENT.Information = "Gunship/Troop Transport of the Galactic Republic"
ENT.Category = "[LVS] - Star Wars"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/laat.mdl"

ENT.AITEAM = 2

ENT.MaxVelocity = 2400
ENT.MaxThrust = 2400

ENT.MaxPitch = 60

ENT.ThrustVtol = 50
ENT.ThrustRateVtol = 2

ENT.TurnRatePitch = 0.7
ENT.TurnRateYaw = 0.7
ENT.TurnRateRoll = 0.7

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.MaxHealth = 4000

ENT.AutomaticFrameAdvance = true

function ENT:OnSetupDataTables()
	self:AddDT( "Entity", "GunnerSeat" )
	self:AddDT( "Entity", "BTPodL" )
	self:AddDT( "Entity", "BTPodR" )

	self:AddDT( "Bool", "RearHatch" )

	self:AddDT( "Int", "DoorMode" )

	self:AddDT( "Bool", "WingTurretFire" )
	self:AddDT( "Vector", "WingTurretTarget" )

	--self:NetworkVar( "Bool",19, "BTLFire" )
	--self:NetworkVar( "Bool",20, "BTRFire" )
end

function ENT:InitWeapons()
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/dual_mg.png")
	weapon.Ammo = 600
	weapon.Delay = 0.25
	weapon.HeatRateUp = 0
	weapon.HeatRateDown = 1
	weapon.Attack = function( ent )
		if math.abs( ent.frontgunYaw ) > 100 then return end

		local ID_L = self:LookupAttachment( "muzzle_frontgun_left" )
		local ID_R = self:LookupAttachment( "muzzle_frontgun_right" )
		local Muzzle = {
			[1] = self:GetAttachment( ID_L ),
			[2] = self:GetAttachment( ID_R ),
		}

		local NewHeat = ent:GetHeat()

		for id = 1, 2 do
			if id == 1 and ent.frontgunYaw > 5 then continue end
			if id == 2 and ent.frontgunYaw < -5 then continue end

			local att = Muzzle[ id ]

			local bullet = {}
			bullet.Src 	= att.Pos
			bullet.Dir 	= att.Ang:Up()
			bullet.Spread 	= Vector( 0.015,  0.015, 0 )
			bullet.TracerName = "lvs_laser_green"
			bullet.Force	= 10
			bullet.HullSize 	= 25
			bullet.Damage	= 40
			bullet.Velocity = 60000
			bullet.Attacker 	= ent:GetDriver()
			bullet.Callback = function(att, tr, dmginfo)
				local effectdata = EffectData()
					effectdata:SetStart( Vector(50,255,50) ) 
					effectdata:SetOrigin( tr.HitPos )
					effectdata:SetNormal( tr.HitNormal )
				util.Effect( "lvs_laser_impact", effectdata )
			end

			ent:LVSFireBullet( bullet )
			ent:TakeAmmo()

			NewHeat = NewHeat + 0.075
		end

		ent:SetHeat( NewHeat )

		if NewHeat >= 1 then
			ent:SetOverheated( true )
		end

		ent.PrimarySND:PlayOnce( 100 + math.cos( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )
	end
	weapon.OnSelect = function( ent ) ent:EmitSound("physics/metal/weapon_impact_soft3.wav") end
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	weapon.OnThink = function( ent, active )
		local trace = ent:GetEyeTrace()

		local AimAngles = ent:WorldToLocalAngles( (trace.HitPos - self:LocalToWorld(  Vector(256,0,36) ) ):GetNormalized():Angle() )

		ent.frontgunYaw = -AimAngles.y

		if math.abs( ent.frontgunYaw ) > 100 then
			ent:SetPoseParameter("frontgun_pitch", 0 )
			ent:SetPoseParameter("frontgun_yaw", 0 )

			return
		end

		ent:SetPoseParameter("frontgun_pitch", -AimAngles.p )
		ent:SetPoseParameter("frontgun_yaw", -AimAngles.y )
	end
	self:AddWeapon( weapon )



	local weapon = {}
	weapon.Icon = Material("lvs/weapons/protontorpedo.png")
	weapon.Ammo = 26
	weapon.Delay = 0 -- this will turn weapon.Attack to a somewhat think function
	weapon.HeatRateUp = -0.5 -- cool down when attack key is held. This system fires on key-release.
	weapon.HeatRateDown = 0.25
	weapon.Attack = function( ent )
		local T = CurTime()

		if IsValid( ent._ProtonTorpedo ) then
			if (ent._nextMissleTracking or 0) > T then return end

			ent._nextMissleTracking = T + 0.1 -- 0.1 second interval because those find functions can be expensive

			ent._ProtonTorpedo:FindTarget( ent:GetPos(), ent:GetForward(), 30, 7500 )

			if IsValid( ent._ProtonTorpedo:GetTarget() ) then
				ent:SetBodygroup( 1, 1 )
			end

			return
		end

		local T = CurTime()

		if (ent._nextMissle or 0) > T then return end

		ent._nextMissle = T + 0.5

		ent._swapMissile = not ent._swapMissile

		local TypeA = self:GetBodygroup( 3 ) == 0
		local Pos = Vector( (TypeA and -20 or 206.07), (ent._swapMissile and -59 or 59), 286.88 )

		local Driver = self:GetDriver()

		local projectile = ents.Create( TypeA and "lvs_protontorpedo" or "lvs_concussionmissile" )
		projectile:SetPos( ent:LocalToWorld( Pos ) )
		projectile:SetAngles( ent:GetAngles() )
		projectile:SetParent( ent )
		projectile:Spawn()
		projectile:Activate()
		projectile:SetAttacker( IsValid( Driver ) and Driver or self )
		projectile:SetEntityFilter( ent:GetCrosshairFilterEnts() )
		projectile:SetSpeed( ent:GetVelocity():Length() + 4000 )

		ent._ProtonTorpedo = projectile
		ent._TypeA = TypeA

		ent:SetNextAttack( CurTime() + 0.1 ) -- wait 0.1 second before starting to track
	end
	weapon.FinishAttack = function( ent )
		ent:SetBodygroup( 1, 0 )

		if not IsValid( ent._ProtonTorpedo ) then return end

		local projectile = ent._ProtonTorpedo

		projectile:Enable()
		projectile:EmitSound( self._TypeA and "lvs/vehicles/naboo_n1_starfighter/proton_fire.mp3" or "lvs/vehicles/vulturedroid/fire_missile.mp3", 125 )
		ent:TakeAmmo()

		ent._ProtonTorpedo = nil

		local NewHeat = ent:GetHeat() + 0.33

		ent:SetHeat( NewHeat )
		if NewHeat >= 1 then
			ent:SetOverheated( true )
		end
	end
	weapon.OnSelect = function( ent ) ent:EmitSound("physics/metal/weapon_impact_soft3.wav") end
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	self:AddWeapon( weapon )



	local weapon = {}
	weapon.Icon = Material("lvs/weapons/gunship_sidedoor.png")
	weapon.Ammo = -1
	weapon.Delay = 0
	weapon.HeatRateUp = 0
	weapon.HeatRateDown = 0
	weapon.StartAttack = function( ent )
		local T = CurTime()

		if (ent.NextDoor or 0) > T then return end

		ent.NextDoor = T + 1

		if ent:GetBodygroup( 2 ) == 0 then
			local DoorMode = ent:GetDoorMode() + 1

			ent:SetDoorMode( DoorMode )
			
			if DoorMode == 1 then
				ent:EmitSound( "lvs/vehicles/laat/door_open.wav" )
			end
			
			if DoorMode == 2 then
				ent:PlayAnimation( "doors_open" )
				ent:EmitSound( "lvs/vehicles/laat/door_large_open.wav" )
			end
			
			if DoorMode == 3 then
				ent:PlayAnimation( "doors_close" )
				ent:EmitSound( "lvs/vehicles/laat/door_large_close.wav" )
			end
			
			if DoorMode >= 4 then
				ent:SetDoorMode( 0 )
				ent:EmitSound( "lvs/vehicles/laat/door_close.wav" )
			end
		else
			local DoorMode = ent:GetDoorMode() + 1

			ent:SetDoorMode( DoorMode )

			if DoorMode == 1 then
				ent:PlayAnimation( "doors_open" )
				ent:EmitSound( "lvs/vehicles/laat/door_large_open.wav" )
			end
			
			if DoorMode >= 2 then
				ent:PlayAnimation( "doors_close" )
				ent:EmitSound( "lvs/vehicles/laat/door_large_close.wav" )
				ent:SetDoorMode( 0 )
			end
		end

		ent:OnDoorsChanged()
	end
	self:AddWeapon( weapon )


	local weapon = {}
	weapon.Icon = Material("lvs/weapons/gunship_reardoor.png")
	weapon.Ammo = -1
	weapon.Delay = 0
	weapon.HeatRateUp = 0
	weapon.HeatRateDown = 0
	weapon.StartAttack = function( ent )
		local T = CurTime()

		if (ent.NextDoor or 0) > T then return end

		ent.NextDoor = T + 1

		local ToggleHatch = not ent:GetRearHatch()

		ent:SetRearHatch( ToggleHatch )
		
		if ToggleHatch then
			ent:EmitSound( "lvs/vehicles/laat/door_open.wav" )
		else
			ent:EmitSound( "lvs/vehicles/laat/door_close.wav" )
		end

		ent:OnDoorsChanged()
	end
	self:AddWeapon( weapon )



	local weapon = {}
	weapon.Icon = Material("lvs/weapons/gunship_reardoor.png")
	weapon.Ammo = -1
	weapon.Delay = 0
	weapon.HeatRateUp = 0.4
	weapon.HeatRateDown = 0.4
	weapon.StartAttack = function( ent )
		local base = ent:GetVehicle()
		base:SetWingTurretFire( true ) 
	end
	weapon.FinishAttack = function( ent )
		local base = ent:GetVehicle()
		base:SetWingTurretFire( false ) 

		if IsValid( base.WingRightSND ) then
			base.WingRightSND:Stop()
		end

		if IsValid( base.WingLeftSND ) then
			base.WingLeftSND:Stop()
		end
	end
	weapon.OnThink = function( ent, active )
		if not active then return end

		local base = ent:GetVehicle()

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

		local snd = {
			[-1] = base.WingLeftSND,
			[1] = base.WingRightSND,
		}

		for i = -1,1,2 do
			local StartPos = self:LocalToWorld( DesStartPos * Vector(1,i,1) )
			local beam = util.TraceLine( { start = StartPos, endpos = DesEndPos} )

			self:BallturretDamage( beam.Entity, ent:GetDriver(), trace.HitPos, (trace.HitPos - StartPos):GetNormalized() )

			if not IsValid( snd[i] ) then continue end

			if beam.Entity ~= base then
				snd[i]:Play()
			else
				snd[i]:Stop()
			end
		end
	end
	weapon.CalcView = function( ent, ply, pos, angles, fov, pod )
		local view = {}
		view.origin = pos
		view.angles = angles
		view.fov = fov
		view.drawviewer = true

		local radius = 800
		radius = radius + radius * pod:GetCameraDistance()

		local StartPos = ent:LocalToWorld( ent:OBBCenter() ) + view.angles:Up() * 250
		local EndPos = StartPos - view.angles:Forward() * radius

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
		local Pos2D = ent:GetEyeTrace().HitPos:ToScreen() 
		local base = ent:GetVehicle()
		base:PaintCrosshairCenter( Pos2D, Color(255,255,255,255) )
		base:PaintCrosshairOuter( Pos2D, Color(255,255,255,255) )
		base:LVSPaintHitMarker( Pos2D )
	end

	self:AddWeapon( weapon, 2 )
end

sound.Add( {
	name = "LVS.LAAT.FLYBY",
	sound = {
		"lvs/vehicles/laat/flyby1.wav",
		"lvs/vehicles/laat/flyby2.wav",
		"lvs/vehicles/laat/flyby3.wav",
		"lvs/vehicles/laat/flyby4.wav",
		"lvs/vehicles/laat/flyby5.wav",
	}
} )

ENT.FlyByAdvance = 1
ENT.FlyBySound = "LVS.LAAT.FLYBY" 
ENT.DeathSound = "lvs/vehicles/generic_starfighter/crash.wav"

ENT.EngineSounds = {
	{
		sound = "lvs/vehicles/laat/loop.wav",
		Pitch = 80,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 40,
		FadeIn = 0,
		FadeOut = 1,
		FadeSpeed = 1.5,
		UseDoppler = true,
	},
	{
		sound = "^lvs/vehicles/laat/dist.wav",
		Pitch = 80,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 40,
		FadeIn = 0.35,
		FadeOut = 1,
		FadeSpeed = 1.5,
		UseDoppler = true,
		VolumeMin = 0,
		VolumeMax = 1,
		SoundLevel = 110,
	},
}

function ENT:CalcMainActivity( ply )
	local Pod = ply:GetVehicle()

	if Pod == self:GetDriverSeat() or Pod == self:GetGunnerSeat() or Pod == self:GetBTPodL() or Pod == self:GetBTPodR() then return end

	if ply.m_bWasNoclipping then 
		ply.m_bWasNoclipping = nil 
		ply:AnimResetGestureSlot( GESTURE_SLOT_CUSTOM ) 

		if CLIENT then 
			ply:SetIK( true )
		end 
	end 

	ply.CalcIdeal = ACT_STAND
	ply.CalcSeqOverride = ply:LookupSequence( "idle_all_02" )

	if ply:GetAllowWeaponsInVehicle() and IsValid( ply:GetActiveWeapon() ) then

		local holdtype = ply:GetActiveWeapon():GetHoldType()

		if holdtype == "smg" then 
			holdtype = "smg1"
		end

		local seqid = ply:LookupSequence( "idle_" .. holdtype )

		if seqid ~= -1 then
			ply.CalcSeqOverride = seqid
		end
	end

	return ply.CalcIdeal, ply.CalcSeqOverride
end