AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:SpawnFunction( ply, tr, ClassName )

	if not tr.Hit then return end

	local ent = ents.Create( ClassName )
	ent.dOwnerEntLFS = ply
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

	local PObj = self:GetPhysicsObject()

	if not IsValid( PObj ) then 
		self:Remove()
		
		print("LFS: missing model. Plane terminated.")
		
		return
	end

	--PObj:EnableMotion( false )
	PObj:SetMass( 500 )
	PObj:EnableGravity( false )

	self:InitPod()

	self.SideThrottle = 0
	self.BackThrottle = 0
	self.UpThrottle = 0

	self:StartMotionController()
	self.ShadowParams = {}
	self:PhysWake()
end

function ENT:PhysicsSimulate( phys, deltatime )
 
	phys:Wake()
 
	local Vel = self:GetVelocity()
	local VelL = self:WorldToLocal( self:GetPos() + Vel )

	local TargetSpeed = (self:GetThrottle() * self.MaxSpeed - self.BackThrottle * self.MaxVtolSpeedX) - VelL.x * 0.1
	local TargetAngle = self:GetAngles()

	local Driver = self:GetDriver()
	if IsValid( Driver ) then
		TargetAngle = Driver:GetView()
	end

	local SideForce = math.Clamp(VelL.y * 0.025,-50,50)
	local UpForce = math.Clamp(VelL.z * 0.025,-50,50)

	if math.abs( self.SideThrottle ) > 0 then
		SideForce = self.SideThrottle * self.MaxVtolSpeedY + VelL.y * 0.1
	end

	if math.abs( self.UpThrottle ) > 0 then
		UpForce = self.UpThrottle * self.MaxVtolSpeedZ + VelL.z * 0.1
	end

	local Force = self:GetForward() * TargetSpeed + self:GetRight() * SideForce - self:GetUp() * UpForce

	TargetAngle.r = TargetAngle.r - math.Clamp(self:WorldToLocalAngles( TargetAngle ).y * 2,-90,90) * math.min(VelL.x * 0.01,1) --  + math.Clamp(VelL.y * (math.abs(self.SideThrottle) > 0 and 0 or 1),-120,120)

	self.ShadowParams.secondstoarrive = 1
	self.ShadowParams.pos = self:GetPos() + Force
	self.ShadowParams.angle = TargetAngle
	self.ShadowParams.maxangular = self.MaxTurnSpeed
	self.ShadowParams.maxangulardamp = self.MaxTurnDamp
	self.ShadowParams.maxspeed = 1000000
	self.ShadowParams.maxspeeddamp = 0
	self.ShadowParams.dampfactor = self.DampFactor
	self.ShadowParams.teleportdistance = 0
	self.ShadowParams.deltatime = deltatime
 
	phys:ComputeShadowControl( self.ShadowParams )

end

function ENT:InitPod()
	if IsValid( self:GetDriverSeat() ) then return end

	local Pod = ents.Create( "prop_vehicle_prisoner_pod" )

	if not IsValid( Pod ) then
		self:Remove()

		print("LFS: Failed to create driverseat. Plane terminated.")

		return
	else
		self:SetDriverSeat( Pod )

		local DSPhys = Pod:GetPhysicsObject()

		Pod:SetMoveType( MOVETYPE_NONE )
		Pod:SetModel( "models/nova/airboat_seat.mdl" )
		Pod:SetKeyValue( "vehiclescript","scripts/vehicles/prisoner_pod.txt" )
		Pod:SetKeyValue( "limitview", 0 )
		Pod:SetPos( self:LocalToWorld( self.SeatPos ) )
		Pod:SetAngles( self:LocalToWorldAngles( self.SeatAng ) )
		Pod:SetOwner( self )
		Pod:Spawn()
		Pod:Activate()
		Pod:SetParent( self )
		Pod:SetNotSolid( true )
		Pod:SetNoDraw( true )
		--Pod:SetColor( Color( 255, 255, 255, 0 ) ) 
		--Pod:SetRenderMode( RENDERMODE_TRANSALPHA )
		Pod:DrawShadow( false )
		Pod.DoNotDuplicate = true
		Pod:SetNWInt( "pPodIndex", 1 )

		if IsValid( DSPhys ) then
			DSPhys:EnableDrag( false ) 
			DSPhys:EnableMotion( false )
			DSPhys:SetMass( 1 )
		end

		self:DeleteOnRemove( Pod )
	end
end

function ENT:HandleEngine()
	local Driver = self:GetDriver()

	if IsValid( Driver ) then
		local FT = FrameTime()
		local Rate = FT * self.ThrottleIncrementRate
		local RateSide = FT * self.VtolIncrementRate

		local THR = self:GetThrottle()
		local THR_FWD = Driver:KeyDown( IN_FORWARD ) and Rate or 0
		local THR_BCK = Driver:KeyDown( IN_BACK ) and -Rate or 0

		local THR_LEFT = (Driver:KeyDown( IN_MOVELEFT ) and -1 or 0)
		local THR_RIGHT = (Driver:KeyDown( IN_MOVERIGHT ) and 1 or 0)

		local THR_UP = (Driver:KeyDown( IN_JUMP ) and -1 or 0)
		local THR_DN = (Driver:KeyDown( IN_DUCK ) and 1 or 0)

		if self.BackThrottle > 0 then
			THR_FWD = 0
		end

		self:SetThrottle( math.Clamp(THR + THR_FWD + THR_BCK,0,1) )

		local SideThrottle = THR_LEFT + THR_RIGHT
		local UpThrottle = THR_UP + THR_DN
		local ReverseThrottle = (THR <= 0 and Driver:KeyDown( IN_BACK )) and 1 or 0

		self.BackThrottle = self.BackThrottle + math.Clamp(ReverseThrottle - self.BackThrottle,-RateSide,RateSide)
		self.SideThrottle = self.SideThrottle + math.Clamp(SideThrottle - self.SideThrottle,-RateSide,RateSide)
		self.UpThrottle = self.UpThrottle + math.Clamp(UpThrottle - self.UpThrottle,-RateSide,RateSide)
	else
		self.SideThrottle = 0
		self.BackThrottle = 0
		self.UpThrottle = 0
	end
end

function ENT:Think()

	self:HandleActive()
	self:HandleEngine()

	self:NextThink( CurTime() )

	return true
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
		if IsValid( self:GetDriver() ) then
			self:GetDriver():SetNoDraw( false )
		end
		if IsValid( Driver ) then
			Driver:SetNoDraw( true )
		end

		self:SetDriver( Driver )
		self:SetActive( IsValid( Driver ) )

		if Active then
			self:EmitSound( "vehicles/atv_ammo_close.wav" )
		else
			self:EmitSound( "vehicles/atv_ammo_open.wav" )
		end
	end
end

function ENT:Use( ply )
	if not IsValid( ply ) then return end
	self:SetPassenger( ply )
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
			if not IsValid( self:GetDriver() ) and not AI then
				ply:EnterVehicle( DriverSeat )
			end
		end
	end
end

function ENT:OnRemove()
end

function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
end

function ENT:PhysicsCollide( data, physobj )
	self:SetThrottle( self:GetThrottle() * 0.8 )
end

function ENT:UpdateTransmitState() 
	return TRANSMIT_ALWAYS
end