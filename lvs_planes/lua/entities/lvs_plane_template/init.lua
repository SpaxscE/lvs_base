AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

--[[
ENT.WaterLevelPreventStart = 1 -- at this water level engine can not start
ENT.WaterLevelAutoStop = 2 -- at this water level (on collision) the engine will stop
ENT.WaterLevelDestroyAI = 2 -- at this water level (on collision) the AI will self destruct
]]

-- use this instead of ENT:Initialize()
function ENT:OnSpawn( PhysObj )
	local Pod = self:AddDriverSeat( Vector(0,0,0), Angle(0,-90,0) ) -- self:AddDriverSeat( Position,  Angle ) -- add a driver seat (max 1)
	-- Pod.ExitPos = Vector(0,0,100) -- change exit position
	-- Pod.HidePlayer = true -- should the player in this pod be invisible?

	-- local Pod = self:AddPassengerSeat( Position, Angle ) -- add a passenger seat (no limit)
	-- Pod.ExitPos = Vector(0,0,100) -- change exit position
	-- Pod.HidePlayer = true -- should the player in this pod be invisible?

	-- self:AddWheel( Position, Radius, Mass, Type ) -- add a wheel.
	--[[ Type can be either:
		LVS.WHEEL_BRAKE -- which is a wheel that acts as a Brake when Throttle = 0, it defaults to this when not given a type
		LVS.WHEEL_STEER_NONE -- a wheel that has free rotation in all direction (no steering)
		LVS.WHEEL_STEER_FRONT -- ..that turns left when left key is pressed
		LVS.WHEEL_STEER_REAR -- ..turns right when left key is pressed
	]]

	self:AddEngine( Vector(40,0,0) ) -- add a engine. This will also register a critical hit point and create black smoke effects when health is low.

	--[[ -- AddEngine internally registers a critical hit point to the damage system like this:
	self:AddDS( {
		pos = Vector(0,0,0),
		ang = Angle(0,0,0),
		mins = Vector(-40,-20,-30),
		maxs =  Vector(40,20,30),
		Callback = function( tbl, ent, dmginfo )
			--dmginfo:ScaleDamage( 15 )
		end
	} )
	]]

	-- self:AddRotor( Position ) -- add a rotor sound handler
end

function ENT:OnDriverChanged( Old, New, VehicleIsActive )
end

function ENT:OnGunnerChanged( Old, New )
end

 -- use this instead of ENT:Think()
function ENT:OnTick()
end

-- use this instead of ENT:OnRemove()
function ENT:OnRemoved()
end

-- called when the vehicle is set to destroyed
function ENT:OnDestroyed()
end

function ENT:OnLandingGearToggled( IsDeployed )
end

function ENT:OnEngineActiveChanged( Active )
end

-- called by the vehicle repair trailer after a repair/refil is performed
function ENT:OnMaintenance()
end


