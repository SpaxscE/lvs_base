AddCSLuaFile()

ENT.Type            = "anim"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.DoNotDuplicate = true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )
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

	self._RotorSound1 = CreateSound( self, "lvs/vehicles/generic/propeller.wav" )
	self._RotorSound1:SetSoundLevel( 70 )
	self._RotorSound1:PlayEx(0,100)

	self._RotorSound2 = CreateSound( self, "lvs/vehicles/generic/propeller_strain.wav" )
	self._RotorSound2:SetSoundLevel( 140 )
	self._RotorSound2:PlayEx(0,100)
end

function ENT:HandleSounds( vehicle, rpm, throttle )

	local rotor_load = vehicle:GetThrustStrenght()

	local mul = math.max( rpm - 470, 0 ) / 330

	local volume = mul * 0.6 + rotor_load * 0.4 * throttle

	local pitch = 80 + mul * 30 - rotor_load * 20 * throttle

	local pitch2 = 100 - rotor_load * 50 * throttle
	local volume2 = math.max(-rotor_load,0) * mul * throttle ^ 2

	if self._RotorSound1 then
		self._RotorSound1:ChangeVolume( volume, 2 )
		self._RotorSound1:ChangePitch( pitch, 0.5 )
	end

	if self._RotorSound2 then
		self._RotorSound2:ChangeVolume( volume2, 0.5 )
		self._RotorSound2:ChangePitch( pitch2, 0 )
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
