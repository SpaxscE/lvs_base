AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:OnSpawn( PObj )
	local DriverSeat = self:AddDriverSeat( Vector(85,-20,-7), Angle(0,-90,10) )
	DriverSeat:SetCameraDistance( 1 )

	local PassengerSeats = {
		{
			pos = Vector(85,20,-7),
			ang = Angle(0,-90,10)
		},
		{
			pos = Vector(30,20,0),
			ang = Angle(0,-90,0)
		},
		{
			pos = Vector(30,-20,0),
			ang = Angle(0,-90,0)
		},
		{
			pos = Vector(-20,-20,0),
			ang = Angle(0,-90,0)
		},
		{
			pos = Vector(-20,20,0),
			ang = Angle(0,-90,0)
		},
		{
			pos = Vector(-70,-20,0),
			ang = Angle(0,-90,0)
		},
		{
			pos = Vector(-70,20,0),
			ang = Angle(0,-90,0)
		},
		{
			pos = Vector(-120,-20,0),
			ang = Angle(0,-90,0)
		},
		{
			pos = Vector(-120,20,0),
			ang = Angle(0,-90,0)
		},
	}
	
	for num, v in pairs( PassengerSeats ) do
		local Pod = self:AddPassengerSeat( v.pos, v.ang )

		if num == 1 then
			self:SetGunnerSeat( Pod )
		end
	end

	self:AddEngineSound( Vector(40,0,10) )

	self.Rotor = self:AddRotor( Vector(0,0,100), Angle(2,0,0), 380, -4000 )
	self.Rotor:SetHP( 50 )
	function self.Rotor:OnDestroyed( base )
		base:SetBodygroup( 1, 2 )
		base:DestroyEngine()

		self:EmitSound( "physics/metal/metal_box_break2.wav" )
	end

	self.TailRotor = self:AddRotor( Vector(-575.360840,31.147699,105.635742), Angle(0,0,90), 80, -6000 )
	self.TailRotor:SetHP( 50 )
	function self.TailRotor:OnDestroyed( base )
		base:SetBodygroup( 2, 2 ) 
		base:DestroySteering( 2.5 )

		self:EmitSound( "physics/metal/metal_box_break2.wav" )
	end
end

function ENT:SetRotor( PhysRot )
	self:SetBodygroup( 1, PhysRot and 0 or 1 ) 
end

function ENT:SetTailRotor( PhysRot )
	self:SetBodygroup( 2, PhysRot and 0 or 1 ) 
end

function ENT:OnTick()
	local PhysRot = self:GetThrottle() < 0.85

	if not self:IsSteeringDestroyed() then
		self:SetTailRotor( PhysRot )
	end

	if not self:IsEngineDestroyed() then
		self:SetRotor( PhysRot )
	end
end

function ENT:OnEngineActiveChanged( Active )
	if Active then
		self:EmitSound( "lvs/vehicles/helicopter/start.wav" )
	end
end