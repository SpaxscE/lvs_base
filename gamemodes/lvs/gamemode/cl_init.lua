include( "shared.lua" )
include( "cl_hud.lua" )
include( "cl_join.lua" )
include( "cl_scoreboard.lua" )
include( "cl_playereditor.lua" )
include( "buymenu/cl_buymenu.lua" )
include( "buymenu/cl_buymenu_button.lua" )

function GM:InitPostEntity()
	self:BuildVehiclePrices()
end

local ColFriend = GM.ColorFriend
local ColEnemy = GM.ColorEnemy

function GM:GetTeamColor( ent )

	local team = TEAM_UNASSIGNED
	if ( ent.Team ) then team = ent:Team() end

	if team == TEAM_SPECTATOR or not ent.lvsGetAITeam then
		return GAMEMODE:GetTeamNumColor( team )
	end

	return (LocalPlayer():lvsGetAITeam() == ent:lvsGetAITeam()) and ColFriend or ColEnemy
end


local meta = FindMetaTable( "Player" )

local ColFriend = GM.ColorFriend
local ColEnemy = GM.ColorEnemy

local ColFriendCool = GM.ColorFriendDark
local ColEnemyCool = GM.ColorEnemyDark

function meta:GetPlayerColor()
	local Team = self:lvsGetAITeam()

	if Team == 0 or Team == 3 then
		return Vector(1,1,1)
	end

	local ply = LocalPlayer()

	if ply:Team() == TEAM_SPECTATOR then
		if Team == 1 then
			return Vector( ColFriendCool.r / 255, ColFriendCool.g / 255, ColFriendCool.b / 255 )
		else
			return Vector( ColEnemyCool.r / 255, ColEnemyCool.g / 255, ColEnemyCool.b / 255 )
		end
	end

	if Team == ply:lvsGetAITeam() then
		return Vector( ColFriendCool.r / 255, ColFriendCool.g / 255, ColFriendCool.b / 255 )
	end

	return Vector( ColEnemyCool.r / 255, ColEnemyCool.g / 255, ColEnemyCool.b / 255 )
end

hook.Add( "PreDrawHalos", "lvs_current_vehicle_halo", function()
	local ply = LocalPlayer()

	if not IsValid( ply ) or ply:InVehicle() then return end

	local weapon = ply:GetActiveWeapon()

	if not IsValid( weapon ) then return end

	if weapon:GetClass() ~= "weapon_lvsvehicles" then return end

	local veh = ply:GetNWEntity( "lvs_current_spawned_vehicle" )

	if not IsValid( veh ) then return end

	halo.Add( { veh }, ColFriend, 3, 3, 2, true, true )
end )