AddCSLuaFile()

ENT.Type            = "anim"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.DoNotDuplicate = true

function ENT:SetupDataTables()
end

if SERVER then
	function ENT:Initialize()	
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:DrawShadow( false )
	end
	
	function ENT:Use( ply )
	end

	function ENT:Think()
	end

	function ENT:OnRemove()
	end

	function ENT:PhysicsCollide( data, physobj )
	end

	function ENT:OnTakeDamage( dmginfo )
		self:TakePhysicsDamage( dmginfo )
	end

	return
end

function ENT:Initialize()	
end

function ENT:Think()
end

function ENT:Draw()
end

function ENT:OnRemove()
end
