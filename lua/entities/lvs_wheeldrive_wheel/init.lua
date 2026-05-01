AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_effects.lua" )
AddCSLuaFile( "cl_skidmarks.lua" )
include("shared.lua")
include("sv_axle.lua")
include("sv_brakes.lua")
include("sv_damage.lua")

function ENT:GetWheelType()
	return self._WheelType or LVS.WHEELTYPE_NONE
end

function ENT:SetWheelType( wheel_type )
	self._WheelType = wheel_type
end

function ENT:SetSuspensionHeight( newheight )
	newheight = newheight and math.Clamp( newheight, -1, 1 ) or 0

	self._SuspensionHeightMultiplier = newheight

	if not IsValid( self.SuspensionConstraintElastic ) then return end

	local Length = self.SuspensionConstraintElastic:GetTable().length or 25

	self.SuspensionConstraintElastic:Fire( "SetSpringLength", Length + Length * newheight )
end

function ENT:GetSuspensionHeight()
	return self._SuspensionHeightMultiplier or 0
end

function ENT:SetSuspensionStiffness( new )
	new = new and math.Clamp( new, -1, 1 ) or 0

	self._SuspensionStiffnessMultiplier = new

	if not IsValid( self.SuspensionConstraintElastic ) then return end

	local data = self.SuspensionConstraintElastic:GetTable()
	local damping = data.damping or 2000
	local constant = data.constant or 20000

	self.SuspensionConstraintElastic:Fire( "SetSpringConstant", constant + constant * new, 0 )
	self.SuspensionConstraintElastic:Fire( "SetSpringDamping", damping + damping * new, 0 )
end

function ENT:DisableSuspension()
	if self._IsSuspensionDisabled or self._OriginalMass then return end

	local PhysObj = self:GetPhysicsObject()

	if not IsValid( PhysObj ) then return end

	self._IsSuspensionDisabled = true
	self._SuspensionDisabledOldValue = self:GetSuspensionStiffness()
	self._SuspensionDisabledOldMass = PhysObj:GetMass()

	self:SetSuspensionStiffness( -0.5 )
	PhysObj:SetMass( self._SuspensionDisabledOldMass * 0.5 )
end

function ENT:EnableSuspension()
	if not self._IsSuspensionDisabled then return end

	local PhysObj = self:GetPhysicsObject()

	if not IsValid( PhysObj ) then return end

	self:SetSuspensionStiffness( self._SuspensionDisabledOldValue )
	PhysObj:SetMass( self._SuspensionDisabledOldMass )

	self._IsSuspensionDisabled = nil
	self._SuspensionDisabledOldValue = nil
	self._SuspensionDisabledOldMass = nil
end

function ENT:GetSuspensionStiffness()
	return self._SuspensionStiffnessMultiplier or 0
end

function ENT:Initialize()
	self:SetCollisionGroup( COLLISION_GROUP_PASSABLE_DOOR )

	-- this is so vj npcs can still see us
	self:AddEFlags( EFL_DONTBLOCKLOS )
end

function ENT:GravGunPickupAllowed( ply )
	return false
end

function ENT:StartThink()
	if self.AutomaticFrameAdvance then return end

	self.AutomaticFrameAdvance = true

	self.Think = function( self )
		self:NextThink( CurTime() )
		return true
	end

	self:Think()
end

function ENT:Think()
	return false
end

function ENT:OnRemove()
	self:StopLeakAir()
end

function ENT:lvsMakeSpherical( radius )
	if not radius or radius <= 0 then
		radius = (self:OBBMaxs() - self:OBBMins()) * 0.5
		radius = math.max( radius.x, radius.y, radius.z )
	end

	self:PhysicsInitSphere( radius, "jeeptire"  )

	self:SetRadius( radius )

	self:DrawShadow( not self:GetHideModel() )
end

function ENT:PhysicsMaterialUpdate( TargetValue )
	local base = self:GetBase()
	local PhysObj = self:GetPhysicsObject()

	if not IsValid( base ) or not IsValid( PhysObj ) then return end

	local ListID = math.Clamp( math.Round( (TargetValue or 1) * 10, 0 ), 0, 12 )

	PhysObj:SetMaterial( base.WheelPhysicsMaterials[ ListID ] )
end

function ENT:PhysicsOnGround()

	local PhysObj = self:GetPhysicsObject()

	if not IsValid( PhysObj ) then return false end

	local EntLoad,_ = PhysObj:GetStress()

	return EntLoad > 0
end

function ENT:AntiSlingshot()
	self:DisableSuspension()

	timer.Simple(0.1, function()
		if not IsValid( self ) then return end

		self:EnableSuspension()
	end)
end

function ENT:PhysicsCollide( data, physobj )
	local HitEntity = data.HitEntity
	local HitObject = data.HitObject

	if IsValid( HitEntity ) and IsValid( HitObject ) then
		physobj:SetVelocityInstantaneous( data.OurOldVelocity )

		if HitObject:IsMotionEnabled() and HitObject:GetMass() < physobj:GetMass() then
			HitObject:SetVelocityInstantaneous( data.OurOldVelocity * 2 )
		end
	end

	local base = self:GetBase()

	if not IsValid( base ) then return end

	base:OnWheelCollision( data, physobj )

	if base.PhysicsWeightScale > 1.6 then
		if data.Speed > 150 and data.DeltaTime > 0.2 then
			local VelDif = data.OurOldVelocity:Length() - data.OurNewVelocity:Length()
			local Volume = math.min( math.abs( VelDif ) / 300 , 1 )

			self:EmitSound( "lvs/vehicles/generic/suspension_hit_".. math.random(1,17) ..".ogg", 70, 100, Volume ^ 2 )
		end

		if math.abs(data.OurNewVelocity.z - data.OurOldVelocity.z) > 100 then
			physobj:SetVelocityInstantaneous( data.OurOldVelocity )
		end

		return
	end

	local Up = base:GetUp()

	if Up.z < 0.9 then return end

	local Radius = self:GetRadius()
	local BumpPos = data.HitPos + Up * Radius
	local SurfacePos = self:GetPos()
	local ToBump = BumpPos - SurfacePos
	local BumpHeight = ToBump.z

	if BumpHeight < 2 or BumpHeight > Radius * 0.9 then return end

	if base:AngleBetweenNormal( ToBump:GetNormalized(), data.OurOldVelocity:GetNormalized() ) > 65 then return end

	local VelDif = data.OurOldVelocity:Length() - data.OurNewVelocity:Length()
	local Volume = math.min( math.abs( VelDif ) / 300 , 1 )
	self:EmitSound( "lvs/vehicles/generic/suspension_hit_".. math.random(1,17) ..".ogg", 70, 100, Volume ^ 2 )

	if self:GetRPM() < 175 then return end

	physobj:SetPos( physobj:GetPos() + Up * BumpHeight )
	physobj:SetVelocityInstantaneous( data.OurOldVelocity )

	self:AntiSlingshot()
end
