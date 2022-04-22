ENT.Type            = "anim"

ENT.PrintName = "basescript"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Framework - Basescript"
ENT.Category = "[LVF]"

ENT.Spawnable		= false
ENT.AdminSpawnable  = false

ENT.AutomaticFrameAdvance = true
ENT.RenderGroup = RENDERGROUP_BOTH 

ENT.Editable = true

ENT.LVF = true

ENT.MDL = "models/error.mdl"

ENT.Mass = 50

function ENT:BaseDT()
	self:NetworkVar( "Entity",0, "Driver" )
	self:NetworkVar( "Entity",1, "DriverSeat" )

	self:NetworkVar( "Bool",0, "Active" )
	self:NetworkVar( "Bool",1, "lvfLockedStatus" )

	self:NetworkVar( "Bool",3, "AI",	{ KeyName = "aicontrolled",	Edit = { type = "Boolean",	order = 1,	category = "AI"} } )
end

function ENT:SetupDataTables()
	self:BaseDT()
end

function ENT:CalcMainActivity( ply )
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