
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

local ValveWierdBlastDamageClass = {
	["npc_strider"] = true, -- takes 70 damage for each blast damage as constant value ...
	["npc_combinegunship"] = true, -- takes 44 damage as constant value ...
	["func_breakable_surf"] = true, -- this entity dont care about anything that isnt a trace attack or blast damage
}

function LVS:BlastDamage( pos, forward, attacker, inflictor, damage, damagetype, radius, force )

	local dmginfo = DamageInfo()
	dmginfo:SetAttacker( attacker )
	dmginfo:SetInflictor( inflictor )
	dmginfo:SetDamage( damage )
	dmginfo:SetDamageType( damagetype == DMG_BLAST and DMG_SONIC or damagetype )

	if damagetype ~= DMG_BLAST then
		dmginfo:SetDamagePosition( pos )
		dmginfo:SetDamageForce( forward * force )

		util.BlastDamageInfo( dmginfo, pos, radius )

		return
	end

	util.BlastDamageInfo( dmginfo, pos, radius )

	local FragmentAngle = 10
	local NumFragments = 16
	local NumFragmentsMissed = 0

	local RegisteredHits = {}

	local trace = util.TraceLine( {
		start = pos,
		endpos = pos - forward * radius,
		filter = { attacker, inflictor },
	} )

	local startpos = trace.HitPos

	for i = 1, NumFragments do
		local ang = forward:Angle() + Angle( math.random(-FragmentAngle,FragmentAngle), math.random(-FragmentAngle,FragmentAngle), 0 )
		local dir = ang:Forward()

		local endpos = pos + dir * radius

		local trace = util.TraceLine( {
			start = startpos,
			endpos = endpos,
			filter = { attacker, inflictor },
		} )

		debugoverlay.Line( startpos, trace.HitPos, 10, Color( 255, 0, 0, 255 ), true )

		if not trace.Hit then
			NumFragmentsMissed = NumFragmentsMissed + 1

			continue
		end

		if not IsValid( trace.Entity ) then continue end

		if not RegisteredHits[ trace.Entity ] then
			RegisteredHits[ trace.Entity ] = {}
		end

		table.insert( RegisteredHits[ trace.Entity ], {
			origin = trace.HitPos,
			force = forward * force,
		} )
	end

	local Hull = Vector(10,10,10)

	for _, ent in ipairs( ents.FindInSphere( pos, radius ) ) do
		if not ent.LVS or ent == inflictor or ent == attacker then continue end

		local trace = util.TraceHull( {
			start = pos,
			endpos = ent:LocalToWorld( ent:OBBCenter() ),
			mins = -Hull,
			maxs = Hull,
			whitelist = true,
			ignoreworld = true,
			filter = ent,
		} )

		debugoverlay.Line( pos, trace.HitPos, 10, Color( 255, 0, 0, 255 ), true )

		NumFragments = NumFragments + 1

		if not RegisteredHits[ ent ] then
			RegisteredHits[ ent ] = {}
		end

		table.insert( RegisteredHits[ ent ], {
			origin = trace.HitPos,
			force = forward * force,
		} )
	end

	if NumFragmentsMissed == NumFragments then return end

	local DamageBoost = NumFragments / ( NumFragments - NumFragmentsMissed )

	for ent, data in pairs( RegisteredHits ) do
		local NumHits = #data
		local AverageOrigin = vector_origin
		local AverageForce = vector_origin

		for _, HitData in pairs( data ) do
			AverageOrigin = AverageOrigin + HitData.origin
			AverageForce = AverageForce + HitData.force
		end

		AverageOrigin = AverageOrigin / NumHits
		AverageForce = AverageForce / NumHits

		local TotalDamage = ( ( NumHits * DamageBoost ) / NumFragments ) * damage

		--debugoverlay.Cross( AverageOrigin, 50, 10, Color( 255, 0, 255 ) )

		-- hack
		if ValveWierdBlastDamageClass[ ent:GetClass() ] then

			util.BlastDamage( inflictor, attacker, pos, radius, damage )

			continue
		end

		local dmginfo = DamageInfo()
		dmginfo:SetAttacker( attacker )
		dmginfo:SetInflictor( inflictor )
		dmginfo:SetDamage( TotalDamage )
		dmginfo:SetDamageForce( AverageForce )
		dmginfo:SetDamagePosition( AverageOrigin )
		dmginfo:SetDamageType( DMG_BLAST )

		ent:TakeDamageInfo( dmginfo )
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