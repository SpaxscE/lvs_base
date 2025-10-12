AddCSLuaFile()

ENT.Type            = "anim"
ENT.DoNotDuplicate = true

ENT._LVS = true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )
	self:NetworkVar( "Entity",1, "DoorHandler" )

	self:NetworkVar( "Float",1, "HP" )
	self:NetworkVar( "Float",2, "MaxHP" )

	self:NetworkVar( "Bool",0, "Destroyed" )

	if SERVER then
		self:SetMaxHP( 100 )
		self:SetHP( 100 )
	end
end

if SERVER then
	function ENT:Initialize()	
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false )
	end

	function ENT:CheckWater( Base )
		local EntTable = self:GetTable()

		if bit.band( util.PointContents( self:GetPos() ), CONTENTS_WATER ) ~= CONTENTS_WATER then
			if EntTable.CountWater then
				EntTable.CountWater = nil
			end

			return
		end

		if Base.WaterLevelAutoStop > 3 then return end

		EntTable.CountWater = (EntTable.CountWater or 0) + 1

		if EntTable.CountWater < 4 then return end

		Base:StopEngine()
	end

	function ENT:Think()

		local Base = self:GetBase()

		if IsValid( Base ) and Base:GetEngineActive() then
			self:CheckWater( Base )
		end

		self:NextThink( CurTime() + 1 )

		return true
	end

	function ENT:OnDestroyed()
		local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
		util.Effect( "lvs_trailer_explosion", effectdata, true, true )

		self:EmitSound("physics/metal/metal_box_break"..math.random(1,2)..".wav",75,100,1)

		local base = self:GetBase()

		if not IsValid( base ) then return end

		net.Start( "lvs_car_break" )
			net.WriteEntity( base )
		net.Broadcast()

		if base:GetEngineActive() then
			self:EmitSound("npc/manhack/bat_away.wav",75,100,0.5)

			timer.Simple(1, function()
				if not IsValid( self ) then return end
				self:EmitSound("npc/manhack/gib.wav",75,90,1)
			end)
		end
	
		base:ShutDownEngine()
	end

	function ENT:TakeTransmittedDamage( dmginfo )
		if self:GetDestroyed() then return end

		local Damage = dmginfo:GetDamage()

		if Damage <= 0 then return end

		local CurHealth = self:GetHP()

		local NewHealth = math.Clamp( CurHealth - Damage, 0, self:GetMaxHP() )

		self:SetHP( NewHealth )

		if NewHealth <= 0 then
			self:SetDestroyed( true )

			self:OnDestroyed()
		end
	end

	function ENT:OnTakeDamage( dmginfo )
	end

	function ENT:UpdateTransmitState() 
		return TRANSMIT_ALWAYS
	end

	function ENT:OnRemove()
		local base = self:GetBase()

		if not IsValid( base ) or base.ExplodedAlready then return end

		base:SetMaxThrottle( 1 )
	end

	return
end

ENT._oldEnActive = false
ENT._ActiveSounds = {}

function ENT:Initialize()
end

function ENT:StopSounds()
	for id, sound in pairs( self._ActiveSounds ) do
		if istable( sound ) then
			for _, snd in pairs( sound ) do
				if snd then
					snd:Stop()
				end
			end
		else
			sound:Stop()
		end
		self._ActiveSounds[ id ] = nil
	end
end

function ENT:OnEngineActiveChanged( Active )
	if not Active then self:StopSounds() return end

	for id, data in pairs( self.EngineSounds ) do
		if not isstring( data.sound ) then continue end

		self.EngineSounds[ id ].Pitch = data.Pitch or 100
		self.EngineSounds[ id ].PitchMul = data.PitchMul or 100
		self.EngineSounds[ id ].Volume = data.Volume or 1
		self.EngineSounds[ id ].SoundType = data.SoundType or LVS.SOUNDTYPE_NONE
		self.EngineSounds[ id ].UseDoppler = data.UseDoppler ~= false
		self.EngineSounds[ id ].SoundLevel = data.SoundLevel or 85

		if data.sound_int and data.sound_int ~= data.sound then
			local sound = CreateSound( self, data.sound )
			sound:SetSoundLevel( data.SoundLevel )
			sound:PlayEx(0,100)

			if data.sound_int == "" then
				self._ActiveSounds[ id ] = {
					ext = sound,
					int = false,
				}
			else
				local sound_interior = CreateSound( self, data.sound_int )
				sound_interior:SetSoundLevel( data.SoundLevel )
				sound_interior:PlayEx(0,100)

				self._ActiveSounds[ id ] = {
					ext = sound,
					int = sound_interior,
				}
			end
		else
			local sound = CreateSound( self, data.sound )
			sound:SetSoundLevel( data.SoundLevel )
			sound:PlayEx(0,100)

			self._ActiveSounds[ id ] = sound
		end
	end
end

function ENT:SetGear( newgear )
	self._CurGear = newgear
end

function ENT:GetGear()
	return (self._CurGear or 1)
end

function ENT:SetRPM( rpm )
	self._CurRPM = rpm
end

function ENT:GetRPM()
	local base = self:GetBase()

	if not IsValid( base ) or not base:GetEngineActive() then return 0 end

	return math.abs(self._CurRPM or 0)
end

function ENT:GetClutch()
	return self._ClutchActive == true
end

function ENT:SetEngineVolume( volume )
	self._engineVolume = volume

	return volume
end

function ENT:GetEngineVolume()
	return (self._engineVolume or 0)
end

function ENT:HandleEngineSounds( vehicle )
	local ply = LocalPlayer()
	local pod = ply:GetVehicle()
	local Throttle = vehicle:GetThrottle()
	local MaxThrottle = vehicle:GetMaxThrottle()
	local Doppler = vehicle:CalcDoppler( ply )

	local EntTable = self:GetTable()

	local DrivingMe = ply:lvsGetVehicle() == vehicle

	local IsManualTransmission = vehicle:IsManualTransmission()

	local VolumeSetNow = false

	local FirstPerson = false
	if IsValid( pod ) then
		local ThirdPerson = pod:GetThirdPersonMode()

		if ThirdPerson ~= EntTable._lvsoldTP then
			EntTable._lvsoldTP = ThirdPerson
			VolumeSetNow = DrivingMe
		end

		FirstPerson = DrivingMe and not ThirdPerson
	end

	if DrivingMe ~= EntTable._lvsoldDrivingMe then
		EntTable._lvsoldDrivingMe = DrivingMe

		self:StopSounds()

		EntTable._oldEnActive = nil

		return
	end

	local FT = RealFrameTime()
	local T = CurTime()

	local Reverse = vehicle:GetReverse()
	local vehVel = vehicle:GetVelocity():Length()
	local wheelVel = vehicle:GetWheelVelocity()

	local IsHandBraking = wheelVel == 0 and vehicle:GetNWHandBrake()

	local Vel = 0
	local Wobble = 0

	if vehVel / wheelVel <= 0.8 then
		Vel = wheelVel
		Wobble = -1
	else
		Vel = vehVel
	end

	local NumGears = vehicle.TransGears
	local MaxGear = Reverse and vehicle.TransGearsReverse or NumGears

	local VolumeValue = self:SetEngineVolume( LVS.EngineVolume )
	local PitchValue = vehicle.MaxVelocity / NumGears

	local DesiredGear = 1

	local subGeared = vehVel - (EntTable._smVelGeared or 0)
	local VelocityGeared = vehVel

	if IsHandBraking then
		VelocityGeared = PitchValue * Throttle
		Vel = VelocityGeared
	end

	--[[ workaround ]]-- TODO: Fix it properly
	if vehicle:Sign( subGeared ) < 0 then
		self._smVelGeared = (EntTable._smVelGeared or 0) + subGeared * FT * 5
		VelocityGeared = EntTable._smVelGeared
	else
		EntTable._smVelGeared = VelocityGeared 
	end
	--[[ workaround ]]--


	while (VelocityGeared > PitchValue) and DesiredGear< NumGears do
		VelocityGeared = VelocityGeared - PitchValue

		DesiredGear = DesiredGear + 1
	end

	if IsManualTransmission then
		EntTable._NextShift = 0

		if IsHandBraking then
			DesiredGear = 1
		else
			DesiredGear = vehicle:GetGear()
		end
	else
		DesiredGear = math.Clamp( DesiredGear, 1, MaxGear )
	end

	local CurrentGear = math.Clamp(self:GetGear(),1,NumGears)

	local RatioThrottle = 0.5 + (Throttle ^ 2) * 0.5

	local RatioPitch = math.max(Vel - (CurrentGear - 1) * PitchValue,0)

	if (not IsManualTransmission or IsHandBraking) then --and CurrentGear ~= MaxGear then
		RatioPitch = math.min( PitchValue, RatioPitch )
	end

	local preRatio = math.Clamp(Vel / (PitchValue * (CurrentGear - 1)),0,1)
	local Ratio = (RatioPitch / PitchValue) * RatioThrottle

	if CurrentGear ~= DesiredGear then
		if (EntTable._NextShift or 0) < T then
			EntTable._NextShift = T + vehicle.TransMinGearHoldTime

			if CurrentGear < DesiredGear then
				EntTable._ShiftTime = T + vehicle.TransShiftSpeed
				EntTable._WobbleTime = T + vehicle.TransWobbleTime
			end

			vehicle:OnChangeGear( CurrentGear, DesiredGear )

			self:SetGear( DesiredGear )
		end
	end

	if Throttle > 0.5 then
		local FullThrottle = Throttle >= 0.99

		if EntTable._oldFullThrottle ~= FullThrottle then
			EntTable._oldFullThrottle = FullThrottle

			if FullThrottle then
				EntTable._WobbleTime = T + vehicle.TransWobbleTime
			end
		end

		if Wobble == 0 then
			local Mul = math.Clamp( (EntTable._WobbleTime or 0) - T, 0, 1 )

			Wobble = (math.cos( T * (20 + CurrentGear * 10) * vehicle.TransWobbleFrequencyMultiplier ) * math.max(1 - Ratio,0) * vehicle.TransWobble * math.max(1 - vehicle:AngleBetweenNormal( vehicle:GetUp(), Vector(0,0,1) ) / 5,0) ^ 2) * Mul 
		end
	end

	local FadeSpeed = 0.15
	local PlayIdleSound = CurrentGear == 1 and Throttle == 0 and Ratio < 0.5
	local rpmSet = false
	local rpmRate = PlayIdleSound and 1 or 5

	if IsManualTransmission and (self:GetRPM() < vehicle.EngineIdleRPM or EntTable.ForcedIdle) then
		if EntTable.ForcedIdle then
			self:SetRPM(  vehicle.EngineIdleRPM )
			PlayIdleSound = true
			rpmRate = 1
			EntTable._ClutchActive = true

			if Ratio > 0 or Throttle > 0 then
				EntTable.ForcedIdle = nil
			end
		else
			if Ratio == 0 and Throttle == 0 then
				EntTable.ForcedIdle = true
			end
		end
	end

	EntTable._smIdleVolume = EntTable._smIdleVolume and EntTable._smIdleVolume + ((PlayIdleSound and 1 or 0) - EntTable._smIdleVolume) * FT or 0
	EntTable._smRPMVolume = EntTable._smRPMVolume and EntTable._smRPMVolume + ((PlayIdleSound and 0 or 1) - EntTable._smRPMVolume) * FT * rpmRate or 0

	if (EntTable._ShiftTime or 0) > T or PlayIdleSound then
		PitchAdd = 0
		Ratio = 0
		Wobble = 0
		Throttle = 0
		FadeSpeed = PlayIdleSound and 0.25 or 3
		EntTable._ClutchActive = true
	else
		EntTable._ClutchActive = false
	end

	if IsManualTransmission and IsHandBraking then
		EntTable._ClutchActive = true
	end

	if not EntTable.EnginePitchStep then
		EntTable.EnginePitchStep = math.Clamp(vehicle.EngineMaxRPM / 10000, 0.6, 0.9)

		return
	end

	for id, sound in pairs( EntTable._ActiveSounds ) do
		if not sound then continue end

		local data = EntTable.EngineSounds[ id ]

		local Vol03 = data.Volume * 0.3
		local Vol02 = data.Volume * 0.2

		local Volume = (Vol02 + Vol03 * Ratio + (Vol02 * Ratio + Vol03) * Throttle) * VolumeValue

		local PitchAdd = CurrentGear * (data.PitchMul / NumGears * EntTable.EnginePitchStep) * MaxThrottle

		local Pitch = data.Pitch + PitchAdd + (data.PitchMul - PitchAdd) * Ratio + Wobble
		local PitchMul = data.UseDoppler and Doppler or 1

		if IsManualTransmission and Ratio == 0 and preRatio < 1 and not PlayIdleSound then
			Pitch = (PitchAdd / CurrentGear) * (1 - preRatio) + (data.Pitch + PitchAdd) * preRatio + Wobble
		end

		local SoundType = data.SoundType

		if SoundType ~= LVS.SOUNDTYPE_ALL then
			Volume = Volume  * EntTable._smRPMVolume

			if SoundType == LVS.SOUNDTYPE_IDLE_ONLY then
				Volume = EntTable._smIdleVolume * data.Volume * VolumeValue
				Pitch = data.Pitch + data.PitchMul * Ratio
			end

			if SoundType == LVS.SOUNDTYPE_REV_UP then
				Volume = Throttle == 0 and 0 or Volume
			end

			if SoundType == LVS.SOUNDTYPE_REV_DOWN then
				Volume =  Throttle == 0 and Volume or 0
			end
		end

		if istable( sound ) then
			sound.ext:ChangePitch( math.Clamp( Pitch * PitchMul, 0, 255 ), FadeSpeed )
	
			if sound.int then
				sound.int:ChangePitch( math.Clamp( Pitch, 0, 255 ), FadeSpeed )
			end

			local fadespeed = VolumeSetNow and 0 or 0.15

			if FirstPerson then
				sound.ext:ChangeVolume( 0, 0 )

				if vehicle:HasActiveSoundEmitters() then
					Volume = Volume * 0.25
					fadespeed = fadespeed * 0.5
				end

				if sound.int then sound.int:ChangeVolume( Volume, fadespeed ) end
			else
				sound.ext:ChangeVolume( Volume, fadespeed )
				if sound.int then sound.int:ChangeVolume( 0, 0 ) end
			end
		else
			sound:ChangePitch( math.Clamp( Pitch * PitchMul, 0, 255 ), FadeSpeed )
			sound:ChangeVolume( Volume, 0.15 )
		end

		if rpmSet then continue end

		if PlayIdleSound then self:SetRPM( vehicle.EngineIdleRPM ) rpmSet = true continue end

		if data.SoundType == LVS.SOUNDTYPE_IDLE_ONLY then continue end

		if istable( sound ) then
			if sound.int then
				rpmSet = true
				self:SetRPM( vehicle.EngineIdleRPM + ((sound.int:GetPitch() - data.Pitch) / data.PitchMul) * (vehicle.EngineMaxRPM - vehicle.EngineIdleRPM) )
			else
				if not sound.ext then continue end

				rpmSet = true
				self:SetRPM( vehicle.EngineIdleRPM + ((sound.ext:GetPitch() - data.Pitch) / data.PitchMul) * (vehicle.EngineMaxRPM - vehicle.EngineIdleRPM) )
			end
		else
			rpmSet = true
			self:SetRPM( vehicle.EngineIdleRPM + ((sound:GetPitch() - data.Pitch) / data.PitchMul) * (vehicle.EngineMaxRPM - vehicle.EngineIdleRPM) )
		end
	end
end

function ENT:Think()
	local vehicle = self:GetBase()

	if not IsValid( vehicle ) then return end

	local EntTable = self:GetTable()

	self:DamageFX( vehicle )

	if not EntTable.EngineSounds then
		EntTable.EngineSounds = vehicle.EngineSounds

		return
	end

	local EngineActive = vehicle:GetEngineActive()

	if EntTable._oldEnActive ~= EngineActive then
		EntTable._oldEnActive = EngineActive

		self:OnEngineActiveChanged( EngineActive )
	end

	if EngineActive then
		self:HandleEngineSounds( vehicle )
		self:ExhaustFX( vehicle )
	end
end

function ENT:RemoveFireSound()
	if self.FireBurnSND then
		self.FireBurnSND:Stop()
		self.FireBurnSND = nil
	end

	self.ShouldStopFire = nil
end

function ENT:StopFireSound()
	if self.ShouldStopFire or not self.FireBurnSND then return end

	self.ShouldStopFire = true

	self:EmitSound("ambient/fire/mtov_flame2.wav")

	self.FireBurnSND:ChangeVolume( 0, 0.5 )

	timer.Simple( 1, function()
		if not IsValid( self ) then return end

		self:RemoveFireSound()
	end )
end

function ENT:StartFireSound()
	if self.ShouldStopFire or self.FireBurnSND then return end

	self.FireBurnSND = CreateSound( self, "ambient/fire/firebig.wav" )
	self.FireBurnSND:PlayEx(0,100)
	self.FireBurnSND:ChangeVolume( LVS.EngineVolume, 1 )

	self:EmitSound("ambient/fire/ignite.wav")
end

function ENT:OnRemove()
	self:StopSounds()
	self:RemoveFireSound()
end

function ENT:Draw()
end

function ENT:DrawTranslucent()
end

function ENT:ExhaustFX( vehicle )
	if not istable( vehicle.ExhaustPositions ) then return end

	local T = CurTime()

	if (self.nextEFX or 0) > T then return end

	self.nextEFX = T + 0.1

	vehicle:DoExhaustFX( (self:GetRPM() / vehicle.EngineMaxRPM) * 0.5 + 0.5 * vehicle:GetThrottle() )
end

function ENT:DamageFX( vehicle )
	local T = CurTime()
	local HP = self:GetHP()
	local MaxHP = self:GetMaxHP()

	local EntTable = self:GetTable()

	if HP >= MaxHP * 0.5 then self:StopFireSound() return end

	if (EntTable.nextDFX or 0) > T then return end

	EntTable.nextDFX = T + 0.05

	if self:GetDestroyed() then
		if not EntTable._FireStopTime then
			EntTable._FireStopTime = T + math.random(20,40)
		end

		if EntTable ._FireStopTime < T then
			self:StopFireSound()

			local effectdata = EffectData()
				effectdata:SetOrigin( self:GetPos() )
				effectdata:SetEntity( vehicle )
			util.Effect( "lvs_carengine_blacksmoke", effectdata )

			return
		end

		self:StartFireSound()

		local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
			effectdata:SetEntity( vehicle )
		util.Effect( "lvs_carengine_fire", effectdata )
	else
		EntTable._FireStopTime = nil

		self:StopFireSound()

		local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
			effectdata:SetEntity( vehicle )
			effectdata:SetMagnitude( math.max(HP,0) / (MaxHP * 0.5) )
		util.Effect( "lvs_carengine_smoke", effectdata )
	end
end

