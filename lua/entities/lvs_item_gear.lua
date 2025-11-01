AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName = "TopSpeed Upgrade"
ENT.Author = "Luna"
ENT.Category = "[LVS]"
ENT.Information = "Edit Properties to change Max Speed"

ENT.Spawnable		= true
ENT.AdminOnly		= false

ENT.Editable = true

ENT.PhysicsSounds = true

function ENT:SetupDataTables()
	self:NetworkVar( "Float",0, "MaxSpeed", { KeyName = "maxspeed", Edit = { type = "Float", order = 1,min = 0, max = 1000, category = "Upgrade Settings"} } )

	if SERVER then

		self:SetMaxSpeed( 300 )
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

	function ENT:Initialize()	
		self:SetModel( "models/props_wasteland/gear01.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:PhysWake()
	end

	function ENT:Think()
		return false
	end

	function ENT:PhysicsCollide( data )
		if self.MarkForRemove then return end

		local ent = data.HitEntity

		if not IsValid( ent ) or not ent.LVS or not ent.MaxVelocity or not isfunction( ent.ChangeVelocity ) then return end

		local MaxVelocity = math.min( self:GetMaxSpeed() * (1 / 0.09144), physenv.GetPerformanceSettings().MaxVelocity )

		local ply = self:GetCreator()

		if ent.MaxVelocity < MaxVelocity then
			ent:EmitSound("ambient/machines/spinup.wav")

			local effectdata = EffectData()
			effectdata:SetOrigin( ent:GetPos() )
			effectdata:SetEntity( ent )
			util.Effect( "lvs_upgrade", effectdata )
		else
			ent:EmitSound("ambient/machines/spindown.wav")

			local effectdata = EffectData()
			effectdata:SetOrigin( ent:GetPos() )
			effectdata:SetEntity( ent )
			util.Effect( "lvs_downgrade", effectdata )
		end

		if IsValid( ply ) then
			ply:ChatPrint( "New Max Velocity: "..MaxVelocity )
		end
	
		ent:ChangeVelocity( MaxVelocity )

		self.MarkForRemove = true

		SafeRemoveEntityDelayed( self, 0 )
	end

	function ENT:OnTakeDamage( dmginfo )
	end
else
	function ENT:Draw( flags )
		self:DrawModel( flags )
	end
end
