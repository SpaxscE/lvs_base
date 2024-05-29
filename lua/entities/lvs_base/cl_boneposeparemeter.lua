
function ENT:CreateBonePoseParameter( name, bone, ang_min, ang_max, pos_min, pos_max )
	if not istable( self._BonePoseParameters ) then self._BonePoseParameters = {} end

	self._BonePoseParameters[ name ] = {
		bone = (bone or -1),
		ang_min = ang_min or angle_zero,
		ang_max = ang_max or angle_zero,
		pos_min = pos_min or vector_origin,
		pos_max = pos_max or vector_origin,
	}
end

function ENT:SetBonePoseParameter( name, value )
	if name and string.StartsWith( name, "!" ) then
		name = string.Replace( name, "!", "" )
	end

	if not istable( self._BonePoseParameters ) or not self._BonePoseParameters[ name ] then return end

	local data = self._BonePoseParameters[ name ]

	local ang = LerpAngle( value, data.ang_min, data.ang_max )
	local pos = LerpVector( value, data.pos_min, data.pos_max )

	self:ManipulateBoneAngles( data.bone, ang )
	self:ManipulateBonePosition( data.bone, pos )
end