-- globals have to be loaded first
if SERVER then
	AddCSLuaFile("lv_framework/globals.lua")
end
include("lv_framework/globals.lua")

-- shared
for _, filename in pairs( file.Find("lv_framework/shared/*.lua", "LUA") ) do
	if SERVER then
		AddCSLuaFile("lv_framework/shared/"..filename)
	end
	include("lv_framework/shared/"..filename)
end

-- server
if SERVER then
	for _, filename in pairs( file.Find("lv_framework/server/*.lua", "LUA") ) do
		include("lv_framework/server/"..filename)
	end
end

-- client
for _, filename in pairs( file.Find("lv_framework/client/*.lua", "LUA") ) do
	if SERVER then
		AddCSLuaFile("lv_framework/client/"..filename)
	else
		include("lv_framework/client/"..filename)
	end
end