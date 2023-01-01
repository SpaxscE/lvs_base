AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName = "Missile"
ENT.Author = "Luna"
ENT.Information = "LVS Missile"
ENT.Category = "[LVS]"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

if SERVER then
	function ENT:SetDamage( num )
		self._dmg = num
	end

	function ENT:SetRadius( num )
		self._radius = num
	end

	function ENT:SetAttacker( ent )
		self._attacker = ent
	end

	function ENT:GetAttacker( ent )
		return self._attacker or NULL
	end

	function ENT:GetDamage( num )
		return (self._dmg or 100)
	end

	function ENT:GetRadius( num )
		return (self._radius or 250)
	end

	function ENT:SpawnFunction( ply, tr, ClassName )

		local ent = ents.Create( ClassName )
		ent:SetPos( ply:GetShootPos() )
		ent:SetAngles( ply:EyeAngles() )
		ent:Spawn()
		ent:Activate()
		ent:SetAttacker( ply )
		ent:Enable()

		return ent
	end

	function ENT:Initialize()	
		self:SetModel( "models/weapons/w_missile_launch.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetRenderMode( RENDERMODE_TRANSALPHA )
		self:PhysWake()
		self:SetCollisionGroup( COLLISION_GROUP_WORLD )
	end

	function ENT:Enable()
		if self.IsEnabled then return end

		self.IsEnabled = true

		local pObj = self:GetPhysicsObject()
		
		if not IsValid( pObj ) then
			self:Remove()

			print("LVS: missing model. Missile terminated.")

			return
		end

		pObj:SetMass( 1 ) 
		pObj:EnableGravity( false ) 
		pObj:EnableMotion( true )
		pObj:EnableDrag( false )

		self:SetTrigger( true )

		self:StartMotionController()

		self:PhysWake()
	end

	function ENT:PhysicsSimulate( phys, deltatime )
		phys:Wake()

		local Thrust = 500
		local Speed = 4000
		local velL = self:WorldToLocal( self:GetPos() + self:GetVelocity() )

		local ForceLinear = Vector( (Speed - velL.x) * deltatime * Thrust,0,0)
		local ForceAngle = -phys:GetAngleVelocity() * 250 * deltatime

		return ForceAngle, ForceLinear, SIM_LOCAL_ACCELERATION
	end

	function ENT:Think()	
		return false
	end

	function ENT:StartTouch( entity )
		if entity == self:GetAttacker() then return end
		self:Detonate( entity )
	end

	function ENT:EndTouch( entity )
	end

	function ENT:Touch( entity )
	end

	function ENT:PhysicsCollide( data )
		self:Detonate()
	end

	function ENT:OnTakeDamage( dmginfo )	
	end

	function ENT:Detonate( target )
		if self.IsDetonated then return end

		self.IsDetonated = true

		local Pos =  self:GetPos() 

		local effectdata = EffectData()
			effectdata:SetOrigin( Pos )
		util.Effect( "lvs_explosion_small", effectdata )

		if IsValid( target ) then
			Pos = target:GetPos() -- place explosion inside the hit targets location so they receive full damage. This fixes all the garbage code the LFS' missile required in order to deliver its damage
		end

		util.BlastDamage( self, self:GetAttacker(), Pos, self:GetRadius(), self:GetDamage() )

		SafeRemoveEntityDelayed( self, FrameTime() )
	end
else
	function ENT:Initialize()	
	end

	function ENT:Draw()
		self:DrawModel()
	end

	function ENT:Think()
	end

	function ENT:OnRemove()
	end
end