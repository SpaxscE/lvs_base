
ENT.Base = "lvs_base_helicopter"

ENT.PrintName = "Combine Helicopter"
ENT.Author = "Luna"
ENT.Information = "Combine Attack Helicopter from Half Life 2 + Episodes"
ENT.Category = "[LVS] - Helicopters"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/Combine_Helicopter.mdl"
ENT.GibModels = {
	"models/gibs/helicopter_brokenpiece_01.mdl",
	"models/gibs/helicopter_brokenpiece_02.mdl",
	"models/gibs/helicopter_brokenpiece_03.mdl",
	"models/gibs/helicopter_brokenpiece_06_body.mdl",
	"models/gibs/helicopter_brokenpiece_04_cockpit.mdl",
	"models/gibs/helicopter_brokenpiece_05_tailfan.mdl",
}

ENT.AITEAM = 1

ENT.MaxHealth = 1600

ENT.MaxVelocity = 2150

ENT.ThrustUp = 1
ENT.ThrustDown = 0.8
ENT.ThrustRate = 1

ENT.ThrottleRateUp = 0.2
ENT.ThrottleRateDown = 0.2

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 1

ENT.ForceLinearDampingMultiplier = 1.5

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.EngineSounds = {
	{
		sound = "^npc/attack_helicopter/aheli_rotor_loop1.wav",
		--sound_int = "lvs/vehicles/helicopter/loop_interior.wav",
		Pitch = 0,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 100,
		Volume = 1,
		VolumeMin = 0,
		VolumeMax = 1,
		SoundLevel = 125,
		UseDoppler = true,
	},
}

function ENT:OnSetupDataTables()
	self:AddDT( "Bool", "LightsEnabled" )
end

function ENT:GetAimAngles()
	local Gun = self:GetAttachment( self:LookupAttachment( "gun" ) )

	if not Gun then return end

	local trace = self:GetEyeTrace()

	local AimAngles = self:WorldToLocalAngles( (trace.HitPos - Gun.Pos):GetNormalized():Angle() )

	return AimAngles
end

function ENT:WeaponsInRange()
	local AimAngles = self:GetAimAngles()

	return math.abs( AimAngles.y ) < 40 and AimAngles.p < 90 and AimAngles.p > -20
end

function ENT:SetPoseParameterTurret()
	local AimAngles = self:GetAimAngles()

	self:SetPoseParameter("weapon_yaw", AimAngles.y )
	self:SetPoseParameter("weapon_pitch", -AimAngles.p )
end

function ENT:HandleShoot( FireInput, active )
	self.charge = self.charge or 0

	if self.charging then
		self.charge = math.min( self.charge + FrameTime() * 60, 100 )

		if self.charge >= 100 then
			self.charging = nil
		end
	else
		if FireInput and self.charge > 0 then
			self:ShootGun()
		else
			if FireInput then
				self:ChargeGun()
			else
				self.charge = math.max(self.charge - FrameTime() * 120,0)
			end
		end
	end

	local Fire = FireInput and active and self.charge > 0 and not self.charging

	if not IsValid( self.weaponSND ) then return end

	if self._oldFire ~= Fire then
		self._oldFire = Fire

		if Fire then
			if self.weaponSND.snd_chrg then
				self.weaponSND.snd_chrg:Stop()
				self.weaponSND.snd_chrg = nil
			end
			self.weaponSND:Play()
		else
			self.weaponSND:Stop()
		end
	end

	if not active then return end

	if Fire then
		self:SetHeat( 1 - self.charge / 100 )
	else
		self:SetHeat( 0 )
	end
end

function ENT:ChargeGun()
	self._doAttack = true
	self.charging = true

	if not IsValid( self.weaponSND ) then return end

	self.weaponSND.snd_chrg = CreateSound( self, "NPC_AttackHelicopter.ChargeGun" )
	self.weaponSND.snd_chrg:Play()
end

function ENT:FinishShoot()
	self._doAttack = nil
	self.charging = nil

	if not IsValid( self.weaponSND ) then return end

	self.weaponSND:Stop()

	if self.weaponSND.snd_chrg then
		self.weaponSND.snd_chrg:Stop()
		self.weaponSND.snd_chrg = nil
	end
end

function ENT:ShootGun()
	local T = CurTime()

	if (self.NextFire or 0) > T then return end

	self.NextFire = T + 0.03

	self.charge = self.charge - 0.9

	local Muzzle = self:GetAttachment( self:LookupAttachment( "muzzle" ) )

	if not Muzzle then return end

	local trace = self:GetEyeTrace()

	local bullet = {}
	bullet.Src 	= Muzzle.Pos
	bullet.Dir 	= (trace.HitPos - Muzzle.Pos):GetNormalized()
	bullet.Spread 	= Vector(0.06,0.06,0.06)
	bullet.TracerName = "lvs_pulserifle_tracer"
	bullet.Force	= 10
	bullet.HullSize 	= 6
	bullet.Damage	= 6
	bullet.Velocity = 15000
	bullet.Attacker 	= self:GetDriver()
	bullet.Callback = function(att, tr, dmginfo)
		local effectdata = EffectData()
		effectdata:SetOrigin( tr.HitPos )
		effectdata:SetNormal( tr.HitNormal )
		util.Effect( "AR2Impact", effectdata, true, true )
	end
	self:LVSFireBullet( bullet )
end

function ENT:InitWeapons()
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/mg.png")
	weapon.Ammo = -1
	weapon.Delay = 0
	weapon.HeatRateUp = 0
	weapon.HeatRateDown = 0
	weapon.StartAttack = function( ent )
		ent:ChargeGun()
	end
	weapon.FinishAttack = function( ent )
		ent:FinishShoot()
	end
	weapon.Attack = function( ent )
	end
	weapon.OnThink = function( ent, active )
		ent:SetPoseParameterTurret()
		ent:HandleShoot( ent._doAttack and active and ent:WeaponsInRange(), active )
	end
	weapon.OnSelect = function( ent ) ent:EmitSound("physics/metal/weapon_impact_soft3.wav") end
	self:AddWeapon( weapon )


	local weapon = {}
	weapon.Icon = Material("lvs/weapons/missile.png")
	weapon.Ammo = 30
	weapon.Delay = 0.25
	weapon.HeatRateUp = 0.25
	weapon.HeatRateDown = 0.25
	weapon.Attack = function( ent )

		ent.FireLeft = not ent.FireLeft

		local Target = ent:GetEyeTrace().HitPos

		local projectile = ents.Create( "lvs_missile" )
		projectile:SetPos( ent:LocalToWorld( Vector(17.36,50.89 * (self.FireLeft and 1 or -1),-59.39) ) )
		projectile:SetAngles( ent:GetAngles() )
		projectile:SetParent( ent )
		projectile:Spawn()
		projectile:Activate()
		projectile.GetTarget = function( missile ) return missile end
		projectile.GetTargetPos = function( missile )
			return Target
		end
		projectile:SetAttacker( IsValid( Driver ) and Driver or self )
		projectile:SetEntityFilter( ent:GetCrosshairFilterEnts() )
		projectile:SetSpeed( ent:GetVelocity():Length() + 4000 )
		projectile:SetDamage( 400 )
		projectile:SetRadius( 150 )
		projectile:Enable()
		projectile:EmitSound("npc/waste_scanner/grenade_fire.wav")

		ent:TakeAmmo()
	end
	weapon.OnSelect = function( ent )
		ent:EmitSound("weapons/shotgun/shotgun_cock.wav")
	end
	self:AddWeapon( weapon )


	local weapon = {}
	weapon.Icon = Material("lvs/weapons/light.png")
	weapon.UseableByAI = false
	weapon.Ammo = -1
	weapon.Delay = 0
	weapon.HeatRateUp = 0
	weapon.HeatRateDown = 1
	weapon.StartAttack = function( ent )
		if not ent.SetLightsEnabled then return end

		if ent:GetAI() then return end

		ent:SetLightsEnabled( not ent:GetLightsEnabled() )
		ent:EmitSound( "items/flashlight1.wav", 75, 105 )
	end
	self:AddWeapon( weapon )
end
