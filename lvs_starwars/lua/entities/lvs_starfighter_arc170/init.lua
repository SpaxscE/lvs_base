AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

ENT.SpawnNormalOffset = 100

function ENT:OnSpawn( PObj )
	PObj:SetMass( 1000 )

	self:AddDriverSeat( Vector(45,0,5), Angle(0,-90,0) )

	self:AddPassengerSeat( Vector(-30,0,18), Angle(0,-90,0) )

	local Pod = self:AddPassengerSeat( Vector(-107,0,18), Angle(0,90,0) )
	self:SetTailGunnerSeat( Pod )

	self:AddEngine( Vector(-95,65,7) )
	self:AddEngine( Vector(-95,-65,7) )
	self:AddEngineSound( Vector(0,0,10) )

	self.SNDLeft = self:AddSoundEmitter( Vector(207.65,303.52,-48.35), "lvs/vehicles/arc170/fire.mp3", "lvs/vehicles/arc170/fire.mp3" )
	self.SNDLeft:SetSoundLevel( 110 )

	self.SNDRight = self:AddSoundEmitter( Vector(207.65,-303.52,-48.35), "lvs/vehicles/arc170/fire.mp3", "lvs/vehicles/arc170/fire.mp3" )
	self.SNDRight:SetSoundLevel( 110 )

	self.SNDTail = self:AddSoundEmitter( Vector(-171.69,0,45), "lvs/vehicles/arc170/fire_gunner.mp3", "lvs/vehicles/arc170/fire_gunner.mp3" )
	self.SNDTail:SetSoundLevel( 110 )

	self:SetMaxThrottle( 1.2 )
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

	if not cur and self:ForceDisableFoils() then return end

	if cur ~= new then
		self:SetFoils( new )
	end
end

function ENT:OnFoilsChanged( name, old, new)
	if new == old then return end

	if new == true then
		self:SetMaxThrottle( 1 )
	else
		self:SetMaxThrottle( 1.2 )
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