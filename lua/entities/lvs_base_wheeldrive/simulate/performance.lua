print("[LVS-Cars] Performance Mode Active")

function ENT:PhysicsSimulate( phys, deltatime )

	if self:GetEngineActive() then phys:Wake() end

	local ent = phys:GetEntity()

	if ent == self then

		if self:IsDestroyed() then self:EnableHandbrake() return vector_origin, vector_origin, SIM_NOTHING end

		local Vel = 0
		for _, wheel in pairs( self:GetWheels() ) do
			self:AlignWheel( wheel )

			if wheel:GetTorqueFactor() <= 0 then continue end

			local wheelVel = wheel:RPMToVel( math.abs( wheel:GetRPM() or 0 ) )

			if wheelVel > Vel then
				Vel = wheelVel
			end
		end
		self:SetWheelVelocity( Vel )

		local throttle = self:GetThrottle()

		local engineTorque = self:GetEngineTorque()
		local engineCurve = self.EngineCurve

		local targetVelocity = self:GetTargetVelocity()

		local boostMul = math.max( self.EngineCurveBoostLow, 0 )
		local boostStart = 1 + boostMul

		local boost
		if self:GetReverse() then
			boost = (targetVelocity / self.TransGearsReverse) * 0.5
		else
			boost = (targetVelocity / self.TransGears) * 0.5
		end

		local targetSpeed = math.abs( targetVelocity )
		local curSpeed = math.abs( Vel )

		local power = targetSpeed * engineCurve
		local powerCurve = (power + math.max( targetSpeed - power,0) - math.max(curSpeed - power,0)) / targetSpeed
		local torqueBoost = boostStart - (math.min( math.max( curSpeed - boost, 0 ), boost) / boost) * boostMul
		local torqueDirection = math.Clamp(targetVelocity - Vel,-1,1)

		self.wheelEngineForce = torqueDirection * powerCurve * torqueBoost * engineTorque * throttle

		if not self:StabilityAssist() or not self:WheelsOnGround() then return self:PhysicsSimulateOverride( Vector(0,0,0), phys, deltatime, SIM_NOTHING ) end

		local ForceAngle = Vector(0,0, math.deg( -phys:GetAngleVelocity().z ) * math.min( phys:GetVelocity():Length() / self.PhysicsDampingSpeed, 1 ) * self.ForceAngleMultiplier )

		return self:PhysicsSimulateOverride( ForceAngle, phys, deltatime, SIM_GLOBAL_ACCELERATION )
	end

	return self:SimulateRotatingWheel( ent, phys, deltatime )
end

local deltatimeMin = 1 / 30
local deltatimeNew = 1 / 15

function ENT:SimulateRotatingWheel( ent, phys, deltatime )
	local T = CurTime()
	local tickdelta = engine.TickInterval()

	local EntTable = self:GetTable()
	local WheelTable = ent:GetTable()

	if not self:GetEngineActive() then
		if (WheelTable._lvsNextThink or 0) > T then
			return vector_origin, vector_origin, SIM_NOTHING
		else
			WheelTable._lvsNextThink = T + 0.05
		end
	end

	if (WheelTable._lvsNextSimulate or 0) > T then return vector_origin, vector_origin, SIM_NOTHING end

	if ent:IsHandbrakeActive() then
		if WheelTable.SetRPM then
			ent:SetRPM( 0 )
		end

		return vector_origin, vector_origin, SIM_NOTHING
	end

	local RotationAxis = ent:GetRotationAxis()

	local curRPM = self:VectorSplitNormal( RotationAxis,  phys:GetAngleVelocity() ) / 6

	local forceMul = 1

	local Throttle = self:GetThrottle()

	if tickdelta < deltatimeMin and not (Throttle > 0 and math.abs( curRPM ) < 50) then
		WheelTable._lvsNextSimulate = T + deltatimeNew - tickdelta * 0.5

		local Tick1 = 1 / deltatime
		local Tick2 = 1 / deltatimeNew

		forceMul = Tick1 / Tick2
	else
		WheelTable._lvsNextSimulate = T - 1
	end

	ent:SetRPM( curRPM )

	local ForceAngle = Vector(0,0,0)

	local TorqueFactor = ent:GetTorqueFactor()

	local IsBraking = self:GetBrake() > 0
	local IsBrakingWheel = (TorqueFactor * Throttle) <= 0.99

	if IsBraking and IsBrakingWheel then
		if not ent:IsRotationLocked() then
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
			if self:PivotSteer() then
				local RotationDirection = ent:GetWheelType() * self:GetPivotSteer()

				if EntTable.PivotSteerByBrake and RotationDirection < 0 then
					ent:LockRotation( true )

					return vector_origin, vector_origin, SIM_NOTHING
				end

				local engineTorque = self:GetEngineTorque()
				local powerCurve = math.Clamp((EntTable.PivotSteerWheelRPM * RotationDirection - curRPM) / EntTable.PivotSteerWheelRPM,-1,1)

				local Torque = powerCurve * engineTorque * TorqueFactor * Throttle * 2 * EntTable.PivotSteerTorqueMul

				ForceAngle:Add( RotationAxis * Torque )
			else
				ForceAngle:Add( RotationAxis * (EntTable.wheelEngineForce or 0) * TorqueFactor )
			end
		end
	end

	if not self:StabilityAssist() or not self:WheelsOnGround() then return ForceAngle * forceMul, vector_origin, SIM_GLOBAL_ACCELERATION end

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
					return ForceAngle * forceMul, vector_origin, SIM_GLOBAL_ACCELERATION
				end
			else
				return ForceAngle * forceMul, vector_origin, SIM_GLOBAL_ACCELERATION
			end
		end
	end

	if IsBraking and not IsBrakingWheel then
		return ForceAngle * forceMul, vector_origin, SIM_GLOBAL_ACCELERATION
	end

	local ForceLinear = -self:GetUp() * EntTable.WheelDownForce * TorqueFactor

	if not self:GetRacingTires() then
		ForceLinear = ForceLinear - Right * math.Clamp(Fy * 5 * math.min( math.abs( Fx ) / 500, 1 ),-EntTable.WheelSideForce,EntTable.WheelSideForce) * EntTable.ForceLinearMultiplier
	end

	return ForceAngle * forceMul, ForceLinear * forceMul, SIM_GLOBAL_ACCELERATION
end
