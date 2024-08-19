
========================================
=========== LVS HOOKS SHARED ===========
========================================


list.Set( "VehiclePrices", "lvs_wheeldrive_dodtiger", 9999 ) -- set price for tiger tank to 9999




hook.Add( "LVS.OnPlayerSelectVehicle", "any_name_you_want", function( ply, class )
	if class == "lvs_trailer_flak" then  -- disallow spawning of flak
		return true   -- return true to prevent
	end
end )



========================================
========== LVS HOOKS SERVER  ===========
========================================

hook.Add( "LVS.PlayerLoadoutWeapons", "any_name_you_want", function( ply, class )
	return true  -- return true prevent giving of standard weapons
end )


hook.Add( "LVS.PlayerLoadoutTools", "any_name_you_want", function( ply, class )
	return true  -- return true prevent giving of standard tools
end )



========================================
=========== LVS HOOKS CLIENT ===========
========================================

local hide = {
	["LVSHudHealth"] = true, -- disable default player health hud
	["LVSHudAmmo"] = true, -- disable default player armor hud
	["LVSHudMoney"] = true, -- disable showing money info
}
hook.Add( "HUDShouldDraw", "HideHUD", function( name )
	if hide[ name ] then
		return false
	end
end )
