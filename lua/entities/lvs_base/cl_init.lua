include("shared.lua")
include( "sh_weapons.lua" )
include( "cl_effects.lua" )
include( "cl_hud.lua" )
include( "cl_seatswitcher.lua" )
include( "cl_trailsystem.lua" )
include( "cl_planescript_module.lua" )
include( "cl_boneposeparemeter.lua" )

function ENT:LVSCalcView( ply, pos, angles, fov, pod )
	return LVS:CalcView( self, ply, pos, angles, fov, pod )
end

function ENT:PreDraw()
	return true
end

function ENT:PreDrawTranslucent()
	return true
end

function ENT:PostDraw()
end

function ENT:PostDrawTranslucent()
end

function ENT:Draw( flags )
	if self:PreDraw() then
		if self.lvsLegacyDraw then
			self:DrawModel() -- ugly, but required in order to fix old addons. Refract wont work on these.
		else
			self:DrawModel( flags )
		end
	end

	self:PostDraw()
end

function ENT:DrawTranslucent( flags )
	self:DrawTrail()

	if self:PreDrawTranslucent() then
		self:DrawModel( flags )
	else
		self.lvsLegacyDraw = true -- insert puke simley
	end

	self:PostDrawTranslucent()
end

function ENT:Initialize()
	self:OnSpawn()

	if not istable( self.GibModels ) then return end

	for _, modelName in ipairs( self.GibModels ) do
		util.PrecacheModel( modelName )
	end
end

function ENT:OnSpawn()
end

function ENT:OnFrameActive()
end

function ENT:OnFrame()
end

function ENT:OnEngineActiveChanged( Active )
end

function ENT:OnActiveChanged( Active )
end

ENT._oldActive = false
ENT._oldEnActive = false

function ENT:HandleActive()
	local Active = self:GetActive()
	local EngineActive = self:GetEngineActive()
	local ActiveChanged = false

	if self._oldActive ~= Active then
		self._oldActive = Active
		self:OnActiveChanged( Active )
		ActiveChanged = true
	end

	if self._oldEnActive ~= EngineActive then
		self._oldEnActive = EngineActive
		self:OnEngineActiveChanged( EngineActive )
		ActiveChanged = true
	end

	if ActiveChanged then
		if Active or EngineActive then
			self:StartWindSounds()
		else
			self:StopWindSounds()
		end
	end

	if Active or EngineActive then
		self:DoVehicleFX()
	end

	self:FlyByThink()

	return EngineActive
end

function ENT:Think()
	if not self:IsInitialized() then return end
 
	if self:HandleActive() then
		self:OnFrameActive()
	end

	self:HandleTrail()
	self:OnFrame()
end

function ENT:OnRemove()
	self:StopEmitter()
	self:StopWindSounds()
	self:StopFlyBy()
	self:StopDeathSound()

	self:OnRemoved()
end

function ENT:OnRemoved()
end

function ENT:CalcDoppler( Ent )
	if not IsValid( Ent ) then return 1 end

	if Ent:IsPlayer() then
		local ViewEnt = Ent:GetViewEntity()
		local Vehicle = Ent:lvsGetVehicle()

		if IsValid( Vehicle ) then
			if Ent == ViewEnt then
				Ent = Vehicle
			end
		else
			if IsValid( ViewEnt ) then
				Ent = ViewEnt
			end
		end
	end

	local sVel = self:GetVelocity()
	local oVel = Ent:GetVelocity()

	local SubVel = oVel - sVel
	local SubPos = self:GetPos() - Ent:GetPos()

	local DirPos = SubPos:GetNormalized()
	local DirVel = SubVel:GetNormalized()

	local A = math.acos( math.Clamp( DirVel:Dot( DirPos ) ,-1,1) )

	return (1 + math.cos( A ) * SubVel:Length() / 13503.9)
end

function ENT:GetCrosshairFilterEnts()
	if not self:IsInitialized() then return { self } end -- wait for the server to be ready

	if not istable( self.CrosshairFilterEnts ) then
		self.CrosshairFilterEnts = {self}

		-- lets ask the server to build the filter for us because it has access to constraint.GetAllConstrainedEntities() 
		net.Start( "lvs_player_request_filter" )
			net.WriteEntity( self )
		net.SendToServer()
	end

	return self.CrosshairFilterEnts
end

function ENT:OnDestroyed()
end

net.Receive( "lvs_vehicle_destroy", function( len )
	local ent = net.ReadEntity()

	if not IsValid( ent ) then return end

	ent:OnDestroyed()
end )
