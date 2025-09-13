AddCSLuaFile()

ENT.Type            = "anim"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.DoNotDuplicate = true

ENT._LVS = true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )
	self:NetworkVar( "String", 1, "Sound" )
	self:NetworkVar( "String", 2, "SoundStrain" )

	if SERVER then
		self:SetSound("lvs/vehicles/generic/propeller.wav")
		self:SetSoundStrain("lvs/vehicles/generic/propeller_strain.wav")
	end
end

if SERVER then
	function ENT:Initialize()	
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false )
		debugoverlay.Cross( self:GetPos(), 50, 5, Color( 255, 0, 255 ) )
	end

	function ENT:Think()
		return false
	end

	function ENT:UpdateTransmitState() 
		return TRANSMIT_ALWAYS
	end

	return
end

ENT._oldActive = false

function ENT:Initialize()
end

function ENT:StopSounds()
	if self._RotorSound1 then
		self._RotorSound1:Stop()
		self._RotorSound1 = nil
	end
	if self._RotorSound2 then
		self._RotorSound2:Stop()
		self._RotorSound2 = nil
	end
end

function ENT:OnActiveChanged( Active )
	if not Active then self:StopSounds() return end

	self:StopSounds()

	self._RotorSound1 = CreateSound( self, self:GetSound() )
	self._RotorSound1:SetSoundLevel( 70 )
	self._RotorSound1:PlayEx(0,100)

	self._RotorSound2 = CreateSound( self, self:GetSoundStrain() )
	self._RotorSound2:SetSoundLevel( 140 )
	self._RotorSound2:PlayEx(0,100)
end

function ENT:HandleSounds( vehicle, rpm, throttle )

	local rotor_load = vehicle:GetThrustStrenght()

	local mul = math.max( rpm - 470, 0 ) / 330

	local volume = mul * 0.6 + rotor_load * 0.4 * throttle

	local pitch = 80 + mul * 30 - rotor_load * 20 * throttle

	local pitch2 = 100 - rotor_load * 50 * throttle
	local volume2 = (math.max(-rotor_load,0) * mul * throttle ^ 2) * (1 - math.min( math.max( pitch2 - 100, 0 ) / 80, 1 ) )

	local fadespeed = 2

	local ply = LocalPlayer()
	if IsValid( ply ) and ply:lvsGetVehicle() == vehicle then
		local pod = ply:GetVehicle()
		if not pod:GetThirdPersonMode() then
			if vehicle:HasActiveSoundEmitters() then
				volume = volume * 0.25
				volume2 = volume2 * 0.25
				fadespeed = 0.5
			end
		end
	end
	
	if self._RotorSound1 then
		self._RotorSound1:ChangeVolume( volume, fadespeed )
		self._RotorSound1:ChangePitch( pitch, 0.5 )
	end

	if self._RotorSound2 then
		self._RotorSound2:ChangeVolume( volume2, 0.5 )
		self._RotorSound2:ChangePitch( math.min( pitch2, 160), 0.1 )
	end
end

function ENT:Think()
	local vehicle = self:GetBase()

	if not IsValid( vehicle ) then return end

	local Active = vehicle:GetEngineActive() and LocalPlayer():lvsGetVehicle() == vehicle

	if self._oldActive ~= Active then
		self._oldActive = Active
		self:OnActiveChanged( Active )
	end

	local Throttle = vehicle:GetThrottle()

	local TargetRPM = vehicle:GetEngineActive() and (300 + Throttle * 500) or 0

	vehicle.RotorRPM = vehicle.RotorRPM and vehicle.RotorRPM + (TargetRPM - vehicle.RotorRPM) * RealFrameTime() or 0

	if Active then
		self:HandleSounds( vehicle, vehicle.RotorRPM, Throttle )
	end
end

function ENT:OnRemove()
	self:StopSounds()
end

function ENT:Draw()
end

function ENT:DrawTranslucent()
end
