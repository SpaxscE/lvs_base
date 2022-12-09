AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:OnSpawn( PObj )
	self:SetBodygroup( 14, 1 ) 
	self:SetBodygroup( 13, 1 ) 

	PObj:SetMass( 5000 )

	self:AddDriverSeat( Vector(32,0,67.5), Angle(0,-90,0) )

	self:AddWheel( Vector(78.12,55,15.16), 13, 1200 )
	self:AddWheel( Vector(78.12,-55,15.16), 13, 600 )
	self:AddWheel( Vector(-146.61,0,76), 13, 600, LVS.WHEEL_STEER_REAR )
end

function ENT:OnEngineStarted()
	self:EmitSound( "lvs/bf109/start.wav" )
end

function ENT:OnEngineStopped()
	self:EmitSound( "lvs/bf109/stop.wav" )
end