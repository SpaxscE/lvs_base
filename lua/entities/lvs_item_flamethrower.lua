AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName = "Flamethrower"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "FlameVelocity" )
	self:NetworkVar( "Bool", 0, "Active" )
	self:NetworkVar( "String", 0, "TargetAttachment" )
	self:NetworkVar( "Entity", 0, "Target" )

	if SERVER then
		self:SetFlameVelocity( 1000 )
	end
end

if SERVER then
	function ENT:AttachTo( target, attachment )
		if not IsValid( target ) or IsValid( self:GetTarget() ) then return end

		self:SetPos( target:GetPos() )
		self:SetAngles( target:GetAngles() )
		self:SetParent( target )
		self:SetTarget( target )
		self:SetTargetAttachment( attachment or "" )
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
	end

	return
end

function ENT:Draw( flags )
end

function ENT:Think()
end
