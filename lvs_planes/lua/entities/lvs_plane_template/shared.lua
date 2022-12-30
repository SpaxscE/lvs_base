
ENT.Base = "lvs_base_fighterplane"

ENT.PrintName = "template script"
ENT.Author = "*your name*"
ENT.Information = ""
ENT.Category = "[LVS] *your category*"

ENT.Spawnable			= true -- set to "true" to make it spawnable
ENT.AdminSpawnable		= false

ENT.MDL = "models/props_wasteland/laundry_cart001.mdl" -- model forward direction must be facing to X+
--[[
ENT.GibModels = {
	"models/XQM/wingpiece2.mdl",
	"models/XQM/wingpiece2.mdl",
	"models/XQM/jetwing2medium.mdl",
	"models/XQM/jetwing2medium.mdl",
	"models/props_phx/misc/propeller3x_small.mdl",
	"models/props_c17/TrapPropeller_Engine.mdl",
	"models/props_junk/Shoe001a.mdl",
	"models/XQM/jetbody2fuselage.mdl",
	"models/XQM/jettailpiece1medium.mdl",
	"models/XQM/pistontype1huge.mdl",
}
]]

ENT.AITEAM = 1
--[[
TEAMS:
	0 = FRIENDLY TO EVERYONE
	1 = FRIENDLY TO TEAM 1 and 0
	2 = FRIENDLY TO TEAM 2 and 0
	3 = HOSTILE TO EVERYONE
]]

ENT.MaxVelocity = 2500 -- max theoretical velocity at 0 degree climb
ENT.MaxPerfVelocity = 1800 -- speed in which the plane will have its maximum turning potential
ENT.MaxThrust = 1250 -- max push power

ENT.TurnRatePitch = 1 -- max turn rate in pitch (up / down)
ENT.TurnRateYaw = 1 -- max turn rate in yaw (left / right)
ENT.TurnRateRoll = 1 -- max turn rate in roll

ENT.ForceLinearMultiplier = 1 -- multiplier for linear force in X / Y / Z direction

ENT.ForceAngleMultiplier = 1 -- multiplier for angular forces in pitch / yaw / roll direction
ENT.ForceAngleDampingMultiplier = 1 -- how much angular motion is dampened (smaller value = wobble more)

ENT.MaxSlipAnglePitch = 20 -- how many degrees the plane is allowed to slip from forward-motion direction vs forward-facing direction
ENT.MaxSlipAngleYaw = 10 -- same for yaw

ENT.MaxHealth = 1000

ENT.FlyByAdvance = 0.5 -- how many second the flyby sound is advanced
ENT.FlyBySound = "lvs/vehicles/bf109/flyby.wav" -- which sound to play on fly by
ENT.DeathSound = "lvs/vehicles/generic/crash.wav" -- which sound to play on death (only in flight)

function ENT:OnSetupDataTables() -- use this to add networkvariables instead of ENT:SetupDataTables().
	--self:AddDT(  string_type, string_name, table_extended ) -- please use self:AddDT() function instead of self:NetworkVar(). It automatically handles slot indexes internally.

	-- example:
	--self:AddDT( "Float", "MyValue", { KeyName = "myvalue", Edit = { type = "Float", order = 3,min = 0, max = 10, category = "Misc"}  )
end

--[[
function ENT:CalcMainActivity( ply ) -- edit player anims here, works just like CalcMainActivity Hook.
end
]]


function ENT:InitWeapons()
	--[[ add a weapon:

	local weapon = {}
	weapon.Icon = Material("lvs/weapons/bullet.png")
	weapon.Ammo = -1
	weapon.Delay = 0.15
	weapon.HeatRateUp = 0.2
	weapon.HeatRateDown = 0.25
	weapon.Attack = function( ent ) end
	weapon.StartAttack = function( ent ) end
	weapon.FinishAttack = function( ent ) end
	weapon.OnSelect = function( ent ) end
	weapon.OnDeselect = function( ent ) end
	weapon.OnThink = function( ent, active ) end
	weapon.OnOverheat = function( ent ) end
	weapon.OnRemove = function( ent ) end
	self:AddWeapon( weapon )
	]]
end
