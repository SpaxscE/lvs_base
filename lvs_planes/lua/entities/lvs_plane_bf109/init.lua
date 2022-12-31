AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:OnSpawn( PObj )
	self:SetBodygroup( 14, 1 ) 
	self:SetBodygroup( 13, 1 ) 

	PObj:SetMass( 5000 )

	self:AddDriverSeat( Vector(32,0,67.5), Angle(0,-90,0) )

	self:AddWheel( Vector(78.12,55,15.16), 13, 600 )
	self:AddWheel( Vector(78.12,-55,15.16), 13, 600 )
	self:AddWheel( Vector(-146.61,0,76), 13, 1200, LVS.WHEEL_STEER_REAR )

	self:AddEngine( Vector(115,0,75) )

	self:AddRotor( Vector(160,0,75) )

	local Exhaust = {
		{
			pos = Vector(129.28,17.85,68.91),
			ang = Angle(-90,-20,0),
		},
		{
			pos = Vector(122.79,17.88,69.14),
			ang = Angle(-90,-20,0),
		},
		{
			pos = Vector(114.7,18.9,69.11),
			ang = Angle(-90,-20,0),
		},
		{
			pos = Vector(107.43,19.74,68.82),
			ang = Angle(-90,-20,0),
		},
		{
			pos = Vector(99.56,20.28,69.05),
			ang = Angle(-90,-20,0),
		},
		{
			pos = Vector(91.97,20.31,68.9),
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
		self:EmitSound( "lvs/vehicles/bf109/engine_start.wav" )
	else
		self:EmitSound( "lvs/vehicles/bf109/engine_stop.wav" )
	end
end