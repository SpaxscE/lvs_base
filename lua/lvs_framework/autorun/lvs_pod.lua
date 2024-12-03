
local meta = FindMetaTable( "Vehicle" )

if CLIENT then
	function meta:lvsGetPodIndex()
		local id = self:GetNWInt( "pPodIndex", -1 )

		if id ~= -1 then return id end

		-- code below is bandaid fix for ent:GetNWInt taking up to 5 minutes to update on client...

		local mat = self:GetMaterial()

		-- material is more reliable than ent:GetNWInt... unless someone has changed it on client...
		if string.StartsWith(mat, "podindexlvs") then

			local id_by_material = tonumber( string.TrimLeft( mat, "podindexlvs" ) )

			if id_by_material then return id_by_material end
		end

		local col = self:GetColor()
		local id_by_color = col.r

		-- 255 or 0 is suspicous...
		if id_by_color == 255 or id_by_color == 0 then return -1 end

		-- lets just assume its right... right?
		if id_by_color == col.g and id_by_color == col.b then
			return id_by_color
		end

		return -1
	end

	function meta:GetCameraHeight()
		if not self._lvsCamHeight then
			self._lvsCamHeight = 0

			net.Start("lvs_camera")
				net.WriteEntity( self )
			net.SendToServer()
		end

		return self._lvsCamHeight
	end

	function meta:SetCameraHeight( newheight )
		self._lvsCamHeight = newheight
	end

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

	
	net.Receive( "lvs_camera", function( length, ply )
		local pod = net.ReadEntity()

		if not IsValid( pod ) then return end

		pod:SetCameraHeight( net.ReadFloat() )
	end)

	return
end

function meta:lvsGetPodIndex()
	return self:GetNWInt( "pPodIndex", -1 )
end

function meta:GetCameraHeight()
	return (self._lvsCamHeight or 0)
end

util.AddNetworkString( "lvs_select_weapon" )
util.AddNetworkString( "lvs_camera" )

net.Receive( "lvs_select_weapon", function( length, ply )
	if not IsValid( ply ) then return end

	local ID = net.ReadInt( 5 )
	local Increment = net.ReadBool()

	local base = ply:lvsGetWeaponHandler()

	if not IsValid( base ) then return end

	if Increment then
		base:SelectWeapon( base:GetSelectedWeapon() + ID )
	else
		base:SelectWeapon( ID )
	end
end)

net.Receive( "lvs_camera", function( length, ply )
	if not IsValid( ply ) then return end

	local pod = net.ReadEntity()

	if not IsValid( pod ) then return end

	net.Start("lvs_camera")
		net.WriteEntity( pod )
		net.WriteFloat( pod:GetCameraHeight() )
	net.Send( ply )
end)

function meta:SetCameraHeight( newheight )
	self._lvsCamHeight = newheight

	net.Start("lvs_camera")
		net.WriteEntity( self )
		net.WriteFloat( newheight )
	net.Broadcast()
end

function meta:lvsAddWeapon( ID )
	if IsValid( self._lvsWeaponEnt ) then
		return self._lvsWeaponEnt
	end

	local weapon = ents.Create( "lvs_base_gunner" )

	if not IsValid( weapon ) then return NULL end

	weapon:SetPos( self:LocalToWorld( Vector(0,0,33.182617) ) ) -- location exactly where ply:GetShootPos() is. This will make AI-Tracing easier.
	weapon:SetAngles( self:LocalToWorldAngles( Angle(0,90,0) ) )
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

function meta:lvsSetPodIndex( index )
	-- garbage networking
	self:SetNWInt( "pPodIndex", index )

	-- more reliable networking, lol
	self:SetMaterial( "podindexlvs"..index )
	self:SetColor( Color( index, index, index, 0 ) )
end
