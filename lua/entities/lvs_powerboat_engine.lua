AddCSLuaFile()

ENT.Base = "lvs_wheeldrive_engine"
DEFINE_BASECLASS( "lvs_wheeldrive_engine" )

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.DoNotDuplicate = true

ENT._LVS = true

ENT.RenderGroup = RENDERGROUP_BOTH 

if SERVER then return end

ENT._oldEnActive = false
ENT._ActiveSounds = {}

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

function ENT:HandleEngineSounds( vehicle )
	local ply = LocalPlayer()
	local pod = ply:GetVehicle()
	local Throttle = (vehicle:GetThrottle() - vehicle:GetThrustStrenght() * vehicle:GetThrottle() * 0.5) + vehicle:GetBrake()
	local Doppler = vehicle:CalcDoppler( ply )

	local DrivingMe = ply:lvsGetVehicle() == vehicle

	local VolumeSetNow = false

	local FirstPerson = false
	if IsValid( pod ) then
		local ThirdPerson = pod:GetThirdPersonMode()

		if ThirdPerson ~= self._lvsoldTP then
			self._lvsoldTP = ThirdPerson
			VolumeSetNow = DrivingMe
		end

		FirstPerson = DrivingMe and not ThirdPerson
	end

	if DrivingMe ~= self._lvsoldDrivingMe then
		self._lvsoldDrivingMe = DrivingMe

		self:StopSounds()

		self._oldEnActive = nil

		return
	end

	local FT = RealFrameTime()

	self._smTHR = self._smTHR and self._smTHR + (Throttle - self._smTHR) * FT or 0

	local HasActiveSoundEmitters = false

	if DrivingMe then
		HasActiveSoundEmitters = vehicle:HasActiveSoundEmitters()
	end

	local rpmSet = false

	for id, sound in pairs( self._ActiveSounds ) do
		if not sound then continue end

		local data = self.EngineSounds[ id ]

		local Pitch = math.Clamp( data.Pitch + self._smTHR * data.PitchMul, data.PitchMin, data.PitchMax )
		local PitchMul = data.UseDoppler and Doppler or 1

		local InActive = self._smTHR > data.FadeOut or self._smTHR < data.FadeIn
		if data.FadeOut >= 1 and self._smTHR > 1 then
			InActive = false
		end

		local Volume = InActive and 0 or LVS.EngineVolume

		if data.VolumeMin and data.VolumeMax and not InActive then
			Volume = math.max(self._smTHR - data.VolumeMin,0) / (1 - data.VolumeMin) * data.VolumeMax * LVS.EngineVolume
		end

		if istable( sound ) then
			sound.ext:ChangePitch( math.Clamp( Pitch * PitchMul, 0, 255 ), 0.2 )
			if sound.int then sound.int:ChangePitch( math.Clamp( Pitch, 0, 255 ), 0.2 ) end

			local fadespeed = VolumeSetNow and 0 or data.FadeSpeed

			if FirstPerson then
				sound.ext:ChangeVolume( 0, 0 )

				if HasActiveSoundEmitters then
					Volume = Volume * 0.25
					fadespeed = fadespeed * 0.5
				end

				if sound.int then sound.int:ChangeVolume( Volume, fadespeed ) end
			else
				if HasActiveSoundEmitters then
					Volume = Volume * 0.75
					fadespeed = fadespeed * 0.5
				end

				sound.ext:ChangeVolume( Volume, fadespeed )

				if sound.int then sound.int:ChangeVolume( 0, 0 ) end
			end
		else
			if data.FadeInRestart then
				if Volume == 0 then
					if sound:GetVolume() == 0 and sound:IsPlaying() then
						sound:Stop()
					else
						sound:ChangePitch( math.Clamp( Pitch * PitchMul, 0, 255 ), 0.2 )
						sound:ChangeVolume( Volume, data.FadeSpeed )
					end
				else
					if sound:IsPlaying() then
						sound:ChangePitch( math.Clamp( Pitch * PitchMul, 0, 255 ), 0.2 )
						sound:ChangeVolume( Volume, data.FadeSpeed )
					else
						sound:PlayEx( Volume, math.Clamp( Pitch * PitchMul, 0, 255 ) )
					end
				end
			else
				sound:ChangePitch( math.Clamp( Pitch * PitchMul, 0, 255 ), 0.2 )
				sound:ChangeVolume( Volume, data.FadeSpeed )
			end

			if not rpmSet then
				rpmSet = true

				self:SetRPM( vehicle.EngineIdleRPM + ((sound:GetPitch() - data.Pitch) / data.PitchMul) * (vehicle.EngineMaxRPM - vehicle.EngineIdleRPM) )
			end
		end
	end
end

function ENT:OnEngineActiveChanged( Active )
	if not Active then self:StopSounds() return end

	local ply = LocalPlayer()
	local ViewPos = ply:GetViewEntity():GetPos()
	local veh = ply:lvsGetVehicle()

	local Base = self:GetBase()

	for id, data in pairs( self.EngineSounds ) do
		if not isstring( data.sound ) then continue end

		self.EngineSounds[ id ].Pitch = data.Pitch or 80
		self.EngineSounds[ id ].PitchMin = data.PitchMin or 0
		self.EngineSounds[ id ].PitchMax = data.PitchMax or 255
		self.EngineSounds[ id ].PitchMul = data.PitchMul or 100
		self.EngineSounds[ id ].UseDoppler = data.UseDoppler ~= false
		self.EngineSounds[ id ].FadeIn = data.FadeIn or 0
		self.EngineSounds[ id ].FadeOut = data.FadeOut or 1
		self.EngineSounds[ id ].FadeSpeed = data.FadeSpeed or 1.5
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

function ENT:Think()
	local vehicle = self:GetBase()

	if not IsValid( vehicle ) then return end

	self:DamageFX( vehicle )
	self:EngineFX( vehicle )

	if not self.EngineSounds then
		self.EngineSounds = vehicle.EngineSounds

		return
	end

	local EngineActive = vehicle:GetEngineActive()

	if self._oldEnActive ~= EngineActive then
		self._oldEnActive = EngineActive
		self:OnEngineActiveChanged( EngineActive )
	end

	if EngineActive then
		self:HandleEngineSounds( vehicle )
		self:ExhaustFX( vehicle )
	else
		self._smTHR = 0
	end
end

function ENT:EngineFX( vehicle )
	if not vehicle:GetEngineActive() then return end

	local EntTable = vehicle:GetTable()

	if not EntTable.EngineSplash then return end

	local T = CurTime()

	if (EntTable.nextPropFX or 0) > T then return end

	local throttle = (self:GetRPM() / EntTable.EngineMaxRPM)

	EntTable.nextPropFX = T + math.max(0.2 - throttle,0.05)

	local startpos = self:GetPos()
	local endpos = self:LocalToWorld( Vector(0,0,-EntTable.EngineSplashDistance) )

	local traceWater = util.TraceLine( {
		start = startpos,
		endpos = endpos,
		mask = MASK_WATER,
		filter = vehicle:GetCrosshairFilterEnts()
	} )

	if not traceWater.Hit then return end

	local pos = traceWater.HitPos

	local emitter = vehicle:GetParticleEmitter( pos )

	if not IsValid( emitter ) then return end

	local VecCol = render.GetLightColor( pos ) * 0.5
	VecCol.r = math.min( VecCol.r + 0.5, 1 ) * 255
	VecCol.g = math.min( VecCol.g + 0.5, 1 ) * 255
	VecCol.b = math.min( VecCol.b + 0.5, 1 ) * 255

	local particle = emitter:Add( "effects/splash4", pos )

	local dir = self:LocalToWorldAngles( Angle(EntTable.EngineSplashThrowAngle,180 - vehicle:GetSteer() * 30,0) ):Forward()

	local vel = (VectorRand() * EntTable.EngineSplashVelocityRandomAdd + dir * EntTable.EngineSplashVelocity) * throttle

	particle:SetVelocity( vel )
	particle:SetDieTime( 1 )
	particle:SetAirResistance( 10 ) 
	particle:SetStartAlpha( 255 )

	particle:SetStartSize( EntTable.EngineSplashStartSize * throttle )
	particle:SetEndSize( EntTable.EngineSplashEndSize * throttle )

	particle:SetRoll( math.Rand(-5,5) )
	particle:SetColor(VecCol.r,VecCol.g,VecCol.b)
	particle:SetGravity( Vector(0,0,-600) )
	particle:SetCollide( false )
	particle:SetNextThink( T )
	particle:SetThinkFunction( function( p )
		p:SetNextThink( CurTime() )

		local fxpos = p:GetPos()

		if fxpos.z > pos.z then return end

		p:SetDieTime( 0 )

		local startpos = Vector(fxpos.x,fxpos.y,pos.z + 1)

		if not IsValid( vehicle ) then return end

		local emitter3D = vehicle:GetParticleEmitter3D( vehicle:GetPos() )

		if not IsValid( emitter3D ) then return end

		local particle = emitter3D:Add("effects/splashwake1", startpos )

		if not particle then return end

		local scale = math.Rand(0.5,2)
		local size = p:GetEndSize()
		local vsize = Vector(size,size,size)

		particle:SetStartSize( size * scale * 0.5 )
		particle:SetEndSize( size * scale )
		particle:SetDieTime( math.Rand(0.5,1) )
		particle:SetStartAlpha( 255 )
		particle:SetEndAlpha( 0 )
		particle:SetPos( startpos )
		particle:SetAngles( Angle(-90,math.Rand(-180,180),0) )
		particle:SetColor(VecCol.r,VecCol.g,VecCol.b)
	end )
end
