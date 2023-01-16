
ENT.Base = "lvs_base_repulsorlift"

ENT.PrintName = "LAAT/c"
ENT.Author = "Luna"
ENT.Information = "Tank Carrier of the Galactic Republic"
ENT.Category = "[LVS] - Star Wars"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/laat_c.mdl"
ENT.GibModels = {
	"models/gibs/helicopter_brokenpiece_01.mdl",
	"models/gibs/helicopter_brokenpiece_02.mdl",
	"models/gibs/helicopter_brokenpiece_03.mdl",
	"models/combine_apc_destroyed_gib02.mdl",
	"models/combine_apc_destroyed_gib04.mdl",
	"models/combine_apc_destroyed_gib05.mdl",
	"models/props_c17/trappropeller_engine.mdl",
	"models/gibs/airboat_broken_engine.mdl",
}

ENT.AITEAM = 2

ENT.MaxVelocity = 2400
ENT.MaxThrust = 2400

ENT.MaxPitch = 40

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
	self:AddDT( "Entity", "HeldEntity" )
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
	weapon.Icon = Material("lvs/weapons/dropship_grabber.png")
	weapon.Ammo = -1
	weapon.Delay = 1
	weapon.HeatRateUp = 10
	weapon.HeatRateDown = 1
	weapon.StartAttack = function( ent )
		ent:ToggleGrabber()
	end
	self:AddWeapon( weapon )



	local COLOR_RED = Color(255,0,0,255)
	local COLOR_WHITE = Color(255,255,255,255)
	self.RearGunAngleRange = 35

	local weapon = {}
	weapon.Icon = Material("lvs/weapons/hmg.png")
	weapon.Ammo = -1
	weapon.Delay = 0.3
	weapon.HeatRateUp = 0.4
	weapon.HeatRateDown = 0.4
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	weapon.Attack = function( ent )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		if ent:AngleBetweenNormal( ent:GetAimVector(), ent:GetForward() ) > base.RearGunAngleRange then return true end

		local trace = ent:GetEyeTrace()

		local Pos,Ang = WorldToLocal( Vector(0,0,0), (trace.HitPos - self:LocalToWorld( Vector(-400,0,158.5)) ):GetNormalized():Angle(), Vector(0,0,0), self:LocalToWorldAngles( Angle(0,180,0) ) )

		local ID = self:LookupAttachment( "muzzle_reargun" )
		local Muzzle = self:GetAttachment( ID )

		if not Muzzle then return true end

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

		if not IsValid( self.SNDTail ) then return end

		self.SNDTail:PlayOnce( 100 + math.Rand(-3,3), 1 )
	end
	weapon.OnThink = function( ent, active )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		if ent:AngleBetweenNormal( ent:GetAimVector(), ent:GetForward() ) > base.RearGunAngleRange then base:SetPoseParameter("reargun_yaw", 0 ) return end

		local trace = ent:GetEyeTrace()

		local _,Ang = WorldToLocal( Vector(0,0,0), (trace.HitPos - self:LocalToWorld( Vector(-400,0,158.5)) ):GetNormalized():Angle(), Vector(0,0,0), self:LocalToWorldAngles( Angle(0,180,0) ) )

		base:SetPoseParameter("reargun_pitch", -Ang.p )
		base:SetPoseParameter("reargun_yaw", -Ang.y )

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

		local StartPos = pod:LocalToWorld( pod:OBBCenter() ) + angles :Up() * 250
		local EndPos = StartPos - angles:Forward() * radius

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

		local RearGunInRange = ent:AngleBetweenNormal( ent:GetAimVector(), ent:GetForward() ) > base.RearGunAngleRange

		local Col = RearGunInRange and COLOR_RED or COLOR_WHITE

		local Pos2D = ent:GetEyeTrace().HitPos:ToScreen() 

		base:PaintCrosshairCenter( Pos2D, Col )
		base:PaintCrosshairOuter( Pos2D, Col )
		base:LVSPaintHitMarker( Pos2D )
	end
	self:AddWeapon( weapon, 2 )
end

sound.Add( {
	name = "LVS.LAAT.GRABBER",
	channel = CHAN_ITEM,
	volume = 1.0,
	level = 90,
	pitch = 100,
	sound = "lvs/vehicles/laat/door_large_open.wav"
} )

sound.Add( {
	name = "LVS.LAAT.GRABBER_CANTDROP",
	channel = CHAN_ITEM,
	volume = 1.0,
	level = 90,
	pitch = 100,
	sound = "buttons/button8.wav"
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

function ENT:ResetFilters()
	-- clear the filters, so they can be rebuild
	self.CrosshairFilterEnts = nil
end

function ENT:BuildFilter()
	if not istable( self.CrosshairFilterEnts ) then
		self:GetCrosshairFilterEnts()
	end

	local HeldEnt = self:GetHeldEntity()

	if not IsValid( HeldEnt ) then return end

	if HeldEnt.GetCrosshairFilterEnts then
		for _, ent in pairs( HeldEnt:GetCrosshairFilterEnts() ) do
			table.insert( self.CrosshairFilterEnts, ent )
		end
	else
		table.insert( self.CrosshairFilterEnts , HeldEnt )
	end
end
