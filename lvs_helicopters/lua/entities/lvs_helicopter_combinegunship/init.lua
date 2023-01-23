AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:OnSpawn( PObj )
	local DriverSeat = self:AddDriverSeat( Vector(120,0,-40), Angle(0,-90,0) )
	DriverSeat:SetCameraDistance( 0.2 )

	self:AddEngineSound( Vector(0,0,0) )

	self:DrawShadow( false )

	local Body = ents.Create( "lvs_gunship_body" )
	Body:SetPos( self:GetPos() )
	Body:SetAngles( self:GetAngles() )
	Body:Spawn()
	Body:Activate()
	Body:SetParent( self )
	self:DeleteOnRemove( Body )
	self:TransferCPPI( Body )
	self:SetBody( Body )
end
