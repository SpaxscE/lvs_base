--DO NOT EDIT OR REUPLOAD THIS FILE

include("shared.lua")

function ENT:LFSHudPaintRollIndicator( HitPlane, Enabled )
end

function ENT:LFSHudPaintInfoLine( HitPlane, HitPilot, LFS_TIME_NOTIFY, Dir, Len, FREELOOK )
end

function ENT:LFSHudPaintCrosshair( HitPlane, HitPilot )
	local X = ScrW()
	local Y = ScrH()

	local Radius = 100

	local Test = self:GetSteer()

	local Test2 = Vector( Test.x, Test.y, 0)
	local Test2Dir = Test2:GetNormalized()
	local Test2Len = Test2:Length()

	surface.DrawCircle( X * 0.5, Y * 0.5, Radius, Color( 255, 0, 0 ) )

	surface.DrawCircle( X * 0.5 + Test2Dir.x * math.abs(Test.x) * Radius, Y * 0.5 + Test2Dir.y * math.abs(Test.y) * Radius, 5, Color( 255, 0, 0 ) )

	local Throttle = self:GetThrottlePercent()

	draw.SimpleText( "THR", "LFS_FONT", 10, 10, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	draw.SimpleText( Throttle.."%" , "LFS_FONT", 120, 10, Col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
end

function ENT:LFSCalcViewFirstPerson( view, ply )
	view.drawviewer = true

	return self:LFSCalcViewThirdPerson( view, ply )
end

function ENT:LFSCalcViewThirdPerson( view, ply )
	self._lerpPos = self._lerpPos or self:GetPos()

	local Delta = RealFrameTime()

	local TargetPos = self:LocalToWorld( Vector(500,0,250) )

	local Sub = TargetPos - self._lerpPos
	local Dir = Sub:GetNormalized()
	local Dist = Sub:Length()

	self._lerpPos = self._lerpPos + (TargetPos - self:GetForward() * 900 - Dir * 100 - self._lerpPos) * Delta * 12

	local vel = self:GetVelocity()

	view.origin = self._lerpPos
	view.angles = self:GetAngles()

	return view
end