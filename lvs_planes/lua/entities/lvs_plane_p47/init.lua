AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

ENT.WheelSteerAngle = 20

function ENT:OnSpawn( PObj )
	PObj:SetMass( 5000 )

	self:AddDriverSeat( Vector(32,0,66.15), Angle(0,-90,0) )

	self:AddWheel( Vector(92.176,-83.624,3,896), 14.5, 200 )
	self:AddWheel( Vector(92.176,83.624,3,896), 14.5, 200 )
	self:AddWheel( Vector(-129.336,0,50), 14.5, 200, LVS.WHEEL_STEER_REAR )

	self:AddEngine( Vector(140,0,64) )

	self:AddRotor( Vector(180,0,64) )

	local Exhaust = {
		{
			pos = Vector(116.8,17.6,34),
			ang = Angle(-120,-45,0),
		},
		{
			pos = Vector(112,17.6,34),
			ang = Angle(-120,-45,0),
		},
		{
			pos = Vector(116.8,-17.6,34),
			ang = Angle(-120,45,0),
		},
		{
			pos = Vector(112,-17.6,34),
			ang = Angle(-120,45,0),
		},
		{
			pos = Vector(116.8,18,38),
			ang = Angle(-120,-45,0),
		},
		{
			pos = Vector(112,18,38),
			ang = Angle(-120,-45,0),
		},
		{
			pos = Vector(116.8,-18,38),
			ang = Angle(-120,45,0),
		},
		{
			pos = Vector(112,-18,38),
			ang = Angle(-120,45,0),
		},
	}

	for id, exh in pairs( Exhaust ) do
		self:AddExhaust( exh.pos, exh.ang )
	end

	self.MISSILE_ENTITIES = {}

	for ID, pos in pairs( self.MISSILE_POSITIONS ) do
		local Missile = ents.Create( "prop_dynamic" )
		Missile:SetModel( self.MISSILE_MDL )
		Missile:SetModelScale( 0.8 )
		Missile:SetPos( self:LocalToWorld( pos * 0.8 ) )
		Missile:SetAngles( self:LocalToWorldAngles( Angle(0, -self:Sign( pos.y ), 0 ) ) )
		Missile:SetMoveType( MOVETYPE_NONE )
		Missile:Spawn()
		Missile:Activate()
		Missile:SetNotSolid( true )
		Missile:DrawShadow( false )
		Missile:SetParent( self )
		Missile.DoNotDuplicate = true
		self:TransferCPPI( Missile )

		
		self.MISSILE_ENTITIES[ ID ] = Missile
	end
end

function ENT:OnMaintenance()
	if not self.MISSILE_ENTITIES then return end

	for _, Missile in pairs( self.MISSILE_ENTITIES ) do
		if not IsValid( Missile ) then continue end
		Missile:SetNoDraw( false )
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