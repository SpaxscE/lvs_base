
ENT.Base = "lvs_base_starfighter"

ENT.PrintName = "N1 Starfighter"
ENT.Author = "Luna"
ENT.Information = "Starfighter of the Royal Naboo Security Force"
ENT.Category = "[LVS] - Star Wars"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/naboostarfighter.mdl"

ENT.AITEAM = 2

ENT.MaxVelocity = 3000
ENT.MaxThrust = 3000

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 1

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.MaxHealth = 450
ENT.MaxShield = 400

function ENT:InitWeapons()
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/bullet.png")
	weapon.Ammo = 400
	weapon.Delay = 0.15
	weapon.HeatRateUp = 0.2
	weapon.HeatRateDown = 0.25
	weapon.Attack = function( ent )
		local bullet = {}
		bullet.Dir 	= ent:GetForward()
		bullet.Spread 	= Vector( 0.015,  0.015, 0 )
		bullet.TracerName = "lvs_laser_green"
		bullet.Force	= 10
		bullet.HullSize 	= 5
		bullet.Damage	= 10
		bullet.Velocity = 60000
		bullet.SplashDamage = 75
		bullet.SplashDamageRadius = 200
		bullet.Attacker 	= ent:GetDriver()
		bullet.Callback = function(att, tr, dmginfo) end

		for i = -1,1,2 do
			bullet.Src 	= ent:LocalToWorld( Vector(118.24,18.04 * i,49.96) )
			ent:LVSFireBullet( bullet )
		end

		ent:EmitSound("lvs/vehicles/naboo_n1_starfighter/fire.mp3" )
	end
	weapon.StartAttack = function( ent ) end
	weapon.FinishAttack = function( ent ) end
	weapon.OnSelect = function( ent ) end
	weapon.OnDeselect = function( ent ) end
	weapon.OnThink = function( ent, active ) end
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	weapon.OnRemove = function( ent ) end
	self:AddWeapon( weapon )
end

ENT.FlyByAdvance = 0.75
ENT.FlyBySound = "lvs/vehicles/naboo_n1_starfighter/flyby.wav" 
ENT.DeathSound = "lvs/vehicles/generic_starfighter/crash.wav"

ENT.EngineSounds = {
	{
		sound = "lvs/vehicles/naboo_n1_starfighter/loop.wav",
		Pitch = 80,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 40,
		FadeIn = 0,
		FadeOut = 1,
		FadeSpeed = 1.5,
		UseDoppler = true,
	},
}