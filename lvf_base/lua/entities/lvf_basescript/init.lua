--DO NOT EDIT OR REUPLOAD THIS FILE

AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:SpawnFunction( ply, tr, ClassName )

	if not tr.Hit then return end

	local ent = ents.Create( ClassName )
	ent:StoreCPPI( ply )
	ent:SetPos( tr.HitPos + tr.HitNormal * 15 )
	ent:Spawn()
	ent:Activate()

	return ent
end

function ENT:Initialize()
	self:SetModel( self.MDL )

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )
	self:SetRenderMode( RENDERMODE_TRANSALPHA )
	self:AddFlags( FL_OBJECT )

	local PObj = self:GetPhysicsObject()

	if not IsValid( PObj ) then 
		self:Remove()
		
		print("LVF: missing model. Vehicle terminated.")
		
		return
	end

	PObj:EnableDrag( false )
	PObj:EnableMotion( false )
	PObj:SetMass( self.Mass )

	self:RunOnSpawn()

	self:StartMotionController()
	self.ShadowParams = {}

	PObj:EnableMotion( true )
	self:PhysWake()
end

function ENT:PhysicsSimulate( phys, deltatime )
end

function ENT:RunOnSpawn()
end

function ENT:Think()
	self:HandleActive()
	self:OnTick()

	self:NextThink( CurTime() )
	
	return true
end

function ENT:OnTick()
end

function ENT:HandleActive()
	local Pod = self:GetDriverSeat()

	if not IsValid( Pod ) then
		self:SetActive( false )
		return
	end

	local Driver = Pod:GetDriver()
	local Active = self:GetActive()

	if Driver ~= self:GetDriver() then
		if self:GetlvfLockedStatus() then
			self:UnLock()
		end

		if self.HideDriver then
			if IsValid( self:GetDriver() ) then
				self:GetDriver():SetNoDraw( false )
			end
			if IsValid( Driver ) then
				Driver:SetNoDraw( true )
			end
		end

		self:SetDriver( Driver )
		self:SetActive( IsValid( Driver ) )

		if IsValid( Driver ) then
			self:AlignView( Driver )
		end

		if Active then
			self:EmitSound( "vehicles/atv_ammo_close.wav" )
		else
			self:EmitSound( "vehicles/atv_ammo_open.wav" )
		end
	end
end

function ENT:OnRemove()
end

function ENT:Lock()
	self:SetlvfLockedStatus( true )
	self:EmitSound( "doors/latchlocked2.wav" )
end

function ENT:UnLock()
	self:SetlvfLockedStatus( false )
	self:EmitSound( "doors/latchunlocked1.wav" )
end

function ENT:Use( ply )
	if not IsValid( ply ) then return end

	if self:GetlvfLockedStatus() then 

		self:EmitSound( "doors/default_locked.wav" )

		return
	end

	self:SetPassenger( ply )
end

function ENT:AlignView( ply )
	if not IsValid( ply ) then return end

	timer.Simple( FrameTime() * 2, function()
		if not IsValid( ply ) or not IsValid( self ) then return end
		local Ang = self:GetAngles()
		Ang.r = 0
		ply:SetEyeAngles( Ang )
	end)
end

function ENT:SetPassenger( ply )
	if not IsValid( ply ) then return end

	local AI = self:GetAI()
	local DriverSeat = self:GetDriverSeat()

	if IsValid( DriverSeat ) and not IsValid( DriverSeat:GetDriver() ) and not ply:KeyDown( IN_WALK ) and not AI then
		ply:EnterVehicle( DriverSeat )
	else
		local Seat = NULL
		local Dist = 500000

		for _, v in pairs( self:GetPassengerSeats() ) do
			if IsValid( v ) and not IsValid( v:GetDriver() ) then
				local cDist = (v:GetPos() - ply:GetPos()):Length()
				
				if cDist < Dist then
					Seat = v
					Dist = cDist
				end
			end
		end

		if IsValid( Seat ) then
			ply:EnterVehicle( Seat )
		else
			if IsValid( DriverSeat ) then
				if not IsValid( self:GetDriver() ) and not AI then
					ply:EnterVehicle( DriverSeat )
				end
			else
				self:EmitSound( "doors/default_locked.wav" )
			end
		end
	end
end

function ENT:InitPod( Pos, Ang )
	if IsValid( self:GetDriverSeat() ) then return end

	local Pod = ents.Create( "prop_vehicle_prisoner_pod" )

	if not IsValid( Pod ) then
		self:Remove()

		print("LVF: Failed to create driverseat. Vehicle terminated.")

		return
	else
		self:SetDriverSeat( Pod )

		local DSPhys = Pod:GetPhysicsObject()

		Pod:SetMoveType( MOVETYPE_NONE )
		Pod:SetModel( "models/nova/airboat_seat.mdl" )
		Pod:SetKeyValue( "vehiclescript","scripts/vehicles/prisoner_pod.txt" )
		Pod:SetKeyValue( "limitview", 0 )
		Pod:SetPos( self:LocalToWorld( Pos ) )
		Pod:SetAngles( self:LocalToWorldAngles( Ang ) )
		Pod:SetOwner( self )
		Pod:Spawn()
		Pod:Activate()
		Pod:SetParent( self )
		Pod:SetNotSolid( true )
		Pod:SetColor( Color( 255, 255, 255, 0 ) ) 
		Pod:SetRenderMode( RENDERMODE_TRANSALPHA )
		Pod:DrawShadow( false )
		Pod.DoNotDuplicate = true
		Pod:SetNWInt( "pPodIndex", 1 )

		if IsValid( DSPhys ) then
			DSPhys:EnableDrag( false ) 
			DSPhys:EnableMotion( false )
			DSPhys:SetMass( 1 )
		end

		self:DeleteOnRemove( Pod )

		self:TransferCPPI( Pod )
	end
end

function ENT:AddPassengerSeat( Pos, Ang )
	if not isvector( Pos ) or not isangle( Ang ) then return NULL end

	local Pod = ents.Create( "prop_vehicle_prisoner_pod" )

	if not IsValid( Pod ) then return NULL end

	Pod:SetMoveType( MOVETYPE_NONE )
	Pod:SetModel( "models/nova/airboat_seat.mdl" )
	Pod:SetKeyValue( "vehiclescript","scripts/vehicles/prisoner_pod.txt" )
	Pod:SetKeyValue( "limitview", 0 )
	Pod:SetPos( self:LocalToWorld( Pos ) )
	Pod:SetAngles( self:LocalToWorldAngles( Ang ) )
	Pod:SetOwner( self )
	Pod:Spawn()
	Pod:Activate()
	Pod:SetParent( self )
	Pod:SetNotSolid( true )
	Pod:SetColor( Color( 255, 255, 255, 0 ) ) 
	Pod:SetRenderMode( RENDERMODE_TRANSALPHA )

	Pod:DrawShadow( false )
	Pod.DoNotDuplicate = true

	self.pPodKeyIndex = self.pPodKeyIndex and self.pPodKeyIndex + 1 or 2

	Pod:SetNWInt( "pPodIndex", self.pPodKeyIndex )

	self:DeleteOnRemove( Pod )
	self:TransferCPPI( Pod )

	local DSPhys = Pod:GetPhysicsObject()
	if IsValid( DSPhys ) then
		DSPhys:EnableDrag( false ) 
		DSPhys:EnableMotion( false )
		DSPhys:SetMass( 1 )
	end

	if not istable( self.pSeats ) then self.pSeats = {} end

	table.insert( self.pSeats, Pod )

	return Pod
end

function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
end

function ENT:PhysicsCollide( data, physobj )
end

function ENT:PlayAnimation( animation, playbackrate )
	playbackrate = playbackrate or 1

	local sequence = self:LookupSequence( animation )

	self:ResetSequence( sequence )
	self:SetPlaybackRate( playbackrate )
	self:SetSequence( sequence )
end

function ENT:UpdateTransmitState() 
	return TRANSMIT_ALWAYS
end

function ENT:StoreCPPI( owner )
	self._OwnerEntLVF = owner
end

function ENT:TransferCPPI( target )
	if not IsEntity( target ) or not IsValid( target ) then return end

	if not CPPI then return end

	local Owner = self._OwnerEntLVF

	if not IsEntity( Owner ) then return end

	if IsValid( Owner ) then
		target:CPPISetOwner( Owner )
	end
end
