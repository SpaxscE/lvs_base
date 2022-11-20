
LVS = istable( LVS ) and LVS or {}

LVS.pSwitchKeys = {[KEY_1] = 1,[KEY_2] = 2,[KEY_3] = 3,[KEY_4] = 4,[KEY_5] = 5,[KEY_6] = 6,[KEY_7] = 7,[KEY_8] = 8,[KEY_9] = 9,[KEY_0] = 10}
LVS.pSwitchKeysInv = {[1] = KEY_1,[2] = KEY_2,[3] = KEY_3,[4] = KEY_4,[5] = KEY_5,[6] = KEY_6,[7] = KEY_7,[8] = KEY_8,[9] = KEY_9,[10] = KEY_0}

LVS.ThemeColor = Color(60,60,60,255)

-- shared
for _, filename in pairs( file.Find("lvs_framework/shared/*.lua", "LUA") ) do
	if SERVER then
		AddCSLuaFile("lvs_framework/shared/"..filename)
	end
	include("lvs_framework/shared/"..filename)
end

-- server
if SERVER then
	for _, filename in pairs( file.Find("lvs_framework/server/*.lua", "LUA") ) do
		include("lvs_framework/server/"..filename)
	end
end

-- client
for _, filename in pairs( file.Find("lvs_framework/client/*.lua", "LUA") ) do
	if SERVER then
		AddCSLuaFile("lvs_framework/client/"..filename)
	else
		include("lvs_framework/client/"..filename)
	end
end