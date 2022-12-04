ENT.Type            = "anim"
DEFINE_BASECLASS( "lunasflightschool_basescript" )

ENT.PrintName = "testscript LFS 2022"
ENT.Author = "Luna"
ENT.Information = "LFS 2022 Prototype"
ENT.Category = "[LFS]"

ENT.Spawnable		= true
ENT.AdminSpawnable	= false

ENT.MDL = "models/blu/bf109.mdl"

ENT.AITEAM = 0

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

function ENT:SetupDataTables()
	self:NetworkVar( "Vector", 0, "Steer" )
	self:NetworkVar( "Float", 9, "Throttle" )

	BaseClass.SetupDataTables( self )
end

function ENT:GetThrottlePercent()
	return math.max(math.Round( self:GetThrottle() * 100,0),0)
end

function ENT:MouseDirectInput( ply, cmd )
	local Delta = FrameTime()

	local KeyLeft = cmd:KeyDown( IN_MOVERIGHT )
	local KeyRight = cmd:KeyDown( IN_MOVELEFT )

	local KeyPitch = cmd:KeyDown( IN_SPEED )

	local MouseY = KeyPitch and -10 or cmd:GetMouseY()

	local Input = Vector( cmd:GetMouseX(), MouseY * 4, 0 ) * 0.25

	local Cur = self:GetSteer()

	local Rate = Delta * 2

	local New = Vector(Cur.x, Cur.y, 0) - Vector( math.Clamp(Cur.x * Delta * 5,-Rate,Rate), math.Clamp(Cur.y * Delta * 5,-Rate,Rate), 0)

	local Target = New + Input * Delta * 0.8

	local Fx = math.Clamp( Target.x, -1, 1 )
	local Fy = math.Clamp( Target.y, -1, 1 )

	local TargetFz = (KeyRight and 1 or 0) - (KeyLeft and 1 or 0)
	local Fz = Cur.z + math.Clamp(TargetFz - Cur.z,-Rate * 3,Rate * 3)

	local F = Cur + (Vector( Fx, Fy, Fz ) - Cur) * math.min(Delta * 100,1)

	self:SetSteer( F )
end

function ENT:CalcThrottle( ply, cmd )
	local Delta = FrameTime()

	local ThrottleUp = cmd:KeyDown( IN_FORWARD ) and 1 or 0
	local ThrottleDown = cmd:KeyDown( IN_BACK ) and -1 or 0

	local Throttle = (ThrottleUp + ThrottleDown) * Delta

	self:SetThrottle( math.Clamp(self:GetThrottle() + Throttle,0,1) )
end

function ENT:StartCommand( ply, cmd )
	if self:GetDriver() ~= ply then return end

	self:MouseDirectInput( ply, cmd )
	self:CalcThrottle( ply, cmd )
end

function ENT:Sign( n )
	if n > 0 then return 1 end

	if n < 0 then return -1 end

	return 0
end