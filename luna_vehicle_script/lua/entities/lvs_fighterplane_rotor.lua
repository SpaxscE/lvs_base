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

		debugoverlay.BoxAngles( self:GetPos(), Vector(-2,-40,-40), Vector(2,40,40), self:GetAngles(), 5, Color( 255, 0, 255 ) )
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
	self._RotorSound1:SetSoundLevel( 140 )
	self._RotorSound1:PlayEx(0,100)

	self._RotorSound2 = CreateSound( self, "lvs/vehicles/generic/propeller_strain.wav" )
	self._RotorSound2:SetSoundLevel( 140 )
	self._RotorSound2:PlayEx(0,100)
end

function ENT:HandleSounds( vehicle )
	local throttle = vehicle:GetThrottle()

	self._smTHR = self._smTHR and self._smTHR + (throttle - self._smTHR) * RealFrameTime() or 0

	local thrust = vehicle:GetThrustStrenght() * self._smTHR

	local volume1 = math.max(thrust,0) * self._smTHR ^ 3
	local volume2 = math.max(-thrust,0) * self._smTHR ^ 3

	local pitch = math.max(95 + math.abs( thrust ) * 30,100)

	self._RotorSound1:ChangeVolume( volume1, 1 )
	self._RotorSound1:ChangePitch( pitch, 0.5 )

	self._RotorSound2:ChangeVolume( volume2, 1 )
	self._RotorSound2:ChangePitch( pitch, 0.5 )
end

function ENT:Think()
	local vehicle = self:GetBase()

	if not IsValid( vehicle ) then return end

	local Active = vehicle:GetEngineActive() and LocalPlayer():lvsGetVehicle() == vehicle

	if self._oldActive ~= Active then
		self._oldActive = Active
		self:OnActiveChanged( Active )
	end

	if Active then
		self:HandleSounds( vehicle )
	end
end

function ENT:OnRemove()
end

function ENT:Draw()
end

function ENT:DrawTranslucent()
end
