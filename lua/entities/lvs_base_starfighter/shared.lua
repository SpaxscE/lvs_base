
ENT.Base = "lvs_base"

ENT.PrintName = "[LVS] Base Starfighter"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

ENT.MaxVelocity = 3000
ENT.MaxThrust = 3000

ENT.ThrustVtol = 55
ENT.ThrustRateVtol = 3

ENT.ThrottleRateUp = 0.6
ENT.ThrottleRateDown = 0.6

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 1

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.DisableBallistics = true

function ENT:SetupDataTables()
	self:AddDT( "Vector", "Steer" )
	self:AddDT( "Vector", "AIAimVector" )
	self:AddDT( "Vector", "NWVtolMove" )
	self:AddDT( "Float", "NWThrottle" )
	self:AddDT( "Float", "MaxThrottle" )
	self:AddDT( "Angle", "SteerAngle" )

	if SERVER then
		self:SetMaxThrottle( 1 )
	end

	self:CreateBaseDT()
end

function ENT:CalcPlayerInput( ply, cmd )
	local Pod = self:GetDriverSeat()

	local Delta = FrameTime()

	local KeyLeft = ply:lvsKeyDown( "-ROLL_SF" )
	local KeyRight = ply:lvsKeyDown( "+ROLL_SF" )
	local KeyPitchUp = ply:lvsKeyDown( "+PITCH_SF" )
	local KeyPitchDown = ply:lvsKeyDown( "-PITCH_SF" )
	local KeyRollRight = ply:lvsKeyDown( "+YAW_SF" )
	local KeyRollLeft = ply:lvsKeyDown( "-YAW_SF" )

	local FreeLook = ply:lvsKeyDown( "FREELOOK" )
	local ThirdPerson = Pod:GetThirdPersonMode()

	if not (ThirdPerson or (not ThirdPerson and not FreeLook)) then return end

	local PitchOverride = (KeyPitchDown and 10 or 0) - (KeyPitchUp and 10 or 0)
	local YawOverride = (KeyRollRight and 10 or 0) - (KeyRollLeft and 10 or 0)
	local RollOverride = (KeyRight and 2 or 0) - (KeyLeft and 2 or 0)

	local TargetAngle = cmd:GetViewAngles() - Angle(0,90,0)

	local NewAngles = self:GetSteerAngle()
	NewAngles:Normalize()

	local LAngles = self:WorldToLocalAngles( NewAngles ) + Angle(TargetAngle.p,TargetAngle.y,0)
	LAngles.p = math.Clamp( LAngles.p + PitchOverride, -25, 25 )
	LAngles.y = math.Clamp( LAngles.y + YawOverride, -25, 25 )

	local AutoRoll = self:GetAngles().r * 0.01
	if math.abs( LAngles.y ) > 1 or math.abs( LAngles.p ) > 1 then
		AutoRoll = (math.abs( LAngles.y ) / 5) ^ 2 * self:Sign( LAngles.y )
	end
	if RollOverride ~= 0 then
		AutoRoll = 0
	end

	LAngles.r = math.Clamp( LAngles.r - AutoRoll + RollOverride, -25, 25 )

	if CLIENT then return end

	self:SetSteerAngle( self:LocalToWorldAngles( LAngles ) )
	ply:SetEyeAngles( Angle(0,90,0) )
end

function ENT:CalcThrottle( ply, cmd )
	if CLIENT then return end

	local Delta = FrameTime()

	local ThrottleUp =  ply:lvsKeyDown( "+THRUST_SF" ) and self.ThrottleRateUp or 0
	local ThrottleDown = ply:lvsKeyDown( "-THRUST_SF" ) and -self.ThrottleRateDown or 0

	local Throttle = (ThrottleUp + ThrottleDown) * Delta

	self:SetThrottle( self:GetThrottle() + Throttle )
end

function ENT:CalcVtolThrottle( ply, cmd )
	local Delta = FrameTime()

	local ThrottleZero = self:GetThrottle() <= 0

	local VtolX = ThrottleZero and (ply:lvsKeyDown( "-VTOL_X_SF" ) and -1 or 0) or 0
	local VtolY = ((ply:lvsKeyDown( "+VTOL_Y_SF" ) and 1 or 0) - (ply:lvsKeyDown( "-VTOL_Y_SF" ) and 1 or 0))
	local VtolZ = ((ply:lvsKeyDown( "+VTOL_Z_SF" ) and 1 or 0) - (ply:lvsKeyDown( "-VTOL_Z_SF" ) and 1 or 0))

	local DesiredVtol = Vector(VtolX,VtolY,VtolZ)
	local NewVtolMove = self:GetNWVtolMove() + (DesiredVtol - self:GetNWVtolMove()) * self.ThrustRateVtol * Delta

	if not ThrottleZero or self:WorldToLocal( self:GetPos() + self:GetVelocity() ).x > 100 then
		NewVtolMove.x = 0
	end

	self:SetVtolMove( NewVtolMove )
end

function ENT:SetVtolMove( NewMove )
	if self:GetEngineActive() then
		self:SetNWVtolMove( NewMove )
	else
		self:SetNWVtolMove( Vector(0,0,0) )
	end
end

function ENT:SetThrottle( NewThrottle )
	if self:GetEngineActive() then
		self:SetNWThrottle( math.Clamp(NewThrottle,0,self:GetMaxThrottle()) )
	else
		self:SetNWThrottle( 0 )
	end
end

function ENT:GetThrottle()
	if self:GetEngineActive() then
		return self:GetNWThrottle()
	else
		return 0
	end
end

function ENT:GetVtolMove()
	if self:GetEngineActive() and not self:GetAI() then
		return self:GetNWVtolMove() * self.ThrustVtol * (1 - math.min( self:GetThrottle(), 1 ))
	else
		return Vector(0,0,0)
	end
end

function ENT:StartCommand( ply, cmd )
	if self:GetDriver() ~= ply then return end

	if SERVER then
		local KeyJump = ply:lvsKeyDown( "VSPEC" )

		if self._lvsOldKeyJump ~= KeyJump then
			self._lvsOldKeyJump = KeyJump

			if KeyJump then
				self:ToggleVehicleSpecific()
			end
		end
	end

	self:CalcPlayerInput( ply, cmd )
	self:CalcThrottle( ply, cmd )
	self:CalcVtolThrottle( ply, cmd )
end

function ENT:GetThrustStrenght()
	local ForwardVelocity = self:WorldToLocal( self:GetPos() + self:GetVelocity() ).x

	return (self.MaxVelocity * self:GetThrottle() - ForwardVelocity) / self.MaxVelocity
end

function ENT:GetVehicleType()
	return "starfighter"
end
