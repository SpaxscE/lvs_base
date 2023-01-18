include("shared.lua")
include( "sh_turret.lua" )
include( "cl_prediction.lua" )

function ENT:OnFrame()
	self:PredictPoseParamaters()
end

function ENT:CalcViewOverride( ply, pos, angles, fov, pod )
	if ply == self:GetDriver() and not pod:GetThirdPersonMode() then
		return pos + self:GetForward() * 60 - self:GetUp() * 30, angles, fov
	end

	return pos, angles, fov
end

local COLOR_RED = Color(255,0,0,255)
local COLOR_WHITE = Color(255,255,255,255)

function ENT:LVSPreHudPaint( X, Y, ply )
	if self:GetIsCarried() then return false end

	if ply == self:GetDriver() then
		local Col = self:WeaponsInRange() and COLOR_WHITE or COLOR_RED

		local Pos2D = self:GetEyeTrace().HitPos:ToScreen() 

		self:PaintCrosshairCenter( Pos2D, Col )
		self:PaintCrosshairOuter( Pos2D, Col )
		self:LVSPaintHitMarker( Pos2D )
	end

	return true
end
