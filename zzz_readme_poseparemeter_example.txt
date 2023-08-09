==================================
========== CLIENT CODE ===========
==================================

function ENT:OnSpawn()
 	-- this creates a custom bone pose parameter
    	-- self:CreateBonePoseParameter( name, boneID, angle_min, angle_max, pos_min, pos_max )

	-- example:
	self:CreateBonePoseParameter( "left_door", 25, Angle(0,0,0), Angle(-90,0,0), Vector(0,0,0), Vector(0,0,0) )
end


you can manually adjust the bone pose parameter by calling:

self:SetBonePoseParameter( name, value ) -- where name is the name you give in CreateBonePoseParameter and value a number from 0-1

-- example:
self:SetBonePoseParameter( "!left_door", 0.5 )



==================================
========== SERVER CODE ===========
==================================

-- how to use bone pose parameter in combination with door handler:
function ENT:OnSpawn()
	local DriverSeat = self:AddDriverSeat( Vector(-26.6,14.5,0), Angle(0,-90,8) )

	local DoorHandler = self:AddDoorHandler( "!left_door" ) -- make sure to add ! in front of the name to tell the system to use a bone pose parameter and not the regular one
	DoorHandler:LinkToSeat( DriverSeat )
end


