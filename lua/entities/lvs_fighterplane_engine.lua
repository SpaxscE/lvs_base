AddCSLuaFile()

ENT.Type            = "anim"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.DoNotDuplicate = true

ENT._LVS = true

ENT.RenderGroup = RENDERGROUP_BOTH 

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )
end

if SERVER then
	util.AddNetworkString( "lvsplane_exhautcompatibility" )

	net.Receive( "lvsplane_exhautcompatibility", function( len, ply )
		local ent = net.ReadEntity()

		if not IsValid( ent ) or not ent.LVS or not ent.ExhaustPositions then return end

		net.Start( "lvsplane_exhautcompatibility")
			net.WriteEntity( ent )
			net.WriteTable( ent.ExhaustPositions )
		net.Send( ply )
	end )

	function ENT:Initialize()	
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false )
		debugoverlay.Cross( self:GetPos(), 50, 5, Color( 0, 255, 255 ) )
	end

	function ENT:CheckWater( Base )
		if bit.band( util.PointContents( self:GetPos() ), CONTENTS_WATER ) ~= CONTENTS_WATER then
			if self.CountWater then
				self.CountWater = nil
			end

			return
		end

		if Base.WaterLevelAutoStop > 3 then return end

		self.CountWater = (self.CountWater or 0) + 1

		if self.CountWater < 4 then return end

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

	function ENT:OnTakeDamage( dmginfo )
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

function ENT:HandleEngineSounds( vehicle )
	local ply = LocalPlayer()
	local pod = ply:GetVehicle()
	local Throttle = vehicle:GetThrottle() - vehicle:GetThrustStrenght() * vehicle:GetThrottle() * 0.5
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
			sound:ChangePitch( math.Clamp( Pitch * PitchMul, 0, 255 ), 0.2 )
			sound:ChangeVolume( Volume, data.FadeSpeed )
		end
	end
end

function ENT:OnEngineActiveChanged( Active )
	if not Active then self:StopSounds() return end

	local ply = LocalPlayer()
	local ViewPos = ply:GetViewEntity():GetPos()
	local veh = ply:lvsGetVehicle()

	local Base = self:GetBase()

	local DrivingMe = veh == Base or ((self:GetPos() - ViewPos):LengthSqr() < 600000 and not Base:GetAI())

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

		if data.sound_int and data.sound_int ~= data.sound and DrivingMe then
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
			if DrivingMe or data.SoundLevel >= 90 then
				local sound = CreateSound( self, data.sound )
				sound:SetSoundLevel( data.SoundLevel )
				sound:PlayEx(0,100)

				self._ActiveSounds[ id ] = sound
			end
		end
	end
end

function ENT:Think()
	local vehicle = self:GetBase()

	if not IsValid( vehicle ) then return end

	self:DamageFX( vehicle )

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
	self:StopSounds()
end

function ENT:Draw()
end

function ENT:DrawTranslucent()
	local vehicle = self:GetBase()

	if not IsValid( vehicle ) or not vehicle:GetEngineActive() then return end

	if not istable( vehicle.ExhaustPositions ) then
		vehicle.ExhaustPositions = {}

		net.Start("lvsplane_exhautcompatibility")
			net.WriteEntity( vehicle )
		net.SendToServer()
	end

	if #vehicle.ExhaustPositions == 0 then return end

	vehicle:DoExhaustFX()
end

function ENT:DamageFX( vehicle )
	local T = CurTime()
	local HP = vehicle:GetHP()
	local MaxHP = vehicle:GetMaxHP() 

	if HP <= 0 or HP > MaxHP * 0.5 or (self.nextDFX or 0) > T then return end

	self.nextDFX = T + 0.05

	local effectdata = EffectData()
		effectdata:SetOrigin( self:GetPos() )
		effectdata:SetEntity( vehicle )
	util.Effect( "lvs_engine_blacksmoke", effectdata )
end

net.Receive( "lvsplane_exhautcompatibility", function( len )
	local ent = net.ReadEntity()

	if not IsValid( ent ) then return end

	ent.ExhaustPositions = net.ReadTable()
end )

