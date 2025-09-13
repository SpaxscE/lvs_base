
ENT.Base = "lvs_base_wheeldrive_trailer"

ENT.PrintName = "FlaK 38"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"

ENT.VehicleCategory = "Artillery"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/flak38.mdl"

ENT.GibModels = {
	"models/blu/flak_db.mdl",
	"models/blu/flak_d1.mdl",
	"models/blu/flak_d2.mdl",
	"models/blu/flak_d3.mdl",
	"models/blu/flak_d4.mdl",
	"models/blu/flak_d5.mdl",
	"models/blu/flak_d6.mdl",
}

ENT.lvsShowInSpawner = false

ENT.AITEAM = 1

ENT.PhysicsWeightScale = 1
ENT.PhysicsMass = 450
ENT.PhysicsInertia = Vector(475,452,162)
ENT.PhysicsDampingSpeed = 4000
ENT.PhysicsDampingForward = false
ENT.PhysicsDampingReverse = false

ENT.MaxHealth = 400

function ENT:InitWeapons()
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/flak_he.png")
	weapon.Ammo = 1500
	weapon.Delay = 0.25
	weapon.HeatRateUp = 0.25
	weapon.HeatRateDown = 0.5
	weapon.Attack = function( ent )

		if not ent:TurretInRange() then
			return true
		end

		local ID = ent:LookupAttachment( "muzzle" )

		local Muzzle = ent:GetAttachment( ID )

		if not Muzzle then return end

		local Pos = Muzzle.Pos
		local Dir = (ent:GetEyeTrace().HitPos - Pos):GetNormalized()

		local bullet = {}
		bullet.Src 	= Pos
		bullet.Dir 	= Dir
		bullet.Spread 	= Vector(0,0,0)
		bullet.TracerName = "lvs_tracer_autocannon"
		bullet.Force	= 3900
		bullet.HullSize 	= 50 * math.max( Dir.z, 0 )
		bullet.Damage	= 40
		bullet.EnableBallistics = true
		bullet.SplashDamage = 20
		bullet.SplashDamageRadius = 100
		bullet.SplashDamageEffect = "lvs_defence_explosion"
		bullet.SplashDamageType = DMG_SONIC
		bullet.Velocity = 50000
		bullet.Attacker 	= ent:GetDriver()
		ent:LVSFireBullet( bullet )

		local effectdata = EffectData()
		effectdata:SetOrigin( bullet.Src )
		effectdata:SetNormal( bullet.Dir )
		effectdata:SetEntity( ent )
		util.Effect( "lvs_muzzle", effectdata )

		ent:PlayAnimation( "fire" )

		ent:TakeAmmo( 1 )

		if not IsValid( ent.SNDTurret ) then return end

		ent.SNDTurret:PlayOnce( 100 + math.cos( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )
	end
	weapon.OnOverheat = function( ent )
		ent:EmitSound("lvs/vehicles/222/cannon_overheat.wav")
	end
	weapon.HudPaint = function( ent, X, Y, ply )
		local Pos2D = ent:GetEyeTrace().HitPos:ToScreen()

		local Col =  ent:TurretInRange() and Color(255,255,255,255) or Color(255,0,0,255)

		ent:PaintCrosshairCenter( Pos2D, Col )
		ent:PaintCrosshairSquare( Pos2D, Col )
		ent:LVSPaintHitMarker( Pos2D )
	end
	self:AddWeapon( weapon )
end

