AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

ENT.SpawnNormalOffset = 100

function ENT:OnSpawn( PObj )
	PObj:SetMass( 1000 )

	self:AddDriverSeat( Vector(45,0,5), Angle(0,-90,0) )

	self:SetGunnerSeat( self:AddPassengerSeat( Vector(-107,0,18), Angle(0,90,0) ) )

	self:AddPassengerSeat( Vector(-30,0,18), Angle(0,-90,0) )

	self:AddEngine(  Vector(-105,0,58) )
	self:AddEngineSound( Vector(-105,0,58) )

	self.SNDLeft = self:AddSoundEmitter( Vector(207.65,303.52,-48.35), "lvs/vehicles/arc170/fire.mp3", "lvs/vehicles/arc170/fire.mp3" )
	self.SNDLeft:SetSoundLevel( 110 )

	self.SNDRight = self:AddSoundEmitter( Vector(207.65,-303.52,-48.35), "lvs/vehicles/arc170/fire.mp3", "lvs/vehicles/arc170/fire.mp3" )
	self.SNDRight:SetSoundLevel( 110 )
end

function ENT:OnEngineActiveChanged( Active )
	if Active then
		self:EmitSound( "lvs/vehicles/naboo_n1_starfighter/start.wav" )
	else
		self:EmitSound( "lvs/vehicles/naboo_n1_starfighter/stop.wav" )
		self:SetFoils( false )
	end
end

function ENT:OnTick()
	if self:ForceDisableFoils() then
		if self:GetThrottle() < 0.1 then
			self:DisableVehicleSpecific()
		end
	end
end

function ENT:OnVehicleSpecificToggled( new )
	local cur = self:GetFoils()

	if cur ~= new then
		self:SetFoils( new )
	end
end

function ENT:ForceDisableFoils()
	local trace = util.TraceLine( {
		start = self:LocalToWorld( Vector(0,0,50) ),
		endpos = self:LocalToWorld( Vector(0,0,-150) ),
		filter = self:GetCrosshairFilterEnts()
	} )
	
	return trace.Hit
end