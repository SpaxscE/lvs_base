AddCSLuaFile()

ENT.Type            = "anim"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.DoNotDuplicate = true
ENT.EngineSounds = {}

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )
end

local function AddEngineSound( ent, data )
	if not data or not isstring( data.SoundPath ) then return false end

	data.StartPitch = data.StartPitch or 80
	data.MinPitch = data.MinPitch or 0
	data.MaxPitch = data.MaxPitch or 255
	data.PitchMul = data.PitchMul or 100
	data.UseDoppler = data.UseDoppler ~= false
	data.FadeIn = data.FadeIn or 0
	data.FadeOut = data.FadeOut or 1
	data.FadeSpeed = data.FadeSpeed or 1.5

	table.insert( ent.EngineSounds, data )
end

if SERVER then
	util.AddNetworkString( "lvs_engine_sounds" )

	function ENT:Initialize()	
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false )

		debugoverlay.Cross( self:GetPos(), 50, 5, Color( 0, 255, 255 ), true )
	end

	function ENT:AddSound( user_data )
		AddEngineSound( self, user_data )
	end

	function ENT:Think()
		return false
	end

	function ENT:SendSoundsTo( ply )
		for _, data in pairs( self.EngineSounds ) do
			net.Start( "lvs_engine_sounds" )
				net.WriteEntity( self )
				net.WriteString( data.SoundPath )
				net.WriteInt( data.StartPitch, 9 )
				net.WriteInt( data.MinPitch, 9 )
				net.WriteInt( data.MaxPitch, 9 )
				net.WriteFloat( data.PitchMul )
				net.WriteBool( data.UseDoppler )
				net.WriteFloat( data.FadeIn )
				net.WriteFloat( data.FadeOut )
				net.WriteFloat( data.FadeSpeed )
			net.Send( ply )
		end
	end

	function ENT:UpdateTransmitState() 
		return TRANSMIT_ALWAYS
	end

	net.Receive( "lvs_engine_sounds", function( len, ply )
		local Engine = net.ReadEntity()

		if not IsValid( Engine ) or not IsValid( ply ) then return end

		Engine:SendSoundsTo( ply )
	end )

	return
end

function ENT:Initialize()
	net.Start("lvs_engine_sounds")
		net.WriteEntity( self )
	net.SendToServer()
end

function ENT:AddSound( data )
	AddEngineSound( self, data )
end

net.Receive( "lvs_engine_sounds", function( len )
	local Engine = net.ReadEntity()

	if not IsValid( Engine ) then return end

	local data = {
		SoundPath = net.ReadString(),
		StartPitch = net.ReadInt( 9 ),
		MinPitch = net.ReadInt( 9 ),
		MaxPitch = net.ReadInt( 9 ),
		PitchMul = net.ReadFloat(),
		UseDoppler = net.ReadBool(),
		FadeIn = net.ReadFloat(),
		FadeOut = net.ReadFloat(),
		FadeSpeed = net.ReadFloat(),
	}

	Engine:AddSound( data )
end )

ENT._oldEnActive = false
ENT._ActiveSounds = {}

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
		local Volume = (self._smTHR > data.FadeOut or self._smTHR < data.FadeIn) and 0 or 1

		local PitchMul = data.UseDoppler and Doppler or 1

		sound:ChangePitch( math.Clamp( Pitch * PitchMul, 0, 255 ), 0.2 )
		sound:ChangeVolume( Volume, data.FadeSpeed )
	end
end

function ENT:OnEngineActiveChanged( Active )
	if Active then
		for id, data in pairs( self.EngineSounds ) do
			local sound = CreateSound( self, data.SoundPath )
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