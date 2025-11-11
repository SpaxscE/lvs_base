AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")
include("sv_controls.lua")
include("sv_components.lua")

function ENT:EnableManualTransmission()
	return false
end

function ENT:DisableManualTransmission()
	return false
end

function ENT:SpawnFunction( ply, tr, ClassName )

	local startpos = ply:GetShootPos()
	local endpos = startpos + ply:GetAimVector() * 10000

	local waterTrace = util.TraceLine( {
		start = startpos,
		endpos = endpos,
		mask = MASK_WATER,
		filter = ply
	} )

	if waterTrace.Hit and ((waterTrace.HitPos - startpos):Length() < (tr.HitPos - startpos):Length()) then
		tr = waterTrace
	end

	if not tr.Hit then return end

	local ent = ents.Create( ClassName )
	ent:StoreCPPI( ply )
	ent:SetPos( tr.HitPos + tr.HitNormal * ent.SpawnNormalOffset )
	ent:SetAngles( Angle(0, ply:EyeAngles().y, 0 ) )
	ent:Spawn()
	ent:Activate()

	return ent
end

function ENT:RunAI()
end

function ENT:GetEnginePos()
	local Engine = self:GetEngine()

	if IsValid( Engine ) then return Engine:GetPos() end

	return self:LocalToWorld( self:OBBCenter() )
end

local up = Vector(0,0,1)
local down = Vector(0,0,-1)
function ENT:PhysicsSimulate( phys, deltatime )

	if self:GetEngineActive() then phys:Wake() end

	local EntTable = self:GetTable()

	local pos = self:GetEnginePos()

	local traceSky = util.TraceLine( {
		start = pos,
		endpos = pos + up * 50000,
		filter = self:GetCrosshairFilterEnts()
	} )

	local traceData = {
		start = traceSky.HitPos,
		endpos = pos + down * 50000,
		filter = self:GetCrosshairFilterEnts()
	}

	pos = phys:LocalToWorld( phys:GetMassCenter() )

	local traceSoil = util.TraceLine( traceData )
	traceData.mask = MASK_WATER
	local traceWater = util.TraceLine( traceData )

	local EngineInWater = traceWater.Hit
	local Engine = self:GetEngine()
	if IsValid( Engine ) then
		traceData.start = Engine:GetPos()
		traceData.endpos = Engine:LocalToWorld( Vector(0,0,-EntTable.EngineSplashDistance) )

		EngineInWater = util.TraceLine( traceData ).Hit
	end

	if not EngineInWater then return vector_origin, vector_origin, SIM_NOTHING end

	local BuoyancyForce = math.min( math.max( traceWater.HitPos.z - pos.z + EntTable.FloatHeight, 0 ), 10 )

	local Grav = physenv.GetGravity()
	local Vel = phys:GetVelocity()
	local AngVel = phys:GetAngleVelocity()

	local mul = BuoyancyForce / 10
	local invmul = math.Clamp( 1 - mul, 0, 1 )

	local Force = (-Grav + Vector(0,0,-Vel.z * invmul * EntTable.FloatForce)) * mul
	local ForcePos = pos + self:GetUp() * BuoyancyForce

	local ForceLinear, ForceAngle = phys:CalculateForceOffset( Force, ForcePos )

	ForceAngle = (ForceAngle - AngVel * invmul * 2) * 15 * EntTable.ForceAngleMultiplier

	local VelL = self:WorldToLocal( self:GetPos() + Vel )

	local Thrust = self:GetThrust()
	local ThrustStrength = math.abs( self:GetThrustStrenght() )

	local SteerInput = self:GetSteer()
	local Steer = SteerInput * math.Clamp( ThrustStrength + math.min(math.abs( VelL.x ) / math.min( EntTable.MaxVelocity, EntTable.MaxVelocityReverse ), 1 ), 0, 1 )

	local Brake = self:GetBrake()

	if Brake > 0 then
		Steer = Steer * -Brake
	end

	local Pitch = -(math.max( math.cos( CurTime() * EntTable.FloatWaveFrequency + self:EntIndex() * 1337 ), 0 ) * VelL.x * 0.25 * EntTable.FloatWaveIntensity + Thrust * 0.25 * math.Clamp( VelL.x / EntTable.MaxVelocity,0,1) * EntTable.FloatThrottleIntensity)
	local Yaw = Steer * EntTable.TurnForceYaw
	local Roll = - AngVel.x * 5 - Steer * EntTable.TurnForceRoll

	if math.abs( SteerInput ) < 1 and BuoyancyForce > 0 and not self:IsPlayerHolding() then
		Yaw = Yaw - AngVel.z * math.max( ((1 - math.abs( SteerInput )) ^ 2) * 100 - 100 * ThrustStrength, 1 )
	end

	ForceLinear:Add( self:GetForward() * Thrust + self:GetRight() * VelL.y )
	ForceAngle:Add( Vector(Roll,Pitch,Yaw) )

	local FloatExp = math.max( self:GetUp().z, 0 ) ^ EntTable.FloatExponent

	ForceLinear:Mul( FloatExp )
	ForceAngle:Mul( FloatExp )

	return self:PhysicsSimulateOverride( ForceAngle, ForceLinear, phys, deltatime, SIM_GLOBAL_ACCELERATION )
end

function ENT:PhysicsSimulateOverride( ForceAngle, ForceLinear, phys, deltatime, simulate )
	return ForceAngle, ForceLinear, simulate
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

	self:SetSteer( Steer )
end
