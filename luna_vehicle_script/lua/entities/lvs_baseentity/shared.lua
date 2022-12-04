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

function ENT:AddDT( type, name, data )
	if not self.DTlist then self.DTlist = {} end

	if self.DTlist[ type ] then
		self.DTlist[ type ] = self.DTlist[ type ] + 1
	else
		self.DTlist[ type ] = 0
	end

	self:NetworkVar( type, self.DTlist[ type ], name, data )
end

function ENT:CreateBaseDT()
	self:AddDT( "Entity", "Driver" )
	self:AddDT( "Entity", "DriverSeat" )
	self:AddDT( "Entity", "Gunner" )
	self:AddDT( "Entity", "GunnerSeat" )

	self:AddDT( "Bool", "Active" )
	self:AddDT( "Bool", "EngineActive" )
	self:AddDT( "Bool", "AI",	{ KeyName = "aicontrolled",	Edit = { type = "Boolean",	order = 1,	category = "AI"} } )
	self:AddDT( "Bool", "lvsLockedStatus" )

	self:AddDT( "Int", "AITEAM", { KeyName = "aiteam", Edit = { type = "Int", order = 2,min = 0, max = 3, category = "AI"} } )

	self:AddDT( "Float", "HP", { KeyName = "health", Edit = { type = "Float", order = 2,min = 0, max = self.MaxHealth, category = "Misc"} } )

	self:AddDT( "Bool", "LockView",	{ KeyName = "lockview",	Edit = { type = "Boolean",	order = 3,	category = "Misc"} } )

	if SERVER then
		self:NetworkVarNotify( "AI", self.OnToggleAI )
		
		self:SetAITEAM( self.AITEAM )
		self:SetHP( self.MaxHealth )
	end

	self:OnSetupDataTables()
end

function ENT:SetupDataTables()
	self:CreateBaseDT()
end

function ENT:OnSetupDataTables()
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