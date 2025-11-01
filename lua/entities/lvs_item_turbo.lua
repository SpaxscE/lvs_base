AddCSLuaFile()

ENT.Base = "lvs_wheeldrive_engine_mod"

ENT.PrintName = "Turbo"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"
ENT.Information = "Edit Properties to change Torque and Power Curve"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

if SERVER then
	function ENT:Initialize()	
		self:SetModel("models/diggercars/dodge_charger/turbo.mdl")
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:PhysWake()
	end

	function ENT:OnLinked( ent )
		ent:OnTurboCharged( true )
		ent:SetTurbo( self )

		if not self.PlaySound then return end

		ent:EmitSound("lvs/equip_turbo.ogg")
	end

	function ENT:OnUnLinked( ent )
		ent:OnTurboCharged( false )

		if not duplicator or not duplicator.ClearEntityModifier then return end

		duplicator.ClearEntityModifier( ent, "lvsCarTurbo" )
	end

	function ENT:CanLink( ent )
		if not ent.AllowTurbo or IsValid( ent:GetTurbo() ) then return false end

		return true
	end

	local function SaveTurbo( ply, ent, data )
		if not duplicator or not duplicator.StoreEntityModifier then return end

		timer.Simple( 0.2, function()
			if not IsValid( ent ) or not isfunction( ent.AddTurboCharger ) then return end

			local turbo = ent:AddTurboCharger()
			if IsValid( turbo ) then
				if data.Curve then turbo:SetEngineCurve( data.Curve ) end
				if data.Torque then turbo:SetEngineTorque( data.Torque ) end
			end
		end )

		duplicator.StoreEntityModifier( ent, "lvsCarTurbo", data )
	end

	if duplicator and duplicator.RegisterEntityModifier then
		duplicator.RegisterEntityModifier( "lvsCarTurbo", SaveTurbo )
	end

	function ENT:OnVehicleUpdated( ent )
		if not duplicator or not duplicator.ClearEntityModifier or not duplicator.StoreEntityModifier then return end

		duplicator.ClearEntityModifier( ent, "lvsCarTurbo" )
		local data = {
			Curve = self:GetEngineCurve(),
			Torque = self:GetEngineTorque(),
		}
		duplicator.StoreEntityModifier( ent, "lvsCarTurbo", data )
	end

	return
end

function ENT:OnEngineActiveChanged( Active, soundname )
	if Active then
		self:StartSounds( soundname )
	else
		self:StopSounds()
	end
end

function ENT:StartSounds( soundname )
	if self.snd then return end

	self.snd = CreateSound( self, soundname )
	self.snd:PlayEx(0,100)
end

function ENT:StopSounds()
	if not self.snd then return end

	self.snd:Stop()
	self.snd = nil
end

function ENT:HandleSounds( vehicle, engine )
	if not self.snd then return end

	if not self.TurboRPM then
		self.TurboRPM = 0
	end

	local FT = FrameTime()

	local throttle = engine:GetClutch() and 0 or vehicle:GetThrottle()

	local volume = math.Clamp(((self.TurboRPM - 300) / 300),0,1) * vehicle.TurboVolume
	local pitch = math.min(self.TurboRPM / 3,150)

	if throttle == 0 and (self.TurboRPM > 350) then
		if istable( vehicle.TurboBlowOff ) then
			self:EmitSound( vehicle.TurboBlowOff[ math.random( 1, #vehicle.TurboBlowOff ) ], 75, 100, volume * LVS.EngineVolume )
		else
			self:EmitSound( vehicle.TurboBlowOff, 75, 100, volume * LVS.EngineVolume )
		end
		self.TurboRPM = 0
	end

	local rpm = engine:GetRPM()
	local maxRPM = vehicle.EngineMaxRPM

	local ply = LocalPlayer()
	local doppler = vehicle:CalcDoppler( ply )

	self.TurboRPM = self.TurboRPM + math.Clamp(math.min(rpm / maxRPM,1) * 600 * (0.75 + 0.25 * throttle) - self.TurboRPM,-100 * FT,500 * FT)

	self._smBoost = self._smBoost and self._smBoost + (math.min( (self.TurboRPM or 0) / 400, 1 ) - self._smBoost) * FT * 10 or 0

	self.snd:ChangeVolume( volume * engine:GetEngineVolume() )
	self.snd:ChangePitch( pitch * doppler )
end

function ENT:Think()
	local vehicle = self:GetBase()

	if not IsValid( vehicle ) then return end

	local EngineActive = vehicle:GetEngineActive()

	if self._oldEnActive ~= EngineActive then
		self._oldEnActive = EngineActive

		self:OnEngineActiveChanged( EngineActive, vehicle.TurboSound )
	end

	if EngineActive then
		local engine = vehicle:GetEngine()

		if not IsValid( engine ) then return end

		self:HandleSounds( vehicle, engine )
	end
end

function ENT:OnRemove()
	self:StopSounds()
end

function ENT:Draw( flags )
	if IsValid( self:GetBase() ) then return end

	self:DrawModel( flags )
end
