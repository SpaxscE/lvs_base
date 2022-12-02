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

function ENT:BaseDT()
	self:NetworkVar( "Entity",0, "Driver" )
	self:NetworkVar( "Entity",1, "DriverSeat" )

	self:NetworkVar( "Bool",0, "Active" )
	self:NetworkVar( "Bool",1, "lvsLockedStatus" )
	self:NetworkVar( "Bool",3, "AI",	{ KeyName = "aicontrolled",	Edit = { type = "Boolean",	order = 1,	category = "AI"} } )

	self:NetworkVar( "Vector", 1, "Steer" )
end

function ENT:SetupDataTables()
	self:BaseDT()
end

function ENT:CalcMainActivity( ply )
end

function ENT:MouseDirectInput( ply, cmd )
	local Delta = FrameTime()

	local KeyLeft = cmd:KeyDown( IN_MOVERIGHT )
	local KeyRight = cmd:KeyDown( IN_MOVELEFT )

	local KeyPitch = cmd:KeyDown( IN_SPEED )

	local MouseY = KeyPitch and -10 or cmd:GetMouseY()

	local Input = Vector( cmd:GetMouseX(), MouseY, 0 )

	local Cur = self:GetSteer()

	local Rate = Delta * 2.5

	local New = Vector(Cur.x, Cur.y, 0) - Vector( math.Clamp(Cur.x * Delta * 5,-Rate,Rate), math.Clamp(Cur.y * Delta * 5,-Rate,Rate), 0)

	local Target = New + Input * Delta * 0.8

	local Dir = Target:GetNormalized()

	local Ax = math.acos( Vector(1,0,0):Dot( Dir ) )
	local Ay = math.asin( Vector(0,1,0):Dot( Dir ) )

	local Len = math.min( Target:Length(), 1 )

	local Fx = math.cos( Ax ) * Len
	local Fy = math.sin( Ay ) * Len

	local F = Cur + (Vector( Fx, Fy, 0 ) - Cur) * Delta * 100
	F.z = (KeyRight and 1 or 0) - (KeyLeft and 1 or 0)

	self:SetSteer( F )
end

function ENT:StartCommand( ply, cmd )
	if self:GetDriver() ~= ply then return end

	self:MouseDirectInput( ply, cmd )
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