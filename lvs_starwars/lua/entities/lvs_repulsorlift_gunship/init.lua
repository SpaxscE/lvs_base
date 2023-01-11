AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

ENT.SpawnNormalOffset = 25

function ENT:OnSpawn( PObj )
	PObj:SetMass( 10000 )

	self:AddDriverSeat( Vector(207,0,120), Angle(0,-90,0) ):SetCameraDistance( 1 )

	self:AddEngine(  Vector(-385,0,255) )
	self:AddEngineSound( Vector(-105,0,58) )

	self.PrimarySND = self:AddSoundEmitter( Vector(256,0,36), "lvs/vehicles/laat/fire.mp3", "lvs/vehicles/laat/fire.mp3" )
	self.PrimarySND:SetSoundLevel( 110 )
end

function ENT:OnEngineActiveChanged( Active )
	if Active then
		self:EmitSound( "lvs/vehicles/naboo_n1_starfighter/start.wav" )
	else
		self:EmitSound( "lvs/vehicles/naboo_n1_starfighter/stop.wav" )
	end
end
