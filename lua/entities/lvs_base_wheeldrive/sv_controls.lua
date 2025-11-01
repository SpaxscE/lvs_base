
function ENT:CalcMouseSteer( ply )
	self:ApproachTargetAngle( ply:EyeAngles() )
end

function ENT:CalcSteer( ply )
	local KeyLeft = ply:lvsKeyDown( "CAR_STEER_LEFT" )
	local KeyRight = ply:lvsKeyDown( "CAR_STEER_RIGHT" )

	local MaxSteer = self:GetMaxSteerAngle()

	local Vel = self:GetVelocity()

	local TargetValue = (KeyRight and 1 or 0) - (KeyLeft and 1 or 0)

	local EntTable = self:GetTable()

	if Vel:Length() > EntTable.FastSteerActiveVelocity then
		local Forward = self:GetForward()
		local Right = self:GetRight()

		local Axle = self:GetAxleData( 1 )

		if Axle then
			local Ang = self:LocalToWorldAngles( self:GetAxleData( 1 ).ForwardAngle )

			Forward = Ang:Forward()
			Right = Ang:Right()
		end

		local VelNormal = Vel:GetNormalized()

		local DriftAngle = self:AngleBetweenNormal( Forward, VelNormal )

		if self:GetRacingTires() or self:GetBrake() >= 1 then
			if math.abs( self:GetSteer() ) < EntTable.FastSteerAngleClamp then
				MaxSteer = math.min( MaxSteer, EntTable.FastSteerAngleClamp )
			end
		else
			if DriftAngle < EntTable.FastSteerDeactivationDriftAngle then
				MaxSteer = math.min( MaxSteer, EntTable.FastSteerAngleClamp )
			end
		end

		if not KeyLeft and not KeyRight then
			local Cur = self:GetSteer() / MaxSteer

			local MaxHelpAng = math.min( MaxSteer, EntTable.SteerAssistMaxAngle )

			local Ang = self:AngleBetweenNormal( Right, VelNormal ) - 90
			local HelpAng = ((math.abs( Ang ) / 90) ^ EntTable.SteerAssistExponent) * 90 * self:Sign( Ang )

			TargetValue = math.Clamp( -HelpAng * EntTable.SteerAssistMultiplier,-MaxHelpAng,MaxHelpAng) / MaxSteer
		end
	end

	self:SteerTo( TargetValue, MaxSteer )
end

function ENT:IsLegalInput()
	local EntTable = self:GetTable()

	if not EntTable.ForwardAngle then return true end

	local MinSpeed = math.min(EntTable.MaxVelocity,EntTable.MaxVelocityReverse)

	local ForwardVel = self:Sign( math.Round( self:VectorSplitNormal( self:LocalToWorldAngles( EntTable.ForwardAngle ):Forward(), self:GetVelocity() ) / MinSpeed, 0 ) )
	local DesiredVel = self:GetReverse() and -1 or 1

	return ForwardVel == DesiredVel * math.abs( ForwardVel )
end

function ENT:LerpThrottle( Throttle )
	if not self:GetEngineActive() then self:SetThrottle( 0 ) return end

	local Rate = FrameTime() * self.ThrottleRate
	local Cur = self:GetThrottle()
	local New = Cur + math.Clamp(Throttle - Cur,-Rate,Rate)

	self:SetThrottle( New )
end

function ENT:LerpBrake( Brake )
	local Rate = FrameTime() * 3.5
	local Cur = self:GetBrake()
	local New = Cur + math.Clamp(Brake - Cur,-Rate,Rate)

	self:SetBrake( New )
end

function ENT:CalcThrottle( ply )
	local KeyThrottle = ply:lvsKeyDown( "CAR_THROTTLE" )
	local KeyBrakes = ply:lvsKeyDown( "CAR_BRAKE" )

	if self:GetReverse() and not self:IsManualTransmission() then
		KeyThrottle = ply:lvsKeyDown( "CAR_BRAKE" )
		KeyBrakes = ply:lvsKeyDown( "CAR_THROTTLE" )
	end

	local ThrottleValue = ply:lvsKeyDown( "CAR_THROTTLE_MOD" ) and self:GetMaxThrottle() or 0.5
	local Throttle = KeyThrottle and ThrottleValue or 0

	if not self:IsLegalInput() then
		self:LerpThrottle( 0 )
		self:LerpBrake( (KeyThrottle or KeyBrakes) and 1 or 0 )

		return
	end

	self:LerpThrottle( Throttle )
	self:LerpBrake( KeyBrakes and 1 or 0 )
end

function ENT:CalcHandbrake( ply )
	if ply:lvsKeyDown( "CAR_HANDBRAKE" ) then
		self:EnableHandbrake()
	else
		self:ReleaseHandbrake()
	end
end

function ENT:CalcTransmission( ply, T )
	local EntTable = self:GetTable()

	if not EntTable.ForwardAngle or self:IsManualTransmission() then
		local ShiftUp = ply:lvsKeyDown( "CAR_SHIFT_UP" )
		local ShiftDn = ply:lvsKeyDown( "CAR_SHIFT_DN" )

		self:CalcManualTransmission( ply, EntTable, ShiftUp, ShiftDn )

		local Reverse = self:GetReverse()

		if Reverse ~= EntTable._oldKeyReverse then
			EntTable._oldKeyReverse = Reverse

			self:EmitSound( EntTable.TransShiftSound, 75 )
		end

		return
	end

	local ForwardVelocity = self:VectorSplitNormal( self:LocalToWorldAngles( EntTable.ForwardAngle ):Forward(), self:GetVelocity() )

	local KeyForward = ply:lvsKeyDown( "CAR_THROTTLE" )
	local KeyBackward = ply:lvsKeyDown( "CAR_BRAKE" )

	local ReverseVelocity = EntTable.AutoReverseVelocity

	if KeyForward and KeyBackward then return end

	if not KeyForward and not KeyBackward then
		if ForwardVelocity > ReverseVelocity then
			self:SetReverse( false )
		end

		if ForwardVelocity < -ReverseVelocity then
			self:SetReverse( true )
		end

		return
	end

	if KeyForward and ForwardVelocity > -ReverseVelocity then
		self:SetReverse( false )
	end

	if KeyBackward and ForwardVelocity < ReverseVelocity then

		if not EntTable._toggleReverse then
			EntTable._toggleReverse = true

			EntTable._KeyBackTime = T + 0.4
		end

		if (EntTable._KeyBackTime or 0) < T then
			self:SetReverse( true )
		end
	else
		EntTable._toggleReverse = nil
	end

	local Reverse = self:GetReverse()

	if Reverse ~= EntTable._oldKeyReverse then
		EntTable._oldKeyReverse = Reverse

		self:EmitSound( EntTable.TransShiftSound, 75 )
	end
end

function ENT:CalcLights( ply, T )
	local LightsHandler = self:GetLightsHandler()

	if not IsValid( LightsHandler ) then return end

	local lights = ply:lvsKeyDown( "CAR_LIGHTS_TOGGLE" )

	local EntTable = self:GetTable()

	if EntTable._lights ~= lights then
		EntTable._lights = lights

		if lights then
			EntTable._LightsUnpressTime = T
		else
			EntTable._LightsUnpressTime = nil
		end
	end

	if EntTable._lights and (T - EntTable._LightsUnpressTime) > 0.4 then
		lights = false
	end

	if lights ~= EntTable._oldlights then
		if not isbool( EntTable._oldlights ) then EntTable._oldlights = lights return end

		if lights then
			EntTable._LightsPressedTime = T
		else
			if LightsHandler:GetActive() then
				if self:HasHighBeams() then
					if (T - (EntTable._LightsPressedTime or 0)) >= 0.4 then
						LightsHandler:SetActive( false )
						LightsHandler:SetHighActive( false )
						LightsHandler:SetFogActive( false )

						self:EmitSound( "items/flashlight1.wav", 75, 100, 0.25 )
					else
						LightsHandler:SetHighActive( not LightsHandler:GetHighActive() )

						self:EmitSound( "buttons/lightswitch2.wav", 75, 80, 0.25)
					end
				else
					LightsHandler:SetActive( false )
					LightsHandler:SetHighActive( false )
					LightsHandler:SetFogActive( false )

					self:EmitSound( "items/flashlight1.wav", 75, 100, 0.25 )
				end
			else
				self:EmitSound( "items/flashlight1.wav", 75, 100, 0.25 )

				if self:HasFogLights() and (T - (EntTable._LightsPressedTime or T)) >= 0.4 then
					LightsHandler:SetFogActive( not LightsHandler:GetFogActive() )
				else
					LightsHandler:SetActive( true )
				end
			end
		end

		EntTable._oldlights = lights
	end
end

function ENT:StartCommand( ply, cmd )
	if self:GetDriver() ~= ply then return end

	local EntTable = self:GetTable()

	self:SetRoadkillAttacker( ply )

	if ply:lvsKeyDown( "CAR_MENU" ) then
		self:LerpBrake( 0 )
		self:LerpThrottle( 0 )

		return
	end

	self:UpdateHydraulics( ply, cmd )

	if ply:lvsMouseAim() then
		if ply:lvsKeyDown( "FREELOOK" ) or ply:lvsKeyDown( "CAR_STEER_LEFT" ) or ply:lvsKeyDown( "CAR_STEER_RIGHT" ) then
			self:CalcSteer( ply )
		else
			self:CalcMouseSteer( ply )
		end
	else
		self:CalcSteer( ply )
	end

	if EntTable.PivotSteerEnable then
		self:CalcPivotSteer( ply )

		if self:PivotSteer() then
			self:LerpBrake( 0 )
		else
			self:CalcThrottle( ply )
		end
	else
		self:CalcThrottle( ply )
	end

	local T = CurTime()

	if (EntTable._nextCalcCMD or 0) > T then return end

	EntTable._nextCalcCMD = T + FrameTime() - 1e-4

	self:CalcHandbrake( ply )
	self:CalcTransmission( ply, T )
	self:CalcLights( ply, T )
	self:CalcSiren( ply, T )
end

function ENT:CalcSiren( ply, T )
	local mode = self:GetSirenMode()
	local horn = ply:lvsKeyDown( "ATTACK" )

	local EntTable = self:GetTable()

	if EntTable.HornSound and IsValid( EntTable.HornSND ) then
		if horn and mode <= 0 then
			EntTable.HornSND:Play()
		else
			EntTable.HornSND:Stop()
		end
	end

	if istable( EntTable.SirenSound ) and IsValid( EntTable.SirenSND ) then
		local siren = ply:lvsKeyDown( "CAR_SIREN" )

		if EntTable._siren ~= siren then
			EntTable._siren = siren

			if siren then
				EntTable._sirenUnpressTime = T
			else
				EntTable._sirenUnpressTime = nil
			end
		end

		if EntTable._siren and (T - EntTable._sirenUnpressTime) > 0.4 then
			siren = false
		end

		if siren ~= EntTable._oldsiren then
			if not isbool( EntTable._oldsiren ) then EntTable._oldsiren = siren return end

			if siren then
				EntTable._SirenPressedTime = T
			else
				if (T - (EntTable._SirenPressedTime or 0)) >= 0.4 then
					if mode >= 0 then
						self:SetSirenMode( -1 )
						self:StopSiren()
					else
						self:SetSirenMode( 0 )
					end
				else
					self:StartSiren( horn, true )
				end
			end

			EntTable._oldsiren = siren
		else
			if horn ~= EntTable._OldKeyHorn then
				EntTable._OldKeyHorn = horn

				if horn then
					self:StartSiren( true, false )
				else
					self:StartSiren( false, false )
				end
			end
		end
	end
end

function ENT:SetSirenSound( sound )
	if sound then 
		if self._PreventSiren then return end

		self._PreventSiren = true

		self.SirenSND:Stop()
		self.SirenSND:SetSound( sound )
		self.SirenSND:SetSoundInterior( sound )

		timer.Simple( 0.1, function()
			if not IsValid( self.SirenSND ) then return end

			self.SirenSND:Play()

			self._PreventSiren = false
		end )
	else
		self:StopSiren()
	end
end

function ENT:StartSiren( horn, incr )
	local EntTable = self:GetTable()

	local Mode = self:GetSirenMode()
	local Max = #EntTable.SirenSound

	local Next = Mode

	if incr then
		Next = Next + 1

		if Mode <= -1 or Next > Max then
			Next = 1
		end

		self:SetSirenMode( Next )
	end

	if not EntTable.SirenSound[ Next ] then return end

	if horn then
		if not EntTable.SirenSound[ Next ].horn then

			self:SetSirenMode( 0 )

			return
		end

		self:SetSirenSound( EntTable.SirenSound[ Next ].horn )
	else
		if not EntTable.SirenSound[ Next ].siren then

			self:SetSirenMode( 0 )

			return
		end

		self:SetSirenSound( EntTable.SirenSound[ Next ].siren )
	end
end

function ENT:StopSiren()
	if not IsValid( self.SirenSND ) then return end

	self.SirenSND:Stop()
end

function ENT:SetRoadkillAttacker( ply )
	local T = CurTime()

	if (self._nextSetAttacker or 0) > T then return end

	self._nextSetAttacker = T + 1

	self:SetPhysicsAttacker( ply, 1.1 )
end
