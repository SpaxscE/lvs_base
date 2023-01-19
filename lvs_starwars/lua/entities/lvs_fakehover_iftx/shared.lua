
ENT.Base = "lvs_base_fakehover"

ENT.PrintName = "IFT-X"
ENT.Author = "Luna"
ENT.Information = "Hover Tank of the Galactic Republic"
ENT.Category = "[LVS] - Star Wars"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/iftx.mdl"
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

ENT.MaxHealth = 2700

ENT.ForceAngleMultiplier = 2
ENT.ForceAngleDampingMultiplier = 1

ENT.ForceLinearMultiplier = 1
ENT.ForceLinearRate = 0.25

ENT.MaxVelocityX = 180
ENT.MaxVelocityY = 180

ENT.MaxTurnRate = 0.5

ENT.BoostAddVelocityX = 120
ENT.BoostAddVelocityY = 120

ENT.GroundTraceHitWater = true
ENT.GroundTraceLength = 50
ENT.GroundTraceHull = 100

ENT.LAATC_PICKUPABLE = true
ENT.LAATC_DROP_IN_AIR = true
ENT.LAATC_PICKUP_POS = Vector(-200,0,25)
ENT.LAATC_PICKUP_Angle = Angle(0,0,0)

function ENT:OnSetupDataTables()
	self:AddDT( "Bool", "BTLFire" )
	self:AddDT( "Bool", "IsCarried" )
	self:AddDT( "Entity", "GunnerSeat" )

	if SERVER then
		self:NetworkVarNotify( "IsCarried", self.OnIsCarried )
	end
end

function ENT:GetAimAngles()
	local trace = self:GetEyeTrace()

	local AimAnglesR = self:WorldToLocalAngles( (trace.HitPos - self:LocalToWorld( Vector(-60,-51,43) ) ):GetNormalized():Angle() )
	local AimAnglesL = self:WorldToLocalAngles( (trace.HitPos - self:LocalToWorld( Vector(-60,51,43) ) ):GetNormalized():Angle() )

	return AimAnglesR, AimAnglesL
end

function ENT:WeaponsInRange()
	if self:GetIsCarried() then return false end

	local AimAnglesR, AimAnglesL = self:GetAimAngles()

	return not ((AimAnglesR.p >= 10 and AimAnglesL.p >= 10) or (AimAnglesR.p <= -25 and AimAnglesL.p <= -25) or (math.abs(AimAnglesL.y) + math.abs(AimAnglesL.y)) >= 30)
end

function ENT:InitWeapons()
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/hmg.png")
	weapon.Ammo = 600
	weapon.Delay = 0.2
	weapon.HeatRateUp = 0.25
	weapon.HeatRateDown = 0.25
	weapon.Attack = function( ent )
		if not ent:WeaponsInRange() then return true end

		local ID_L = ent:LookupAttachment( "muzzle_left" )
		local ID_R = ent:LookupAttachment( "muzzle_right" )
		local MuzzleL = ent:GetAttachment( ID_L )
		local MuzzleR = ent:GetAttachment( ID_R )

		if not MuzzleL or not MuzzleR then return end

		ent.MirrorPrimary = not ent.MirrorPrimary

		local Pos = ent.MirrorPrimary and MuzzleL.Pos or MuzzleR.Pos
		local Dir =  (ent.MirrorPrimary and MuzzleL.Ang or MuzzleR.Ang):Up()

		local bullet = {}
		bullet.Src 	= Pos
		bullet.Dir 	= Dir
		bullet.Spread 	= Vector( 0.01,  0.01, 0 )
		bullet.TracerName = "lvs_laser_blue_long"
		bullet.Force	= 100
		bullet.HullSize 	= 1
		bullet.Damage	= 25
		bullet.Velocity = 40000
		bullet.Attacker 	= ent:GetDriver()
		bullet.Callback = function(att, tr, dmginfo)
			local effectdata = EffectData()
				effectdata:SetStart( Vector(50,50,255) ) 
				effectdata:SetOrigin( tr.HitPos )
				effectdata:SetNormal( tr.HitNormal )
			util.Effect( "lvs_laser_impact", effectdata )
		end
		ent:LVSFireBullet( bullet )

		local effectdata = EffectData()
		effectdata:SetStart( Vector(50,50,255) )
		effectdata:SetOrigin( bullet.Src )
		effectdata:SetNormal( Dir )
		effectdata:SetEntity( ent )
		util.Effect( "lvs_muzzle_colorable", effectdata )

		ent:TakeAmmo()

		if ent.MirrorPrimary then
			ent:PlayAnimation( "fire_left" )
	
			if not IsValid( ent.SNDLeft ) then return end
	
			ent.SNDLeft:PlayOnce( 100 + math.cos( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )

			return
		end

		ent:PlayAnimation( "fire_right" )

		if not IsValid( ent.SNDRight ) then return end

		ent.SNDRight:PlayOnce( 100 + math.sin( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )
	end
	weapon.OnSelect = function( ent )
		ent:EmitSound("physics/metal/weapon_impact_soft3.wav")
	end
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	weapon.OnThink = function( ent, active )
		if ent:GetIsCarried() then
			self:SetPoseParameter("cannon_right_pitch", 0 )
			self:SetPoseParameter("cannon_right_yaw", 0 )

			self:SetPoseParameter("cannon_left_pitch", 0 )
			self:SetPoseParameter("cannon_left_yaw", 0 )

			return
		end

		local AimAnglesR, AimAnglesL = ent:GetAimAngles()

		self:SetPoseParameter("cannon_right_pitch", AimAnglesR.p )
		self:SetPoseParameter("cannon_right_yaw", AimAnglesR.y )

		self:SetPoseParameter("cannon_left_pitch", AimAnglesL.p )
		self:SetPoseParameter("cannon_left_yaw", AimAnglesL.y )
	end
	self:AddWeapon( weapon )


	local weapon = {}
	weapon.Icon = Material("lvs/weapons/missile.png")
	weapon.Ammo = 60
	weapon.Delay = 1
	weapon.HeatRateUp = 0
	weapon.HeatRateDown = 0.2
	weapon.Attack = function( ent )
		if not ent:WeaponsInRange() then return true end

		local Driver = ent:GetDriver()

		for i = 1, 6 do
			timer.Simple( (i / 5) * 0.75, function()
				if not IsValid( ent ) then return end

				if ent:GetAmmo() <= 0 then ent:SetHeat( 1 ) return end
	
				ent:TakeAmmo()

				local ID_L = ent:LookupAttachment( "muzzle_left" )
				local ID_R = ent:LookupAttachment( "muzzle_right" )
				local MuzzleL = ent:GetAttachment( ID_L )
				local MuzzleR = ent:GetAttachment( ID_R )

				if not MuzzleL or not MuzzleR then return end

				ent.MirrorPrimary = not ent.MirrorPrimary

				local Pos = ent.MirrorPrimary and MuzzleL.Pos or MuzzleR.Pos
				local Dir =  (ent.MirrorPrimary and MuzzleL.Ang or MuzzleR.Ang):Up()

				local projectile = ents.Create( "lvs_concussionmissile" )
				projectile:SetPos( Pos )
				projectile:SetAngles( Dir:Angle() )
				projectile:SetParent( ent )
				projectile:Spawn()
				projectile:Activate()
				projectile.GetTarget = function( missile ) return missile end
				projectile.GetTargetPos = function( missile )
					return missile:LocalToWorld( Vector(150,0,0) + VectorRand() * math.random(-10,10) )
				end
				projectile:SetAttacker( IsValid( Driver ) and Driver or self )
				projectile:SetEntityFilter( ent:GetCrosshairFilterEnts() )
				projectile:SetSpeed( 4000 )
				projectile:SetDamage( 300 )
				projectile:SetRadius( 150 )
				projectile:Enable()
				projectile:EmitSound( "LVS.IFTX.FIRE_MISSILE" )

				if ent.MirrorPrimary then
					ent:PlayAnimation( "fire_left" )
				else
					ent:PlayAnimation( "fire_right" )
				end
			end)
		end

		ent:SetHeat( 1 )
		ent:SetOverheated( true )
	end
	weapon.OnSelect = function( ent )
		ent:EmitSound("weapons/shotgun/shotgun_cock.wav")
	end
	self:AddWeapon( weapon )

	self:InitTurret()
end

ENT.EngineSounds = {
	{
		sound = "lvs/vehicles/iftx/loop.wav",
		Pitch = 70,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 30,
		FadeIn = 0,
		FadeOut = 1,
		FadeSpeed = 1.5,
		UseDoppler = true,
		SoundLevel = 85,
	},
	{
		sound = "lvs/vehicles/iftx/loop_hi.wav",
		Pitch = 70,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 30,
		FadeIn = 0,
		FadeOut = 1,
		FadeSpeed = 1.5,
		UseDoppler = true,
		SoundLevel = 85,
	},
	{
		sound = "^lvs/vehicles/iftx/dist.wav",
		Pitch = 70,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 30,
		FadeIn = 0,
		FadeOut = 1,
		FadeSpeed = 1.5,
		SoundLevel = 90,
	},
}

sound.Add( {
	name = "LVS.IFTX.FIRE_MISSILE",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 125,
	pitch = {95, 105},
	sound = "lvs/vehicles/iftx/fire_missile.mp3"
} )
