ENT.Type            = "anim"

ENT.PrintName = "[LVS] Base Entity"
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
ENT.MaxShield = 150

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
	self:AddDT( "Float", "Shield" )

	if SERVER then
		self:NetworkVarNotify( "AI", self.OnToggleAI )
		
		self:SetAITEAM( self.AITEAM )
		self:SetHP( self.MaxHealth )
		self:SetShield( self.MaxShield )
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
