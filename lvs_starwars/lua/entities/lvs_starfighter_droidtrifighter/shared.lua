
ENT.Base = "lvs_base_starfighter"

ENT.PrintName = "Droid Tri-Fighter"
ENT.Author = "Luna"
ENT.Information = "Droid Starfighter of the Separatists"
ENT.Category = "[LVS] - Star Wars"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/salza/droidtrifighter.mdl"
ENT.GibModels = {
	"models/salza/tridroid_gib1.mdl",
	"models/salza/tridroid_gib2.mdl",
	"models/salza/tridroid_gib3.mdl",
	"models/salza/tridroid_gib4.mdl",
	"models/salza/tridroid_gib5.mdl",
}

ENT.AITEAM = 1

ENT.MaxVelocity = 2150
ENT.MaxThrust = 2150

ENT.ThrustVtol = 55
ENT.ThrustRateVtol = 3

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 1.25

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.MaxHealth = 250

function ENT:InitWeapons()
	self.FirePositions = {
		Vector(114.58,0,86.08),
		Vector(112.54,74.47,-42.69),
		Vector(112.54,-74.47,-42.69),
	}

	local weapon = {}
	weapon.Icon = Material("lvs/weapons/mg.png")
	weapon.Ammo = 1200
	weapon.Delay = 0.1
	weapon.HeatRateUp = 0.25
	weapon.HeatRateDown = 1
	weapon.Attack = function( ent )
		ent.NumPrim = ent.NumPrim and ent.NumPrim + 1 or 1
		if ent.NumPrim > #ent.FirePositions then ent.NumPrim = 1 end

		local pod = ent:GetDriverSeat()

		if not IsValid( pod ) then return end

		local startpos = pod:LocalToWorld( pod:OBBCenter() )
		local trace = util.TraceHull( {
			start = startpos,
			endpos = (startpos + ent:GetForward() * 50000),
			mins = Vector( -10, -10, -10 ),
			maxs = Vector( 10, 10, 10 ),
			filter = ent:GetCrosshairFilterEnts()
		} )

		local bullet = {}
		bullet.Src 	= ent:LocalToWorld( ent.FirePositions[ent.NumPrim] )
		bullet.Dir 	= (trace.HitPos - bullet.Src):GetNormalized()
		bullet.Spread 	= Vector( 0.02,  0.02, 0 )
		bullet.TracerName = "lvs_laser_red"
		bullet.Force	= 10
		bullet.HullSize 	= 40
		bullet.Damage	= 10
		bullet.Velocity = 60000
		bullet.Attacker 	= ent:GetDriver()
		bullet.Callback = function(att, tr, dmginfo)
			local effectdata = EffectData()
				effectdata:SetStart( Vector(255,50,50) ) 
				effectdata:SetOrigin( tr.HitPos )
				effectdata:SetNormal( tr.HitNormal )
			util.Effect( "lvs_laser_impact", effectdata )
		end
		ent:LVSFireBullet( bullet )

		local effectdata = EffectData()
		effectdata:SetStart( Vector(255,50,50) )
		effectdata:SetOrigin( bullet.Src )
		effectdata:SetNormal( ent:GetForward() )
		effectdata:SetEntity( ent )
		util.Effect( "lvs_muzzle_colorable", effectdata )

		ent:TakeAmmo()

		ent.PrimarySND:PlayOnce( 100 + math.cos( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )
	end
	weapon.OnSelect = function( ent ) ent:EmitSound("physics/metal/weapon_impact_soft3.wav") end
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	self:AddWeapon( weapon )


	local weapon = {}
	weapon.Icon = Material("lvs/weapons/hmg.png")
	weapon.Ammo = 200
	weapon.Delay = 0.1
	weapon.HeatRateUp = 1.5
	weapon.HeatRateDown = 1
	weapon.Attack = function( ent )
		local bullet = {}
		bullet.Src 	= ent:LocalToWorld( Vector(152.24,0,0) )
		bullet.Dir 	= ent:GetForward()
		bullet.Spread 	= Vector( 0.015,  0.015, 0 )
		bullet.TracerName = "lvs_laser_red"
		bullet.Force	= 10
		bullet.HullSize 	= 25
		bullet.Damage	= 40
		bullet.SplashDamage = 40
		bullet.SplashDamageRadius = 200
		bullet.Velocity = 30000
		bullet.Attacker 	= ent:GetDriver()
		bullet.Callback = function(att, tr, dmginfo)
			local effectdata = EffectData()
				effectdata:SetStart( Vector(255,0,0) ) 
				effectdata:SetOrigin( tr.HitPos )
			util.Effect( "lvs_laser_explosion", effectdata )
		end
		ent:LVSFireBullet( bullet )

		local effectdata = EffectData()
		effectdata:SetStart( Vector(255,50,50) )
		effectdata:SetOrigin( bullet.Src )
		effectdata:SetNormal( ent:GetForward() )
		effectdata:SetEntity( ent )
		util.Effect( "lvs_muzzle_colorable", effectdata )

		ent:TakeAmmo()

		ent.SecondarySND:PlayOnce( 100 + math.cos( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )
	end
	weapon.OnSelect = function( ent ) ent:EmitSound("physics/metal/weapon_impact_soft3.wav") end
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	self:AddWeapon( weapon )

	self:AddWeapon( LVS:GetWeaponPreset( "TURBO" ) )
end

ENT.EngineSounds = {
	{
		sound = "lvs/vehicles/droidtrifighter/loop.wav",
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
		sound = "^lvs/vehicles/vulturedroid/dist.wav",
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
		SoundLevel = 100,
	},
}