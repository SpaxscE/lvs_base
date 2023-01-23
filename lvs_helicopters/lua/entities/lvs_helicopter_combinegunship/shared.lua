
ENT.Base = "lvs_base_helicopter"

ENT.PrintName = "Combine Gunship"
ENT.Author = "Luna"
ENT.Information = "Combine Synth Gunship from Half Life 2 + Episodes"
ENT.Category = "[LVS] - Helicopters"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/combine_gunship.mdl"
ENT.GibModels = {
	"models/gibs/gunship_gibs_engine.mdl",
	"models/gibs/gunship_gibs_eye.mdl",
	"models/gibs/gunship_gibs_headsection.mdl",
	"models/gibs/gunship_gibs_midsection.mdl",
	"models/gibs/gunship_gibs_nosegun.mdl",
	"models/gibs/gunship_gibs_sensorarray.mdl",
	"models/gibs/gunship_gibs_tailsection.mdl",
	"models/gibs/gunship_gibs_wing.mdl",
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
		sound = "^npc/combine_gunship/engine_whine_loop1.wav",
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
	{
		sound = "npc/combine_gunship/engine_rotor_loop1.wav",
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
	self:AddDT( "Entity", "Body" )
end

function ENT:GetAimAngles()
	local Muzzle = self:GetAttachment( self:LookupAttachment( "muzzle" ) )

	if not Muzzle then return end

	local trace = self:GetEyeTrace()

	local AimAngles = self:WorldToLocalAngles( (trace.HitPos - Muzzle.Pos):GetNormalized():Angle() )

	return AimAngles
end

function ENT:WeaponsInRange()
	return self:AngleBetweenNormal( self:GetForward(), self:GetAimVector() ) < 75
end

function ENT:InitWeapons()
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/mg.png")
	weapon.Ammo = 2000
	weapon.Delay = 0.1
	weapon.HeatRateUp = 0.2
	weapon.HeatRateDown = 0.25
	weapon.StartAttack = function( ent )
		if not IsValid( ent.weaponSND ) then return end

		ent.weaponSND:EmitSound("NPC_CombineGunship.CannonStartSound")

		self.ShouldPlaySND = true
	end
	weapon.FinishAttack = function( ent )
		if not IsValid( ent.weaponSND ) then return end

		self.ShouldPlaySND = false

		ent.weaponSND:Stop()
		ent.weaponSND:EmitSound("NPC_CombineGunship.CannonStopSound")
	end
	weapon.Attack = function( ent )
		if not ent:WeaponsInRange() then

			ent.ShouldPlaySND = false

			return true
		end

		ent.ShouldPlaySND = true

		local Body = ent:GetBody()

		if not IsValid( Body ) then return end

		local Muzzle = Body:GetAttachment( Body:LookupAttachment( "muzzle" ) )

		if not Muzzle then return end

		local trace = ent:GetEyeTrace()

		local bullet = {}
		bullet.Src 	= Muzzle.Pos
		bullet.Dir 	= (trace.HitPos - Muzzle.Pos):GetNormalized()
		bullet.Spread 	= Vector(0.02,0.02,0.02)
		bullet.TracerName = "lvs_pulserifle_tracer_large"
		bullet.Force	= 10
		bullet.HullSize 	= 6
		bullet.Damage	= 18
		bullet.Velocity = 12000
		bullet.Attacker 	= self:GetDriver()
		bullet.Callback = function(att, tr, dmginfo)
			local effectdata = EffectData()
			effectdata:SetOrigin( tr.HitPos )
			effectdata:SetNormal( tr.HitNormal )
			util.Effect( "AR2Impact", effectdata, true, true )
		end
		self:LVSFireBullet( bullet )

		ent:TakeAmmo()
	end
	weapon.OnThink = function( ent, active )
		if not IsValid( ent.weaponSND ) then return end

		local ShouldPlay = ent.ShouldPlaySND and active

		if ent._oldShouldPlaySND ~= ShouldPlay then
			ent._oldShouldPlaySND = ShouldPlay
			if ShouldPlay then
				ent.weaponSND:Play()
			else
				ent.weaponSND:Stop()
			end
		end
	end
	weapon.OnSelect = function( ent ) ent:EmitSound("physics/metal/weapon_impact_soft3.wav") end
	self:AddWeapon( weapon )
end