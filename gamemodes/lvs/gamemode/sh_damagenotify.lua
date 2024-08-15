if SERVER then
	util.AddNetworkString( "lvs_player_hitmarker" )
	util.AddNetworkString( "lvs_player_killmarker" )

	include("sv_killreactions.lua")

	hook.Add( "EntityTakeDamage", "!!!lvs_basegun_hitmarker", function( target, dmginfo )
		local attacker = dmginfo:GetAttacker()

		if not IsValid( attacker ) or not attacker:IsPlayer() or attacker == target then return end

		local attacker_team = attacker:lvsGetAITeam()

		if not target:IsPlayer() then
			if not isfunction( target.GetAITEAM ) or (target.IsFortification and not target._lvsPlayerSpawnPoint) then return end

			if attacker_team == target:GetAITEAM() then
				dmginfo:ScaleDamage( 0.01 )
			end

			return
		end

		if not target:Alive() then return end

		if attacker_team == target:lvsGetAITeam() then dmginfo:ScaleDamage( 0.01 ) return end

		local Health = target:Health() + target:Armor()
		local Damage = dmginfo:GetDamage()

		if Health < Damage then return end

		net.Start("lvs_player_hitmarker")
		net.Send( attacker )
	end )

	hook.Add( "PlayerDeath", "!!!lvs_basegun_killmarker", function( victim, inflictor, attacker )
		if victim == attacker or not attacker:IsPlayer() then return end

		if attacker:lvsGetAITeam() == victim:lvsGetAITeam() then
			GAMEMODE:OnPlayerKillOtherPlayer( attacker, victim, true )

			return
		end

		GAMEMODE:OnPlayerKillOtherPlayer( attacker, victim, false )

		net.Start("lvs_player_killmarker")
		net.Send( attacker )
	end )

	return
end

local function GetHitMarker()
	return LocalPlayer().LastHitMarker or 0
end

local function GetKillMarker()
	return LocalPlayer().LastKillMarker or 0
end

local function HitMarker()
	local ply = LocalPlayer()

	ply.LastHitMarker = CurTime() + 0.4

	if not ply:InVehicle() then return end

	ply:EmitSound( "npc/sniper/echo1.wav", 140, 255, 0.25, CHAN_ITEM )
end

local function KillMarker()
	local ply = LocalPlayer()

	ply.LastKillMarker = CurTime() + 0.8

	if ply:InVehicle() then
		ply:EmitSound( "npc/roller/blade_cut.wav", 140, 255, 0.5, CHAN_ITEM2 )

		return
	end

	ply:EmitSound( "npc/roller/blade_cut.wav", 140, 255, 0.75, CHAN_ITEM2 )
end

net.Receive( "lvs_player_hitmarker", function( len )
	if not LVS.ShowHitMarker then return end

	HitMarker()
end )

net.Receive( "lvs_player_killmarker", function( len )
	if not LVS.ShowHitMarker then return end

	KillMarker()
end )

function GM:HUDPaintHitMarker( scr )
	local X = scr.x
	local Y = scr.y

	local T = CurTime()

	local aV = math.min( (GetKillMarker() - T) / 0.8, 1 )
	if aV > 0.01 then
		local Size = 5
		local Start = math.sin( math.rad( -90 + aV * 90 ) ) * 400

		surface.SetDrawColor( 255, 0, 0, 255 * aV )
		surface.DrawRect( X + Start, Y + Start, Size, Size )
		surface.DrawRect( X - Start - Size, Y + Start, Size, Size )

		surface.DrawRect( X + Start, Y - Start - Size, Size, Size )
		surface.DrawRect( X - Start - Size, Y - Start - Size, Size, Size )

		surface.DrawRect( X + Start * 0.5, Y + Start, Size, Size )
		surface.DrawRect( X - (Start - Size) * 0.5, Y + Start, Size, Size )

		surface.DrawRect( X + Start * 0.5, Y - Start - Size, Size, Size )
		surface.DrawRect( X - (Start - Size) * 0.5, Y - Start - Size, Size, Size )

		surface.DrawRect( X + Start, Y + Start * 0.5, Size, Size )
		surface.DrawRect( X - Start - Size, Y + Start * 0.5, Size, Size )

		surface.DrawRect( X + Start, Y - (Start - Size) * 0.5, Size, Size )
		surface.DrawRect( X - Start - Size, Y - (Start - Size) * 0.5, Size, Size )
	else
		aV = math.min( (GetHitMarker() - T) / 0.4, 1 )

		if aV > 0.01 then
			local Size = 4
			local Start = math.sin( math.rad( -90 + aV * 90 ) ) * 200

			surface.SetDrawColor( 255, 150, 0, 255 * aV )

			surface.DrawRect( X + Start, Y + Start, Size, Size )
			surface.DrawRect( X - Start - Size, Y + Start, Size, Size )

			surface.DrawRect( X + Start, Y - Start - Size, Size, Size )
			surface.DrawRect( X - Start - Size, Y - Start - Size, Size, Size )

			surface.DrawRect( X + Start * 0.5, Y + Start, Size, Size )
			surface.DrawRect( X - (Start - Size) * 0.5, Y + Start, Size, Size )

			surface.DrawRect( X + Start * 0.5, Y - Start - Size, Size, Size )
			surface.DrawRect( X - (Start - Size) * 0.5, Y - Start - Size, Size, Size )

			surface.DrawRect( X + Start, Y + Start * 0.5, Size, Size )
			surface.DrawRect( X - Start - Size, Y + Start * 0.5, Size, Size )

			surface.DrawRect( X + Start, Y - (Start - Size) * 0.5, Size, Size )
			surface.DrawRect( X - Start - Size, Y - (Start - Size) * 0.5, Size, Size )
		end
	end
end
