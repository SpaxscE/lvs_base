
ENT._WEAPONS = {
	[1] = Material("lvs_weapons/hmg.png"),
	[2] = Material("lvs_weapons/mg.png"),
	[3] = Material("lvs_weapons/nos.png"),
	[4] = Material("lvs_weapons/missile.png"),
}

if SERVER then
	util.AddNetworkString( "lvs_select_weapon" )

	net.Receive( "lvs_select_weapon", function( length, ply )
		if not IsValid( ply ) then return end

		local ID = net.ReadInt( 5 )

		local vehicle = ply:lvsGetVehicle()

		if not IsValid( vehicle ) or vehicle:GetDriver() ~= ply then return end

		vehicle:SelectWeapon( ID )
	end)

	function ENT:SelectWeapon( ID )
		if not isnumber( ID ) then return end

		if self._WEAPONS[ ID ] then
			self:SetSelectedWeapon( ID )
		end
	end

	function ENT:OnWeaponChanged( name, old, new)
		if new == old then return end
	end
else
	function ENT:SelectWeapon( ID )
		if not isnumber( ID ) then return end

		net.Start( "lvs_select_weapon" )
			net.WriteInt( ID, 5 )
		net.SendToServer()
	end
end