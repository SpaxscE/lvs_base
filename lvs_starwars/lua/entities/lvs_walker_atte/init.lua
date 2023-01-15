AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_ikfunctions.lua" )
AddCSLuaFile( "cl_camera.lua" )
AddCSLuaFile( "cl_legs.lua" )
include("shared.lua")
include("sv_ragdoll.lua")
include("sv_controls.lua")
include("sv_contraption.lua")

function ENT:OnSpawn( PObj )
	PObj:SetMass( 5000 )

	local DriverSeat = self:AddDriverSeat( Vector(218,0,148), Angle(0,-90,0) )
	DriverSeat:SetCameraDistance( 0.75 )

	self.SNDPrimary = self:AddSoundEmitter( Vector(250,0,148), "lvs/vehicles/atte/fire.mp3", "lvs/vehicles/atte/fire.mp3" )
	self.SNDPrimary:SetSoundLevel( 110 )
	
	local TurretSeat = self:AddPassengerSeat( Vector(150,0,150), Angle(0,-90,0) )

	local ID = self:LookupAttachment( "driver_turret" )
	local Attachment = self:GetAttachment( ID )

	if Attachment then
		local Pos,Ang = LocalToWorld( Vector(0,-5,8), Angle(180,0,-90), Attachment.Pos, Attachment.Ang )

		TurretSeat:SetParent( NULL )
		TurretSeat:SetPos( Pos )
		TurretSeat:SetAngles( Ang )
		TurretSeat:SetParent( self )
	end

	local GunnerSeat = self:AddPassengerSeat( Vector(150,0,150), Angle(0,-90,0) )
	GunnerSeat.HidePlayer = true

	for i =1,4 do
		self:AddPassengerSeat( Vector(75,-62.5 + i * 25,150), Angle(0,-90,0) ).HidePlayer = true
	end
end

function ENT:InitRear()
	if IsValid( self:GetRearEntity() ) then return end

	local ent = ents.Create( "lvs_walker_atte_rear" )

	if not IsValid( ent ) then
		self:Remove()

		print("LVS: couldn't create 'lvs_atte_rear'. Vehicle terminated.")

		return
	end

	self:SetRearEntity( ent )

	ent:SetPos( self:GetPos() )
	ent:SetAngles( self:GetAngles() )
	ent:SetBase( self )
	ent:Spawn()
	ent:Activate()
	ent:DeleteOnRemove( self )
	self:DeleteOnRemove( ent )
	self:TransferCPPI( ent )

	local rPObj = ent:GetPhysicsObject()

	if not IsValid( rPObj ) then 
		self:Remove()

		print("LVS: missing model. Vehicle terminated.")

		return
	end

	rPObj:SetMass( 5000 ) 

	local Friction = 0
	local ballsocket = constraint.AdvBallsocket(ent, self,0,0,Vector(35,0,128),Vector(35,0,128),0,0, -20, -20, -20, 20, 20, 20, Friction, Friction, Friction, 0, 1)
	ballsocket:DeleteOnRemove( self )
	ballsocket:DeleteOnRemove( ent )
	self:TransferCPPI( ballsocket )

	self:AddToMotionController( rPObj )

	-- clear the filters, because they might have been build by now
	self.CrosshairFilterEnts = nil
	self._EntityLookUp = nil
end

function ENT:OnTick()
	self:InitRear() -- this fixes a gmod bug
	self:ContraptionThink()
end

function ENT:OnMaintenance()
	self:UnRagdoll()
end

function ENT:AlignView( ply, SetZero )
	if not IsValid( ply ) then return end

	timer.Simple( 0, function()
		if not IsValid( ply ) or not IsValid( self ) then return end

		ply:SetEyeAngles( Angle(0,90,0) )
	end)
end
