
ENT.DriverActiveSound = "vehicles/atv_ammo_close.wav" 
ENT.DriverInActiveSound = "vehicles/atv_ammo_open.wav"

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
	local Pod = self:GetDriverSeat()

	if not IsValid( Pod ) then
		self:SetActive( false )

		return
	end

	local Driver = Pod:GetDriver()
	local Active = self:GetActive()

	if Driver ~= self:GetDriver() then
		local NewDriver = Driver
		local OldDriver = self:GetDriver()
		local IsActive = IsValid( Driver )

		self:SetDriver( Driver )
		self:SetActive( IsActive )

		self:OnDriverChanged( OldDriver, NewDriver, IsActive )

		if IsActive then
			Driver:lvsBuildControls()
			self:AlignView( Driver )

			if self.DriverActiveSound then self:EmitSound( self.DriverActiveSound ) end
		else
			self:WeaponsFinish()

			if self.DriverInActiveSound then self:EmitSound( self.DriverInActiveSound ) end
		end
	end
end

function ENT:SetPassenger( ply )
	if not IsValid( ply ) then return end

	local AI = self:GetAI()
	local DriverSeat = self:GetDriverSeat()
	local AllowedToBeDriver = hook.Run( "LVS.CanPlayerDrive", ply, self ) ~= false

	if IsValid( DriverSeat ) and not IsValid( DriverSeat:GetDriver() ) and not ply:KeyDown( IN_WALK ) and not AI and AllowedToBeDriver then
		ply:EnterVehicle( DriverSeat )
		self:AlignView( ply )

		hook.Run( "LVS.UpdateRelationship", self )
	else
		local Seat = NULL
		local Dist = 500000

		for _, v in pairs( self:GetPassengerSeats() ) do
			if not IsValid( v ) or IsValid( v:GetDriver() ) then continue end
			if v:GetNWInt( "pPodIndex" ) == -1 then continue end

			local cDist = (v:GetPos() - ply:GetPos()):Length()

			if cDist < Dist then
				Seat = v
				Dist = cDist
			end
		end

		if IsValid( Seat ) then
			ply:EnterVehicle( Seat )
			self:AlignView( ply, true )

			hook.Run( "LVS.UpdateRelationship", self )
		else
			if IsValid( DriverSeat ) then
				if not IsValid( self:GetDriver() ) and not AI then
					if AllowedToBeDriver then
						ply:EnterVehicle( DriverSeat )
						self:AlignView( ply )

						hook.Run( "LVS.UpdateRelationship", self )
					else
						hook.Run( "LVS.OnPlayerCannotDrive", ply, self )
					end
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
		Pod:PhysicsDestroy()

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

	if self.WEAPONS[ self.pPodKeyIndex ] then
		local weapon = Pod:lvsAddWeapon( self.pPodKeyIndex )

		if IsValid( weapon ) then
			self:TransferCPPI( weapon )
			self:DeleteOnRemove( weapon )
		end
	end

	Pod:SetNWInt( "pPodIndex", self.pPodKeyIndex )
	Pod:PhysicsDestroy()

	self:DeleteOnRemove( Pod )
	self:TransferCPPI( Pod )

	if not istable( self.pSeats ) then self.pSeats = {} end

	table.insert( self.pSeats, Pod )

	return Pod
end
