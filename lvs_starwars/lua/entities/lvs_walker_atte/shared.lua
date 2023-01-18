
ENT.Base = "lvs_walker_atte_hoverscript"

ENT.PrintName = "ATTE"
ENT.Author = "Luna"
ENT.Information = "Assault Walker of the Galactic Republic"
ENT.Category = "[LVS] - Star Wars"

ENT.Spawnable		= true
ENT.AdminSpawnable	= false

ENT.MDL = "models/blu/atte.mdl"
ENT.GibModels = {
	"models/blu/atte.mdl",
	"models/blu/atte_rear.mdl",
	"models/blu/atte_bigfoot.mdl",
	"models/blu/atte_bigleg.mdl",
	"models/blu/atte_smallleg_part1.mdl",
	"models/blu/atte_smallleg_part2.mdl",
	"models/blu/atte_smallleg_part3.mdl"
}

ENT.AITEAM = 2

ENT.MaxHealth = 12000

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.HoverHeight = 140
ENT.HoverTraceLength = 225
ENT.HoverHullRadius = 20

ENT.TurretTurnRate = 100

ENT.LAATC_PICKUPABLE = true
ENT.LAATC_DROP_IN_AIR = true
ENT.LAATC_PICKUP_POS = Vector(-220,0,-115)
ENT.LAATC_PICKUP_Angle = Angle(0,0,0)

ENT.CanMoveOn = {
	["func_door"] = true,
	["func_movelinear"] = true,
	["prop_physics"] = true,
}

ENT.lvsShowInSpawner = true

function ENT:OnSetupDataTables()
	self:AddDT( "Entity", "RearEntity" )
	self:AddDT( "Entity", "TurretSeat" )
	self:AddDT( "Entity", "GunnerSeat" )

	self:AddDT( "Float", "Move" )
	self:AddDT( "Bool", "IsMoving" )
	self:AddDT( "Bool", "IsCarried" )
	self:AddDT( "Bool", "IsRagdoll" )
	self:AddDT( "Vector", "AIAimVector" )

	self:AddDT( "Float", "TurretPitch" )
	self:AddDT( "Float", "TurretYaw" )

	if SERVER then
		self:NetworkVarNotify( "IsCarried", self.OnIsCarried )
	end
end

function ENT:GetContraption()
	return {self, self:GetRearEntity()}
end

function ENT:GetEyeTrace()
	local startpos = self:GetPos()

	local pod = self:GetDriverSeat()

	if IsValid( pod ) then
		startpos = pod:LocalToWorld( Vector(0,0,33) )
	end

	local trace = util.TraceLine( {
		start = startpos,
		endpos = (startpos + self:GetAimVector() * 50000),
		filter = self:GetCrosshairFilterEnts()
	} )

	return trace
end

function ENT:GetAimVector()
	if self:GetAI() then
		return self:GetAIAimVector()
	end

	local Driver = self:GetDriver()

	if IsValid( Driver ) then
		return Driver:GetAimVector()
	else
		return self:GetForward()
	end
end

function ENT:GetAimAngles()
	local trace = self:GetEyeTrace()

	local AimAngles = self:WorldToLocalAngles( (trace.HitPos - self:LocalToWorld( Vector(265,0,100)) ):GetNormalized():Angle() )

	local ID = self:LookupAttachment( "muzzle_right_up" )
	local Muzzle = self:GetAttachment( ID )

	if not Muzzle then return AimAngles, trace.HitPos, false end

	local DirAng = self:WorldToLocalAngles( (trace.HitPos - self:GetDriverSeat():LocalToWorld( Vector(0,0,33) ) ):Angle() )

	return AimAngles, trace.HitPos, (math.abs( DirAng.p ) < 12 and math.abs( DirAng.y ) < 35)
end

function ENT:InitWeapons()
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/hmg.png")
	weapon.Ammo = 1000
	weapon.Delay = 0.1
	weapon.HeatRateUp = 2.5
	weapon.HeatRateDown = 1
	weapon.Attack = function( ent )
		if ent:GetIsCarried() then ent:SetHeat( 0 ) return true end

		local ID1 = ent:LookupAttachment( "muzzle_right_up" )
		local ID2 = ent:LookupAttachment( "muzzle_left_up" )
		local ID3 = ent:LookupAttachment( "muzzle_right_dn" )
		local ID4 = ent:LookupAttachment( "muzzle_left_dn" )

		local Muzzle1 = ent:GetAttachment( ID3 )
		local Muzzle2 = ent:GetAttachment( ID2 )
		local Muzzle3 = ent:GetAttachment( ID1 )
		local Muzzle4 = ent:GetAttachment( ID4 )

		if not Muzzle1 or not Muzzle2 or not Muzzle3 or not Muzzle4 then return end

		local FirePos = {
			[1] = Muzzle1,
			[2] = Muzzle2,
			[3] = Muzzle3,
			[4] = Muzzle4,
		}

		ent.FireIndex = ent.FireIndex and ent.FireIndex + 1 or 2
	
		if ent.FireIndex > #FirePos then
			ent.FireIndex = 1
		end

		local AimAngles, AimPos, InRange = ent:GetAimAngles()

		local Pos = FirePos[ent.FireIndex].Pos
		local Dir = (AimPos - Pos):GetNormalized()

		if not InRange then return true end

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

		if not IsValid( ent.SNDPrimary ) then return end

		ent.SNDPrimary:PlayOnce( 100 + math.cos( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )
	end
	weapon.OnThink = function( ent, active )
		local base = ent:GetVehicle()

		if IsValid( base ) and base:GetIsCarried() then return end

		local AimAngles = ent:GetAimAngles()

		ent:SetPoseParameter("frontgun_pitch", math.Clamp(AimAngles.p,-5,5) )
		ent:SetPoseParameter("frontgun_yaw", AimAngles.y )
	end
	self:AddWeapon( weapon )

	self:InitTurret()
	self:InitGunner()
end