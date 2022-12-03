ENT.Type            = "anim"

ENT.PrintName = "basescript"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"

ENT.Spawnable		= false
ENT.AdminSpawnable  = false

ENT.AutomaticFrameAdvance = true
ENT.RenderGroup = RENDERGROUP_BOTH 

ENT.Editable = true

ENT.LVS = true

ENT.MDL = "models/error.mdl"

ENT.MaxVelocity = 2500
ENT.MaxPerfVelocity = 2000
ENT.MaxThrust = 100

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 1

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.MaxSlipAnglePitch = 20
ENT.MaxSlipAngleYaw = 10

function ENT:BaseDT()
	self:NetworkVar( "Entity",0, "Driver" )
	self:NetworkVar( "Entity",1, "DriverSeat" )

	self:NetworkVar( "Bool",0, "Active" )
	self:NetworkVar( "Bool",1, "lvsLockedStatus" )
	self:NetworkVar( "Bool",3, "AI",	{ KeyName = "aicontrolled",	Edit = { type = "Boolean",	order = 1,	category = "AI"} } )

	self:NetworkVar( "Vector", 1, "Steer" )
	self:NetworkVar( "Float", 1, "Throttle" )
end

function ENT:SetupDataTables()
	self:BaseDT()
end

function ENT:CalcMainActivity( ply )
end

function ENT:CalcSteer( ply, cmd )
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

	self:CalcSteer( ply, cmd )
	self:CalcThrottle( ply, cmd )
end

function ENT:GetPassengerSeats()
	if not istable( self.pSeats ) then
		self.pSeats = {}

		local DriverSeat = self:GetDriverSeat()

		for _, v in pairs( self:GetChildren() ) do
			if v ~= DriverSeat and v:GetClass():lower() == "prop_vehicle_prisoner_pod" then
				table.insert( self.pSeats, v )
			end
		end
	end

	return self.pSeats
end