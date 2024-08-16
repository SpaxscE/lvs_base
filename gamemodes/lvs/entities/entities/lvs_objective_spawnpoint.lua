AddCSLuaFile()

ENT.Type            = "anim"

ENT.FortificationIgnorePhysicsDamage = true

function ENT:SetupDataTables()
end

if SERVER then
	function ENT:Initialize()
		self:SetModel( "models/Combine_Helicopter/helicopter_bomb01.mdl" )

		local size = 16

		self:PhysicsInitSphere( size, "default_silent" )

		self:SetCollisionBounds( Vector( -size, -size, -size ), Vector( size, size, size ) )

		self:PhysWake()

		self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

		self:DrawShadow( false )
	end

	function ENT:PhysicsCollide( data, physobj )
		local Time = CurTime()
		local StartTime, Delay = GAMEMODE:GetGameTime()

		if (StartTime + Delay - 5) < Time then

			return
		end

		physobj:SetAngleVelocityInstantaneous( vector_origin )
		physobj:SetVelocityInstantaneous( data.OurNewVelocity:GetNormalized() * 1000 )
	end

	function ENT:OnTakeDamage( dmginfo )
		self:TakePhysicsDamage( dmginfo )
	end

	function ENT:Use( activator, caller )
	end

	return
end

function ENT:Initialize()
end

function ENT:Draw( flags )
end

function ENT:OnRemove()
end
