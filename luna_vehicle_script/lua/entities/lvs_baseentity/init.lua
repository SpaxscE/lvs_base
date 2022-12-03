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

		print("LVS: missing model. Vehicle terminated.")

		return
	end

	PObj:EnableMotion( false )
	PObj:EnableDrag( false )

	self:OnSpawn( PObj )

	self:StartMotionController()

	PObj:EnableMotion( true )

	self:PhysWake()
end

function ENT:GetWorldGravity()
	local PhysObj = self:GetPhysicsObject()

	if not IsValid( PhysObj ) or not PhysObj:IsGravityEnabled() then return 0 end

	return physenv.GetGravity():Length()
end

function ENT:GetWorldUp()
	local Gravity = physenv.GetGravity()

	if Gravity:Length() > 0 then
		return -Gravity:GetNormalized()
	else
		return Vector(0,0,1)
	end
end

function ENT:GetStability()
	local ForwardVelocity = self:WorldToLocal( self:GetPos() + self:GetVelocity() ).x
	local MaxPerfVelocity = 650

	return math.Clamp(ForwardVelocity / MaxPerfVelocity,0,1) ^ 2
end

function ENT:CalcAero( phys, deltatime )
	local WorldGravity = self:GetWorldGravity()
	local WorldUp = self:GetWorldUp()

	local Stability = self:GetStability()

	local A90 = 90
	
	local Forward = self:GetForward()
	local Left = -self:GetRight()
	local Up = self:GetUp()

	local PitchPull = math.max( (math.deg( math.acos( math.Clamp( WorldUp:Dot( Up ) ,-1,1) ) ) - A90) / A90, 0 )
	local YawPull = (math.deg( math.acos( math.Clamp( WorldUp:Dot( Left ) ,-1,1) ) ) - A90) / A90

	local GravMul = WorldGravity / 600
	local GravityPitch = math.abs( PitchPull ) ^ 1.25 * math.Sign( PitchPull ) * GravMul
	local GravityYaw = math.abs( YawPull ) ^ 1.25 * math.Sign( YawPull ) * GravMul

	local Steer = self:GetSteer()
	local Pitch = math.Clamp(Steer.y * 8 - GravityPitch,-1,1) * self.TurnRatePitch * 3
	local Yaw = math.Clamp(Steer.z * 8 + GravityYaw,-1,1) * self.TurnRateYaw * 0.75
	local Roll = math.Clamp(Steer.x * 8,-1,1) * self.TurnRateRoll * 10

	local Vel = self:GetVelocity()
	local VelForward = Vel:GetNormalized()

	local VelL = self:WorldToLocal( self:GetPos() + Vel )

	local MulZ = (math.max( math.deg( math.acos( math.Clamp( VelForward:Dot( Forward ) ,-1,1) ) ) - self.MaxSlipAnglePitch * math.abs( Steer.y ), 0 ) / A90) * 0.3
	local MulY = (math.max( math.abs( math.deg( math.acos( math.Clamp( VelForward:Dot( Left ) ,-1,1) ) ) - A90 ) - self.MaxSlipAngleYaw * math.abs( Steer.z ), 0 ) / A90) * 0.3

	local Lift = -math.min( (math.deg( math.acos( math.Clamp( WorldUp:Dot( Up ) ,-1,1) ) ) - A90) / 180,0) * (WorldGravity / (1 / deltatime)) * Stability

	PrintChat( math.Round(Lift,0).." @  "..math.Round(self:WorldToLocal( self:GetPos() + self:GetVelocity() ).z,0) )

	return Vector(0, -VelL.y * MulY, Lift - VelL.z * MulZ ),  Vector( Roll, Pitch, Yaw )
end

function ENT:PhysicsSimulate( phys, deltatime )
	local Aero, Torque = self:CalcAero( phys, deltatime )

	phys:Wake()

	local ForwardVelocity = self:WorldToLocal( self:GetPos() + self:GetVelocity() ).x
	local TargetVelocity = 2000 * self:GetThrottle()

	local Thrust = Vector(math.max(TargetVelocity - ForwardVelocity,0),0,0) * 100

	local ForceLinear = (Aero * 10000 + Thrust) * deltatime
	local ForceAngle = (Torque * 25 - phys:GetAngleVelocity() * 1.5) * deltatime * 250

	return ForceAngle, ForceLinear, SIM_LOCAL_ACCELERATION
end

function ENT:OnSpawn()
end

function ENT:Think()
	self:HandleActive()
	self:OnTick()

	self:NextThink( CurTime() )
	
	return true
end

function ENT:OnDriverChanged( VehicleIsActive, OldDriver, NewDriver )
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
		if self:GetlvsLockedStatus() then
			self:UnLock()
		end

		local NewDriver = Driver
		local OldDriver = self:GetDriver()
		local IsActive = IsValid( Driver )

		self:SetDriver( Driver )
		self:SetActive( IsActive )

		self:OnDriverChanged( IsActive, OldDriver, NewDriver )
	end
end

function ENT:OnRemove()
end

function ENT:Lock()
	self:SetlvsLockedStatus( true )
	self:EmitSound( "doors/latchlocked2.wav" )
end

function ENT:UnLock()
	self:SetlvsLockedStatus( false )
	self:EmitSound( "doors/latchunlocked1.wav" )
end

function ENT:Use( ply )
	if not IsValid( ply ) then return end

	if self:GetlvsLockedStatus() then 

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

function ENT:AddDriverSeat( Pos, Ang )
	if IsValid( self:GetDriverSeat() ) then return end

	local Pod = ents.Create( "prop_vehicle_prisoner_pod" )

	if not IsValid( Pod ) then
		self:Remove()

		print("LVS: Failed to create driverseat. Vehicle terminated.")

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
	self._OwnerEntLVS = owner
end

function ENT:TransferCPPI( target )
	if not IsEntity( target ) or not IsValid( target ) then return end

	if not CPPI then return end

	local Owner = self._OwnerEntLVS

	if not IsEntity( Owner ) then return end

	if IsValid( Owner ) then
		target:CPPISetOwner( Owner )
	end
end
