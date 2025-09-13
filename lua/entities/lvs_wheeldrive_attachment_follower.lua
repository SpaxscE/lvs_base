AddCSLuaFile()

ENT.Type            = "anim"
ENT.DoNotDuplicate = true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )
	self:NetworkVar( "Entity",1, "Master" )
end

function ENT:GetMins()
	return self:OBBMins()
end

function ENT:GetMaxs()
	return self:OBBMaxs()
end

if SERVER then
	function ENT:SetFollowAttachment( id )
		self._attidFollow = id
	end

	function ENT:Initialize()
		self:SetUseType( SIMPLE_USE )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:AddEFlags( EFL_NO_PHYSCANNON_INTERACTION )

		-- this is so vj npcs can still see us
		self:AddEFlags( EFL_DONTBLOCKLOS )

		self:DrawShadow( false )

		self:SetMaterial( "models/wireframe" )

		local PhysObj = self:GetPhysicsObject()

		if not IsValid( PhysObj ) then return end

		PhysObj:SetMass( 1 )
		PhysObj:EnableDrag( false )
		PhysObj:EnableGravity( false ) 
		PhysObj:EnableMotion( true )

		timer.Simple( 0, function()
			if not IsValid( self ) or not self.GetBase then return end

			local Base = self:GetBase()

			if not IsValid( Base ) or not Base.GetWheels then return end

			for _, Wheel in pairs( Base:GetWheels() ) do
				if not IsValid( Wheel ) then continue end

				local nocollide_constraint = constraint.NoCollide(self,Wheel,0,0)
				nocollide_constraint.DoNotDuplicate = true
			end
		end )
	end

	function ENT:Think()
		local T = CurTime()

		self:NextThink( T )

		local Base = self:GetBase()
		local Master = self:GetMaster()

		if not self._attidFollow or not IsValid( Base ) or not IsValid( Master ) then return true end

		local PhysObj = Master:GetPhysicsObject()

		if not IsValid( PhysObj ) then return true end

		if PhysObj:IsMotionEnabled() then PhysObj:EnableMotion( false ) end

		local att = Base:GetAttachment( self._attidFollow )

		if not att then self:NextThink( T + 1 ) return true end

		local OldAng = Master:GetAngles()
		local NewAng = att.Ang

		if OldAng ~= NewAng then
			Master:SetAngles( att.Ang )
			self:PhysWake()
		end

		return true
	end

	function ENT:OnHealthChanged( dmginfo, old, new )
	end

	function ENT:OnRepaired()
	end

	function ENT:OnDestroyed( dmginfo )
	end

	function ENT:OnTakeDamage( dmginfo )
		local base = self:GetBase()

		if not IsValid( base ) then return end

		local OldTotalHealth = 0
		local NewTotalHealth = 0
		local CallDestroyed = false

		local children = self:GetChildren()

		for _, entity in pairs( children ) do
			if entity:GetClass() ~= "lvs_armor" then continue end

			OldTotalHealth = OldTotalHealth + entity:GetHP()

			if entity._IsRepairFunctionTagged then continue end

			entity._IsRepairFunctionTagged = true

			local OldOnRepaired = entity.OnRepaired

			entity.OnRepaired = function( ent )
				if IsValid( self ) then
					self:OnRepaired()
				end

				OldOnRepaired( ent )
			end
		end

		base:OnTakeDamage( dmginfo )

		for _, entity in pairs( children ) do
			if entity:GetClass() ~= "lvs_armor" then continue end

			local HP = entity:GetHP()

			NewTotalHealth = NewTotalHealth + HP

			if HP > 0 then continue end

			CallDestroyed = true
		end

		self:OnHealthChanged( dmginfo, OldTotalHealth, NewTotalHealth )

		if CallDestroyed then
			self:OnDestroyed( dmginfo )
		end
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

	function ENT:OnRemove()
	end

	return
end

function ENT:Initialize()
end

function ENT:OnRemove()
end

function ENT:Draw()
	if not LVS.DeveloperEnabled then return end

	self:DrawModel()
end
