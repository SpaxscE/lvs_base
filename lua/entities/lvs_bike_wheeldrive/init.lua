AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

-- code relies on this forward angle...
ENT.ForcedForwardAngle = Angle(0,0,0)

ENT.TippingForceMul = 1

ENT.LeanAngleIdle = -10
ENT.LeanAnglePark = -10

function ENT:PhysicsSimulateOverride( ForceAngle, phys, deltatime, simulate )
	local EntTable = self:GetTable()

	if EntTable._IsDismounted then

		local Pod = self:GetDriverSeat()

		if IsValid( Pod ) then
			local z = math.max( self:GetUp().z, 0 )

			local Gravity = self:GetWorldUp() * self:GetWorldGravity() * phys:GetMass() * deltatime
			phys:ApplyForceCenter( Gravity * 1.5 * EntTable.TippingForceMul * z )
			phys:ApplyForceOffset( -Gravity * 3 * EntTable.TippingForceMul, Pod:GetPos() )
		end

		return vector_origin, vector_origin, SIM_NOTHING
	end

	local Steer = self:GetSteer()

	local VelL = self:WorldToLocal( self:GetPos() + phys:GetVelocity() )

	local ShouldIdle = self:ShouldPutFootDown()

	if ShouldIdle then
		Steer = self:GetEngineActive() and EntTable.LeanAngleIdle or EntTable.LeanAnglePark
		VelL.x = EntTable.MaxVelocity
	else
		local SpeedMul = math.Clamp( 1 - VelL.x / EntTable.MaxVelocity, 0, 1 ) ^ 2

		ForceAngle.y = (math.Clamp( VelL.x * self:GetBrake() * EntTable.PhysicsRollMul, -EntTable.WheelBrakeForce, EntTable.WheelBrakeForce ) - self:GetThrottle() * self:GetEngineTorque() * 0.1 * SpeedMul) * EntTable.PhysicsPitchInvertForceMul
	end

	local Mul = (self:GetUp().z > 0.5 and 1 or 0) * 50 * (math.min( math.abs( VelL.x ) / EntTable.PhysicsWheelGyroSpeed, 1 ) ^ 2) * EntTable.PhysicsWheelGyroMul
	local Diff = (Steer - self:GetAngles().r)

	local ForceLinear = Vector(0,0,0)
	ForceAngle.x = (Diff * 2.5 * EntTable.PhysicsRollMul - phys:GetAngleVelocity().x * EntTable.PhysicsDampingRollMul) * Mul

	if ShouldIdle and math.abs( Diff ) > 1 then
		simulate = SIM_GLOBAL_ACCELERATION
	end

	if self:GetRacingTires() and self:WheelsOnGround() then
		local WheelSideForce = EntTable.WheelSideForce * EntTable.ForceLinearMultiplier
		for id, wheel in pairs( self:GetWheels() ) do
			if wheel:IsHandbrakeActive() then continue end

			local AxleAng = wheel:GetDirectionAngle()
		
			local Forward = AxleAng:Forward()
			local Right = AxleAng:Right()
			local Up = AxleAng:Up()

			local wheelPos = wheel:GetPos()
			local wheelVel = phys:GetVelocityAtPoint( wheelPos )
			local wheelRadius = wheel:GetRadius()

			local ForwardVel = self:VectorSplitNormal( Forward, wheelVel )

			Force = -Right * self:VectorSplitNormal( Right, wheelVel ) * WheelSideForce
			local wSideForce, wAngSideForce = phys:CalculateVelocityOffset( Force, wheelPos )

			ForceAngle:Add( wAngSideForce )
			ForceLinear:Add( wSideForce )
		end
	end

	return ForceAngle, vector_origin, simulate
end

function ENT:CalcDismount( data, physobj )
	if self._IsDismounted then return end

	self._IsDismounted = true

	self:PhysicsCollide( data, physobj )

	if self:GetEngineActive() then
		self:StopEngine()
	end

	local LocalSpeed = self:WorldToLocal( self:GetPos() + data.OurOldVelocity )

	for _, ply in pairs( self:GetEveryone() ) do
		if ply:GetNoDraw() then continue end

		local EnablePartDrawing = false

		if pac then
			local Pod = ply:GetVehicle()

			if IsValid( Pod ) and not Pod.HidePlayer then
				EnablePartDrawing = true
				pac.TogglePartDrawing( ply, 0 )
			end
		end

		ply:SetNoDraw( true )
		ply:SetAbsVelocity( LocalSpeed )
		ply:CreateRagdoll()
		ply:SetNWBool( "lvs_camera_follow_ragdoll", true )
		ply:lvsSetInputDisabled( true )

		timer.Simple( math.Rand(3.5,4.5), function()
			if not IsValid( ply ) then return end

			if EnablePartDrawing then
				pac.TogglePartDrawing( ply, 1 )
			end
	
			ply:SetNoDraw( false )
			ply:SetNWBool( "lvs_camera_follow_ragdoll", false)
			ply:lvsSetInputDisabled( false )

			local ragdoll = ply:GetRagdollEntity()

			if not IsValid( ragdoll ) then return end

			ragdoll:Remove()
		end)
	end

	timer.Simple(3, function()
		if not IsValid( self ) then return end

		self._IsDismounted = nil
	end)
end

function ENT:OnWheelCollision( data, physobj )
	local Speed = math.abs(data.OurOldVelocity:Length() - data.OurNewVelocity:Length())

	if Speed < 200 then return end

	local ent = physobj:GetEntity()

	local pos, ang = WorldToLocal( data.HitPos, angle_zero, ent:GetPos(), ent:GetDirectionAngle() )
	local radius = ent:GetRadius() - 2

	if Speed > 300 then
		if math.abs( pos.y ) > radius and self:GetUp().z < 0.5 then
			self:CalcDismount( data, physobj )
		end
	end

	if math.abs( pos.x ) < radius or pos.z < -1 then return end

	self:CalcDismount( data, physobj )
end

util.AddNetworkString( "lvs_kickstart_network" )

function ENT:ToggleEngine()
	if self:GetEngineActive() then
		self:StopEngine()

		self._KickStartAttemt = 0
	else
		if self.KickStarter and not self:GetAI() then
			local T = CurTime()

			if (self._KickStartTime or 0) > T then return end

			self:EmitSound( self.KickStarterSound, 70, 100, 0.5 )

			if not self._KickStartAttemt or ((T - (self.KickStarterStart or 0)) > (self.KickStarterAttemptsInSeconds or 0)) then
				self._KickStartAttemt = 0
				self.KickStarterStart = T
			end

			net.Start( "lvs_kickstart_network" )
				net.WriteEntity( self:GetDriver() )
			net.Broadcast()

			self._KickStartAttemt = self._KickStartAttemt + 1
			self._KickStartTime = T + self.KickStarterMinDelay

			if self._KickStartAttemt >= math.random( self.KickStarterMinAttempts, self.KickStarterMaxAttempts ) then
				self._KickStartAttemt = nil

				self:StartEngine()
			end
		else
			self:StartEngine()
		end
	end
end
