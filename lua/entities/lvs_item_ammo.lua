AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName = "Ammo"
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
		self:SetModel( "models/misc/88mm_shell.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:PhysWake()
		self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
	end

	function ENT:Think()
		if self.MarkForRemove then
			self:Remove()

			return false
		end

		self:NextThink( CurTime() + 0.1 )

		return true
	end

	function ENT:AddSingleRound( entity )
		local AmmoIsSet = false

		for PodID, data in pairs( entity.WEAPONS ) do
			for id, weapon in pairs( data ) do
				local MaxAmmo = weapon.Ammo or -1
				local CurAmmo = weapon._CurAmmo or MaxAmmo

				if CurAmmo == MaxAmmo then continue end

				entity.WEAPONS[PodID][ id ]._CurAmmo = math.min( CurAmmo + 1, MaxAmmo )

				AmmoIsSet = true
			end
		end

		if AmmoIsSet then
			entity:SetNWAmmo( entity:GetAmmo() )

			for _, pod in pairs( entity:GetPassengerSeats() ) do
				local weapon = pod:lvsGetWeapon()

				if not IsValid( weapon ) then continue end

				weapon:SetNWAmmo( weapon:GetAmmo() )
			end
		end

		return AmmoIsSet
	end

	function ENT:Refil( entity )
		if self.MarkForRemove then return end

		if not IsValid( entity ) then return end

		if not entity.LVS then return end

		if self:AddSingleRound( entity ) then
			entity:OnMaintenance()

			entity:EmitSound("items/ammo_pickup.wav")

			self.MarkForRemove = true
		end
	end

	function ENT:ShootBullet( attacker )
		if self.BeenFired then return end

		self.BeenFired = true

		local hit_decal = ents.Create( "lvs_armor_bounce" )
		hit_decal:SetPos( self:GetPos() )
		hit_decal:SetAngles( self:GetAngles() )
		hit_decal:Spawn()
		hit_decal:Activate()
		hit_decal:EmitSound("ambient/explosions/explode_4.wav", 75, 120, 1)
		hit_decal:SetCollisionGroup( COLLISION_GROUP_NONE )

		if IsValid( attacker ) then
			hit_decal:SetPhysicsAttacker( attacker, 10 )
		end

		local PhysObj = hit_decal:GetPhysicsObject()
		if IsValid( PhysObj ) then
			PhysObj:SetMass( 50 )
			PhysObj:EnableDrag( false )
			PhysObj:SetVelocityInstantaneous( self:GetForward() * 4000 )
			PhysObj:SetAngleVelocityInstantaneous( VectorRand() * 250 )
		end

		self:SetModel("models/misc/88mm_casing.mdl")
	end

	function ENT:PhysicsCollide( data, physobj )
		if data.Speed > 60 and data.DeltaTime > 0.2 then
			local VelDif = data.OurOldVelocity:Length() - data.OurNewVelocity:Length()

			if VelDif > 700 then
				self:ShootBullet()
			end
		end

		self:Refil( data.HitEntity )
	end

	function ENT:OnTakeDamage( dmginfo )
		self:ShootBullet( dmginfo:GetAttacker() )
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
	end

	function ENT:OnRemove()
	end

	function ENT:Think()
	end
end

function ENT:GetCrosshairFilterEnts()
	return {self}
end