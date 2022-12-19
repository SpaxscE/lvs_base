include("shared.lua")
include("sh_func.lua")
include( "sh_weapons.lua" )
include( "cl_effects.lua" )
include( "cl_hud.lua" )
include( "cl_seatswitcher.lua" )
include( "cl_trailsystem.lua" )

function ENT:LVSCalcView( ply, pos, angles, fov, pod )
	return LVS:CalcView( self, ply, pos, angles, fov, pod )
end

function ENT:OnDraw()
	return true
end

function ENT:OnDrawTranslucent()
	return false
end

function ENT:Draw()
	if not self:OnDraw() then return end

	self:DrawModel()
end

function ENT:DrawTranslucent()
	self:DrawTrail()

	if not self:OnDrawTranslucent() then return end

	self:DrawModel()
end

function ENT:Initialize()
	self:OnSpawn()
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
	if Active then
		if not IsValid( self:GetDriver() ) then return end

		self:StartWindSounds()
	else
		self:StopWindSounds()
	end
end

ENT._oldActive = false
ENT._oldEnActive = false

function ENT:HandleActive()
	local Active = self:GetActive()
	local EngineActive = self:GetEngineActive()

	if self._oldActive ~= Active then
		self._oldActive = Active
		self:OnActiveChanged( Active )
	end

	if self._oldEnActive ~= EngineActive then
		self._oldEnActive = EngineActive
		self:OnEngineActiveChanged( EngineActive )
	end

	return EngineActive
end

function ENT:Think()
	if self:HandleActive() then
		self:DoVehicleFX()
		self:OnFrameActive()
	end

	self:HandleTrail()
	self:OnFrame()
end

function ENT:OnRemove()
	self:StopEmitter()
	self:StopWindSounds()

	self:OnRemoved()
end

function ENT:OnRemoved()
end

function ENT:CalcDoppler( Ent )
	if not IsValid( Ent ) then return 1 end

	if Ent:IsPlayer() then
		local ViewEnt = Ent:GetViewEntity()

		if Ent:lvsGetVehicle() == self then
			if ViewEnt == Ent then
				Ent = self
			else
				Ent = ViewEnt
			end
		else
			Ent = ViewEnt
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
	if not istable( self.CrosshairFilterEnts ) then
		self.CrosshairFilterEnts = {self}

		-- lets ask the server to build the filter for us because it has access to constraint.GetAllConstrainedEntities() 
		net.Start( "lvs_player_request_filter" )
			net.WriteEntity( self )
		net.SendToServer()
	end

	return self.CrosshairFilterEnts
end
