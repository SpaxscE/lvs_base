
if SERVER then
	AddCSLuaFile("includes/circles/circles.lua")
end

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

hook.Run( "LVS:Initialize" )

if CLIENT then
	hook.Add( "InitPostEntity", "!!!lvscheckupdates", function()
		timer.Simple(20, function()
			LVS.CheckUpdates()

			local convar = GetConVar( "no_error_hitboxes" )

			if not convar then return end

			convar:SetBool( false )
		end)
	end )

	return
end

resource.AddWorkshop("2912816023")

function LVS:FixVelocity()
	local tbl = physenv.GetPerformanceSettings()

	if tbl.MaxVelocity < 4000 then
		local OldVel = tbl.MaxVelocity

		tbl.MaxVelocity = 4000
		physenv.SetPerformanceSettings(tbl)

		print("[LVS] Low MaxVelocity detected! Increasing! "..OldVel.." => 4000")
	end

	if tbl.MaxAngularVelocity < 7272 then
		local OldAngVel = tbl.MaxAngularVelocity

		tbl.MaxAngularVelocity = 7272
		physenv.SetPerformanceSettings(tbl)

		print("[LVS] Low MaxAngularVelocity detected! Increasing! "..OldAngVel.." => 7272")
	end
end

hook.Add( "InitPostEntity", "!!!lvscheckupdates", function()
	timer.Simple(20, function()
		LVS.CheckUpdates()
	end)
end )