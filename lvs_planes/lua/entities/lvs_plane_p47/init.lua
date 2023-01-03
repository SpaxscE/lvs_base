AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

ENT.WheelSteerAngle = 25

function ENT:OnSpawn( PObj )
	PObj:SetMass( 5000 )

	self:AddDriverSeat( Vector(32,0,66.15), Angle(0,-90,0) )

	self:AddWheel( Vector(92.176,-83.624,3,896), 14.5, 200 )
	self:AddWheel( Vector(92.176,83.624,3,896), 14.5, 200 )
	self:AddWheel( Vector(-129.336,0,50), 14.5, 200, LVS.WHEEL_STEER_REAR )

	self:AddEngine( Vector(140,0,64) )

	self:AddRotor( Vector(180,0,64) )

	local Exhaust = {
		{
			pos = Vector(116.8,17.6,34),
			ang = Angle(-120,-45,0),
		},
		{
			pos = Vector(112,17.6,34),
			ang = Angle(-120,-45,0),
		},
		{
			pos = Vector(116.8,-17.6,34),
			ang = Angle(-120,45,0),
		},
		{
			pos = Vector(112,-17.6,34),
			ang = Angle(-120,45,0),
		},
		{
			pos = Vector(116.8,18,38),
			ang = Angle(-120,-45,0),
		},
		{
			pos = Vector(112,18,38),
			ang = Angle(-120,-45,0),
		},
		{
			pos = Vector(116.8,-18,38),
			ang = Angle(-120,45,0),
		},
		{
			pos = Vector(112,-18,38),
			ang = Angle(-120,45,0),
		},
	}

	for id, exh in pairs( Exhaust ) do
		self:AddExhaust( exh.pos, exh.ang )
	end
end

function ENT:OnLandingGearToggled( IsDeployed )
	self:EmitSound( "lvs/vehicles/generic/gear.wav" )
end

function ENT:OnEngineActiveChanged( Active )
	if Active then
		self:EmitSound( "lvs/vehicles/spitfire/engine_start.wav" )
	else
		self:EmitSound( "lvs/vehicles/spitfire/engine_stop.wav" )
	end
end