
local StartTime = SysTime()

if SERVER then
	AddCSLuaFile("includes/circles/circles.lua")
end

local function FileIsEmpty( filename )
	if file.Size( filename, "LUA" ) <= 1 then -- this is suspicous
		local data = file.Read( filename, "LUA" )

		if data and string.len( data ) <= 1 then -- confirm its empty

			print("[LVS] - refusing to load '"..filename.."'! File is Empty!" )

			return true
		end
	end

	return false
end

for _, filename in pairs( file.Find("lvs_framework/autorun/*.lua", "LUA") ) do
	if FileIsEmpty( "lvs_framework/autorun/"..filename ) then continue end

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

print("[LVS] - initialized ["..math.Round((SysTime() - StartTime) * 1000,2).."ms]")

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

function LVS:BlastDamage( pos, forward, attacker, inflictor, damage, damagetype, radius, force )

	local dmginfo = DamageInfo()
	dmginfo:SetAttacker( attacker )
	dmginfo:SetInflictor( inflictor )
	dmginfo:SetDamage( damage )
	dmginfo:SetDamageType( DMG_SONIC )

	util.BlastDamageInfo( dmginfo, pos, radius )

	if damagetype ~= DMG_BLAST then return end

	local HitEntities = {}

	local startpos = pos - forward * radius

	local fragmentangle = 10
	local numfragments = 16

	for i = 1, numfragments do
		local ang = forward:Angle() + Angle( math.random(-fragmentangle,fragmentangle), math.random(-fragmentangle,fragmentangle), 0 )
		local dir = ang:Forward()

		local endpos = pos + dir * radius

		debugoverlay.Line( startpos, endpos, 10, Color( 255, 0, 0, 255 ), true )

		local trace = util.TraceLine( {
			start = startpos,
			endpos = endpos,
			filter = { attacker, inflictor },
			ignoreworld = true,
		} )

		if not IsValid( trace.Entity ) then continue end

		local dmginfo = DamageInfo()
		dmginfo:SetAttacker( attacker )
		dmginfo:SetInflictor( inflictor )
		dmginfo:SetDamage( damage / numfragments )
		dmginfo:SetDamageForce( dir * force )
		dmginfo:SetDamagePosition( trace.HitPos )
		dmginfo:SetDamageType( DMG_BLAST )

		trace.Entity:TakeDamageInfo( dmginfo )
	end
end

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