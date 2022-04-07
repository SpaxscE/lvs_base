local meta = FindMetaTable( "Player" )

function meta:lvfGetVehicle()
	if not self:InVehicle() then return NULL end

	local Pod = self:GetVehicle()

	if not IsValid( Pod ) then return NULL end

	if Pod.LVFchecked then

		return Pod.LVFBaseEnt

	else
		local Parent = Pod:GetParent()
		
		if not IsValid( Parent ) then return NULL end

		if not Parent.LVF then return NULL end

		Pod.LVFchecked = true
		Pod.LVFBaseEnt = Parent

		return Parent
	end
end
