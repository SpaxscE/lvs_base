
ENT.Base = "lvs_base"

ENT.PrintName = "[LVS] Wheeldrive Base"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS] - Cars"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

ENT.MaxHealth = 600
ENT.MaxHealthEngine = 50
ENT.MaxHealthFuelTank = 10

ENT.MaxVelocity = 1400
ENT.MaxVelocityReverse = 700

ENT.EngineCurve = 0.65
ENT.EngineCurveBoostLow = 1
ENT.EngineTorque = 350
ENT.EngineIdleRPM = 1000
ENT.EngineMaxRPM = 6000

ENT.ThrottleRate = 3.5

ENT.ForceLinearMultiplier = 1
ENT.ForceAngleMultiplier = 0.5

ENT.TransGears = 4
ENT.TransGearsReverse = 1
ENT.TransMinGearHoldTime = 1
ENT.TransShiftSpeed = 0.3
ENT.TransWobble = 40
ENT.TransWobbleTime = 1.5
ENT.TransWobbleFrequencyMultiplier = 1
ENT.TransShiftSound = "lvs/vehicles/generic/gear_shift.wav"

ENT.SteerSpeed = 3
ENT.SteerReturnSpeed = 10

ENT.FastSteerActiveVelocity = 500
ENT.FastSteerAngleClamp = 10
ENT.FastSteerDeactivationDriftAngle = 7

ENT.SteerAssistDeadZoneAngle = 1
ENT.SteerAssistMaxAngle = 15
ENT.SteerAssistExponent = 1.5
ENT.SteerAssistMultiplier = 3

ENT.MouseSteerAngle = 20
ENT.MouseSteerExponent = 2

ENT.PhysicsWeightScale = 1
ENT.PhysicsMass = 1000
ENT.PhysicsInertia = Vector(1500,1500,750)
ENT.PhysicsDampingSpeed = 4000
ENT.PhysicsDampingForward = true
ENT.PhysicsDampingReverse = false

ENT.WheelPhysicsMass = 100
ENT.WheelPhysicsInertia = Vector(10,8,10)
ENT.WheelPhysicsTireHeight = 4
ENT.WheelPhysicsMaterials = {
	[0] = "friction_00", -- 0
	[1] = "friction_10", --  0.1
	[2] = "friction_25", --  0.25
	[3] = "rubber",  --  0.8
	[4] = "rubber",
	[5] = "rubber",
	[6] = "rubber",
	[7] = "rubber",
	[8] = "rubber",
	[9] = "rubber",
	[10] = "jeeptire", --  1.337 -- i don't believe friction in havok can go above 1, however other settings such as bouncyness and elasticity are affected by it as it seems. We use jeeptire as default even tho it technically isn't the "best" choice, but rather the most common one
	[11] = "jalopytire", -- 1.337
	[12] = "phx_tire_normal", --  3
}

ENT.AutoReverseVelocity = 50

ENT.WheelBrakeLockupRPM = 20

ENT.WheelBrakeForce = 400

ENT.WheelSideForce = 800
ENT.WheelDownForce = 500

ENT.AllowSuperCharger = true
ENT.SuperChargerVolume = 0.6
ENT.SuperChargerSound = "lvs/vehicles/generic/supercharger_loop.wav"
ENT.SuperChargerVisible = true

ENT.AllowTurbo = true
ENT.TurboVolume = 0.6
ENT.TurboSound = "lvs/vehicles/generic/turbo_loop.wav"
ENT.TurboBlowOff = {"lvs/vehicles/generic/turbo_blowoff1.wav","lvs/vehicles/generic/turbo_blowoff2.wav"}

ENT.DeleteOnExplode = false

ENT.lvsAllowEngineTool = true
ENT.lvsShowInSpawner = false

function ENT:SetupDataTables()
	self:CreateBaseDT()

	self:AddDT( "Float", "Steer" )
	self:AddDT( "Float", "Throttle" )
	self:AddDT( "Float", "MaxThrottle" )
	self:AddDT( "Float", "Brake" )

	self:AddDT( "Float", "NWMaxSteer" )

	self:AddDT( "Float", "WheelVelocity" )

	self:AddDT( "Int", "NWGear" )
	self:AddDT( "Int", "TurnMode" )
	self:AddDT( "Int", "SirenMode" )

	self:AddDT( "Bool", "Reverse" )
	self:AddDT( "Bool", "NWHandBrake" )

	self:AddDT( "Bool", "RacingHud" )
	self:AddDT( "Bool", "Backfire" )

	self:AddDT( "Entity", "Engine" )
	self:AddDT( "Entity", "FuelTank" )
	self:AddDT( "Entity", "LightsHandler" )
	self:AddDT( "Entity", "Turbo" )
	self:AddDT( "Entity", "Compressor" )

	self:AddDT( "Vector", "AIAimVector" )

	self:TurretSystemDT()
	self:TrackSystemDT()

	if SERVER then
		self:SetMaxThrottle( 1 )
		self:SetSirenMode( -1 )
	end
end

function ENT:TurretSystemDT()
end

function ENT:TrackSystemDT()
end

function ENT:StabilityAssist()
	if self:GetReverse() then
		return self.PhysicsDampingReverse
	end

	return self.PhysicsDampingForward
end

function ENT:GetMaxSteerAngle()
	if CLIENT then return self:GetNWMaxSteer() end

	local EntTable = self:GetTable()

	if EntTable._WheelMaxSteerAngle then return EntTable._WheelMaxSteerAngle end

	local Cur = 0

	for _, Axle in pairs( EntTable._WheelAxleData ) do
		if not Axle.SteerAngle then continue end

		if Axle.SteerAngle > Cur then
			Cur = Axle.SteerAngle
		end
	end

	EntTable._WheelMaxSteerAngle = Cur

	self:SetNWMaxSteer( Cur )

	return Cur
end

function ENT:GetTargetVelocity()
	local Reverse = self:GetReverse()

	if self:IsManualTransmission() then
		local Gear = self:GetGear()
		local EntTable = self:GetTable()

		local NumGears = Reverse and EntTable.TransGearsReverse or EntTable.TransGears
		local MaxVelocity = Reverse and EntTable.MaxVelocityReverse or EntTable.MaxVelocity

		local GearedVelocity = math.min( (MaxVelocity / NumGears) * (Gear + 1), MaxVelocity )

		return GearedVelocity * (Reverse and -1 or 1)
	end

	if Reverse then
		return -self.MaxVelocityReverse
	end

	return self.MaxVelocity
end

function ENT:HasHighBeams()
	local EntTable = self:GetTable()

	if isbool( EntTable._HasHighBeams ) then return EntTable._HasHighBeams end

	if not istable( EntTable.Lights ) then return false end

	local HasHigh = false

	for _, data in pairs( EntTable.Lights ) do
		if not istable( data ) then continue end

		for id, typedata in pairs( data ) do
			if id == "Trigger" and typedata == "high" then
				HasHigh = true

				break
			end
		end
	end

	EntTable._HasHighBeams = HasHigh

	return HasHigh
end

function ENT:HasFogLights()
	local EntTable = self:GetTable()

	if isbool( EntTable._HasFogLights ) then return EntTable._HasFogLights end

	if not istable( EntTable.Lights ) then return false end

	local HasFog = false

	for _, data in pairs( EntTable.Lights ) do
		if not istable( data ) then continue end

		for id, typedata in pairs( data ) do
			if id == "Trigger" and typedata == "fog" then
				HasFog = true

				break
			end
		end
	end

	EntTable._HasFogLights = HasFog

	return HasFog
end

function ENT:HasTurnSignals()
	local EntTable = self:GetTable()

	if isbool( EntTable._HasTurnSignals ) then return EntTable._HasTurnSignals end

	if not istable( EntTable.Lights ) then return false end

	local HasTurnSignals = false

	for _, data in pairs( EntTable.Lights ) do
		if not istable( data ) then continue end

		for id, typedata in pairs( data ) do
			if id == "Trigger" and (typedata == "turnleft" or  typedata == "turnright" or typedata == "main+brake+turnleft" or typedata == "main+brake+turnright") then
				HasTurnSignals = true

				break
			end
		end
	end

	EntTable._HasTurnSignals = HasTurnSignals

	return HasTurnSignals
end

function ENT:GetGear()
	local Gear = self:GetNWGear()

	if Gear <= 0 then
		return -1
	end

	if self:GetReverse() then
		return math.Clamp( Gear, 1, self.TransGearsReverse )
	end

	return math.Clamp( Gear, 1, self.TransGears )
end

function ENT:IsManualTransmission()
	return self:GetNWGear() > 0
end

function ENT:BodygroupIsValid( name, groups )
	if not name or not istable( groups ) then return false end

	local EntTable = self:GetTable()

	local id = -1

	if EntTable._StoredBodyGroups then
		if EntTable._StoredBodyGroups[ name ] then
			id = EntTable._StoredBodyGroups[ name ]
		end
	else
		EntTable._StoredBodyGroups = {}
	end

	if id == -1 then
		for _, data in pairs( self:GetBodyGroups() ) do
			if data.name == name then
				id = data.id

				break
			end
		end
	end

	if id == -1 then return false end

	EntTable._StoredBodyGroups[ name ] = id

	local cur = self:GetBodygroup( id )

	for _, active in pairs( groups ) do
		if cur == active then return true end
	end

	return false
end

function ENT:GetWheelUp()
	return self:GetUp()
end

function ENT:GetVehicleType()
	return "car"
end
