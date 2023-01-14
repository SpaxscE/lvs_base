include("shared.lua")
include( "sh_mainweapons.lua" )
include( "sh_ballturret_left.lua" )
include( "sh_ballturret_right.lua" )
include( "sh_wingturret.lua" )
include( "cl_drawing.lua" )
include( "cl_prediction.lua" )
include( "cl_lights.lua" )

function ENT:CalcViewOverride( ply, pos, angles, fov, pod )
	if pod == self:GetDriverSeat() then

		if pod:GetThirdPersonMode() then
			pos = pos + self:GetUp() * 100, angles, fov
		end

		return pos, angles, fov
	end

	if pod:GetThirdPersonMode() then
		pos = ply:GetShootPos() + pod:GetUp() * 40
	else
		pos = pos + pod:GetUp() * 40
	end

	return pos, angles, fov
end

function ENT:OnSpawn()
end

function ENT:OnFrame()
	self:AnimRearHatch()
	self:AnimLights()
	self:WingTurretProjector()
	self:BTLProjector()
	self:BTRProjector()
	self:PredictPoseParamaters()
end

function ENT:BTRProjector()
	local Fire = self:GetBTRFire()
	if Fire == self.OldFireBTR then return end

	self.OldFireBTR = Fire

	if Fire then
		local effectdata = EffectData()
		effectdata:SetEntity( self )
		util.Effect( "lvs_laat_right_projector", effectdata )
	end
end
	
function ENT:BTLProjector()
	local Fire = self:GetBTLFire()

	if Fire == self.OldFireBTL then return end

	self.OldFireBTL = Fire
	
	if Fire then
		local effectdata = EffectData()
		effectdata:SetEntity( self )
		util.Effect( "lvs_laat_left_projector", effectdata )
	end
end

function ENT:WingTurretProjector()
	local FireWingTurret = self:GetWingTurretFire()

	if FireWingTurret == self.OldWingTurretFire then return end

	self.OldWingTurretFire = FireWingTurret

	if FireWingTurret then
		local effectdata = EffectData()
		effectdata:SetEntity( self )
		util.Effect( "lvs_laat_wing_projector", effectdata )
	end
end

function ENT:AnimRearHatch()
	local Tval = self:GetRearHatch() and 32 or 0
	local Rate = 50 * RealFrameTime()
	
	self.smRH = self.smRH and self.smRH + math.Clamp(Tval - self.smRH,-Rate,Rate) or 0

	if not self.HatchID then
		self.HatchID = self:LookupBone( "hatch" ) 
	else
		self:ManipulateBoneAngles( self.HatchID, Angle(0,-self.smRH,0) )
	end
end

function ENT:OnStartBoost()
	self:EmitSound( "^lvs/vehicles/laat/boost_"..math.random(1,2)..".wav", 85 )
end

function ENT:OnStopBoost()
end
