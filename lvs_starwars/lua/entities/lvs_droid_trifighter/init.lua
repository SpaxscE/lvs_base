AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

ENT.SpawnNormalOffset = 80

function ENT:OnSpawn( PObj )
	PObj:SetMass( 1000 )

	self:AddDriverSeat( Vector(100,0,-15), Angle(0,-90,0) ).HidePlayer = true

	self:AddEngine( Vector(-70,0,10) )
	self:AddEngineSound( Vector(100,0,0) )

	self.PrimarySND = self:AddSoundEmitter( Vector(152.24,0,0), "lvs/vehicles/droidtrifighter/fire_wing.mp3", "lvs/vehicles/droidtrifighter/fire_wing.mp3" )
	self.PrimarySND:SetSoundLevel( 110 )

	self.SecondarySND = self:AddSoundEmitter( Vector(152.24,0,0), "lvs/vehicles/droidtrifighter/fire_nose.mp3", "lvs/vehicles/droidtrifighter/fire_nose.mp3" )
	self.SecondarySND:SetSoundLevel( 110 )
end

function ENT:OnEngineActiveChanged( Active )
	if Active then
		self:EmitSound( "lvs/vehicles/naboo_n1_starfighter/start.wav" )
	else
		self:EmitSound( "lvs/vehicles/naboo_n1_starfighter/stop.wav" )
	end
end