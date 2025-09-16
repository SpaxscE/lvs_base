
ENT.TurretBallisticsPredicted = true
ENT.TurretBallisticsUpright = 0.6
ENT.TurretBallisticsProjectileVelocity = 10000
ENT.TurretBallisticsMuzzleAttachment = "muzzle"
ENT.TurretBallisticsViewAttachment = "sight"

ENT.OpticsZoomOnly = true
ENT.OpticsScreenCentered = true

function ENT:TurretSystemDT()
	self:AddDT( "Bool", "TurretForceCenter" )
	self:AddDT( "Bool", "NWTurretEnabled" )
	self:AddDT( "Bool", "NWTurretDestroyed" )
	self:AddDT( "Bool", "TurretDamaged" )
	self:AddDT( "Entity", "NWTurretArmor" )

	self:AddDT( "Float", "TurretCompensation" )
	self:AddDT( "Float", "NWTurretPitch" )
	self:AddDT( "Float", "NWTurretYaw" )

	if SERVER then
		self:SetTurretEnabled( true )
		self:SetTurretPitch( self.TurretPitchOffset )
		self:SetTurretYaw( self.TurretYawOffset )
	end
end

function ENT:SetTurretPitch( num )
	self:SetNWTurretPitch( num )
end

function ENT:SetTurretYaw( num )
	self:SetNWTurretYaw( num )
end

function ENT:GetTurretPitch()
	return self:GetNWTurretPitch()
end

function ENT:GetTurretYaw()
	return self:GetNWTurretYaw()
end

function ENT:GetTurretViewOrigin()
	local ID = self:LookupAttachment( self.TurretBallisticsViewAttachment )

	local Att = self:GetAttachment( ID )

	if not Att then return self:GetPos(), false end

	return Att.Pos, true
end

if SERVER then
	util.AddNetworkString( "lvs_turret_ballistics_synchronous" )

	local function GetTurretEyeTrace( base, weapon )
		local startpos, found = base:GetTurretViewOrigin()

		if not found then return weapon:GetEyeTrace() end
	
		local pod = weapon:GetDriverSeat()

		if IsValid( pod ) and pod:GetThirdPersonMode() then
			if weapon == base then
				startpos = pod:LocalToWorld( pod:OBBCenter() )
			else
				startpos = weapon:GetPos()
			end
		end

		local data = {
			start = startpos,
			endpos = (startpos + weapon:GetAimVector() * 50000),
			filter = base:GetCrosshairFilterEnts(),
		}

		local trace = util.TraceLine( data )

		return trace
	end

	function ENT:CalcTurretAngles( EntTable )
		local weapon = self:GetWeaponHandler( EntTable.TurretPodIndex )

		if not IsValid( weapon ) then return angle_zero end

		local UpZ = self:GetUp().z

		if UpZ < EntTable.TurretBallisticsUpright then return self:WorldToLocalAngles( weapon:GetAimVector():Angle() ) end

		local pod = weapon:GetDriverSeat()

		if IsValid( pod ) then
			local ply = weapon:GetDriver()

			local ForceNoCompensation = false

			if IsValid( ply ) then
				if self.OpticsZoomOnly and not ply:lvsKeyDown( "ZOOM" ) then
					ForceNoCompensation = true
				end

				if ply ~= weapon._LastBallisticsSendTo then
					weapon._LastBallisticsSendTo = ply

					local velocity = EntTable.TurretBallisticsProjectileVelocity
					local muzzle = EntTable.TurretBallisticsMuzzleAttachment
					local sight = EntTable.TurretBallisticsViewAttachment

					self:TurretUpdateBallistics( velocity, muzzle, sight )
				end

				if pod:GetThirdPersonMode() or ForceNoCompensation then
					return self:WorldToLocalAngles( weapon:GetAimVector():Angle() )
				end
			else
				if not weapon:GetAI() then
					return self:WorldToLocalAngles( weapon:GetAimVector():Angle() )
				end
			end
		end

		local ID = self:LookupAttachment( EntTable.TurretBallisticsMuzzleAttachment )

		local Muzzle = self:GetAttachment( ID )

		if not Muzzle then return self:WorldToLocalAngles( weapon:GetAimVector():Angle() ) end

		local MuzzlePos = Muzzle.Pos
		local MuzzleDir = Muzzle.Ang:Forward()
		local MuzzleAng = MuzzleDir:Angle()

		local AimPos = GetTurretEyeTrace( self, weapon ).HitPos

		local StartPos = MuzzlePos

		local ProjectileVelocity = EntTable.TurretBallisticsProjectileVelocity
		local Dist = (AimPos - MuzzlePos):Length()

		local OffsetPredicted = vector_origin

		if EntTable.TurretBallisticsPredicted then
			OffsetPredicted = physenv.GetGravity() * ((Dist / ProjectileVelocity) ^ 2)
		end

		local EndPos = AimPos - OffsetPredicted

		local Dir = (EndPos - StartPos):GetNormalized()

		local Pos, Ang = WorldToLocal( Muzzle.Pos, Dir:Angle(), Muzzle.Pos, MuzzleAng )

		-- more body pitch/roll = more inaccurate. If Z up get smaller, turret must align more conservative to not overshoot
		local TurretSmoothing = math.abs( UpZ )

		self:SetTurretCompensation( OffsetPredicted.z )

		return Angle( self:GetTurretPitch() + Ang.p * TurretSmoothing, self:GetTurretYaw() + Ang.y * TurretSmoothing, 0 )
	end

else
	ENT.IconTurret = Material( "lvs/turret.png" )
	ENT.IconTurretBody = Material( "lvs/turret_body.png" )
	ENT.IconTurretBarrel = Material( "lvs/turret_barrel.png" )
	ENT.IconTurretRing = Material( "lvs/turret_ring.png" )
	ENT.TurretColorMain = color_white
	ENT.TurretColorShadow = Color(0,0,0,200)
	ENT.TurretColorDamaged = Color(255,0,0,255)

	LVS:AddHudEditor( "Turret Info",  ScrW() * 0.5 - 75, ScrH() - 110,  150, 100, 150, 100, "TURRETINFO",
		function( self, vehicle, X, Y, W, H, ScrX, ScrY, ply )
			if not vehicle.LVSHudPaintTurretInfo then return end

			vehicle:LVSHudPaintTurretInfo( X + W * 0.5 - H * 0.5, Y, H, H, ScrX, ScrY, ply )
		end
	)

	function ENT:LVSHudPaintTurretInfo( X, Y, W, H, ScrX, ScrY, ply )
		local pod = ply:GetVehicle()

		if not IsValid( pod ) or pod:lvsGetPodIndex() ~= self.TurretPodIndex then return end

		local EntTable = self:GetTable()

		local _, viewangles = ply:lvsGetView()

		local turret_yaw = self:GetTurretYaw()

		local yaw_body = - ply:GetVehicle():WorldToLocalAngles( viewangles ).y + 90
		local yaw_turret = turret_yaw + yaw_body

		local IconSize = W * 0.75

		surface.SetDrawColor( EntTable.TurretColorShadow )
		surface.SetMaterial( EntTable.IconTurretBody )
		surface.DrawTexturedRectRotated( X + W * 0.5 + 2, Y + H * 0.5 + 2, IconSize, IconSize, yaw_body )

		
		local BodyColor = EntTable.TurretColorMain

		if self.GetWheels then
			for _, wheel in pairs( self:GetWheels() ) do
				if not wheel:GetDamaged() then continue end

				BodyColor = EntTable.TurretColorDamaged

				break
			end
		end

		surface.SetDrawColor( BodyColor )
		surface.SetMaterial( EntTable.IconTurretBody )
		surface.DrawTexturedRectRotated( X + W * 0.5, Y + H * 0.5, IconSize, IconSize, yaw_body )

		surface.SetDrawColor( EntTable.TurretColorShadow )
		surface.SetMaterial( EntTable.IconTurret )
		surface.DrawTexturedRectRotated( X + W * 0.5 + 2, Y + H * 0.5 + 2, IconSize, IconSize, yaw_turret )

		surface.SetDrawColor( EntTable.TurretColorMain )
		surface.SetMaterial( EntTable.IconTurretBarrel )
		surface.DrawTexturedRectRotated( X + W * 0.5, Y + H * 0.5, IconSize, IconSize, yaw_turret )

		if self:GetTurretDamaged() then surface.SetDrawColor( EntTable.TurretColorDamaged ) end
		surface.SetMaterial( EntTable.IconTurretRing )
		surface.DrawTexturedRectRotated( X + W * 0.5, Y + H * 0.5, IconSize, IconSize, yaw_turret )
	end

	net.Receive( "lvs_turret_ballistics_synchronous", function( len )
		local vehicle = net.ReadEntity()

		local velocity = net.ReadFloat()
		local muzzle = net.ReadString()
		local sight = net.ReadString()

		if not IsValid( vehicle ) then return end

		if velocity == 0 then velocity = nil end
		if muzzle == "" then muzzle = nil end
		if sight == "" then sight = nil end

		vehicle:TurretUpdateBallistics( velocity, muzzle, sight )
	end )

	function ENT:CalcOpticsCrosshairDot( Pos2D )
		local ID = self:LookupAttachment( self.TurretBallisticsMuzzleAttachment )

		local Muzzle = self:GetAttachment( ID )

		if not Muzzle then return end

		local MuzzlePos = Muzzle.Pos

		local Pos = MuzzlePos
		local LastPos = MuzzlePos
		local StartPos = MuzzlePos
		local StartDirection = Muzzle.Ang:Forward()
		local Velocity  = self.TurretBallisticsProjectileVelocity

		local Gravity = vector_origin

		if self.TurretBallisticsPredicted then
			Gravity = physenv.GetGravity()
		end

		cam.Start3D()
		local Iteration = 0
		while Iteration < 1000 do
			Iteration = Iteration + 1

			local TimeAlive = Iteration / 200

			local EndPos = StartPos + StartDirection * TimeAlive * Velocity + Gravity * (TimeAlive ^ 2)

			Pos = EndPos

			local trace = util.TraceLine( {
				start = LastPos,
				endpos = EndPos,
				mask = MASK_SOLID,
			} )

			LastPos = EndPos

			if trace.Hit then
				Pos = trace.HitPos

				break
			end
		end
		cam.End3D()

		self:PaintOpticsCrosshair( Pos:ToScreen() )
	end
end

function ENT:TurretUpdateBallistics( newvelocity, newmuzzle, newsight )
	if newvelocity then
		self.TurretBallisticsProjectileVelocity = newvelocity
	end

	if newmuzzle then
		self.TurretBallisticsMuzzleAttachment = newmuzzle
	end

	if newsight then
		self.TurretBallisticsViewAttachment = newsight
	end

	if CLIENT then return end

	local ply = self:GetPassenger( self.TurretPodIndex )

	if not IsValid( ply ) then return end

	net.Start( "lvs_turret_ballistics_synchronous" )
		net.WriteEntity( self )
		net.WriteFloat( newvelocity or 0 )
		net.WriteString( newmuzzle or "" )
		net.WriteString( newsight or "" )
	net.Send( ply )
end

function ENT:AimTurret()
	if not self:IsTurretEnabled() then if SERVER then self:StopTurretSound() self:StopTurretSoundDMG() end return end

	local EntTable = self:GetTable()

	if SERVER then
		local AimAngles = self:CalcTurretAngles( EntTable )

		local AimRate = EntTable.TurretAimRate * FrameTime() 

		if self:GetTurretDamaged() then
			AimRate = AimRate * EntTable.TurretRateDestroyedMul
		end

		if self:GetTurretForceCenter() then
			if EntTable.TurretPitchEnableCentering then AimAngles.p = EntTable.TurretPitchOffset end
			if EntTable.TurretYawEnableCentering then AimAngles.y = EntTable.TurretYawOffset end
		end

		local Pitch = math.Clamp( math.ApproachAngle( self:GetTurretPitch(), AimAngles.p, AimRate ), EntTable.TurretPitchMin, EntTable.TurretPitchMax )
		local Yaw = math.ApproachAngle( self:GetTurretYaw(), AimAngles.y, AimRate )

		if EntTable.TurretYawMin and EntTable.TurretYawMax then
			Yaw = math.Clamp( Yaw, EntTable.TurretYawMin, EntTable.TurretYawMax )
		end

		self:CalcTurretSound( Pitch, Yaw, AimRate )

		self:SetTurretPitch( Pitch )
		self:SetTurretYaw( Yaw )

		self:SetPoseParameter(EntTable.TurretPitchPoseParameterName, EntTable.TurretPitchOffset + self:GetTurretPitch() * EntTable.TurretPitchMul )
		self:SetPoseParameter(EntTable.TurretYawPoseParameterName, EntTable.TurretYawOffset + self:GetTurretYaw() * EntTable.TurretYawMul )

		return
	end

	local Rate = math.min( FrameTime() * EntTable.TurretAimRate, 1 )

	local TargetPitch = EntTable.TurretPitchOffset + self:GetTurretPitch() * EntTable.TurretPitchMul
	local TargetYaw = EntTable.TurretYawOffset + self:GetTurretYaw() * EntTable.TurretYawMul

	EntTable._turretPitch = EntTable._turretPitch and EntTable._turretPitch + (TargetPitch - EntTable._turretPitch) * Rate or EntTable.TurretPitchOffset
	EntTable._turretYaw = EntTable._turretYaw and EntTable._turretYaw + (TargetYaw - EntTable._turretYaw) * Rate or EntTable.TurretYawOffset

	self:SetPoseParameter(EntTable.TurretPitchPoseParameterName, EntTable._turretPitch )
	self:SetPoseParameter(EntTable.TurretYawPoseParameterName, EntTable._turretYaw )
end
