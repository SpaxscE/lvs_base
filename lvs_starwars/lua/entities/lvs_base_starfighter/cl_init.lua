include("shared.lua")
include("cl_camera.lua")
include("sh_camera_eyetrace.lua")
include("cl_hud.lua")
include("cl_flyby.lua")
include("cl_deathsound.lua")

ENT.TrailAlpha = 25

DEFINE_BASECLASS( "lvs_base" )

function ENT:Think()
	BaseClass.Think( self )

	self.EFxScale = self.EFxScale and (self.EFxScale - self.EFxScale * RealFrameTime()) or 0

	self:CalcOnThrottle()
end

function ENT:CalcOnThrottle()
	if not self:GetEngineActive() then 
		self._oldOnTHR = nil

		return
	end

	local Throttle = self:GetThrottle()

	if self._oldOnTHR ~= Throttle then
		if self._oldOnTHR == 0 and Throttle > 0 then
			self._IsAccelerating = true
		end

		if Throttle > (self._oldOnTHR or 0) then
			self._IsAccelerating = true
		else
			self._IsAccelerating = false
		end

		if self._oldOnTHR == 1 then
			self:StopBoost()
		end

		self._oldOnTHR = Throttle
	end

	if self._oldAccelerating ~= self._IsAccelerating then
		self._oldAccelerating = self._IsAccelerating

		if not self._IsAccelerating then return end

		self:StartBoost()
	end
end

function ENT:StartBoost()
	local T = CurTime()

	if (self._NextSND or 0) > T then return end

	self._NextSND = T + 1

	self.EFxScale = 100

	self:OnStartBoost()
end

function ENT:StopBoost()
	local T = CurTime()

	if (self._NextSND or 0) > T then return end

	self._NextSND = T + 1

	self:OnStopBoost()
end

function ENT:GetBoost()
	return (self.EFxScale or 0)
end

function ENT:OnStartBoost()
end

function ENT:OnStopBoost()
end