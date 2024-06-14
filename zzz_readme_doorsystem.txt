==================================
========== SERVER CODE ===========
==================================

-- create a door handler using:

self:AddDoorHandler( PoseParameterName, position, angle, boundingbox_mins, boundingbox_maxs, boundingbox_mins_open, boundingbox_maxs_open ) -- example:

local DoorHandler = self:AddDoorHandler( "hood", Vector(50,0,25), Angle(7,0,0), Vector(-25,-30,-6), Vector(25,30,6), Vector(-25,-30,-3), Vector(25,30,40) )

-- when only given a poseparametername it will just use the models bounding box as trigger-area
-- the poseparameter should go from 0-1  where 0 should be closed

-- door handlers are clientside by default, if you wish it to be serverside (move attachments too) add "^" prefix to your PoseParameterName




-- to link it to a pod to use as an door you have to call:

DoorHandler:LinkToSeat( pod_entity )

-- example:

local DriverSeat = self:AddDriverSeat( Vector(-12.6,11.9,0), Angle(0,-90,8) )

local DoorHandler = self:AddDoorHandler( "left_door", Vector(0,27,20), Angle(0,0,0), Vector(-23,-6,-12), Vector(20,6,12), Vector(-23,-20,-12), Vector(20,40,12) )
DoorHandler:LinkToSeat( DriverSeat )



-- you can change some settings on it using:

DoorHandler:SetSoundOpen( "lvs/vehicles/generic/car_door_open.wav" ) -- sound played when the door is opened
DoorHandler:SetSoundClose( "lvs/vehicles/generic/car_door_close.wav" ) -- sound played when the door is closed
DoorHandler:SetRate( 5 ) -- how fast the doors should open
DoorHandler:SetRateExponent( 2 ) -- exponent multiplier to make the movement less linear
DoorHandler:DisableOnBodyGroup( 6, 3 ) -- if bodygroup 6 is set to subgroup 3, this doorhandler will be inactive
