include("shared.lua")

function ENT:OnFrame()
	self:AnimRotor()
	self:AnimTail()
end

function ENT:AnimTail()
	local Steer = self:GetSteer()

	local TargetValue = -(Steer.x + Steer.z * 2) * 10

	self.sm_pp_rudder = self.sm_pp_rudder and (self.sm_pp_rudder + (TargetValue - self.sm_pp_rudder) * RealFrameTime() * 10) or 0

	self:SetPoseParameter("rudder", self.sm_pp_rudder)
	self:InvalidateBoneCache() 
end

function ENT:AnimRotor()
	local RPM = self:GetThrottle() * 2500

	self.RPM = self.RPM and (self.RPM + RPM * RealFrameTime() * 0.5) or 0

	local Rot1 = Angle( -self.RPM,0,0)
	Rot1:Normalize() 
	
	local Rot2 = Angle(0,0,self.RPM)
	Rot2:Normalize() 

	self:ManipulateBoneAngles( 2, Rot1 )
	self:ManipulateBoneAngles( 5, Rot2 )
	self:ManipulateBoneAngles( 3, Rot2 )
end
