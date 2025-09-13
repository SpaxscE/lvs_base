
include("entities/lvs_tank_wheeldrive/modules/sh_turret.lua")

ENT.TurretFakeBarrel = true
ENT.TurretFakeBarrelRotationCenter =  Vector(0,0,40)

ENT.TurretAimRate = 80

ENT.TurretRotationSound = "common/null.wav"

ENT.TurretPitchPoseParameterName = "cannon_pitch"
ENT.TurretPitchMin = -30
ENT.TurretPitchMax = 90
ENT.TurretPitchMul = 1
ENT.TurretPitchOffset = 0

ENT.TurretYawPoseParameterName = "cannon_yaw"
ENT.TurretYawMul = -1
ENT.TurretYawOffset = 180

function ENT:TurretInRange()
	local ID = self:LookupAttachment( "muzzle" )

	local Muzzle = self:GetAttachment( ID )

	if not Muzzle then return true end

	local Dir1 = Muzzle.Ang:Forward()
	local Dir2 = self:GetAimVector() 

	return self:AngleBetweenNormal( Dir1, Dir2 ) < 5
end