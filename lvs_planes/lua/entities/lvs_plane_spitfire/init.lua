AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:OnSpawn( PObj )
	PObj:SetMass( 5000 )

	self:AddDriverSeat( Vector(29,0,61), Angle(0,-90,0) )

	self:AddWheel( Vector(80.28,45,11.05), 10, 300 )
	self:AddWheel( Vector(80.28,-45,11.05), 10, 300 )
	self:AddWheel (Vector(-150.29,0,64), 10, 200, LVS.WHEEL_STEER_REAR )

	self:AddEngine( Vector(115,0,75.52) )

	self:AddRotor( Vector(165,0,75.52) )

	local Exhaust = {
		{
			pos = Vector(128.47,16.7,79),
			ang = Angle(-90,-20,0),
		},
		{
			pos = Vector(117.01,17.6,78.93),
			ang = Angle(-90,-20,0),
		},
		{
			pos = Vector(105.68,17.49,79.16),
			ang = Angle(-90,-20,0),
		},
	}

	for id, exh in pairs( Exhaust ) do
		for i = -1, 1, 2 do
			local pos = Vector( exh.pos.x, exh.pos.y * i, exh.pos.z )
			local ang = Angle( exh.ang.p, exh.ang.y * i, exh.ang.r )

			self:AddExhaust( pos, ang )
		end
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