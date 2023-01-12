AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

ENT.SpawnNormalOffset = 25

function ENT:OnSpawn( PObj )
	PObj:SetMass( 10000 )

	local DriverSeat = self:AddDriverSeat( Vector(207,0,120), Angle(0,-90,0) )
	DriverSeat:SetCameraDistance( 1 )
	DriverSeat.ExitPos = Vector(75,0,36)

	self:AddEngine( Vector(-385,0,255) )
	self:AddEngineSound( Vector(-180,0,230) )

	self.PrimarySND = self:AddSoundEmitter( Vector(256,0,36), "lvs/vehicles/laat/fire.mp3", "lvs/vehicles/laat/fire.mp3" )
	self.PrimarySND:SetSoundLevel( 110 )

	local GunnerSeat = self:AddPassengerSeat( Vector(111.87,0,156), Angle(0,-90,0) )
	GunnerSeat.ExitPos = Vector(75,0,36)

	self:SetGunnerSeat( GunnerSeat )

	do
		local BallTurretPod = self:AddPassengerSeat( Vector(0,0,100), Angle(0,-90,0) )

		local ID = self:LookupAttachment( "muzzle_ballturret_left" )
		local Muzzle = self:GetAttachment( ID )

		if Muzzle then
			local Pos,Ang = LocalToWorld( Vector(0,-20,-55), Angle(180,0,-90), Muzzle.Pos, Muzzle.Ang )

			BallTurretPod:SetParent( NULL )
			BallTurretPod:SetPos( Pos )
			BallTurretPod:SetAngles( Ang )
			BallTurretPod:SetParent( self, ID )
			self:SetBTPodL( BallTurretPod )
		end
	end

	do
		local BallTurretPod = self:AddPassengerSeat( Vector(0,0,100), Angle(0,-90,0) )

		local ID = self:LookupAttachment( "muzzle_ballturret_right" )
		local Muzzle = self:GetAttachment( ID )

		if Muzzle then
			local Pos,Ang = LocalToWorld( Vector(0,-20,-55), Angle(180,0,-90), Muzzle.Pos, Muzzle.Ang )

			BallTurretPod:SetParent( NULL )
			BallTurretPod:SetPos( Pos )
			BallTurretPod:SetAngles( Ang )
			BallTurretPod:SetParent( self, ID )
			self:SetBTPodR( BallTurretPod )
		end
	end

	self:AddPassengerSeat( Vector(95,0,15), Angle(0,90,0) ).ExitPos = Vector(75,0,36)

	for i = 0, 5 do
		local X = i * 35
		local Y = 30 - i * 3
		
		self:AddPassengerSeat( Vector(10 - X,Y,10), Angle(0,0,0) ).ExitPos = Vector(10 - X,25,36)
		self:AddPassengerSeat( Vector(10 - X,-Y,10), Angle(0,180,0) ).ExitPos = Vector(10 - X,-25,36)
	end

	self:SetPoseParameter("ballturret_left_pitch", 0 )
	self:SetPoseParameter("ballturret_left_yaw", -70 )
	self:SetPoseParameter("ballturret_right_pitch", 0 )
	self:SetPoseParameter("ballturret_right_yaw", -70 )
end

function ENT:OnEngineActiveChanged( Active )
	if Active then
		self:EmitSound( "lvs/vehicles/naboo_n1_starfighter/start.wav" )
	else
		self:EmitSound( "lvs/vehicles/naboo_n1_starfighter/stop.wav" )
	end
end

function ENT:OnBallturretMounted( ismounted, oldvar )
	if ismounted == oldvar then return end

	if ismounted then
		if IsValid( self.BTPodR_ent_orig ) then 
			self:SetBTPodR( self.BTPodR_ent_orig )
			self.BTPodR_ent_orig:SetNWInt( "pPodIndex", self.BTPodR_index_orig )
		end

		if IsValid( self.BTPodL_ent_orig ) then 
			self:SetBTPodL( self.BTPodL_ent_orig )
			self.BTPodL_ent_orig:SetNWInt( "pPodIndex", self.BTPodL_index_orig )
		end
	else
		local Pod_R = self:GetBTPodR()
		if IsValid( Pod_R ) then 
			self.BTPodR_ent_orig = Pod_R
			self.BTPodR_index_orig = Pod_R:GetNWInt( "pPodIndex" )
			Pod_R:SetNWInt( "pPodIndex", -1 )

			local ply = Pod_R:GetDriver()
			if IsValid( ply ) then
				ply:ExitVehicle()
			end
		end

		local Pod_L = self:GetBTPodL()
		if IsValid( Pod_L ) then 
			self.BTPodL_ent_orig = Pod_L
			self.BTPodL_index_orig = Pod_L:GetNWInt( "pPodIndex" )
			Pod_L:SetNWInt( "pPodIndex", -1 )

			local ply = Pod_L:GetDriver()
			if IsValid( ply ) then
				ply:ExitVehicle()
			end
		end

		self:SetBTPodR( NULL )
		self:SetBTPodL( NULL )
	end
end

function ENT:OnTick()
	local BTbodygroup = self:GetBodygroup(4)

	if BTbodygroup ~= self.oldBTbodygroup then
		self:OnBallturretMounted( BTbodygroup == 0, self.oldBTbodygroup == 0 )

		self.oldBTbodygroup = BTbodygroup
	end
end