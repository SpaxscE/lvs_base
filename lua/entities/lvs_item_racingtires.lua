AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName = "Racing Tires"
ENT.Author = "Luna"
ENT.Category = "[LVS]"

ENT.Spawnable		= true
ENT.AdminOnly		= false

ENT.PhysicsSounds = true

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
		self:SetModel( "models/diggercars/tires.mdl" )
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

		if not IsValid( ent ) or not ent.LVS or not isfunction( ent.SetRacingTires ) or ent.PivotSteerEnable then return end

		ent:SetRacingTires( not ent:GetRacingTires() )

		local ply = self:GetCreator()

		ent:EmitSound("npc/dog/dog_servo6.wav")

		if ent:GetRacingTires() then
			if IsValid( ply ) then
				ply:ChatPrint( "Racing Tires Mounted" )
			end

			for _, wheel in pairs( ent:GetWheels() ) do
				if not IsValid( wheel ) then continue end

				local effectdata = EffectData()
				effectdata:SetOrigin( wheel:GetPos() )
				effectdata:SetEntity( wheel )
				util.Effect( "lvs_upgrade", effectdata )
			end
		else
			if IsValid( ply ) then
				ply:ChatPrint( "Racing Tires Removed" )
			end

			for _, wheel in pairs( ent:GetWheels() ) do
				if not IsValid( wheel ) then continue end

				local effectdata = EffectData()
				effectdata:SetOrigin( wheel:GetPos() )
				effectdata:SetEntity( wheel )
				util.Effect( "lvs_downgrade", effectdata )
			end
		end

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
