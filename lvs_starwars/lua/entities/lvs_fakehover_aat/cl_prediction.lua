
function ENT:PredictPoseParamaters()
	local pod = self:GetGunnerSeat()

	if not IsValid( pod ) then return end

	local plyL = LocalPlayer()
	local ply = pod:GetDriver()

	if ply ~= plyL then return end

	self:SetPoseParameterTurret( pod:lvsGetWeapon() )

	self:InvalidateBoneCache()
end