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
include("sh_camera_eyetrace.lua")

if (1 / engine.TickInterval()) <= 65 then
	include("simulate/performance.lua")
else
	include("simulate/accuracy.lua")
end

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
