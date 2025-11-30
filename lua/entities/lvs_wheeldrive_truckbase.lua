
AddCSLuaFile()

ENT.Base = "lvs_base_wheeldrive"
DEFINE_BASECLASS( "lvs_base_wheeldrive" )

ENT.PrintName = "[LVS] Truck Base"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS] - Trucks - Pack"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

ENT.WheelBrakeApplySound = "LVS.Brake.Apply"
ENT.WheelBrakeReleaseSound = "LVS.Brake.Release"

ENT.EngineRevLimited = true
ENT.EngineIgnitionTime = 0
ENT.EngineStartStopVolume = 1.0
ENT.EngineStartSound = "common/null.wav"
ENT.EngineStopSound = "common/null.wav"

ENT.TransShiftSound = "common/null.wav"

if CLIENT then
	ENT.TireSoundTypes = {
		["roll"] = "lvs/vehicles/generic/heavywheel_roll.wav",
		["roll_racing"] = "lvs/vehicles/generic/wheel_roll.wav",
		["roll_dirt"] = "lvs/vehicles/generic/heavywheel_roll_dirt.wav",
		["roll_wet"] = "lvs/vehicles/generic/heavywheel_roll_wet.wav",
		["roll_damaged"] = "lvs/wheel_damaged_loop.wav",
		["skid"] = "lvs/vehicles/generic/heavywheel_skid.wav",
		["skid_racing"] = "lvs/vehicles/generic/wheel_skid_racing.wav",
		["skid_dirt"] = "lvs/vehicles/generic/heavywheel_skid_dirt.wav",
		["skid_wet"] = "lvs/vehicles/generic/wheel_skid_wet.wav",
		["tire_damage_layer"] = "lvs/wheel_destroyed_loop.wav",
	}

	function ENT:TireSoundThink()
		for snd, _ in pairs( self.TireSoundTypes ) do
			local T = self:GetTireSoundTime( snd )

			if T > 0 then
				local speed = self:GetVelocity():Length()

				local sound = self:StartTireSound( snd )

				if string.StartsWith( snd, "skid" ) or snd == "tire_damage_layer" then
					local vel = speed
					speed = math.max( math.abs( self:GetWheelVelocity() ) - vel, 0 ) * 5 + vel
				end

				local volume = math.min(speed / 400,1) ^ 2 * T
				local pitch = 100 + math.Clamp((speed - 50) / 20,0,155)

				sound:ChangeVolume( volume, 0 )
				sound:ChangePitch( pitch )
			else
				self:StopTireSound( snd )
			end
		end
	end

	function ENT:LVSHudPaintInfoText( X, Y, W, H, ScrX, ScrY, ply )
		BaseClass.LVSHudPaintInfoText( self, X, Y, W, H, ScrX, ScrY, ply )

		if ply ~= self:GetDriver() then return end

		local Throttle = self:GetThrottle()
		local MaxThrottle = self:GetMaxThrottle()

		if self:GetRacingHud() or MaxThrottle >= 0.99 then return end

		if MaxThrottle <= 0.51 then
			MaxThrottle = math.min(Throttle,MaxThrottle)
		end

		local hX = X + W - H * 0.5
		local hY = Y + H * 0.25 + H * 0.25
		local radius = H * 0.35

		local rad1 = radius * 0.8
		local rad2 = radius * 1.2

		local ang = math.rad( 92 + MaxThrottle * 360 )

		surface.SetDrawColor( 255, 0, 0, 255 )

		for i = -8,8 do
			local printang = ang + math.rad( i * 0.35 )

			local startX = hX + math.cos( printang ) * rad1
			local startY = hY + math.sin( printang ) * rad1
			local endX = hX + math.cos( printang ) * rad2
			local endY = hY + math.sin( printang ) * rad2

			surface.DrawLine( startX, startY, endX, endY )
		end
	end

	return
end

function ENT:UpdateReverseSound()
	local EntTable = self:GetTable()

	local ReverseSoundHandler = EntTable._ReverseSoundHandler

	if not IsValid( ReverseSoundHandler ) then return end

	local IsActive = ReverseSoundHandler:GetActive()
	local ShouldActive = self:GetActive() and self:GetReverse()

	if ShouldActive then
		if self:GetVelocity():LengthSqr() < 250 and self:GetThrottle() == 0 then
			ShouldActive = false
		end
	end

	if IsActive == ShouldActive then return end

	ReverseSoundHandler:SetActive( ShouldActive )
end

function ENT:AddReverseSound( pos, snd, snd_interior )
	if IsValid( self._ReverseSoundHandler ) then return end

	if not snd then snd = "lvs/vehicles/generic/reverse_warning_beep.wav" end

	self._ReverseSoundHandler = self:AddSoundEmitter( pos, snd, snd_interior )
	self._ReverseSoundHandler:SetSoundLevel( 65 )

	return self._ReverseSoundHandler
end

function ENT:LerpBrake( Brake )
	local Old = self:GetBrake()

	BaseClass.LerpBrake( self, Brake )

	local New = self:GetBrake()

	self:OnBrakeChanged( Old, New )
end

function ENT:OnBrakeChanged( Old, New )
	if Old == New then return end

	local BrakeActive = New ~= 0

	if BrakeActive == self._OldBrakeActive then return end

	self._OldBrakeActive = BrakeActive

	if BrakeActive then
		if self:GetVelocity():Length() > 100 then
			self:EmitSound( self.WheelBrakeApplySound, 75, 100, 1 )
		end

		return
	end

	self:EmitSound( self.WheelBrakeReleaseSound, 75, math.random(90,110), 1 )
end

function ENT:PostInitialize( PObj )
	BaseClass.PostInitialize( self, PObj )

	self:OnCoupleChanged( nil, nil, false )
end

function ENT:OnCoupleChanged( targetVehicle, targetHitch, active )
	self.HitchIsHooked = active
end

function ENT:GetEngineTorque()
	local EntTable = self:GetTable()

	local MaxVelocity = EntTable.MaxVelocity
	local Velocity = self:GetVelocity():Length()
	local Geared = (MaxVelocity / EntTable.TransGears) * 0.5

	local TargetValue = EntTable.HitchIsHooked and 1 or math.min( math.max( 1 - (math.max( Velocity - Geared, 0 ) / Geared) , 0.5 ) + math.max( (Velocity / MaxVelocity) ^ 2 - 0.5, 0 ), 1 )

	if TargetValue ~= self:GetMaxThrottle() then
		self:SetMaxThrottle( TargetValue )
	end

	return BaseClass.GetEngineTorque( self )
end

function ENT:OnHandbrakeActiveChanged( Active )
	if Active then
		if self:GetVelocity():Length() > 100 then
			self:EmitSound( self.WheelBrakeApplySound, 75, 100, 1 )
			self._AllowReleaseSound = true
		end
	else
		if self._AllowReleaseSound then
			self._AllowReleaseSound = nil
			self:EmitSound( self.WheelBrakeReleaseSound, 75, math.random(90,110), 1 )
		end
	end
end

function ENT:HandleStart()
	self:UpdateReverseSound()

	BaseClass.HandleStart( self )

	local Engine = self:GetEngine()

	if not IsValid( Engine ) then return end

	local EntTable = self:GetTable()

	local ShouldStart = EntTable.DoEngineStart == true

	local T = CurTime()

	if EntTable.OldShouldStart ~= ShouldStart then
		EntTable.OldShouldStart = ShouldStart

		if ShouldStart then
			EntTable.EngineStartTime = T + EntTable.EngineIgnitionTime

			Engine:EmitSound( self.EngineStartSound, 75, 100, self.EngineStartStopVolume )
		end
	end

	if not EntTable.EngineStartTime or EntTable.EngineStartTime > T then return end

	EntTable.EngineStartTime = nil

	if self:GetEngineActive() then return end

	self:StartEngine()
end

function ENT:ToggleEngine()
	local Engine = self:GetEngine()

	if not IsValid( Engine ) or Engine:GetDestroyed() then

		BaseClass.ToggleEngine( self )

		return
	end

	if self:GetEngineActive() then
		self:StopEngine()
	else
		self.DoEngineStart = true
	end
end

function ENT:StopEngine()
	BaseClass.StopEngine( self )

	self.EngineStartTime = nil

	self.DoEngineStart = false
	self.OldShouldStart = false

	local Engine = self:GetEngine()

	if not IsValid( Engine ) then return end

	Engine:EmitSound( self.EngineStopSound, 75, 100, self.EngineStartStopVolume )
end