ENT.Type            = "anim"

ENT.PrintName = "mini basescript"
ENT.Author = "Luna"
ENT.Information = ""
ENT.Category = "Prophecy - TinyLFS"

ENT.Spawnable		= true
ENT.AdminSpawnable  = true

ENT.AutomaticFrameAdvance = true
ENT.RenderGroup = RENDERGROUP_BOTH 

ENT.Editable = true

--ENT.MDL = "error.mdl"
ENT.MDL = "models/diggerthings/v19/v19_downscaled1150.mdl"

ENT.SeatPos = Vector(0,0,-33)
ENT.SeatAng = Angle(0,-90,0)

ENT.MiniLFS = true

ENT.MaxTurnSpeed = 15
ENT.MaxTurnDamp = 100
ENT.DampFactor = 0.2

ENT.MaxSpeed = 12
ENT.MaxVtolSpeedX = 4
ENT.MaxVtolSpeedY = 4
ENT.MaxVtolSpeedZ = 4
ENT.VtolIncrementRate = 1

ENT.ThrottleIncrementRate = 0.75

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Driver" )
	self:NetworkVar( "Entity",1, "DriverSeat" )

	self:NetworkVar( "Bool",0, "Active" )
	self:NetworkVar( "Bool",1, "AI",	{ KeyName = "aicontrolled",	Edit = { type = "Boolean",	order = 1,	category = "AI"} } )

	self:NetworkVar( "Float",0, "Throttle" )

	self:NetworkVar( "Int",2, "AITEAM", { KeyName = "aiteam", Edit = { type = "Int", order = 2,min = 0, max = 3, category = "AI"} } )
end

function ENT:GetRotorPos()
	return self:GetPos()
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