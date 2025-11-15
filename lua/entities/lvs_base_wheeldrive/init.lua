AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_flyby.lua" )
AddCSLuaFile( "cl_camera.lua" )
AddCSLuaFile( "cl_hud.lua" )
AddCSLuaFile( "cl_hud_speedometer.lua" )
AddCSLuaFile( "cl_tiresounds.lua" )
AddCSLuaFile( "cl_scrolltexture.lua" )
AddCSLuaFile( "cl_exhausteffects.lua" )
AddCSLuaFile( "sh_animations.lua" )
AddCSLuaFile( "sh_camera_eyetrace.lua" )
include("shared.lua")
include("sh_animations.lua")
include("sv_controls.lua")
include("sv_controls_handbrake.lua")
include("sv_components.lua")
include("sv_ai.lua")
include("sv_riggedwheels.lua")
include("sv_wheelsystem.lua")
include("sv_damage.lua")
include("sv_pivotsteer.lua")
include("sv_manualtransmission.lua")
include("sv_engine.lua")
include("sv_hydraulics.lua")
include("sh_camera_eyetrace.lua")

ENT.DriverActiveSound = "common/null.wav"
ENT.DriverInActiveSound = "common/null.wav"

DEFINE_BASECLASS( "lvs_base" )

local function SetMinimumAngularVelocityTo( new )
	local tbl = physenv.GetPerformanceSettings()

	if tbl.MaxAngularVelocity < new then
		local OldAngVel = tbl.MaxAngularVelocity

		tbl.MaxAngularVelocity = new
		physenv.SetPerformanceSettings( tbl )

		print("[LVS-Cars] Wheels require higher MaxAngularVelocity to perform correctly! Increasing! "..OldAngVel.." =>"..new)
	end
end

local function IsServerOK( class )

	if GetConVar( "gmod_physiterations" ):GetInt() ~= 4 then
		RunConsoleCommand("gmod_physiterations", "4")

		return false
	end

	return true
end

function ENT:TracksCreate( PObj )
end

local function DontDuplicatePaintSheme( ply, ent, data )
	ent.RandomColor = nil

	if not duplicator or not duplicator.StoreEntityModifier then return end

	duplicator.StoreEntityModifier( ent, "lvsVehiclePaintSheme", data )
end

if duplicator and duplicator.RegisterEntityModifier then
	duplicator.RegisterEntityModifier( "lvsVehiclePaintSheme", DontDuplicatePaintSheme )
end

function ENT:PostInitialize( PObj )

	self:TracksCreate( PObj )

	if not IsServerOK( self:GetClass() ) then
		self:Remove()
		print("[LVS] ERROR COULDN'T INITIALIZE VEHICLE!")
	end

	if istable( self.Lights ) then
		self:AddLights()
	end

	if istable( self.RandomColor ) then
		local data = self.RandomColor[ math.random( #self.RandomColor ) ]

		if IsColor( data ) then
			self:SetColor( data )
		else
			self:SetSkin( data.Skin or 0 )
			self:SetColor( data.Color or color_white )

			if istable( data.Wheels ) then
				self._WheelSkin = data.Wheels.Skin or 0
				self._WheelColor = data.Wheels.Color or color_white
			end

			if istable( data.BodyGroups ) then
				for id, subgroup in pairs( data.BodyGroups ) do
					self:SetBodygroup( id, subgroup )
				end
			end
		end

		DontDuplicatePaintSheme( NULL, self, {} )
	end

	BaseClass.PostInitialize( self, PObj )

	if isstring( self.HornSound ) and isvector( self.HornPos ) then
		if IsValid( self.HornSND ) then self.HornSND:Remove() end

		self.HornSND = self:AddSoundEmitter( self.HornPos or vector_origin, self.HornSound, self.HornSoundInterior )
		self.HornSND:SetSoundLevel( 75 )
		self.HornSND:SetDoppler( true )
	end

	if istable( self.SirenSound ) then
		if IsValid( self.SirenSND ) then self.SirenSND:Remove() end

		self.SirenSND = self:AddSoundEmitter( self.SirenPos or vector_origin, "common/null.wav" )
		self.SirenSND:SetSoundLevel( 75 )
		self.SirenSND:SetDoppler( true )
	end

	PObj:SetMass( self.PhysicsMass * self.PhysicsWeightScale )
	PObj:EnableDrag( false )
	PObj:SetInertia( self.PhysicsInertia * self.PhysicsWeightScale )

	SetMinimumAngularVelocityTo( 24000 )

	self:EnableHandbrake()
end

function ENT:AlignView( ply )
	if not IsValid( ply ) then return end

	timer.Simple( 0, function()
		if not IsValid( ply ) or not IsValid( self ) then return end

		local Ang = Angle(0,90,0)

		local pod = ply:GetVehicle()
		local MouseAim = ply:lvsMouseAim() and self:GetDriver() == ply

		if MouseAim and IsValid( pod ) then
			Ang = pod:LocalToWorldAngles( Angle(0,90,0) )
			Ang.r = 0
		end

		ply:SetEyeAngles( Ang )
	end)
end

function ENT:PhysicsSimulateOverride( ForceAngle, phys, deltatime, simulate )

	if not self:GetRacingTires() then
		return ForceAngle, vector_origin, simulate
	end

	local EntTable = self:GetTable()

	local WheelSideForce = EntTable.WheelSideForce * EntTable.ForceLinearMultiplier
	local ForceLinear = Vector(0,0,0)

	for id, wheel in pairs( self:GetWheels() ) do
		if wheel:IsHandbrakeActive() or not wheel:PhysicsOnGround() then continue end

		local AxleAng = wheel:GetDirectionAngle()
	
		local Forward = AxleAng:Forward()
		local Right = AxleAng:Right()
		local Up = AxleAng:Up()

		local wheelPos = wheel:GetPos()
		local wheelVel = phys:GetVelocityAtPoint( wheelPos )
		local wheelRadius = wheel:GetRadius()

		local Slip = math.Clamp(1 - self:AngleBetweenNormal( Forward, wheelVel:GetNormalized() ) / 90,0,1)

		local ForwardVel = self:VectorSplitNormal( Forward, wheelVel )

		Force = -Right * self:VectorSplitNormal( Right, wheelVel ) * WheelSideForce * Slip
		local wSideForce, wAngSideForce = phys:CalculateVelocityOffset( Force, wheelPos )

		ForceAngle:Add( Vector(0,0,wAngSideForce.z) )
		ForceLinear:Add( wSideForce )
	end

	return ForceAngle, ForceLinear, simulate
end

function ENT:PhysicsSimulate( phys, deltatime )

	if self:GetEngineActive() then phys:Wake() end

	local ent = phys:GetEntity()

	if ent == self then
		local Vel = 0

		for _, wheel in pairs( self:GetWheels() ) do
			if wheel:GetTorqueFactor() <= 0 then continue end

			local wheelVel = wheel:RPMToVel( math.abs( wheel:GetRPM() or 0 ) )

			if wheelVel > Vel then
				Vel = wheelVel
			end
		end

		self:SetWheelVelocity( Vel )

		if not self:StabilityAssist() or not self:WheelsOnGround() then return self:PhysicsSimulateOverride( Vector(0,0,0), phys, deltatime, SIM_NOTHING ) end

		local ForceAngle = Vector(0,0, math.deg( -phys:GetAngleVelocity().z ) * math.min( phys:GetVelocity():Length() / self.PhysicsDampingSpeed, 1 ) * self.ForceAngleMultiplier )

		return self:PhysicsSimulateOverride( ForceAngle, phys, deltatime, SIM_GLOBAL_ACCELERATION )
	end

	if not self:AlignWheel( ent ) or self:IsDestroyed() then self:EnableHandbrake() return vector_origin, vector_origin, SIM_NOTHING end

	local WheelTable = ent:GetTable()
	local EntTable = self:GetTable()

	if ent:IsHandbrakeActive() then
		if WheelTable.SetRPM then
			ent:SetRPM( 0 )
		end

		return vector_origin, vector_origin, SIM_NOTHING
	end

	local T = CurTime()

	if (WheelTable._NextSimulate or 0) < T or not WheelTable.Simulate then
		WheelTable._NextSimulate = T + ((self:PivotSteer() or self:GetBrake() > 0) and 0.05 or 0.2)

		WheelTable.Force, WheelTable.ForceAng, WheelTable.Simulate = self:SimulateRotatingWheel( ent, EntTable, WheelTable, phys, deltatime )
	end

	return WheelTable.Force, WheelTable.ForceAng, WheelTable.Simulate
end

function ENT:SimulateRotatingWheel( ent, EntTable, WheelTable, phys, deltatime )
	local RotationAxis = ent:GetRotationAxis()

	local curRPM = self:VectorSplitNormal( RotationAxis,  phys:GetAngleVelocity() ) / 6

	local Throttle = self:GetThrottle()

	ent:SetRPM( curRPM )

	local ForceAngle = vector_origin
	local ForceLinear = Vector(0,0,0)

	local TorqueFactor = ent:GetTorqueFactor()

	local IsBraking = self:GetBrake() > 0
	local IsBrakingWheel = (TorqueFactor * Throttle) <= 0.99

	if IsBraking and IsBrakingWheel then
		if ent:IsRotationLocked() then
			ForceAngle = vector_origin
		else
			local ForwardVel = self:VectorSplitNormal( ent:GetDirectionAngle():Forward(),  phys:GetVelocity() )

			local targetRPM = ent:VelToRPM( ForwardVel ) * 0.5

			if math.abs( curRPM ) < EntTable.WheelBrakeLockupRPM then
				ent:LockRotation()
			else
				if (ForwardVel > 0 and targetRPM > 0) or (ForwardVel < 0 and targetRPM < 0) then
					ForceAngle = RotationAxis * math.Clamp( (targetRPM - curRPM) / 100,-1,1) * math.deg( EntTable.WheelBrakeForce ) * ent:GetBrakeFactor() * self:GetBrake()
				end
			end
		end
	else
		if math.abs( curRPM ) < EntTable.WheelBrakeLockupRPM and Throttle == 0 then
			ent:LockRotation()
		else
			if ent:IsRotationLocked() then
				ent:ReleaseRotation()
			end
		end

		if TorqueFactor > 0 and Throttle > 0 then
			local engineTorque = self:GetEngineTorque()

			local targetVelocity = self:GetTargetVelocity()

			local targetRPM = ent:VelToRPM( targetVelocity )

			local targetRPMabs = math.abs( targetRPM )

			local powerRPM = targetRPMabs * EntTable.EngineCurve

			local powerCurve = (powerRPM + math.max( targetRPMabs - powerRPM,0) - math.max(math.abs(curRPM) - powerRPM,0)) / targetRPMabs * self:Sign( targetRPM - curRPM )

			local Torque = powerCurve * engineTorque * TorqueFactor * Throttle

			local BoostRPM = 0

			if self:GetReverse() then
				Torque = math.min( Torque, 0 )

				BoostRPM = ent:VelToRPM( EntTable.MaxVelocityReverse / EntTable.TransGearsReverse ) * 0.5
			else
				Torque = math.max( Torque, 0 )

				BoostRPM = ent:VelToRPM( EntTable.MaxVelocity / EntTable.TransGears ) * 0.5
			end

			local BoostMul = math.max( EntTable.EngineCurveBoostLow, 0 )
			local BoostStart = 1 + BoostMul

			local TorqueBoost = BoostStart - (math.min( math.max( math.abs( curRPM ) - BoostRPM, 0 ), BoostRPM) / BoostRPM) * BoostMul

			local Forward = ent:GetDirectionAngle():Forward()

			local curVelocity = self:VectorSplitNormal( Forward,  phys:GetVelocity() )

			if self:IsFakePhysicsEnabled() and TorqueBoost == 1 and ent:PhysicsOnGround() then
				if targetVelocity >= 0 then
					if curVelocity < targetVelocity then
						ForceLinear = Forward * Torque
					end
				else
					if curVelocity > targetVelocity then
						ForceLinear = Forward * Torque
					end
				end
			else
				if targetVelocity >= 0 then
					if curVelocity < targetVelocity then
						ForceAngle = RotationAxis * Torque * TorqueBoost
					end
				else
					if curVelocity > targetVelocity then
						ForceAngle = RotationAxis * Torque * TorqueBoost
					end
				end
			end

			if self:PivotSteer() then
				local RotationDirection = ent:GetWheelType() * self:GetPivotSteer()
	
				if EntTable.PivotSteerByBrake and RotationDirection < 0 then
					ent:LockRotation( true )

					return vector_origin, vector_origin, SIM_NOTHING
				end

				powerCurve = math.Clamp((EntTable.PivotSteerWheelRPM * RotationDirection - curRPM) / EntTable.PivotSteerWheelRPM,-1,1)

				Torque = powerCurve * engineTorque * TorqueFactor * Throttle * 2 * EntTable.PivotSteerTorqueMul

				ForceLinear = Vector(0,0,0)
				ForceAngle = RotationAxis * Torque
			end
		end
	end

	if not self:StabilityAssist() or not self:WheelsOnGround() then return ForceAngle, ForceLinear, SIM_GLOBAL_ACCELERATION end

	local Vel = phys:GetVelocity()

	local ForwardAngle = ent:GetDirectionAngle()

	local Forward = ForwardAngle:Forward()
	local Right = ForwardAngle:Right()

	local Fy = self:VectorSplitNormal( Right, Vel )
	local Fx = self:VectorSplitNormal( Forward, Vel )

	if TorqueFactor >= 1 then
		local VelX = math.abs( Fx )
		local VelY = math.abs( Fy )

		if VelY > VelX * 0.1 then
			if VelX > EntTable.FastSteerActiveVelocity then
				if VelY < VelX * 0.6 then
					return ForceAngle, ForceLinear, SIM_GLOBAL_ACCELERATION
				end
			else
				return ForceAngle, ForceLinear, SIM_GLOBAL_ACCELERATION
			end
		end
	end

	ForceLinear:Div( 4.5 ) -- trust me bro, its 4.5!!

	if IsBraking and not IsBrakingWheel then
		return ForceAngle, ForceLinear, SIM_GLOBAL_ACCELERATION
	end

	ForceLinear:Add( -self:GetUp() * EntTable.WheelDownForce * TorqueFactor )

	if not self:GetRacingTires() then
		ForceLinear:Add( -Right * math.Clamp(Fy * 5 * math.min( math.abs( Fx ) / 500, 1 ),-EntTable.WheelSideForce,EntTable.WheelSideForce) * EntTable.ForceLinearMultiplier )
	end

	return ForceAngle, ForceLinear, SIM_GLOBAL_ACCELERATION
end

function ENT:SteerTo( TargetValue, MaxSteer )
	local Cur = self:GetSteer() / MaxSteer
	
	local Diff = TargetValue - Cur

	local Returning = (Diff > 0 and Cur < 0) or (Diff < 0 and Cur > 0)

	local Rate = FrameTime() * (Returning and self.SteerReturnSpeed or self.SteerSpeed)

	local New = (Cur + math.Clamp(Diff,-Rate,Rate))

	self:SetSteer( New * MaxSteer )

	if New == 0 or self:GetEngineActive() then return end

	for _, wheel in pairs( self:GetWheels() ) do
		if not IsValid( wheel ) then continue end

		wheel:PhysWake()
	end
end

function ENT:OnDriverEnterVehicle( ply )
end

function ENT:OnDriverExitVehicle( ply )
end

function ENT:OnDriverChanged( Old, New, VehicleIsActive )
	self:OnPassengerChanged( Old, New, 1 )

	if VehicleIsActive then

		self:OnDriverEnterVehicle( New )

		return
	end

	self:OnDriverExitVehicle( Old )
	self:SetThrottle( 0 )

	if self:GetBrake() > 0 then
		self:SetBrake( 0 )
		self:EnableHandbrake()
		self:StopEngine()
		self:SetTurnMode( 0 )

		local LightsHandler = self:GetLightsHandler()

		if IsValid( LightsHandler ) then
			LightsHandler:SetActive( false )
			LightsHandler:SetHighActive( false )
			LightsHandler:SetFogActive( false )
		end
	else
		if not self:GetEngineActive() then
			self:SetBrake( 0 )
			self:EnableHandbrake()
		end
	end

	self:SetReverse( false )

	self:StopSiren()

	if self:GetSirenMode() > 0 then
		self:SetSirenMode( 0 )
	end

	if IsValid( self.HornSND ) then
		self.HornSND:Stop()
	end
end

function ENT:OnRefueled()
	local FuelTank = self:GetFuelTank()

	if not IsValid( FuelTank ) then return end

	FuelTank:EmitSound( "vehicles/jetski/jetski_no_gas_start.wav" )
end

function ENT:OnMaintenance()
	local FuelTank = self:GetFuelTank()
	local Engine = self:GetEngine()

	if IsValid( Engine ) then
		Engine:SetHP( Engine:GetMaxHP() )
		Engine:SetDestroyed( false )
	end

	if IsValid( FuelTank ) then
		FuelTank:ExtinguishAndRepair()

		if FuelTank:GetFuel() ~= 1 then
			FuelTank:SetFuel( 1 )

			self:OnRefueled()
		end
	end

	for _, wheel in pairs( self:GetWheels() ) do
		if not IsValid( wheel ) then continue end

		wheel:SetHP( wheel:GetMaxHP() )
	end
end

function ENT:OnSuperCharged( enable )
end

function ENT:OnTurboCharged( enable )
end

function ENT:ApproachTargetAngle( TargetAngle )
	local pod = self:GetDriverSeat()

	if not IsValid( pod ) then return end

	local ang = pod:GetAngles()
	ang:RotateAroundAxis( self:GetUp(), 90 )

	local Forward = ang:Right()
	local View = pod:WorldToLocalAngles( TargetAngle ):Forward()

	local Reversed = false
	if self:AngleBetweenNormal( View, ang:Forward() ) < 90 then
		Reversed = self:GetReverse()
	end

	local LocalAngSteer = (self:AngleBetweenNormal( View, ang:Right() ) - 90) / self.MouseSteerAngle

	local Steer = (math.min( math.abs( LocalAngSteer ), 1 ) ^ self.MouseSteerExponent * self:Sign( LocalAngSteer ))

	self:SteerTo( Reversed and Steer or -Steer, self:GetMaxSteerAngle() )
end

function ENT:IsFakePhysicsEnabled()
	local EntTable = self:GetTable()

	if not EntTable.MaxVelocityWheelSpazz then return false end

	return math.max( EntTable.MaxVelocity, EntTable.MaxVelocityReverse ) > EntTable.MaxVelocityWheelSpazz
end