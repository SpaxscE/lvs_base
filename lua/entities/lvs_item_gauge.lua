AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName = "Gauge"
ENT.Author = "Luna"
ENT.Category = "[LVS]"

ENT.Spawnable		= true
ENT.AdminOnly		= false

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
		self:SetModel( "models/diggercars/tacho.mdl" )
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

		if not IsValid( ent ) or not ent.LVS or not isfunction( ent.SetRacingHud ) then return end

		ent:SetRacingHud( not ent:GetRacingHud() )

		local ply = self:GetCreator()

		if ent:GetRacingHud() then
			ent:EmitSound("common/wpn_hudoff.wav")

			if IsValid( ply ) then
				ply:ChatPrint( "Gauge Added" )
			end
		else
			ent:EmitSound("common/wpn_denyselect.wav")

			if IsValid( ply ) then
				ply:ChatPrint( "Gauge Removed" )
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
