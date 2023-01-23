
ENT.Base = "lvs_base"

ENT.PrintName = "[LVS] Base Helicopter"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

ENT.MaxVelocity = 2150

ENT.ThrustUp = 1
ENT.ThrustDown = 0.8
ENT.ThrustRate = 1

ENT.ThrottleRateUp = 0.2
ENT.ThrottleRateDown = 0.2

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 1

ENT.ForceLinearDampingMultiplier = 1.5

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

function ENT:SetupDataTables()
	self:CreateBaseDT()

	self:AddDT( "Vector", "Steer" )
	self:AddDT( "Vector", "AIAimVector" )
	self:AddDT( "Float", "Throttle" )
	self:AddDT( "Float", "NWThrust" )
end

function ENT:PlayerDirectInput( ply, cmd )
	local Pod = self:GetDriverSeat()

	local Delta = FrameTime()

	local KeyLeft = ply:lvsKeyDown( "-ROLL_HELI" )
	local KeyRight = ply:lvsKeyDown( "+ROLL_HELI" )
	local KeyPitchUp = ply:lvsKeyDown( "+PITCH_HELI" )
	local KeyPitchDown = ply:lvsKeyDown( "-PITCH_HELI" )

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

	if CLIENT then return end

	if ply:lvsKeyDown( "HELI_HOVER" ) then
		self:CalcHover(ply:lvsKeyDown( "-YAW_HELI" ), ply:lvsKeyDown( "+YAW_HELI" ), KeyPitchUp, KeyPitchDown, ply:lvsKeyDown( "+THRUST_HELI" ), ply:lvsKeyDown( "-THRUST_HELI" ) )
	else
		self:CalcThrust( ply:lvsKeyDown( "+THRUST_HELI" ), ply:lvsKeyDown( "-THRUST_HELI" ) )
	end
end

function ENT:PlayerMouseAim( ply, cmd )
	if CLIENT then return end

	local Pod = self:GetDriverSeat()

	local PitchUp = ply:lvsKeyDown( "+PITCH_HELI" )
	local PitchDown = ply:lvsKeyDown( "-PITCH_HELI" )
	local YawRight = ply:lvsKeyDown( "+YAW_HELI" )
	local YawLeft = ply:lvsKeyDown( "-YAW_HELI" )
	local RollRight = ply:lvsKeyDown( "+ROLL_HELI" )
	local RollLeft = ply:lvsKeyDown( "-ROLL_HELI" )

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

	if ply:lvsKeyDown( "HELI_HOVER" ) then
		self:CalcHover( RollLeft, RollRight, PitchUp, PitchDown, ply:lvsKeyDown( "+THRUST_HELI" ), ply:lvsKeyDown( "-THRUST_HELI" ) )
	else
		self:CalcThrust( ply:lvsKeyDown( "+THRUST_HELI" ), ply:lvsKeyDown( "-THRUST_HELI" ) )
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
end

function ENT:SetThrust( New )
	if self:GetEngineActive() then
		self:SetNWThrust( math.Clamp(New,-1,1) )
	else
		self:SetNWThrust( 0 )
	end
end

function ENT:GetThrust()
	return self:GetNWThrust()
end

function ENT:GetThrustPercent()
	return math.Clamp(0.5 * self:GetThrottle() + self:GetThrust() * 0.5,0,1)
end

function ENT:GetThrustStrenght()
	return (1 - (self:GetVelocity():Length() / self.MaxVelocity)) * self:GetThrustPercent()
end
