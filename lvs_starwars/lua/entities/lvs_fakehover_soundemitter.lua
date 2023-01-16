AddCSLuaFile()

ENT.Base = "lvs_starfighter_soundemitter"

if SERVER then return end

function ENT:HandleEngineSounds( vehicle )
	local ply = LocalPlayer()
	local pod = ply:GetVehicle()
	local Throttle = vehicle:GetThrottle()
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
		VolumeSetNow = true
		self._lvsoldDrivingMe = DrivingMe
	end

	for id, sound in pairs( self._ActiveSounds ) do
		if not sound then continue end

		local data = self.EngineSounds[ id ]

		local Pitch = math.Clamp( data.Pitch + Throttle * data.PitchMul, data.PitchMin, data.PitchMax )
		local PitchMul = data.UseDoppler and Doppler or 1

		local InActive = Throttle > data.FadeOut or Throttle < data.FadeIn
		if data.FadeOut >= 1 and Throttle > 1 then
			InActive = false
		end

		local Volume = InActive and 0 or LVS.EngineVolume

		if data.VolumeMin and data.VolumeMax and not InActive then
			Volume = math.max(Throttle - data.VolumeMin,0) / (1 - data.VolumeMin) * data.VolumeMax * LVS.EngineVolume
		end

		if istable( sound ) then
			sound.ext:ChangePitch( math.Clamp( Pitch * PitchMul, 0, 255 ), 0.2 )
			if sound.int then sound.int:ChangePitch( math.Clamp( Pitch, 0, 255 ), 0.2 ) end

			local fadespeed = VolumeSetNow and 0 or data.FadeSpeed

			if FirstPerson then
				sound.ext:ChangeVolume( 0, 0 )
				if sound.int then sound.int:ChangeVolume( Volume, fadespeed ) end
			else
				sound.ext:ChangeVolume( Volume, fadespeed )
				if sound.int then sound.int:ChangeVolume( 0, 0 ) end
			end
		else
			sound:ChangePitch( math.Clamp( Pitch * PitchMul, 0, 255 ), 0.2 )
			sound:ChangeVolume( Volume, data.FadeSpeed )
		end
	end
end
