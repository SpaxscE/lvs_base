
function ENT:PredictBTL()
	local pod = self:GetBTPodL()

	if not IsValid( pod ) then return end

	local plyL = LocalPlayer()
	local ply = pod:GetDriver()

	if ply ~= plyL then return end

	self:SetPosBTL()
	self:SetPoseParameterBTL( pod:lvsGetWeapon() )
end

function ENT:PredictBTR()
	local pod = self:GetBTPodR()

	if not IsValid( pod ) then return end

	local plyL = LocalPlayer()
	local ply = pod:GetDriver()

	if ply ~= plyL then return end

	self:SetPosBTR()
	self:SetPoseParameterBTR( pod:lvsGetWeapon() )
end

function ENT:PredictPoseParamaters()
	self:PredictBTL()
	self:PredictBTR()

	self:InvalidateBoneCache()
end