AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

ENT.SpawnNormalOffset = 25

function ENT:OnSpawn( PObj )
	PObj:SetMass( 2500 )

	local DriverSeat = self:AddDriverSeat( Vector(-30,0,43), Angle(0,-90,0) )
	DriverSeat.HidePlayer = true

	local WheelMass = 25
	local WheelRadius = 14
	local WheelPos = {
		Vector(-85,-60,-12),
		Vector(-5,-60,-11),
		Vector(80,-60,-8),
		Vector(-85,60,-12),
		Vector(-5,60,-11),
		Vector(80,60,-8),
	}

	for _, Pos in pairs( WheelPos ) do
		--self:AddWheel( pos, radius, mass, buoyancy_ratio )
		self:AddWheel( Pos, WheelRadius, WheelMass, 10 )
	end

	self:AddEngineSound( Vector(0,0,0) )

	self.SNDLeft = self:AddSoundEmitter( Vector(256,0,36), "lvs/vehicles/iftx/fire.mp3", "lvs/vehicles/iftx/fire.mp3" )
	self.SNDLeft:SetSoundLevel( 110 )
	self.SNDLeft:SetParent( NULL )
	local ID = self:LookupAttachment( "muzzle_left" )
	local Muzzle = self:GetAttachment( ID )
	self.SNDLeft:SetPos( Muzzle.Pos )
	self.SNDLeft:SetParent( self, ID )

	self.SNDRight = self:AddSoundEmitter( Vector(256,0,36), "lvs/vehicles/iftx/fire.mp3", "lvs/vehicles/iftx/fire.mp3" )
	self.SNDRight:SetSoundLevel( 110 )
	self.SNDRight:SetParent( NULL )
	local ID = self:LookupAttachment( "muzzle_right" )
	local Muzzle = self:GetAttachment( ID )
	self.SNDRight:SetPos( Muzzle.Pos )
	self.SNDRight:SetParent( self, ID )
end

function ENT:OnTick()
	local phys = self:GetPhysicsObject()

	if not IsValid( phys ) then return end

	local steer = phys:GetAngleVelocity().z

	local VelL = self:WorldToLocal( self:GetPos() + self:GetVelocity() )

	self:SetPoseParameter( "move_x", math.Clamp(-VelL.x / self.MaxVelocityX,-1,1) )
	self:SetPoseParameter( "move_y", math.Clamp(-VelL.y / self.MaxVelocityY + steer / 100,-1,1) )
end

function ENT:OnCollision( data, physobj )
	if self:WorldToLocal( data.HitPos ).z < 0 then return true end -- dont detect collision  when the lower part of the model touches the ground

	return false
end

function ENT:OnIsCarried( name, old, new)
	if new == old then return end

	if new then
		self:SetPoseParameter("cannon_right_pitch", 0 )
		self:SetPoseParameter("cannon_right_yaw", 0 )

		self:SetPoseParameter("cannon_left_pitch", 0 )
		self:SetPoseParameter("cannon_left_yaw", 0 )

		self:SetPoseParameter( "move_x", 0 )
		self:SetPoseParameter( "move_y", 0 )
	
		self:SetPoseParameter("turret_pitch", 0 )
		self:SetPoseParameter("turret_yaw", 0 )

		self:SetBTLFire( false )
	end
end

function ENT:OnVehicleSpecificToggled( IsActive )
	self:SetBodygroup(2, (self:GetBodygroup(2) == 1) and 0 or 1 )
	self:EmitSound( "buttons/lightswitch2.wav", 75, 105 )
end