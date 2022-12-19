
ENT._WEAPONS = {
	[1] = {
		Icon = Material("lvs_weapons/hmg.png"),
		UseHeat = true,
		OnFire = function( vehicle ) end,
		OnSelect = function( vehicle ) end,
		OnDeselect = function( vehicle ) end,
		OnRemove = function( vehicle ) end,
		OnThink = function( vehicle ) end,
	},
	[2] = {
		Icon = Material("lvs_weapons/mg.png"),
	},
	[3] = {
		Icon = Material("lvs_weapons/nos.png"),
	},
	[4] = {
		Icon = Material("lvs_weapons/bomb.png"),
	},
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

		local ply = self:GetDriver()

		if not IsValid( ply ) then return end

		net.Start( "lvs_select_weapon" )
		net.Send( ply )
	end

	function ENT:OnWeaponChanged( name, old, new)
		if new == old then return end
	end
else
	net.Receive( "lvs_select_weapon", function( length)
		local ply = LocalPlayer()
		local vehicle = ply:lvsGetVehicle()

		if not IsValid( vehicle ) or vehicle:GetDriver() ~= ply then return end

		vehicle._SelectActiveTime = CurTime() + 2
	end)

	function ENT:SelectWeapon( ID )
		if not isnumber( ID ) then return end

		net.Start( "lvs_select_weapon" )
			net.WriteInt( ID, 5 )
		net.SendToServer()
	end

	LVS:AddHudEditor( "WeaponSwitcher", ScrW() - 210, ScrH() - 165,  200, 68, 200, 68, "WEAPON SELECTOR", 
		function( self, vehicle, X, Y, W, H, ScrX, ScrY, ply )
			if not vehicle.LVSHudPaintWeapons then return end

			if ply ~= vehicle:GetDriver() then return end

			vehicle:LVSHudPaintWeapons( X, Y, W, H, ScrX, ScrY, ply )
		end
	)

	function ENT:LVSHudPaintWeapons( X, Y, w, h, ScrX, ScrY, ply )
		local CenterY = (Y + h * 0.5)
		local CenterX = (X + w * 0.5)

		local FlatSelector = CenterX > ScrX * 0.333 and CenterX < ScrX * 0.666

		local T = CurTime()
		local FT = RealFrameTime()

		local gap = 4
		local num = #self._WEAPONS
		local SizeY = h - gap

		local Selected = self:GetSelectedWeapon()
		if Selected ~= self._OldSelected then
			self._OldSelected = Selected
			self._SelectActiveTime = T + 2
		end

		local tAlpha = (self._SelectActiveTime or 0) > T and 1 or 0
		local tAlphaRateUp = FT * 30
		local tAlphaRateDn = FT * 15

		self.smAlphaSW = self.smAlphaSW and (self.smAlphaSW + math.Clamp(tAlpha - self.smAlphaSW,-tAlphaRateDn,tAlphaRateUp)) or 0

		if self.smAlphaSW > 0.95 then
			self._DisplaySelected = Selected
		else
			self._DisplaySelected = self._DisplaySelected or Selected
		end

		local A255 = 255 * self.smAlphaSW
		local A150 = 150 * self.smAlphaSW
	
		local Col = Color(0,0,0,A150)
		local ColSelect = Color(255,255,255,A150)

		local SwapY = 0

		if Y < (ScrY * 0.5 - h * 0.5) then
			SwapY = 1
		end

		for ID = 1, num do
			local IsSelected = self._DisplaySelected == ID
			local n = num - ID
			local xPos = FlatSelector and X + (w + gap) * (ID - 1) - ((w + gap) * 0.5 * num - w * 0.5) or X
			local yPos = FlatSelector and Y - h * math.min(SwapY,0) or Y - h * n + (num - 1) * h * SwapY

			draw.RoundedBox(5, xPos, yPos, w, SizeY, IsSelected and ColSelect or Col )

			if IsSelected then
				surface.SetDrawColor( 0, 0, 0, A255 )
			else
				surface.SetDrawColor( 255, 255, 255, A255 )
			end
			surface.SetMaterial( self._WEAPONS[ID].Icon )
			surface.DrawTexturedRect( xPos, yPos, SizeY * 2, SizeY )
		end
	end
end