ENT.TurretPodIndex = 1 -- 1 = driver

ENT.TurretAimRate = 25

ENT.TurretRotationSound = "vehicles/tank_turret_loop1.wav"
ENT.TurretRotationSoundDamaged = "lvs/turret_damaged_loop.wav"

ENT.TurretFakeBarrel = false
ENT.TurretFakeBarrelRotationCenter = vector_origin

ENT.TurretPitchPoseParameterName = "turret_pitch"
ENT.TurretPitchMin = -15
ENT.TurretPitchMax = 15
ENT.TurretPitchMul = 1
ENT.TurretPitchOffset = 0

ENT.TurretYawPoseParameterName = "turret_yaw"
ENT.TurretYawMul = 1
ENT.TurretYawOffset = 0

ENT.TurretRateDestroyedMul = 0.25

function ENT:TurretSystemDT()
	self:AddDT( "Bool", "NWTurretEnabled" )
	self:AddDT( "Bool", "NWTurretDestroyed" )
	self:AddDT( "Bool", "TurretDamaged" )
	self:AddDT( "Entity", "NWTurretArmor" )

	if SERVER then
		self:SetTurretEnabled( true )
		self:SetTurretPitch( self.TurretPitchOffset )
		self:SetTurretYaw( self.TurretYawOffset )
	end
end

function ENT:SetTurretDestroyed( new )
	self:SetNWTurretDestroyed( new )
	self:SetTurretDamaged( new )
end

function ENT:GetTurretDestroyed( new )
	return self:GetNWTurretDestroyed()
end

function ENT:SetTurretEnabled( new )
	self:SetNWTurretEnabled( new )
end

function ENT:SetTurretArmor( TurretArmor )
	self:SetNWTurretArmor( TurretArmor )

	if CLIENT then return end

	TurretArmor.OnDestroyed = function( ent, dmginfo )
		if not IsValid( self ) then return end

		self:SetTurretDestroyed( true )
	end

	TurretArmor.OnRepaired = function( ent )
		if not IsValid( self ) then return end

		self:SetTurretDestroyed( false )
	end

	TurretArmor.OnHealthChanged = function( ent, dmginfo, old, new )
		if new >= old then return end

		self:SetTurretDamaged( true )
	end
end

function ENT:GetTurretArmor()
	return self:GetNWTurretArmor()
end

function ENT:GetTurretEnabled()
	if self:GetTurretDestroyed() then return false end

	return self:GetNWTurretEnabled()
end

function ENT:SetTurretPitch( num )
	self._turretPitch = num
end

function ENT:SetTurretYaw( num )
	self._turretYaw = num
end

function ENT:GetTurretPitch()
	return (self._turretPitch or self.TurretPitchOffset)
end

function ENT:GetTurretYaw()
	return (self._turretYaw or self.TurretYawOffset)
end

if CLIENT then
	function ENT:UpdatePoseParameters( steer, speed_kmh, engine_rpm, throttle, brake, handbrake, clutch, gear, temperature, fuel, oil, ammeter )
		self:CalcTurret()
	end

	function ENT:CalcTurret()
		local pod = self:GetPassengerSeat( self.TurretPodIndex )

		if not IsValid( pod ) then return end

		local plyL = LocalPlayer()
		local ply = pod:GetDriver()

		if ply ~= plyL then return end

		self:AimTurret()
	end

	net.Receive( "lvs_turret_sync_other", function( len )
		local veh = net.ReadEntity()

		if not IsValid( veh ) then return end

		local Pitch = net.ReadFloat()
		local Yaw = net.ReadFloat()

		if isfunction( veh.SetTurretPitch ) then
			veh:SetTurretPitch( Pitch )
		end

		if isfunction( veh.SetTurretYaw ) then
			veh:SetTurretYaw( Yaw )
		end
	end )
else
	util.AddNetworkString( "lvs_turret_sync_other" )

	function ENT:OnPassengerChanged( Old, New, PodIndex )
		if PodIndex ~= self.TurretPodIndex then return end

		if IsValid( New ) then return end

		net.Start( "lvs_turret_sync_other" )
			net.WriteEntity( self )
			net.WriteFloat( self:GetTurretPitch() )
			net.WriteFloat( self:GetTurretYaw() )
		net.Broadcast()
	end

	function ENT:CalcTurretSound( Pitch, Yaw, AimRate )
		local DeltaPitch = Pitch - self:GetTurretPitch()
		local DeltaYaw = Yaw - self:GetTurretYaw()

		local PitchVolume = math.abs( DeltaPitch ) / AimRate
		local YawVolume = math.abs( DeltaYaw ) / AimRate

		local PlayPitch = PitchVolume > 0.95
		local PlayYaw = YawVolume > 0.95

		local TurretArmor = self:GetTurretArmor()
		local Destroyed = self:GetTurretDamaged()

		if Destroyed and (PlayPitch or PlayYaw) and IsValid( TurretArmor ) then
			local T = CurTime()

			if (self._NextTurDMGfx or 0) < T then
				self._NextTurDMGfx = T + 0.1

				local effectdata = EffectData()
				effectdata:SetOrigin( TurretArmor:LocalToWorld( Vector(0,0,TurretArmor:GetMins().z) ) )
				effectdata:SetNormal( self:GetUp() )
				util.Effect( "lvs_physics_turretscraping", effectdata, true, true )
			end
		end

		if PlayPitch or PlayYaw then
			self:DoTurretSound()
		end

		local T = self:GetTurretSoundTime()

		if T > 0 then
			local volume = math.max( PitchVolume, YawVolume )
			local pitch = 90 + 10 * (1 - volume)

			if Destroyed then
				local sound = self:StartTurretSoundDMG()

				pitch = pitch * self.TurretRateDestroyedMul

				sound:ChangeVolume( volume * 0.25, 0.25 )
			end
	
			local sound = self:StartTurretSound()

			sound:ChangeVolume( volume * 0.25, 0.25 )
			sound:ChangePitch( pitch, 0.25 )
		else
			self:StopTurretSound()
			self:StopTurretSoundDMG()
		end
	end

	function ENT:DoTurretSound()
		if not self._TurretSound then self._TurretSound = 0 end

		self._TurretSound = CurTime() + 1.1
	end

	function ENT:GetTurretSoundTime()
		if not self._TurretSound then return 0 end

		return math.max(self._TurretSound - CurTime(),0) / 1
	end

	function ENT:StopTurretSound()
		if not self._turretSND then return end

		self._turretSND:Stop()
		self._turretSND = nil
	end

	function ENT:StartTurretSoundDMG()
		if self._turretSNDdmg then return self._turretSNDdmg end

		self._turretSNDdmg = CreateSound( self, self.TurretRotationSoundDamaged  )
		self._turretSNDdmg:PlayEx(0.5, 100)

		return self._turretSNDdmg
	end

	function ENT:StopTurretSoundDMG()
		if not self._turretSNDdmg then return end

		self._turretSNDdmg:Stop()
		self._turretSNDdmg = nil
	end

	function ENT:StartTurretSound()
		if self._turretSND then return self._turretSND end

		self._turretSND = CreateSound( self, self.TurretRotationSound  )
		self._turretSND:PlayEx(0,100)

		return self._turretSND
	end

	function ENT:OnRemoved()
		self:StopTurretSound()
		self:StopTurretSoundDMG()
	end

	function ENT:OnTick()
		self:AimTurret()
	end

	function ENT:CreateTurretPhysics( data )
		if not isstring( data.follow ) or not isstring( data.mdl ) then return NULL end

		local idFollow = self:LookupAttachment( data.follow )

		local attFollow = self:GetAttachment( idFollow )

		if not attFollow then return NULL end

		local Follower = ents.Create( "lvs_wheeldrive_attachment_follower" )

		if not IsValid( Follower ) then return NULL end

		local Master = ents.Create( "lvs_wheeldrive_steerhandler" )

		if not IsValid( Master ) then Follower:Remove() return NULL end

		Master:SetPos( attFollow.Pos )
		Master:SetAngles( attFollow.Ang )
		Master:Spawn()
		Master:Activate()
		self:DeleteOnRemove( Master )
		self:TransferCPPI( Master )
	
		Follower:SetModel( data.mdl )
		Follower:SetPos( attFollow.Pos )
		Follower:SetAngles( self:GetAngles() )
		Follower:Spawn()
		Follower:Activate()
		Follower:SetBase( self )
		Follower:SetFollowAttachment( idFollow )
		Follower:SetMaster( Master )
		self:TransferCPPI( Follower )
		self:DeleteOnRemove( Follower )

		local B1 = constraint.Ballsocket( Follower, self, 0, 0, self:WorldToLocal( attFollow.Pos ), 0, 0, 1 )
		B1.DoNotDuplicate = true

		local Lock = 0.0001
		local B2 = constraint.AdvBallsocket( Follower,Master,0,0,vector_origin,vector_origin,0,0,-Lock,-Lock,-Lock,Lock,Lock,Lock,0,0,0,1,1)
		B2.DoNotDuplicate = true

		return Follower
	end
end

function ENT:IsTurretEnabled()
	if self:GetHP() <= 0 then return false end

	if not self:GetTurretEnabled() then return false end

	return IsValid( self:GetPassenger( self.TurretPodIndex ) ) or self:GetAI()
end

function ENT:AimTurret()
	if not self:IsTurretEnabled() then if SERVER then self:StopTurretSound() self:StopTurretSoundDMG() end return end

	local EntTable = self:GetTable()

	local weapon = self:GetWeaponHandler( EntTable.TurretPodIndex )

	if not IsValid( weapon ) then return end

	local AimAngles = self:WorldToLocalAngles( weapon:GetAimVector():Angle() )

	if EntTable.TurretFakeBarrel then
		AimAngles = self:WorldToLocalAngles( (self:LocalToWorld( EntTable.TurretFakeBarrelRotationCenter ) - weapon:GetEyeTrace().HitPos):Angle() )
	end

	local AimRate = EntTable.TurretAimRate * FrameTime() 

	if self:GetTurretDamaged() then
		AimRate = AimRate * EntTable.TurretRateDestroyedMul
	end

	local Pitch = math.Clamp( math.ApproachAngle( self:GetTurretPitch(), AimAngles.p, AimRate ), EntTable.TurretPitchMin, EntTable.TurretPitchMax )
	local Yaw = math.ApproachAngle( self:GetTurretYaw(), AimAngles.y, AimRate )

	if EntTable.TurretYawMin and EntTable.TurretYawMax then
		Yaw = math.Clamp( Yaw, EntTable.TurretYawMin, EntTable.TurretYawMax )
	end

	if SERVER then
		self:CalcTurretSound( Pitch, Yaw, AimRate )
	end

	self:SetTurretPitch( Pitch )
	self:SetTurretYaw( Yaw )

	self:SetPoseParameter(EntTable.TurretPitchPoseParameterName, EntTable.TurretPitchOffset + self:GetTurretPitch() * EntTable.TurretPitchMul )
	self:SetPoseParameter(EntTable.TurretYawPoseParameterName, EntTable.TurretYawOffset + self:GetTurretYaw() * EntTable.TurretYawMul )
end
