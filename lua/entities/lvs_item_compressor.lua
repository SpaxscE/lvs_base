AddCSLuaFile()

ENT.Base = "lvs_wheeldrive_engine_mod"

ENT.PrintName = "Supercharger"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

if SERVER then
	function ENT:Initialize()	
		self:SetModel("models/diggercars/dodge_charger/blower_animated.mdl")
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:PhysWake()
	end

	function ENT:CanLink( ent )
		if not ent.AllowSuperCharger or IsValid( ent:GetCompressor() ) then return false end

		return true
	end

	local function SaveCompressor( ply, ent, data )
		if not duplicator or not duplicator.StoreEntityModifier then return end

		timer.Simple( 0.2, function()
			if not IsValid( ent ) or not isfunction( ent.AddSuperCharger ) then return end

			local compressor = ent:AddSuperCharger()
			if IsValid( compressor ) then
				if data.Curve then compressor:SetEngineCurve( data.Curve ) end
				if data.Torque then compressor:SetEngineTorque( data.Torque ) end
			end
		end )

		duplicator.StoreEntityModifier( ent, "lvsCarCompressor", data )
	end

	if duplicator and duplicator.RegisterEntityModifier then
		duplicator.RegisterEntityModifier( "lvsCarCompressor", SaveCompressor )
	end

	function ENT:OnLinked( ent )
		ent:OnSuperCharged( true )
		ent:SetCompressor( self )

		if not self.PlaySound then return end

		ent:EmitSound("lvs/equip_blower.ogg")
	end

	function ENT:OnUnLinked( ent )
		ent:OnSuperCharged( false )

		if not duplicator or not duplicator.ClearEntityModifier then return end

		duplicator.ClearEntityModifier( ent, "lvsCarCompressor" )
	end

	function ENT:OnVehicleUpdated( ent )
		if not duplicator or not duplicator.ClearEntityModifier or not duplicator.StoreEntityModifier then return end

		duplicator.ClearEntityModifier( ent, "lvsCarCompressor" )
		local data = {
			Curve = self:GetEngineCurve(),
			Torque = self:GetEngineTorque(),
		}
		duplicator.StoreEntityModifier( ent, "lvsCarCompressor", data )
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

	local throttle = engine:GetClutch() and 0 or vehicle:GetThrottle()
	local volume = (0.2 + math.max( math.sin( math.rad( ((engine:GetRPM() - vehicle.EngineIdleRPM) / (vehicle.EngineMaxRPM - vehicle.EngineIdleRPM)) * 90 ) ), 0 ) * 0.8) * throttle * vehicle.SuperChargerVolume
	local pitch = engine:GetRPM() / vehicle.EngineMaxRPM

	local ply = LocalPlayer()
	local doppler = vehicle:CalcDoppler( ply )

	self._smBoost = self._smBoost and self._smBoost + (volume - self._smBoost) * FrameTime() * 5 or 0

	self.snd:ChangeVolume( volume * engine:GetEngineVolume() )
	self.snd:ChangePitch( (60 + pitch * 85) * doppler )
end

function ENT:Think()
	local vehicle = self:GetBase()

	if not IsValid( vehicle ) then return end

	local EngineActive = vehicle:GetEngineActive()

	if self._oldEnActive ~= EngineActive then
		self._oldEnActive = EngineActive

		self:OnEngineActiveChanged( EngineActive, vehicle.SuperChargerSound )
	end

	if EngineActive then
		local engine = vehicle:GetEngine()

		if not IsValid( engine ) then return end

		self:SetPoseParameter( "throttle_pedal", math.max( vehicle:GetThrottle() - (engine:GetClutch() and 1 or 0), 0 ) )
		self:InvalidateBoneCache()

		self:HandleSounds( vehicle, engine )
	end
end

function ENT:OnRemove()
	self:StopSounds()
end

function ENT:Draw( flags )
	local vehicle = self:GetBase()

	if not IsValid( vehicle ) then
		self:DrawModel( flags )

		return
	end

	if not vehicle.SuperChargerVisible then return end

	self:DrawModel( flags )
end
