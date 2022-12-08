
ENT.Base = "lvs_base"

ENT.PrintName = "[LVS] Base Fighter Plane"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/bf109.mdl"

ENT.AITEAM = 3

ENT.MaxVelocity = 2500
ENT.MaxPerfVelocity = 1500
ENT.MaxThrust = 100

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 1

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.MaxSlipAnglePitch = 20
ENT.MaxSlipAngleYaw = 10

ENT.MaxHealth = 1000

function ENT:SetupDataTables()
	self:CreateBaseDT()

	self:AddDT( "Vector", "Steer" )
	self:AddDT( "Float", "Throttle" )
end

function ENT:PlayerDirectInput( ply, cmd )
	local Delta = FrameTime()

	local KeyLeft = ply:lvsKeyDown( "-ROLL" )
	local KeyRight = ply:lvsKeyDown( "+ROLL" )
	local KeyPitchUp = ply:lvsKeyDown( "+PITCH" )
	local KeyPitchDown = ply:lvsKeyDown( "-PITCH" )

	local MouseY = cmd:GetMouseY()

	if KeyPitchDown then MouseY = 10 end
	if KeyPitchUp then MouseY = -10 end

	local Input = Vector( cmd:GetMouseX(), MouseY * 4, 0 ) * 0.25

	local Cur = self:GetSteer()

	local Rate = Delta * 2

	local New = Vector(Cur.x, Cur.y, 0) - Vector( math.Clamp(Cur.x * Delta * 5,-Rate,Rate), math.Clamp(Cur.y * Delta * 5,-Rate,Rate), 0)

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

	local PitchUp = ply:lvsKeyDown( "+PITCH" )
	local PitchDown = ply:lvsKeyDown( "-PITCH" )
	local YawRight =ply:lvsKeyDown( "+YAW" )
	local YawLeft = ply:lvsKeyDown( "-YAW" )
	local RollRight = ply:lvsKeyDown( "+ROLL" )
	local RollLeft = ply:lvsKeyDown( "-ROLL" )

	local EyeAngles = Pod:WorldToLocalAngles( ply:EyeAngles() )

	if ply:lvsKeyDown( "FREELOOK" ) then
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

	self:ApproachTargetAngle( EyeAngles, OverridePitch, OverrideYaw, OverrideRoll )
end

function ENT:CalcThrottle( ply, cmd )
	local Delta = FrameTime()

	local ThrottleUp =  ply:lvsKeyDown( "+THROTTLE" ) and 1 or 0
	local ThrottleDown = ply:lvsKeyDown( "-THROTTLE" ) and -1 or 0

	local Throttle = (ThrottleUp + ThrottleDown) * Delta

	self:SetThrottle( math.Clamp(self:GetThrottle() + Throttle,0,1) )
end

function ENT:StartCommand( ply, cmd )
	if self:GetDriver() ~= ply then return end

	local KeyJump = ply:lvsKeyDown( "VSPEC" )

	if self._lvsOldKeyJump ~= KeyJump then
		self._lvsOldKeyJump = KeyJump
		if KeyJump then
			self:ToggleLandingGear()
			self:PhysWake()
		end
	end

	if ply:lvsMouseAim() then
		self:PlayerMouseAim( ply, cmd )
	else
		self:PlayerDirectInput( ply, cmd )
	end

	self:CalcThrottle( ply, cmd )
end

function ENT:GetStability()
	local ForwardVelocity = self:WorldToLocal( self:GetPos() + self:GetVelocity() ).x

	local Stability = math.Clamp(ForwardVelocity / self.MaxPerfVelocity,0,1) ^ 2
	local InvStability = 1 - Stability

	return Stability, InvStability, ForwardVelocity
end
