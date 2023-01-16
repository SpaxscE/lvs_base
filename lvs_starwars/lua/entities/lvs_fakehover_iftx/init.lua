AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:OnSpawn( PObj )
	PObj:SetMass( 2500 )

	local DriverSeat = self:AddDriverSeat( Vector(-30,0,43), Angle(0,-90,0) )
	DriverSeat.HidePlayer = true

	local WheelMass = 25
	local WheelRadius = 14
	local WheelPos = {
		Vector(-85,-60,-12),
		Vector(-5,-60,-11),
		Vector(80,-60,-8),
		Vector(-85,60,-12),
		Vector(-5,60,-11),
		Vector(80,60,-8),
	}

	for _, Pos in pairs( WheelPos ) do
		--self:AddWheel( pos, radius, mass, buoyancy_ratio )
		self:AddWheel( Pos, WheelRadius, WheelMass, 10 )
	end
end

function ENT:OnCollision( data, physobj )
	if self:WorldToLocal( data.HitPos ).z < 0 then return true end -- dont detect collision  when the lower part of the model touches the ground

	return false
end
