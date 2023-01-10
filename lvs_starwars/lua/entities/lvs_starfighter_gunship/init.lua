AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

ENT.SpawnNormalOffset = 25

function ENT:OnSpawn( PObj )
	PObj:SetMass( 10000 )

	self:AddDriverSeat( Vector(207,0,120), Angle(0,-90,0) )

	self:AddEngine(  Vector(-105,0,58) )
	self:AddEngineSound( Vector(-105,0,58) )
end

function ENT:OnEngineActiveChanged( Active )
	if Active then
		self:EmitSound( "lvs/vehicles/naboo_n1_starfighter/start.wav" )
	else
		self:EmitSound( "lvs/vehicles/naboo_n1_starfighter/stop.wav" )
	end
end
