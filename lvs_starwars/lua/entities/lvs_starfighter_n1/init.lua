AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:OnSpawn( PObj )
	PObj:SetMass( 5000 )

	self:AddDriverSeat( Vector(-30,0,33), Angle(0,-90,0) )

	self:AddEngine( Vector(100,145,30) )
	self:AddEngine( Vector(100,-145,30) )
	self:AddEngineSound( Vector(100,0,0) )
end
