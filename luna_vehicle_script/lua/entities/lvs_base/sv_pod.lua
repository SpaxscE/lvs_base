
function ENT:AlignView( ply, SetZero )
	if not IsValid( ply ) then return end

	timer.Simple( 0, function()
		if not IsValid( ply ) or not IsValid( self ) then return end
		local Ang = Angle(0,90,0)

		if not SetZero then
			Ang = self:GetAngles()
			Ang.r = 0
		end

		ply:SetEyeAngles( Ang )
	end)
end

function ENT:HandleActive()
	local gPod = self:GetGunnerSeat()

	if IsValid( gPod ) then
		local Gunner = gPod:GetDriver()
		local OldGunner = self:GetGunner()

		if Gunner ~= self:GetGunner() then
			self:SetGunner( Gunner )

			self:OnGunnerChanged( OldGunner, Gunner )

			if IsValid( Gunner ) then
				Gunner:lvsBuildControls()
			end
		end
	end

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

		self:OnDriverChanged( OldDriver, NewDriver, IsActive )

		if IsActive then
			Driver:lvsBuildControls()
			self:AlignView( Driver )

			self:EmitSound( "vehicles/atv_ammo_close.wav" )
		else
			self:WeaponsFinish()

			self:EmitSound( "vehicles/atv_ammo_open.wav" )
		end
	end
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
	if IsValid( self:GetDriverSeat() ) then return self:GetDriverSeat() end

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

		debugoverlay.BoxAngles( Pod:GetPos(), Pod:OBBMins(), Pod:OBBMaxs(), Pod:GetAngles(), 5, Color( 255, 93, 0, 200 ) )

		self:DeleteOnRemove( Pod )

		self:TransferCPPI( Pod )
	end

	return Pod
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

	debugoverlay.BoxAngles( Pod:GetPos(), Pod:OBBMins(), Pod:OBBMaxs(), Pod:GetAngles(), 5, Color( 100, 65, 127, 200 ) )

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
