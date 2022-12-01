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

local function Sign( n )
	if n > 0 then return 1 end

	if n < 0 then return -1 end

	return 0
end

function ENT:MouseDirectInput( ply, cmd )
	local Delta = FrameTime()

	local Cur = self:GetSteer()
	local New = Cur + Vector( cmd:GetMouseX(), cmd:GetMouseY(), 0 ) * Delta * 0.25

	local Dir = New:GetNormalized()

	local Ax = math.acos( Vector(1,0,0):Dot( Dir ) )
	local Ay = math.asin( Vector(0,1,0):Dot( Dir ) )

	local Len = math.min( New:Length(), 1 )
	Len = Len - Len * Delta * 0.025
	Len = math.Clamp( math.abs( Len ) ^ 1.1 * Sign( Len ), -1, 1 )

	local Fx = math.cos( Ax ) * Len
	local Fy = math.sin( Ay ) * Len

	self:SetSteer( Cur + (Vector( Fx, Fy, 0 ) - Cur) * Delta * 100 )
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