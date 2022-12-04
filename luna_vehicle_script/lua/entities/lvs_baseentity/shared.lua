ENT.Type            = "anim"

ENT.PrintName = "generic basescript"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

ENT.AutomaticFrameAdvance = true
ENT.RenderGroup = RENDERGROUP_BOTH 

ENT.Editable = true

ENT.LVS = true

ENT.MDL = "models/error.mdl"

ENT.AITEAM = 0

ENT.MaxHealth = 1000

function ENT:BaseDT()
	self:NetworkVar( "Entity",0, "Driver" )
	self:NetworkVar( "Entity",1, "DriverSeat" )
	self:NetworkVar( "Entity",2, "Gunner" )
	self:NetworkVar( "Entity",3, "GunnerSeat" )

	self:NetworkVar( "Bool",0, "Active" )
	self:NetworkVar( "Bool",1, "EngineActive" )
	self:NetworkVar( "Bool",2, "AI",	{ KeyName = "aicontrolled",	Edit = { type = "Boolean",	order = 1,	category = "AI"} } )
	self:NetworkVar( "Bool",3, "lvsLockedStatus" )

	self:NetworkVar( "Int", 0, "AITEAM", { KeyName = "aiteam", Edit = { type = "Int", order = 2,min = 0, max = 3, category = "AI"} } )

	self:NetworkVar( "Vector", 0, "Steer" )

	self:NetworkVar( "Float", 1, "Throttle" )
	self:NetworkVar( "Float", 2, "HP", { KeyName = "health", Edit = { type = "Float", order = 2,min = 0, max = self.MaxHealth, category = "Misc"} } )

	if SERVER then
		self:NetworkVarNotify( "AI", self.OnToggleAI )
		
		self:SetAITEAM( self.AITEAM )
		self:SetHP( self.MaxHealth )
	end
end

function ENT:SetupDataTables()
	self:BaseDT()
end

function ENT:CalcMainActivity( ply )
end

function ENT:StartCommand( ply, cmd )
end

function ENT:GetMaxHP()
	return self.MaxHealth
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

function ENT:GetPassenger( num )
	if num == 1 then
		return self:GetDriver()
	else
		for _, Pod in pairs( self:GetPassengerSeats() ) do
			local id = Pod:GetNWInt( "pPodIndex", -1 )
			if id == -1 then continue end

			if id == num then
				return Pod:GetDriver()
			end
		end

		return NULL
	end
end

function ENT:Sign( n )
	if n > 0 then return 1 end

	if n < 0 then return -1 end

	return 0
end