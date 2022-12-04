local meta = FindMetaTable( "Player" )

function meta:lvsGetVehicle()
	if not self:InVehicle() then return NULL end

	local Pod = self:GetVehicle()

	if not IsValid( Pod ) then return NULL end

	if Pod.LVSchecked then

		return Pod.LVSBaseEnt

	else
		local Parent = Pod:GetParent()
		
		if not IsValid( Parent ) then return NULL end

		if not Parent.LVS then return NULL end

		Pod.LVSchecked = true
		Pod.LVSBaseEnt = Parent

		return Parent
	end
end
