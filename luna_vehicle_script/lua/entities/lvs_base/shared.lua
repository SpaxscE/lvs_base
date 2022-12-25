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
	self:AddDT( "Int", "SelectedWeapon" )
	self:AddDT( "Int", "NWAmmo" )

	self:AddDT( "Float", "HP", { KeyName = "health", Edit = { type = "Float", order = 2,min = 0, max = self.MaxHealth, category = "Misc"} } )
	self:AddDT( "Float", "NWHeat" )

	if SERVER then
		self:NetworkVarNotify( "AI", self.OnToggleAI )
		self:NetworkVarNotify( "SelectedWeapon", self.OnWeaponChanged )

		self:SetAITEAM( self.AITEAM )
		self:SetHP( self.MaxHealth )
		self:SetSelectedWeapon( 1 )
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

sound.Add( {
	name = "LVS.Physics.Scrape",
	channel = CHAN_STATIC,
	level = 80,
	sound = "lvs/physics/scrape_loop.wav"
} )

sound.Add( {
	name = "LVS.Physics.Impact",
	channel = CHAN_STATIC,
	level = 75,
	sound = {
		"lvs/physics/impact_soft1.wav",
		"lvs/physics/impact_soft2.wav",
		"lvs/physics/impact_soft3.wav",
		"lvs/physics/impact_soft4.wav",
		"lvs/physics/impact_soft5.wav",
	}
} )

sound.Add( {
	name = "LVS.Physics.Crash",
	channel = CHAN_STATIC,
	level = 75,
	sound = "lvs/physics/impact_hard.wav",
} )

sound.Add( {
	name = "LVS.Physics.Wind",
	channel = CHAN_STATIC,
	level = 140,
	sound = "lvs/physics/wind_loop.wav",
} )

sound.Add( {
	name = "LVS.Physics.Water",
	channel = CHAN_STATIC,
	level = 140,
	sound = "lvs/physics/water_loop.wav",
} )

sound.Add( {
	name = "LVS.DYNAMIC_EXPLOSION",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 130,
	pitch = {90, 110},
	sound = "^lvs/explosion_dist.wav"
} )

sound.Add( {
	name = "LVS.EXPLOSION",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 115,
	pitch = {95, 115},
	sound = "lvs/explosion.wav"
} )
