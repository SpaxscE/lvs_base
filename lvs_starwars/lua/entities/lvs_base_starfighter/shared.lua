
ENT.Base = "lvs_base"

ENT.PrintName = "[LVS] Base Starfighter"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

ENT.MaxVelocity = 3000
ENT.MaxThrust = 3000

ENT.ThrustVtol = 55
ENT.ThrustRateVtol = 3

ENT.ThrottleRateUp = 0.6
ENT.ThrottleRateDown = 0.6

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 1

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

function ENT:SetupDataTables()
	self:CreateBaseDT()

	self:AddDT( "Vector", "Steer" )
	self:AddDT( "Vector", "AIAimVector" )
	self:AddDT( "Vector", "NWVtolMove" )
	self:AddDT( "Float", "NWThrottle" )
	self:AddDT( "Float", "MaxThrottle" )

	if SERVER then
		self:SetMaxThrottle( 1 )
	end
end

function ENT:PlayerDirectInput( ply, cmd )
	local Pod = self:GetDriverSeat()

	local Delta = FrameTime()

	local KeyLeft = ply:lvsKeyDown( "-ROLL_SF" )
	local KeyRight = ply:lvsKeyDown( "+ROLL_SF" )
	local KeyPitchUp = ply:lvsKeyDown( "+PITCH_SF" )
	local KeyPitchDown = ply:lvsKeyDown( "-PITCH_SF" )

	local MouseX = cmd:GetMouseX()
	local MouseY = cmd:GetMouseY()

	if ply:lvsKeyDown( "FREELOOK" ) and not Pod:GetThirdPersonMode() then
		MouseX = 0
		MouseY = 0
	else
		ply:SetEyeAngles( Angle(0,90,0) )
	end

	local SensX, SensY, ReturnDelta = ply:lvsMouseSensitivity()

	if KeyPitchDown then MouseY = 10 * ReturnDelta end
	if KeyPitchUp then MouseY = -10 * ReturnDelta end

	local Input = Vector( MouseX * 0.4 * SensX, MouseY * SensY, 0 )

	local Cur = self:GetSteer()

	local Rate = Delta * 3 * ReturnDelta

	local New = Vector(Cur.x, Cur.y, 0) - Vector( math.Clamp(Cur.x * Delta * 5 * ReturnDelta,-Rate,Rate), math.Clamp(Cur.y * Delta * 5 * ReturnDelta,-Rate,Rate), 0)

	local Target = New + Input * Delta * 0.8

	local Fx = math.Clamp( Target.x, -1, 1 )
	local Fy = math.Clamp( Target.y, -1, 1 )

	local TargetFz = (KeyLeft and 1 or 0) - (KeyRight and 1 or 0)
	local Fz = Cur.z + math.Clamp(TargetFz - Cur.z,-Rate * 3,Rate * 3)

	local F = Cur + (Vector( Fx, Fy, Fz ) - Cur) * math.min(Delta * 100,1)

	self:SetSteer( F )
end

function ENT:PlayerMouseAim( ply, cmd )
	if CLIENT then return end

	local Pod = self:GetDriverSeat()

	local PitchUp = ply:lvsKeyDown( "+PITCH_SF" )
	local PitchDown = ply:lvsKeyDown( "-PITCH_SF" )
	local YawRight = ply:lvsKeyDown( "+YAW_SF" )
	local YawLeft = ply:lvsKeyDown( "-YAW_SF" )
	local RollRight = ply:lvsKeyDown( "+ROLL_SF" )
	local RollLeft = ply:lvsKeyDown( "-ROLL_SF" )

	local FreeLook = ply:lvsKeyDown( "FREELOOK" )

	local EyeAngles = Pod:WorldToLocalAngles( ply:EyeAngles() )

	if FreeLook then
		if isangle( self.StoredEyeAngles ) then
			EyeAngles = self.StoredEyeAngles
		end
	else
		self.StoredEyeAngles = EyeAngles
	end

	local OverridePitch = 0
	local OverrideYaw = 0
	local OverrideRoll = (RollRight and 1 or 0) - (RollLeft and 1 or 0)

	if PitchUp or PitchDown then
		EyeAngles = self:GetAngles()

		self.StoredEyeAngles = Angle(EyeAngles.p,EyeAngles.y,0)

		OverridePitch = (PitchUp and 1 or 0) - (PitchDown and 1 or 0)
	end

	if YawRight or YawLeft then
		EyeAngles = self:GetAngles()

		self.StoredEyeAngles = Angle(EyeAngles.p,EyeAngles.y,0)

		OverrideYaw = (YawRight and 1 or 0) - (YawLeft and 1 or 0) 
	end

	self:ApproachTargetAngle( EyeAngles, OverridePitch, OverrideYaw, OverrideRoll, FreeLook )
end

function ENT:CalcThrottle( ply, cmd )
	if CLIENT then return end

	local Delta = FrameTime()

	local ThrottleUp =  ply:lvsKeyDown( "+THRUST_SF" ) and self.ThrottleRateUp or 0
	local ThrottleDown = ply:lvsKeyDown( "-THRUST_SF" ) and -self.ThrottleRateDown or 0

	local Throttle = (ThrottleUp + ThrottleDown) * Delta

	self:SetThrottle( self:GetThrottle() + Throttle )
end

function ENT:CalcVtolThrottle( ply, cmd )
	local Delta = FrameTime()

	local ThrottleZero = self:GetThrottle() <= 0

	local VtolX = ThrottleZero and (ply:lvsKeyDown( "-VTOL_X_SF" ) and -1 or 0) or 0
	local VtolY = ((ply:lvsKeyDown( "+VTOL_Y_SF" ) and 1 or 0) - (ply:lvsKeyDown( "-VTOL_Y_SF" ) and 1 or 0))
	local VtolZ = ((ply:lvsKeyDown( "+VTOL_Z_SF" ) and 1 or 0) - (ply:lvsKeyDown( "-VTOL_Z_SF" ) and 1 or 0))

	local DesiredVtol = Vector(VtolX,VtolY,VtolZ)
	local NewVtolMove = self:GetNWVtolMove() + (DesiredVtol - self:GetNWVtolMove()) * self.ThrustRateVtol * Delta

	if not ThrottleZero or self:WorldToLocal( self:GetPos() + self:GetVelocity() ).x > 100 then
		NewVtolMove.x = 0
	end

	self:SetVtolMove( NewVtolMove )
end

function ENT:SetVtolMove( NewMove )
	if self:GetEngineActive() then
		self:SetNWVtolMove( NewMove )
	else
		self:SetNWVtolMove( Vector(0,0,0) )
	end
end

function ENT:SetThrottle( NewThrottle )
	if self:GetEngineActive() then
		self:SetNWThrottle( math.Clamp(NewThrottle,0,self:GetMaxThrottle()) )
	else
		self:SetNWThrottle( 0 )
	end
end

function ENT:GetThrottle()
	if self:GetEngineActive() then
		return self:GetNWThrottle()
	else
		return 0
	end
end

function ENT:GetVtolMove()
	if self:GetEngineActive() and not self:GetAI() then
		return self:GetNWVtolMove() * self.ThrustVtol * (1 - math.min( self:GetThrottle(), 1 ))
	else
		return Vector(0,0,0)
	end
end

function ENT:StartCommand( ply, cmd )
	if self:GetDriver() ~= ply then return end

	if SERVER then
		local KeyJump = ply:lvsKeyDown( "VSPEC" )

		if self._lvsOldKeyJump ~= KeyJump then
			self._lvsOldKeyJump = KeyJump

			if KeyJump then
				self:ToggleVehicleSpecific()
			end
		end
	end

	if ply:lvsMouseAim() then
		self:PlayerMouseAim( ply, cmd )
	else
		self:PlayerDirectInput( ply, cmd )
	end

	self:CalcThrottle( ply, cmd )
	self:CalcVtolThrottle( ply, cmd )
end

function ENT:GetThrustStrenght()
	local ForwardVelocity = self:WorldToLocal( self:GetPos() + self:GetVelocity() ).x

	return (self.MaxVelocity * self:GetThrottle() - ForwardVelocity) / self.MaxVelocity
end
