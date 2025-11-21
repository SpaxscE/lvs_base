AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")
include("sv_ai.lua")
include("sv_kill_functions.lua")

function ENT:EnableManualTransmission()
	return false
end

function ENT:DisableManualTransmission()
	return false
end

function ENT:OnTick()
	local InputTarget = self:GetInputTarget()

	if not IsValid( InputTarget ) then return end

	local InputLightsHandler = InputTarget:GetLightsHandler()
	local LightsHandler = self:GetLightsHandler()

	if not IsValid( InputLightsHandler ) or not IsValid( LightsHandler ) then return end

	LightsHandler:SetActive( InputLightsHandler:GetActive() )
	LightsHandler:SetHighActive( InputLightsHandler:GetHighActive() )
	LightsHandler:SetFogActive( InputLightsHandler:GetFogActive() )
end

function ENT:PhysicsSimulateOverride( ForceAngle, phys, deltatime, simulate )
	return ForceAngle, vector_origin, simulate
end

function ENT:PhysicsSimulate( phys, deltatime )
	local ent = phys:GetEntity()

	if ent == self then
		if not self:StabilityAssist() or not self:WheelsOnGround() then return vector_origin, vector_origin, SIM_NOTHING end

		local ForceAngle = Vector(0,0, math.deg( -phys:GetAngleVelocity().z ) * math.min( phys:GetVelocity():Length() / self.PhysicsDampingSpeed, 1 ) * self.ForceAngleMultiplier )

		return self:PhysicsSimulateOverride( ForceAngle, phys, deltatime, SIM_GLOBAL_ACCELERATION )
	end

	return self:SimulateRotatingWheel( ent, phys, deltatime )
end

function ENT:SimulateRotatingWheel( ent, phys, deltatime )
	local RotationAxis = ent:GetRotationAxis()

	local curRPM = self:VectorSplitNormal( RotationAxis,  phys:GetAngleVelocity() ) / 6

	ent:SetRPM( curRPM )

	if not self:AlignWheel( ent ) or ent:IsHandbrakeActive() then

		local HandBrake = self:GetNWHandBrake()

		if HandBrake then
			if not ent:IsRotationLocked() then
				ent:LockRotation()
			end

			ent:SetRPM( 0 )
		else
			if ent:IsRotationLocked() then
				ent:ReleaseRotation()
			end
		end

		return vector_origin, vector_origin, SIM_NOTHING
	end

	if self:GetBrake() > 0 and not ent:IsRotationLocked() then
		local ForwardVel = self:VectorSplitNormal( ent:GetDirectionAngle():Forward(),  phys:GetVelocity() )

		local targetRPM = ent:VelToRPM( ForwardVel ) * 0.5

		if math.abs( curRPM ) < self.WheelBrakeLockupRPM then
			ent:LockRotation()
		else
			if (ForwardVel > 0 and targetRPM > 0) or (ForwardVel < 0 and targetRPM < 0) then
				ForceAngle = RotationAxis * math.Clamp( (targetRPM - curRPM) / 100,-1,1) * math.deg( self.WheelBrakeForce ) * ent:GetBrakeFactor() * self:GetBrake()
			end
		end

		return ForceAngle, vector_origin, SIM_GLOBAL_ACCELERATION
	end

	if ent:IsRotationLocked() then
		ent:ReleaseRotation()
	end

	return vector_origin, vector_origin, SIM_NOTHING
end

function ENT:OnCoupleChanged( targetVehicle, targetHitch, active )
	if active then
		self:OnCoupled( targetVehicle, targetHitch )

		self:SetInputTarget( targetVehicle )

		if not IsValid( targetHitch ) then return end

		targetHitch:EmitSound("doors/door_metal_medium_open1.wav")
	else
		self:OnDecoupled( targetVehicle, targetHitch )

		self:SetInputTarget( NULL )

		if not IsValid( targetHitch ) then return end

		targetHitch:EmitSound("buttons/lever8.wav")

		local LightsHandler = self:GetLightsHandler()

		if not IsValid( LightsHandler ) then return end

		LightsHandler:SetActive( false )
		LightsHandler:SetHighActive( false )
		LightsHandler:SetFogActive( false )
	end
end

function ENT:OnCoupled( targetVehicle, targetHitch )
end

function ENT:OnDecoupled( targetVehicle, targetHitch )
end

function ENT:OnStartDrag( caller, activator )
end

function ENT:OnStopDrag( caller, activator )
end

function ENT:OnStartExplosion()
end

function ENT:OnFinishExplosion()
	local effectdata = EffectData()
		effectdata:SetOrigin( self:LocalToWorld( self:OBBCenter() ) )
	util.Effect( "lvs_trailer_explosion", effectdata, true, true )

	self:EmitSound("physics/metal/metal_box_break"..math.random(1,2)..".wav",75,100,1)

	self:SpawnGibs()
end

local gibs = {
	"models/gibs/manhack_gib01.mdl",
	"models/gibs/manhack_gib02.mdl",
	"models/gibs/manhack_gib03.mdl",
	"models/gibs/manhack_gib04.mdl",
	"models/props_c17/canisterchunk01a.mdl",
	"models/props_c17/canisterchunk01d.mdl",
	"models/props_c17/oildrumchunk01a.mdl",
	"models/props_c17/oildrumchunk01b.mdl",
	"models/props_c17/oildrumchunk01c.mdl",
	"models/props_c17/oildrumchunk01d.mdl",
	"models/props_c17/oildrumchunk01e.mdl",
}

function ENT:SpawnGibs()
	local pos = self:LocalToWorld( self:OBBCenter() )
	local ang = self:GetAngles()

	self.GibModels = istable( self.GibModels ) and self.GibModels or gibs

	for _, v in pairs( self.GibModels ) do
		local ent = ents.Create( "prop_physics" )

		if not IsValid( ent ) then continue end

		ent:SetPos( pos )
		ent:SetAngles( ang )
		ent:SetModel( v )
		ent:Spawn()
		ent:Activate()
		ent:SetRenderMode( RENDERMODE_TRANSALPHA )
		ent:SetCollisionGroup( COLLISION_GROUP_WORLD )

		local PhysObj = ent:GetPhysicsObject()

		if IsValid( PhysObj ) then
			PhysObj:SetVelocityInstantaneous( Vector( math.Rand(-1,1), math.Rand(-1,1), 1.5 ):GetNormalized() * math.random(250,400)  )
			PhysObj:AddAngleVelocity( VectorRand() * 500 ) 
			PhysObj:EnableDrag( false ) 
		end

		timer.Simple( 4.5, function()
			if not IsValid( ent ) then return end

			ent:SetRenderFX( kRenderFxFadeFast  ) 
		end)

		timer.Simple( 5, function()
			if not IsValid( ent ) then return end

			ent:Remove()
		end)
	end
end

function ENT:OnStartFireTrail( PhysObj, ExplodeTime )
end

function ENT:OnExploded()
	local PhysObj = self:GetPhysicsObject()

	if not IsValid( PhysObj ) then return end

	PhysObj:SetVelocity( self:GetVelocity() + Vector(math.random(-5,5),math.random(-5,5),math.random(150,250)) )
end

function ENT:OnDriverChanged( Old, New, VehicleIsActive )
	self:OnPassengerChanged( Old, New, 1 )

	if VehicleIsActive then

		self:OnDriverEnterVehicle( New )

		return
	end

	self:OnDriverExitVehicle( Old )
end
