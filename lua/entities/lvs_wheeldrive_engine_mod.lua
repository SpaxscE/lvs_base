AddCSLuaFile()

ENT.Type            = "anim"

ENT._LVS = true

ENT.Editable = true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )

	self:NetworkVar( "Float",0, "EngineCurve", { KeyName = "addpower", Edit = { type = "Float",	 order = 1,min = 0, max = 0.5, category = "Upgrade Settings"} } )
	self:NetworkVar( "Int",1, "EngineTorque", { KeyName = "addtorque", Edit = { type = "Int", order = 2,min = 0, max = 100, category = "Upgrade Settings"} } )

	if SERVER then
		self:SetEngineCurve( 0.25 )
		self:SetEngineTorque( 50 )

		self:NetworkVarNotify( "EngineCurve", self.OnEngineCurveChanged )
		self:NetworkVarNotify( "EngineTorque", self.OnEngineTorqueChanged )
	end
end

function ENT:GetBoost()
	if not self._smBoost then return 0 end

	return self._smBoost
end

if SERVER then
	function ENT:SpawnFunction( ply, tr, ClassName )
		if not tr.Hit then return end

		local ent = ents.Create( ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal * 5 )
		ent:Spawn()
		ent:Activate()
		ent.PlaySound = true
		ent:SetEngineTorque( 15 )

		return ent
	end

	function ENT:Initialize()	
	end

	function ENT:Think()
		return false
	end

	function ENT:CanLink( ent )
		return true
	end

	function ENT:OnLinked( ent )
	end

	function ENT:OnUnLinked( ent )
	end

	function ENT:OnVehicleUpdated()
	end

	local function ResetEngine( ply, ent, data )
		if not duplicator or not duplicator.StoreEntityModifier then return end

		if data.Curve then ent.EngineCurve = data.Curve end
		if data.Torque then ent.EngineTorque = data.Torque end

		duplicator.StoreEntityModifier( ent, "lvsCarResetEngine", data )
	end

	if duplicator and duplicator.RegisterEntityModifier then
		duplicator.RegisterEntityModifier( "lvsCarResetEngine", ResetEngine )
	end

	function ENT:LinkTo( ent )
		if not IsValid( ent ) or not ent.LVS or not self:CanLink( ent ) then return end

		local engine = ent:GetEngine()

		if not IsValid( engine ) then return end

		self.DoNotDuplicate = true

		self:PhysicsDestroy()

		self:SetSolid( SOLID_NONE )
		self:SetMoveType( MOVETYPE_NONE )

		self:SetPos( engine:GetPos() )
		self:SetAngles( engine:GetAngles() )

		self:SetParent( engine )

		self:SetBase( ent )

		if not ent.OriginalTorque or not ent.OriginalCurve then
			ent.OriginalTorque = ent.EngineTorque
			ent.OriginalCurve = ent.EngineCurve

			local data = {
				Curve = ent.OriginalCurve,
				Torque = ent.OriginalTorque,
			}

			duplicator.StoreEntityModifier( ent, "lvsCarResetEngine", data )
		end

		ent.EngineCurve = ent.EngineCurve + self:GetEngineCurve()
		ent.EngineTorque = ent.EngineTorque + self:GetEngineTorque()

		self:OnVehicleUpdated( ent )
		self:OnLinked( ent )
	end

	function ENT:PhysicsCollide( data )
		if self.HasTouched then return end

		self.HasTouched = true

		timer.Simple(0, function()
			if not IsValid( self ) then return end

			self.HasTouched = nil

			self:LinkTo( data.HitEntity )
		end)
	end

	function ENT:OnRemove()
		local base = self:GetBase()

		if not IsValid( base ) or base.ExplodedAlready then return end

		base.EngineCurve = base.EngineCurve - self:GetEngineCurve()
		base.EngineTorque = base.EngineTorque - self:GetEngineTorque()

		self:OnVehicleUpdated( base )

		self:OnUnLinked( base )
	end

	function ENT:OnEngineCurveChanged( name, old, new )
		if old == new then return end

		local ent = self:GetBase()

		if not IsValid( ent ) then return end

		ent.EngineCurve = ent.EngineCurve - old + new

		self:OnVehicleUpdated( ent )
	end

	function ENT:OnEngineTorqueChanged( name, old, new )
		if old == new then return end

		local ent = self:GetBase()

		if not IsValid( ent ) then return end

		ent.EngineTorque = ent.EngineTorque - old + new

		self:OnVehicleUpdated( ent )
	end

	return
end

function ENT:Initialize()
end

function ENT:Think()
end

function ENT:OnRemove()
end

function ENT:Draw( flags )
	self:DrawModel( flags )
end
