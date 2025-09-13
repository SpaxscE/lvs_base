AddCSLuaFile()

ENT.Base = "lvs_walker_atte_component"

if SERVER then
	function ENT:Initialize()	
		self:SetModel( "models/blu/atte_rear.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )

		-- this is so vj npcs can still see us
		self:AddEFlags( EFL_DONTBLOCKLOS )

		-- this is for our npc relationship system to work
		self:AddFlags( FL_OBJECT )
	end

	function ENT:Think()
		self:NextThink( CurTime() )
		return true
	end

	return
end

include("entities/lvs_walker_atte/cl_ikfunctions.lua")

function ENT:OnRemove()
	self:OnRemoved()
end