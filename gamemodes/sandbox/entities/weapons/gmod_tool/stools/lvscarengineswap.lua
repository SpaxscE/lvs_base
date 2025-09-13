

TOOL.Category		= "LVS"
TOOL.Name			= "#Engine Swap"

TOOL.Information = {
	{ name = "left" },
	{ name = "right" },
}

if CLIENT then
	language.Add( "tool.lvscarengineswap.name", "Engine Swap" )
	language.Add( "tool.lvscarengineswap.desc", "A tool used to swap engine sounds on [LVS] - Cars" )
	language.Add( "tool.lvscarengineswap.left", "Apply Engine Sound" )
	language.Add( "tool.lvscarengineswap.right", "Copy Engine Sound" )
end


local function SwapEngine( ent, data )
	if not IsValid( ent ) or not istable( data ) then return end

	local originalEngine = ent:GetEngine()

	if not IsValid( originalEngine ) then return end

	local Engine = ents.Create( "lvs_wheeldrive_engine_swapped" )
	Engine:SetPos( originalEngine:GetPos() )
	Engine:SetAngles( originalEngine:GetAngles() )
	Engine:Spawn()
	Engine:Activate()
	Engine:SetParent( ent )
	Engine:SetBase( ent )
	Engine.EngineSounds = data
	Engine:SetDoorHandler( originalEngine:GetDoorHandler() )

	ent:SetEngine( Engine )

	ent:DeleteOnRemove( Engine )

	ent:TransferCPPI( Engine )

	originalEngine:Remove()

	if not duplicator or not duplicator.StoreEntityModifier then return end

	duplicator.StoreEntityModifier( ent, "lvsCarSwapEngine", data )
end

local function DuplicatorSwapEngine( ply, ent, data )
	timer.Simple(0.1, function()
		if not IsValid( ent ) then return end

		SwapEngine( ent, data )
	end )
end
if duplicator and duplicator.RegisterEntityModifier then
	duplicator.RegisterEntityModifier( "lvsCarSwapEngine", DuplicatorSwapEngine )
end

function TOOL:SwapEngine( ent )
	if CLIENT then return end

	SwapEngine( ent, self.EngineSounds )
end

function TOOL:IsValidTarget( ent )
	if not IsValid( ent ) then return false end

	if not ent.LVS or not ent.lvsAllowEngineTool then return false end

	return true
end

function TOOL:LeftClick( trace )
	if not self.EngineSounds then return false end

	local ent = trace.Entity

	if not self:IsValidTarget( ent ) then return false end

	self:SwapEngine( ent )

	return true
end

function TOOL:RightClick( trace )
	local ent = trace.Entity

	if not self:IsValidTarget( ent ) then return false end

	self.EngineSounds = ent.EngineSounds

	return true
end

function TOOL:Reload( trace )
	return false
end
