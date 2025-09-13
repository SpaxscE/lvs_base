
include("sh_turret.lua")

ENT.TurretRotationSound = "vehicles/tank_turret_loop1.wav"

ENT.TurretElevationSound = "vehicles/tank_turret_loop2.wav"

if CLIENT then return end

function ENT:CalcTurretSound( Pitch, Yaw, AimRate )
	local DeltaPitch = Pitch - self:GetTurretPitch()
	local DeltaYaw = Yaw - self:GetTurretYaw()

	local PitchVolume = math.abs( DeltaPitch ) / AimRate
	local YawVolume = math.abs( DeltaYaw ) / AimRate

	local PlayPitch = PitchVolume > 0.95
	local PlayYaw = YawVolume > 0.95

	local TurretArmor = self:GetTurretArmor()
	local Destroyed = self:GetTurretDestroyed()

	if Destroyed and (PlayPitch or PlayYaw) and IsValid( TurretArmor ) then
		local T = CurTime()

		if (self._NextTurDMGfx or 0) < T then
			self._NextTurDMGfx = T + 0.1

			local effectdata = EffectData()
			effectdata:SetOrigin( TurretArmor:GetPos() )
			effectdata:SetNormal( self:GetUp() )
			effectdata:SetRadius( 0 )
			util.Effect( "cball_bounce", effectdata, true, true )
		end
	end

	if Destroyed and (PlayPitch or PlayYaw) then
		self:StartTurretSoundDMG()
	else
		self:StopTurretSoundDMG()
	end

	if PlayPitch then
		self:DoElevationSound()
	end

	if PlayYaw then
		self:DoRotationSound()
	end

	if self:GetRotationSoundTime() > 0 then
		local sound = self:StartRotationSound()
		local volume = YawVolume
		local pitch = 90 + 10 * (1 - volume)

		sound:ChangeVolume( volume * 0.25, 0.25 )
		sound:ChangePitch( pitch, 0.25 )
	else
		self:StopRotationSound()
	end

	if self:GetElevationSoundTime() > 0 then
		local sound = self:StartElevationSound()
		local volume = PitchVolume
		local pitch = 90 + 10 * (1 - volume)

		sound:ChangeVolume( volume * 0.25, 0.25 )
		sound:ChangePitch( pitch, 0.25 )
	else
		self:StopElevationSound()
	end
end

function ENT:DoRotationSound()
	if not self._RotationSound then self._RotationSound = 0 end

	self._RotationSound = CurTime() + 1.1
end

function ENT:DoElevationSound()
	if not self._ElevationSound then self._ElevationSound = 0 end

	self._ElevationSound = CurTime() + 1.1
end

function ENT:GetRotationSoundTime()
	if not self._RotationSound then return 0 end

	return math.max(self._RotationSound - CurTime(),0) / 1
end

function ENT:GetElevationSoundTime()
	if not self._ElevationSound then return 0 end

	return math.max(self._ElevationSound - CurTime(),0) / 1
end

function ENT:StopRotationSound()
	if not self._turretRotSND then return end

	self._turretRotSND:Stop()
	self._turretRotSND = nil
end

function ENT:StopElevationSound()
	if not self._turretElevSND then return end

	self._turretElevSND:Stop()
	self._turretElevSND = nil
end

function ENT:StartTurretSoundDMG()
	if self._turretSNDdmg then return self._turretSNDdmg end

	self._turretSNDdmg = CreateSound( self, self.TurretRotationSoundDamaged  )
	self._turretSNDdmg:PlayEx(0.5, 100)

	return self._turretSNDdmg
end

function ENT:StopTurretSoundDMG()
	if not self._turretSNDdmg then return end

	self._turretSNDdmg:Stop()
	self._turretSNDdmg = nil
end

function ENT:StartRotationSound()
	if self._turretRotSND then return self._turretRotSND end

	self._turretRotSND = CreateSound( self, self.TurretRotationSound  )
	self._turretRotSND:PlayEx(0,100)

	return self._turretRotSND
end

function ENT:StartElevationSound()
	if self._turretElevSND then return self._turretElevSND end

	self._turretElevSND = CreateSound( self, self.TurretElevationSound  )
	self._turretElevSND:PlayEx(0,100)

	return self._turretElevSND
end

function ENT:StopTurretSound()
	self:StopElevationSound()
	self:StopRotationSound()

	self:StopTurretSoundDMG()
end

function ENT:OnRemoved()
	self:StopTurretSound()
end
