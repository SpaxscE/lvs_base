AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

ENT.WheelAutoRetract = true

function ENT:OnSpawn( PObj )
	PObj:SetMass( 1000 )

	self:AddDriverSeat( Vector(5,8,38), Angle(0,-90,0) )

	for _, Pos in pairs( { Vector(5,-8,38), Vector(-35,-8,38), Vector(-35,8,38) } ) do
		self:AddPassengerSeat( Pos, Angle(0,-90,0) )
	end

	self:AddWheel( Vector(-30,50,10), 15, 80 )
	self:AddWheel( Vector(-30,-50,10), 15, 80 )
	self:AddWheel( Vector(53.3,0,5), 15, 80, LVS.WHEEL_STEER_FRONT )

	self:AddEngine( Vector(40,0,45) )

	self:AddRotor( Vector(50,0,47.28) )

	self:AddExhaust( Vector(65.04,-14.93,19.46), Angle(145,-90,0) )
end

function ENT:OnEngineActiveChanged( Active )
	if Active then
		self:EmitSound( "lvs/vehicles/cessna/start.wav" )
	else
		self:EmitSound( "lvs/vehicles/cessna/stop.wav" )
	end
end
