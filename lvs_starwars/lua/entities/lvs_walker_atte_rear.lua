AddCSLuaFile()

ENT.Type            = "anim"

ENT.AutomaticFrameAdvance = true
ENT.DoNotDuplicate = true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )
end

if SERVER then
	function ENT:Initialize()	
		self:SetModel( "models/blu/atte_rear.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		self:AddFlags( FL_OBJECT )
	end

	function ENT:Think()
		return false
	end

	function ENT:OnTakeDamage( dmginfo )
		local base = self:GetBase()

		if not IsValid( base ) then return end

		base:OnTakeDamage( dmginfo )
	end

	function ENT:PhysicsCollide( data, phys )
		local base = self:GetBase()

		if not IsValid( base ) then return end

		base:PhysicsCollide( data, phys )
	end

	function ENT:Use( ply )
		if (ply._lvsNextUse or 0) > CurTime() then return end

		local base = self:GetBase()

		if not IsValid( base ) then return end

		base:Use( ply )
	end

	return
end

include("entities/lvs_walker_atte/cl_ikfunctions.lua")

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()
end

function ENT:OnRemove()
	self:OnRemoved()
end