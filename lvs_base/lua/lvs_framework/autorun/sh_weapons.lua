
local meta = FindMetaTable( "Vehicle" )

if CLIENT then
	function meta:lvsGetWeapon()
		if self._lvsWeaponEntChecked then
			return self._lvsWeaponEnt
		end

		local found = false

		for _, ent in ipairs( self:GetChildren() ) do
			if not ent.LVS_GUNNER then continue end

			self._lvsWeaponEntChecked = true
			self._lvsWeaponEnt = ent

			found = true

			break
		end

		return found and self._lvsWeaponEnt or NULL
	end

	net.Receive( "lvs_select_weapon", function( length)
		local ply = LocalPlayer()
		local vehicle = ply:lvsGetVehicle()

		if not IsValid( vehicle ) or vehicle:GetDriver() ~= ply then return end

		vehicle._SelectActiveTime = CurTime() + 2
	end)

	return
end

util.AddNetworkString( "lvs_select_weapon" )

net.Receive( "lvs_select_weapon", function( length, ply )
	if not IsValid( ply ) then return end

	local ID = net.ReadInt( 5 )

	local base = ply:lvsGetWeaponHandler()

	if not IsValid( base ) then return end

	base:SelectWeapon( ID )
end)

function meta:lvsAddWeapon( ID )
	if IsValid( self._lvsWeaponEnt ) then
		return self._lvsWeaponEnt
	end

	local weapon = ents.Create( "lvs_base_gunner" )

	if not IsValid( weapon ) then return NULL end

	weapon:SetPos( self:LocalToWorld( Vector(0,0,33.182617) ) ) -- location exactly where ply:GetShootPos() is. This will make AI-Tracing easier.
	weapon:SetAngles( self:GetAngles() )
	weapon:SetOwner( self )
	weapon:Spawn()
	weapon:Activate()
	weapon:SetParent( self )
	weapon:SetPodIndex( ID )
	weapon:SetDriverSeat( self )

	self._lvsWeaponEnt = weapon

	weapon:SetSelectedWeapon( 1 )

	return weapon
end

function meta:lvsGetWeapon()
	return self._lvsWeaponEnt
end
