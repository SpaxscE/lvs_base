AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:OnSpawn( PObj )
	local WheelModel = "models/blu/carriage_wheel.mdl"

	local FrontAxle = self:DefineAxle( {
		Axle = {
			ForwardAngle = Angle(0,0,0),
			SteerType = LVS.WHEEL_STEER_NONE,
			SteerAngle = 0,
			BrakeFactor = 1,
			UseHandbrake = true,
		},
		Wheels = {
			self:AddWheel( {
				pos = Vector(3.41,33.5,2),
				mdl = WheelModel,
				mdl_ang = Angle(0,0,0),
			} ),

			self:AddWheel( {
				pos = Vector(3.41,-33.5,2),
				mdl = WheelModel,
				mdl_ang = Angle(0,180,0),

			} ),
		},
		Suspension = {
			Height = 0,
			MaxTravel = 0,
			ControlArmLength = 0,
		},
	} )

	self:AddTrailerHitch( Vector(-86.5,0,18), LVS.HITCHTYPE_FEMALE )

	local SupportEnt = ents.Create( "prop_physics" )

	if not IsValid( SupportEnt ) then return end

	SupportEnt:SetModel( "models/props_junk/PopCan01a.mdl" )
	SupportEnt:SetPos( self:LocalToWorld( Vector(-57,0,-13) ) )
	SupportEnt:SetAngles( self:GetAngles() )
	SupportEnt:Spawn()
	SupportEnt:Activate()
	SupportEnt:PhysicsInitSphere( 5, "default_silent" )
	SupportEnt:SetNoDraw( true ) 
	SupportEnt:SetCollisionGroup( COLLISION_GROUP_PASSABLE_DOOR )
	SupportEnt.DoNotDuplicate = true
	self:DeleteOnRemove( SupportEnt )
	SupportEnt:SetOwner( self )

	constraint.Weld( self, SupportEnt, 0, 0, 0, false, false )

	self.SupportEnt = SupportEnt:GetPhysicsObject()

	if not IsValid( self.SupportEnt ) then return end

	self.SupportEnt:SetMass( 250 )
end

function ENT:OnCoupled( targetVehicle, targetHitch )
	timer.Simple(0.2, function()
		if not IsValid( self ) or not IsValid( self._MountEnt ) then return end

		self._MountEnt:RebuildCrosshairFilterEnts()
	end)

	self:SetProng( true )

	if not IsValid( self.SupportEnt ) then return end
	self.SupportEnt:SetMass( 1 )
end

function ENT:OnDecoupled( targetVehicle, targetHitch )
	timer.Simple(0.2, function()
		if not IsValid( self ) or not IsValid( self._MountEnt ) then return end

		self._MountEnt:RebuildCrosshairFilterEnts()
	end)

	self:SetProng( false )

	if not IsValid( self.SupportEnt ) then return end
	self.SupportEnt:SetMass( 250 )
end

function ENT:OnStartDrag( caller, activator )
	self:SetProng( true )

	if not IsValid( self.SupportEnt ) then return end
	self.SupportEnt:SetMass( 1 )
end

function ENT:OnStopDrag( caller, activator )
	self:SetProng( false )

	if not IsValid( self.SupportEnt ) then return end
	self.SupportEnt:SetMass( 250 )
end

function ENT:Mount( ent )
	if IsValid( self._MountEnt ) or ent._IsMounted then return end

	if ent:IsPlayerHolding() then return end
 
	ent:SetOwner( self )
	ent:SetPos( self:GetPos() )
	ent:SetAngles( self:GetAngles() )

	ent._MountOriginalCollision = ent:GetCollisionGroup()
	self._MountEnt = ent
	ent._IsMounted = true

	ent:SetCollisionGroup( COLLISION_GROUP_WORLD )

	self._MountConstraint = constraint.Weld( ent, self, 0, 0, 0, false, false )

	ent:RebuildCrosshairFilterEnts()
end

function ENT:Dismount()
	if not IsValid( self._MountEnt ) or not IsValid( self._MountConstraint ) then return end

	self._MountConstraint:Remove()

	self._MountEnt._IsMounted = nil

	local ent = self._MountEnt

	timer.Simple(1, function()
		if not IsValid( ent ) then return end

		ent:SetOwner( NULL )

		if ent._MountOriginalCollision then
			ent:SetCollisionGroup( ent._MountOriginalCollision )

			ent._MountOriginalCollision = nil
		end

	end)

	self._MountEnt.CrosshairFilterEnts = nil

	self._MountEnt = nil
end

function ENT:OnCollision( data, physobj )
	local ent = data.HitEntity

	if not IsValid( ent ) or ent:GetClass() ~= "lvs_trailer_flak" then return end

	timer.Simple(0, function()
		if not IsValid( self ) or not IsValid( ent ) then return end

		self:Mount( ent )
	end)
end

function ENT:OnTick()
	if not IsValid( self._MountEnt ) or not self._MountEnt:IsPlayerHolding() then return end

	self:Dismount()
end

function ENT:Use( ply )
	if not IsValid( self._MountEnt ) then return end

	self:Dismount()
end