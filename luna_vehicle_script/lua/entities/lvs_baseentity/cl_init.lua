include("shared.lua")

function ENT:LVSHudPaint( X, Y, ply )
end

function ENT:LVSCalcViewFirstPerson( view, ply )
	view.drawviewer = true

	return self:LVSCalcViewThirdPerson( view, ply )
end

function ENT:LVSCalcViewThirdPerson( view, ply )
	self._lerpPos = self._lerpPos or self:GetPos()

	local Delta = RealFrameTime()

	local TargetPos = self:LocalToWorld( Vector(500,0,250) )

	local Sub = TargetPos - self._lerpPos
	local Dir = Sub:GetNormalized()
	local Dist = Sub:Length()

	self._lerpPos = self._lerpPos + (TargetPos - self:GetForward() * 750 - Dir * 250 - self._lerpPos) * Delta * 12

	local vel = self:GetVelocity()

	view.origin = self._lerpPos
	view.angles = self:GetAngles()

	return view
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:DrawTranslucent()
end

function ENT:Initialize()
end

function ENT:Think()
end

function ENT:OnRemove()
end

function ENT:GetCrosshairFilterEnts()
	if not istable( self.CrosshairFilterEnts ) then
		self.CrosshairFilterEnts = {self}

		-- lets ask the server to build the filter for us because it has access to constraint.GetAllConstrainedEntities() 
		net.Start( "lvs_player_request_filter" )
			net.WriteEntity( self )
		net.SendToServer()
	end

	return self.CrosshairFilterEnts
end
