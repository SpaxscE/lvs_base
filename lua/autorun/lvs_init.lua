
LVS = istable( LVS ) and LVS or {}

LVS.VERSION = 335
LVS.VERSION_GITHUB = 0
LVS.VERSION_TYPE = ".GIT"
LVS.VERSION_ADDONS_OUTDATED = false

LVS.KEYS_CATEGORIES = {}
LVS.KEYS_REGISTERED = {}
LVS.pSwitchKeys = {[KEY_1] = 1,[KEY_2] = 2,[KEY_3] = 3,[KEY_4] = 4,[KEY_5] = 5,[KEY_6] = 6,[KEY_7] = 7,[KEY_8] = 8,[KEY_9] = 9,[KEY_0] = 10}
LVS.pSwitchKeysInv = {[1] = KEY_1,[2] = KEY_2,[3] = KEY_3,[4] = KEY_4,[5] = KEY_5,[6] = KEY_6,[7] = KEY_7,[8] = KEY_8,[9] = KEY_9,[10] = KEY_0}

LVS.ThemeColor = Color(127,0,0,255)

LVS.WHEEL_BRAKE = 1
LVS.WHEEL_STEER_NONE = 2
LVS.WHEEL_STEER_FRONT = 3
LVS.WHEEL_STEER_REAR = 4

LVS.WHEELTYPE_NONE = 0
LVS.WHEELTYPE_LEFT = 1
LVS.WHEELTYPE_RIGHT = -1

LVS.HITCHTYPE_NONE = -1
LVS.HITCHTYPE_MALE = 0
LVS.HITCHTYPE_FEMALE = 1

LVS.SOUNDTYPE_NONE = 0
LVS.SOUNDTYPE_IDLE_ONLY = 1
LVS.SOUNDTYPE_REV_UP = 2
LVS.SOUNDTYPE_REV_DOWN = 3
LVS.SOUNDTYPE_REV_DN = 3
LVS.SOUNDTYPE_ALL = 4

LVS.FUELTYPE_PETROL = 0
LVS.FUELTYPE_DIESEL = 1
LVS.FUELTYPE_ELECTRIC = 2
LVS.FUELTYPES = {
	[LVS.FUELTYPE_PETROL] = {
		name = "Petrol",
		color = Vector(240,200,0),
	},
	[LVS.FUELTYPE_DIESEL] = {
		name = "Diesel",
		color = Vector(255,60,0),
	},
	[LVS.FUELTYPE_ELECTRIC] = {
		name = "Electric",
		color = Vector(0,127,255),
	},
}

LVS.WEAPONS = {
	["DEFAULT"] = {
		Icon = Material("lvs/weapons/bullet.png"),
		Ammo = 9999,
		Delay = 0,
		HeatRateUp = 0.2,
		HeatRateDown = 0.25,
		Attack = function( ent ) end,
		StartAttack = function( ent ) end,
		FinishAttack = function( ent ) end,
		OnSelect = function( ent, old ) end,
		OnDeselect = function( ent, new ) end,
		OnThink = function( ent, active ) end,
		OnOverheat = function( ent ) end,
		OnRemove = function( ent ) end,
		OnReload = function( ent ) end,
	},
	["LMG"] = {
		Icon = Material("lvs/weapons/mg.png"),
		Ammo = 1000,
		Delay = 0.1,
		Attack = function( ent )
			ent.MirrorPrimary = not ent.MirrorPrimary

			local Mirror = ent.MirrorPrimary and -1 or 1

			local Pos = ent:LocalToWorld( ent.PosLMG and Vector(ent.PosLMG.x,ent.PosLMG.y * Mirror,ent.PosLMG.z) or Vector(0,0,0) )
			local Dir = ent.DirLMG or 0

			local effectdata = EffectData()
			effectdata:SetOrigin( Pos )
			effectdata:SetNormal( ent:GetForward() )
			effectdata:SetEntity( ent )
			util.Effect( "lvs_muzzle", effectdata )

			local bullet = {}
			bullet.Src =  Pos
			bullet.Dir = ent:LocalToWorldAngles( Angle(0,-Dir * Mirror,0) ):Forward()
			bullet.Spread 	= Vector( 0.015, 0.015, 0.015 )
			bullet.TracerName = "lvs_tracer_white"
			bullet.Force	= 1000
			bullet.HullSize 	= 50
			bullet.Damage	= 35
			bullet.Velocity = 30000
			bullet.Attacker 	= ent:GetDriver()
			bullet.Callback = function(att, tr, dmginfo) end
			ent:LVSFireBullet( bullet )

			ent:TakeAmmo()
		end,
		StartAttack = function( ent )
			if not IsValid( ent.SoundEmitter1 ) then
				ent.SoundEmitter1 = ent:AddSoundEmitter( Vector(109.29,0,92.85), "lvs/weapons/mg_loop.wav", "lvs/weapons/mg_loop_interior.wav" )
				ent.SoundEmitter1:SetSoundLevel( 95 )
			end
		
			ent.SoundEmitter1:Play()
		end,
		FinishAttack = function( ent )
			if IsValid( ent.SoundEmitter1 ) then
				ent.SoundEmitter1:Stop()
				ent.SoundEmitter1:EmitSound("lvs/weapons/mg_lastshot.wav")
			end
		end,
		OnSelect = function( ent ) ent:EmitSound("physics/metal/weapon_impact_soft3.wav") end,
		OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end,
	},
	["TABLE_POINT_MG"] = {
		Icon = Material("lvs/weapons/mc.png"),
		Ammo = 2000,
		Delay = 0.1,
		Attack = function( ent )
			if not ent.PosTPMG or not ent.DirTPMG then return end

			for i = 1, 2 do
				ent._NumTPMG = ent._NumTPMG and ent._NumTPMG + 1 or 1

				if ent._NumTPMG > #ent.PosTPMG then ent._NumTPMG = 1 end
			
				local Pos = ent:LocalToWorld( ent.PosTPMG[ ent._NumTPMG ] )
				local Dir = ent.DirTPMG[ ent._NumTPMG ]

				local effectdata = EffectData()
				effectdata:SetOrigin( Pos )
				effectdata:SetNormal( ent:GetForward() )
				effectdata:SetEntity( ent )
				util.Effect( "lvs_muzzle", effectdata )

				local bullet = {}
				bullet.Src = Pos
				bullet.Dir = ent:LocalToWorldAngles( Angle(0,-Dir,0) ):Forward()
				bullet.Spread 	= Vector( 0.035, 0.035, 0.035 )
				bullet.TracerName = "lvs_tracer_yellow"
				bullet.Force	= 1000
				bullet.HullSize 	= 25
				bullet.Damage	= 35
				bullet.Velocity = 40000
				bullet.Attacker 	= ent:GetDriver()
				bullet.Callback = function(att, tr, dmginfo) end
				ent:LVSFireBullet( bullet )
			end

			ent:TakeAmmo( 2 )
		end,
		StartAttack = function( ent )
			if not IsValid( ent.SoundEmitter1 ) then
				ent.SoundEmitter1 = ent:AddSoundEmitter( Vector(109.29,0,92.85), "lvs/weapons/mg_light_loop.wav", "lvs/weapons/mg_light_loop_interior.wav" )
				ent.SoundEmitter1:SetSoundLevel( 95 )
			end
		
			ent.SoundEmitter1:Play()
		end,
		FinishAttack = function( ent )
			if IsValid( ent.SoundEmitter1 ) then
				ent.SoundEmitter1:Stop()
				ent.SoundEmitter1:EmitSound("lvs/weapons/mg_light_lastshot.wav")
			end
		end,
		OnSelect = function( ent ) ent:EmitSound("physics/metal/weapon_impact_soft3.wav") end,
		OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end,
	},
	["HMG"] = {
		Icon = Material("lvs/weapons/hmg.png"),
		Ammo = 300,
		Delay = 0.14,
		Attack = function( ent )
			ent.MirrorSecondary = not ent.MirrorSecondary

			local Mirror = ent.MirrorSecondary and -1 or 1

			local Pos = ent:LocalToWorld( ent.PosHMG and Vector(ent.PosHMG.x,ent.PosHMG.y * Mirror,ent.PosHMG.z) or Vector(0,0,0) )
			local Dir = ent.DirHMG or 0.5

			local effectdata = EffectData()
			effectdata:SetOrigin( Pos )
			effectdata:SetNormal( ent:GetForward() )
			effectdata:SetEntity( ent )
			util.Effect( "lvs_muzzle", effectdata )

			local bullet = {}
			bullet.Src = Pos
			bullet.Dir = ent:LocalToWorldAngles( Angle(0,-Dir * Mirror,0) ):Forward()
			bullet.Spread 	= Vector( 0.02, 0.02, 0.02 )
			bullet.TracerName = "lvs_tracer_orange"
			bullet.Force	= 4000
			bullet.HullSize 	= 15
			bullet.Damage	= 45
			bullet.SplashDamage = 75
			bullet.SplashDamageRadius = 200
			bullet.Velocity = 15000
			bullet.Attacker 	= ent:GetDriver()
			bullet.Callback = function(att, tr, dmginfo)
			end
			ent:LVSFireBullet( bullet )

			ent:TakeAmmo()
		end,
		StartAttack = function( ent )
			if not IsValid( ent.SoundEmitter2 ) then
				ent.SoundEmitter2 = ent:AddSoundEmitter( Vector(109.29,0,92.85), "lvs/weapons/mc_loop.wav", "lvs/weapons/mc_loop_interior.wav" )
				ent.SoundEmitter2:SetSoundLevel( 95 )
			end

			ent.SoundEmitter2:Play()
		end,
		FinishAttack = function( ent )
			if IsValid( ent.SoundEmitter2 ) then
				ent.SoundEmitter2:Stop()
				ent.SoundEmitter2:EmitSound("lvs/weapons/mc_lastshot.wav")
			end
		end,
		OnSelect = function( ent ) ent:EmitSound("physics/metal/weapon_impact_soft2.wav") end,
		OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end,
	},
	["TURBO"] = {
		Icon = Material("lvs/weapons/nos.png"),
		HeatRateUp = 0.1,
		HeatRateDown = 0.1,
		UseableByAI = false,
		Attack = function( ent )
			local PhysObj = ent:GetPhysicsObject()
			if not IsValid( PhysObj ) then return end
			local THR = ent:GetThrottle()
			local FT = FrameTime()

			local Vel = ent:GetVelocity():Length()

			PhysObj:ApplyForceCenter( ent:GetForward() * math.Clamp(ent.MaxVelocity + 500 - Vel,0,1) * PhysObj:GetMass() * THR * FT * 150 ) -- increase speed
			PhysObj:AddAngleVelocity( PhysObj:GetAngleVelocity() * FT * 0.5 * THR ) -- increase turn rate
		end,
		StartAttack = function( ent )
			ent.TargetThrottle = 1.3
			ent:EmitSound("lvs/vehicles/generic/boost.wav")
		end,
		FinishAttack = function( ent )
			ent.TargetThrottle = 1
		end,
		OnSelect = function( ent )
			ent:EmitSound("buttons/lever5.wav")
		end,
		OnThink = function( ent, active )
			if not ent.TargetThrottle then return end

			local Rate = FrameTime() * 0.5

			ent:SetMaxThrottle( ent:GetMaxThrottle() + math.Clamp(ent.TargetThrottle - ent:GetMaxThrottle(),-Rate,Rate) )

			local MaxThrottle = ent:GetMaxThrottle()

			ent:SetThrottle( MaxThrottle )

			if MaxThrottle == ent.TargetThrottle then
				ent.TargetThrottle = nil
			end
		end,
		OnOverheat = function( ent ) ent:EmitSound("lvs/overheat_boost.wav") end,
	},
}

function LVS:GetVersion()
	return LVS.VERSION
end

function LVS:AddKey(name, category, printname, cmd, default)
	local data = {
		printname = printname,
		id = name,
		category = category,
		cmd = cmd,
	}

	if not LVS.KEYS_CATEGORIES[ category ] then
		LVS.KEYS_CATEGORIES[ category ] = {}
	end

	if SERVER then
		table.insert( LVS.KEYS_REGISTERED, data )
	else
		if default then
			if isstring( default ) then
				local Key = input.LookupBinding( default )

				if Key then
					default = input.GetKeyCode( Key )
				else
					default = 0
				end
			end
		else
			default = 0
		end

		data.default = default

		table.insert( LVS.KEYS_REGISTERED, data )

		CreateClientConVar( cmd, default, true, true )
	end
end

function LVS:CheckUpdates()
	http.Fetch("https://raw.githubusercontent.com/SpaxscE/lvs_base/main/lua/autorun/lvs_init.lua", function(contents,size) 
		local Entry = string.match( contents, "LVS.VERSION%s=%s%d+" )

		if Entry then
			LVS.VERSION_GITHUB = tonumber( string.match( Entry , "%d+" ) ) or 0
		else
			LVS.VERSION_GITHUB = 0
		end

		if LVS.VERSION_GITHUB == 0 then
			print("[LVS] - Framework: latest version could not be detected, You have Version: "..LVS:GetVersion())
		else
			if LVS:GetVersion() >= LVS.VERSION_GITHUB then
				print("[LVS] - Framework is up to date, Version: "..LVS:GetVersion())
			else
				print("[LVS] - Framework: a newer version is available! Version: "..LVS.VERSION_GITHUB..", You have Version: "..LVS:GetVersion())

				if LVS.VERSION_TYPE == ".GIT" then
					print("[LVS] - Framework: get the latest version at https://github.com/SpaxscE/lvs_base")
				else
					print("[LVS] - Framework: restart your game/server to get the latest version!")
				end

				if CLIENT then 
					timer.Simple(18, function() 
						chat.AddText( Color( 255, 0, 0 ), "[LVS] - Framework: a newer version is available!" )
					end)
				end
			end
		end

		local Delay = 0
		local addons = file.Find( "data_static/lvs/*", "GAME" )

		for _, addonFile in pairs( addons ) do
			local addonInfo = file.Read( "data_static/lvs/"..addonFile, "GAME" )

			if not addonInfo then continue end

			local data = string.Explode( "\n", addonInfo )

			local wsid = string.Replace( addonFile, ".txt", "" )
			local addon_name = wsid
			local addon_url
			local addon_version

			for _, entry in pairs( data ) do
				if string.StartsWith( entry, "url=" ) then
					addon_url = string.Replace( entry, "url=", "" )
				end

				if string.StartsWith( entry, "version=" ) then
					addon_version = string.Replace( entry, "version=", "" )
				end

				if string.StartsWith( entry, "name=" ) then
					addon_name = string.Replace( entry, "name=", "" )
				end
			end

			if not addon_url or not addon_version then continue end

			addon_version = tonumber( addon_version )

			Delay = Delay + 1.5

			timer.Simple( Delay, function()
				http.Fetch(addon_url, function(con,_) 
					local addon_entry = string.match( con, "version=%d+" )

					local addon_version_git = 0

					if addon_entry then
						addon_version_git = tonumber( string.match( addon_entry, "%d+" ) ) or 0
					end

					local wsurl = "https://steamcommunity.com/sharedfiles/filedetails/?id="..wsid

					if addon_version_git == 0 then
						print("[LVS] latest version of "..addon_name.." ( "..wsurl.." ) could not be detected, You have Version: "..addon_version)
					else
						if addon_version_git > addon_version then
							print("[LVS] - "..addon_name.." ( "..wsurl.." ) is out of date!")

							if CLIENT then 
								timer.Simple(18, function() 
									chat.AddText( Color( 255, 0, 0 ),"[LVS] - "..addon_name.." is out of date!" )
								end)
							end

							LVS.VERSION_ADDONS_OUTDATED = true

						else
							print("[LVS] - "..addon_name.." is up to date, Version: "..addon_version)
						end
					end
				end)
			end )
		end
	end)
end

function LVS:GetWeaponPreset( name )
	if not LVS.WEAPONS[ name ] then return table.Copy( LVS.WEAPONS["DEFAULT"] ) end

	return table.Copy( LVS.WEAPONS[ name ] )
end

function LVS:AddWeaponPreset( name, data )
	if not isstring( name ) or not istable( data ) then return end

	LVS.WEAPONS[ name ] = data
end

function LVS:GetVehicleTypes()
	local VehicleTypes = {}

	for s, v in pairs( scripted_ents.GetList() ) do
		if not v.t or not isfunction( v.t.GetVehicleType ) then continue end

		local vehicletype = v.t:GetVehicleType()

		if not isstring( vehicletype ) or string.StartsWith( vehicletype, "LBase" ) or table.HasValue( VehicleTypes, vehicletype ) then continue end

		table.insert( VehicleTypes, vehicletype )
	end

	return VehicleTypes
end

AddCSLuaFile("lvs_framework/init.lua")
include("lvs_framework/init.lua")