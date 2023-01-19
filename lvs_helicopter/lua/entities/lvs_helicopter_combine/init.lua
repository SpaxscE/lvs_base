AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:OnSpawn( PObj )
	self:AddDriverSeat( Vector(120,0,-40), Angle(0,-90,0) )
end