include("shared.lua")

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
	self:WingTurretProjector()
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
