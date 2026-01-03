
ENT.Base = "lvs_base"

ENT.PrintName = "[LVS] Base Fighter Plane"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

ENT.MaxVelocity = 2500
ENT.MaxPerfVelocity = 1500
ENT.MaxThrust = 250

ENT.ThrottleRateUp = 0.6
ENT.ThrottleRateDown = 0.3

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 1

ENT.GravityTurnRatePitch = 1
ENT.GravityTurnRateYaw = 1

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.MaxSlipAnglePitch = 20
ENT.MaxSlipAngleYaw = 10

ENT.StallVelocity = 150
ENT.StallForceMultiplier = 4
ENT.StallForceMax = 40

ENT.lvsEditables = {
	[1] = {
		Category = "Body",
		Options = {
			[1] = { name = "MaxVelocity", type = "float", min = 1, max = 4000 },
			[2] = { name = "MaxPerfVelocity", type = "float", min = 1, max = 4000 },
			[3] = { name = "ThrottleRateUp", Category = "Body", type = "float", min = 0.01, max = 10 },
			[4] = { name = "ThrottleRateDown", Category = "Body", type = "float", min = 0.01, max = 10 },
		},
	},
	[2] = {
		Category = "Rotor",
		Options = {
			[1] = { name = "MaxThrust", type = "float", min = 1, max = 4000 },
		},
	},
	[3] = {
		Category = "Turning",
		Options = {
			[1] = { name = "TurnRatePitch", type = "float", min = 0, max = 10 },
			[2] = { name = "TurnRateYaw", type = "float", min = 0, max = 10 },
			[3] = { name = "TurnRateRoll", type = "float", min = 0, max = 10 },
			[4] = { name = "GravityTurnRatePitch", type = "float", min = 0, max = 10 },
			[5] = { name = "GravityTurnRateYaw", type = "float", min = 0, max = 10 },
		},
	},
	[4] = {
		Category = "Physics",
		Options = {
			[1] = { name = "ForceLinearMultiplier", type = "float", min = 0, max = 10 },
			[2] = { name = "ForceAngleMultiplier", type = "float", min = 0, max = 10 },
			[3] = { name = "ForceAngleDampingMultiplier", type = "float", min = 0, max = 10 },
		},
	},
	[5] = {
		Category = "Aerodynamics",
		Options = {
			[1] = { name = "MaxSlipAnglePitch", type = "float", min = 0, max = 90 },
			[2] = { name = "MaxSlipAngleYaw", type = "float", min = 0, max = 90 },
			[3] = { name = "StallVelocity", type = "float", min = 0, max = 4000 },
			[4] = { name = "StallForceMultiplier", type = "float", min = 0, max = 25 },
			[5] = { name = "StallForceMax", type = "float", min = 0, max = 1000 },
		},
	},
}

function ENT:SetupDataTables()
	self:CreateBaseDT()

	self:AddDT( "Vector", "Steer" )
	self:AddDT( "Vector", "AIAimVector" )
	self:AddDT( "Float", "NWThrottle" )
	self:AddDT( "Float", "MaxThrottle" )
	self:AddDT( "Float", "LandingGear" )

	if SERVER then
		self:SetLandingGear( 1 )
		self:SetMaxThrottle( 1 )
	end
end

function ENT:PlayerDirectInput( ply, cmd )
	local Pod = self:GetDriverSeat()

	local Delta = FrameTime()

	local KeyLeft = ply:lvsKeyDown( "-ROLL" )
	local KeyRight = ply:lvsKeyDown( "+ROLL" )
	local KeyPitchUp = ply:lvsKeyDown( "+PITCH" )
	local KeyPitchDown = ply:lvsKeyDown( "-PITCH" )
	local KeyRollRight = ply:lvsKeyDown( "+YAW" )
	local KeyRollLeft = ply:lvsKeyDown( "-YAW" )

	local MouseX = cmd:GetMouseX()
	local MouseY = cmd:GetMouseY()

	if ply:lvsKeyDown( "FREELOOK" ) and not Pod:GetThirdPersonMode() then
		MouseX = 0
		MouseY = 0
	else
		ply:SetEyeAngles( Angle(0,90,0) )
	end

	local SensX, SensY, ReturnDelta = ply:lvsMouseSensitivity()

	if KeyPitchDown then MouseY = (10 / SensY) * ReturnDelta end
	if KeyPitchUp then MouseY = -(10 / SensY) * ReturnDelta end
	if KeyRollRight or KeyRollLeft then
		local NewX = (KeyRollRight and 10 or 0) - (KeyRollLeft and 10 or 0)

		MouseX = (NewX / SensX) * ReturnDelta
	end

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

function ENT:CalcThrottle( ply, cmd )
	if CLIENT then return end

	local Delta = FrameTime()

	local ThrottleUp =  ply:lvsKeyDown( "+THROTTLE" ) and self.ThrottleRateUp or 0
	local ThrottleDown = ply:lvsKeyDown( "-THROTTLE" ) and -self.ThrottleRateDown or 0

	local Throttle = (ThrottleUp + ThrottleDown) * Delta

	self:SetThrottle( self:GetThrottle() + Throttle )
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

function ENT:StartCommand( ply, cmd )
	if self:GetDriver() ~= ply then return end

	if SERVER and not self.WheelAutoRetract then
		local KeyJump = ply:lvsKeyDown( "VSPEC" )

		if self._lvsOldKeyJump ~= KeyJump then
			self._lvsOldKeyJump = KeyJump
			if KeyJump then
				self:ToggleLandingGear()
				self:PhysWake()
			end
		end
	end

	if not ply:lvsMouseAim() then
		self:PlayerDirectInput( ply, cmd )
	end

	self:CalcThrottle( ply, cmd )
end

function ENT:FreezeStability()
	self._StabilityFrozen = CurTime() + 2
end

function ENT:GetStability()
	if (self._StabilityFrozen or 0) > CurTime() then
		return 1, 0, self.MaxPerfVelocity
	end

	local ForwardVelocity = self:WorldToLocal( self:GetPos() + self:GetVelocity() ).x

	local Stability = math.Clamp(ForwardVelocity / self.MaxPerfVelocity,0,1) ^ 2
	local InvStability = 1 - Stability

	return Stability, InvStability, ForwardVelocity
end

function ENT:GetThrustStrenght()
	local ForwardVelocity = self:WorldToLocal( self:GetPos() + self:GetVelocity() ).x

	return (self.MaxVelocity - ForwardVelocity) * self:GetThrottle() / self.MaxVelocity
end

function ENT:GetVehicleType()
	return "plane"
end