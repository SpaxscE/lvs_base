if SERVER then
	AddCSLuaFile("includes/circles/circles.lua")
	return
end

return include("includes/circles/circles.lua")