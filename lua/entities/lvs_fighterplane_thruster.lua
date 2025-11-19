AddCSLuaFile()

ENT.Type            = "anim"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.DoNotDuplicate = true

ENT._LVS = true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )
	self:NetworkVar( "String", 1, "Sound" )

	if SERVER then
		self:SetSound("^lvs/vehicles/generic/afterburner.wav")
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
	if not self._ThrusterSound then return end

	self._ThrusterSound:Stop()
	self._ThrusterSound = nil
end

function ENT:OnActiveChanged( Active )
	if not Active then self:StopSounds() return end

	self:StopSounds()

	self._ThrusterSound = CreateSound( self, self:GetSound() )
	self._ThrusterSound:SetSoundLevel( 90 )
	self._ThrusterSound:PlayEx(0,100)
end

function ENT:HandleSounds( vehicle, throttle )

	local thrust = vehicle:GetThrustStrenght()

	if not self._ThrusterSound then return end

	local volume = throttle * 0.5 + math.Clamp( thrust * 0.5, 0, 1 )

	self._ThrusterSound:ChangeVolume( volume, 0.5 )
	self._ThrusterSound:ChangePitch( 100 + thrust * 20, 0.5 )
end

function ENT:Think()
	local vehicle = self:GetBase()

	if not IsValid( vehicle ) then return end

	local Active = vehicle:GetEngineActive()

	if self._oldActive ~= Active then
		self._oldActive = Active
		self:OnActiveChanged( Active )
	end

	local Throttle = vehicle:GetThrottle()

	if Active then
		self:HandleSounds( vehicle, Throttle )
	end
end

function ENT:OnRemove()
	self:StopSounds()
end

function ENT:Draw()
end

function ENT:DrawTranslucent()
end
