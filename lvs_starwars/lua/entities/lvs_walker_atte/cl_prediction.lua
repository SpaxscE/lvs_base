
function ENT:PredictPoseParamaters()
	local pod = self:GetTurretSeat()

	if not IsValid( pod ) then return end

	local plyL = LocalPlayer()
	local ply = pod:GetDriver()

	if ply ~= plyL then return end

	self:SetPosTurret()
	self:SetPoseParameterTurret( pod:lvsGetWeapon() )
end