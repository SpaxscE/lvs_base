
LVS = istable( LVS ) and LVS or {}

LVS.pSwitchKeys = {[KEY_1] = 1,[KEY_2] = 2,[KEY_3] = 3,[KEY_4] = 4,[KEY_5] = 5,[KEY_6] = 6,[KEY_7] = 7,[KEY_8] = 8,[KEY_9] = 9,[KEY_0] = 10}
LVS.pSwitchKeysInv = {[1] = KEY_1,[2] = KEY_2,[3] = KEY_3,[4] = KEY_4,[5] = KEY_5,[6] = KEY_6,[7] = KEY_7,[8] = KEY_8,[9] = KEY_9,[10] = KEY_0}

LVS.ThemeColor = Color(60,60,60,255)

for _, filename in pairs( file.Find("lvs_framework/autorun/*.lua", "LUA") ) do
	if string.StartWith( filename, "sv_") then -- sv_ prefix only load serverside
		if SERVER then
			include("lvs_framework/autorun/"..filename)
		end

		continue
	end

	if string.StartWith( filename, "cl_") then -- cl_ prefix only load clientside
		if SERVER then
			AddCSLuaFile("lvs_framework/autorun/"..filename)
		else
			include("lvs_framework/autorun/"..filename)
		end

		continue
	end

	-- everything else is shared
	if SERVER then
		AddCSLuaFile("lvs_framework/autorun/"..filename)
	end
	include("lvs_framework/autorun/"..filename)
end
