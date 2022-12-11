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

		debugoverlay.Cross( self:GetPos(), 50, 5, Color( 0, 255, 255 ), true )
	end

	function ENT:Think()
		return false
	end

	function ENT:UpdateTransmitState() 
		return TRANSMIT_ALWAYS
	end

	return
end

ENT._oldEnActive = false
ENT._ActiveSounds = {}

function ENT:Initialize()
end

function ENT:StopSounds()
	for id, sound in pairs( self._ActiveSounds ) do
		sound:Stop()
		self._ActiveSounds[ id ] = nil
	end
end

function ENT:HandleEngineSounds( vehicle )
	local Throttle = vehicle:GetThrottle()
	local Doppler = vehicle:CalcDoppler( LocalPlayer() )

	local FT = RealFrameTime()

	self._smTHR = self._smTHR and self._smTHR + (Throttle - self._smTHR) * FT or 0

	for id, sound in pairs( self._ActiveSounds ) do
		if not sound then continue end

		local data = self.EngineSounds[ id ]

		local Pitch = math.Clamp( data.StartPitch + self._smTHR * data.PitchMul, data.MinPitch, data.MaxPitch )
		local Volume = (self._smTHR > data.FadeOut or self._smTHR < data.FadeIn) and 0 or LVS.EngineVolume

		local PitchMul = data.UseDoppler and Doppler or 1

		sound:ChangePitch( math.Clamp( Pitch * PitchMul, 0, 255 ), 0.2 )
		sound:ChangeVolume( Volume, data.FadeSpeed )
	end
end

function ENT:OnEngineActiveChanged( Active )
	if Active then
		for id, data in pairs( self.EngineSounds ) do
			if not isstring( data.SoundPath ) then continue end

			self.EngineSounds[ id ].StartPitch = data.StartPitch or 80
			self.EngineSounds[ id ].MinPitch = data.MinPitch or 0
			self.EngineSounds[ id ].MaxPitch = data.MaxPitch or 255
			self.EngineSounds[ id ].PitchMul = data.PitchMul or 100
			self.EngineSounds[ id ].UseDoppler = data.UseDoppler ~= false
			self.EngineSounds[ id ].FadeIn = data.FadeIn or 0
			self.EngineSounds[ id ].FadeOut = data.FadeOut or 1
			self.EngineSounds[ id ].FadeSpeed = data.FadeSpeed or 1.5

			local sound = CreateSound( self, data.SoundPath )
			sound:SetSoundLevel( 140 )
			sound:PlayEx(0,100)

			self._ActiveSounds[ id ] = sound
		end
	else
		self:StopSounds()
	end
end

function ENT:Think()
	local vehicle = self:GetBase()

	if not IsValid( vehicle ) then return end

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
	else
		self._smTHR = 0
	end
end

function ENT:OnRemove()
	self:StopEmitter()
	self:StopSounds()
end

function ENT:GetParticleEmitter( Pos )
	if self.Emitter then
		if self.EmitterTime > CurTime() then
			return self.Emitter
		end
	end

	self:StopEmitter()

	self.Emitter = ParticleEmitter( Pos, false )
	self.EmitterTime = CurTime() + 2

	return self.Emitter
end

function ENT:StopEmitter()
	if IsValid( self.Emitter ) then
		self.Emitter:Finish()
	end
end

function ENT:Draw()
end

function ENT:DrawTranslucent()
end

--[[
	self.nextDFX = self.nextDFX or 0

	if self.nextDFX < CurTime() then
		self.nextDFX = CurTime() + 0.05
		
		local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
			effectdata:SetEntity( self )
		util.Effect( "lvs_engine_blacksmoke", effectdata )
	end
]]