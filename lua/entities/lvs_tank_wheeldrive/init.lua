AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")
include("sv_tracksystem.lua")

AddCSLuaFile( "modules/cl_tankview.lua" )
AddCSLuaFile( "modules/cl_attachable_playermodels.lua" )
AddCSLuaFile( "modules/sh_turret.lua" )
AddCSLuaFile( "modules/sh_turret_ballistics.lua" )
AddCSLuaFile( "modules/sh_turret_splitsound.lua" )

ENT.DSArmorDamageReductionType = DMG_CLUB
ENT.DSArmorIgnoreDamageType = DMG_BULLET + DMG_SONIC + DMG_ENERGYBEAM

function ENT:PhysicsSimulateNew( phys, deltatime )

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
		WheelTable._NextSimulate = T + ((self:PivotSteer() or self:GetBrake() > 0) and EntTable.WheelTickIntervalBraking or EntTable.WheelTickInterval)

		WheelTable.Force, WheelTable.ForceAng, WheelTable.Simulate = self:SimulateRotatingWheel( ent, EntTable, WheelTable, phys, deltatime )
	end

	return WheelTable.Force, WheelTable.ForceAng, WheelTable.Simulate
end

function ENT:SimulateRotatingWheelNew( ent, EntTable, WheelTable, phys, deltatime )
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

			if targetVelocity >= 0 then
				if curVelocity < targetVelocity then
					ForceAngle = RotationAxis * Torque * TorqueBoost
				end
			else
				if curVelocity > targetVelocity then
					ForceAngle = RotationAxis * Torque * TorqueBoost
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

	if IsBraking and not IsBrakingWheel then
		return ForceAngle, ForceLinear, SIM_GLOBAL_ACCELERATION
	end

	ForceLinear:Add( -self:GetUp() * EntTable.WheelDownForce * TorqueFactor )

	if not self:GetRacingTires() then
		ForceLinear:Add( -Right * math.Clamp(Fy * 5 * math.min( math.abs( Fx ) / 500, 1 ),-EntTable.WheelSideForce,EntTable.WheelSideForce) * EntTable.ForceLinearMultiplier )
	end

	return ForceAngle, ForceLinear, SIM_GLOBAL_ACCELERATION
end