AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName = "Flamethrower"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

ENT.Editable = false

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "FlameVelocity" )
	self:NetworkVar( "Bool", 0, "Active" )

	if SERVER then
		self:SetFlameVelocity( 1000 )
	end
end

if SERVER then
	function ENT:SpawnFunction( ply, tr, ClassName )
		if not tr.Hit then return end

		local ent = ents.Create( ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal * 5 )
		ent:Spawn()
		ent:Activate()

		return ent
	end

	function ENT:Enable()
		if self:GetActive() then return end

		self:SetActive( true )

		local effectdata = EffectData()
			effectdata:SetOrigin( self:LocalToWorld( self:OBBCenter() ) )
			effectdata:SetEntity( self )
		util.Effect( "lvs_flamestream", effectdata )
	end

	function ENT:Disable()
		if not self:GetActive() then return end

		self:SetActive( false )
	end

	function ENT:Initialize()
		self:SetModel("models/items/ar2_grenade.mdl")
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		self:SetRenderMode( RENDERMODE_NORMAL )
	end

	return
end

function ENT:Draw( flags )
end

function ENT:Think()
end
