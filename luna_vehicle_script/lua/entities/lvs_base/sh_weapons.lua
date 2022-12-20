
ENT.WEAPONS = {}

if SERVER then
	util.AddNetworkString( "lvs_select_weapon" )

	net.Receive( "lvs_select_weapon", function( length, ply )
		if not IsValid( ply ) then return end

		local ID = net.ReadInt( 5 )

		local vehicle = ply:lvsGetVehicle()

		if not IsValid( vehicle ) or vehicle:GetDriver() ~= ply then return end

		vehicle:SelectWeapon( ID )
	end)

	function ENT:GetActiveWeapon()
		local SelectedID = self:GetSelectedWeapon()
		local CurWeapon = self.WEAPONS[ SelectedID ]

		return CurWeapon, SelectedID
	end

	function ENT:WeaponsFinish()
		if not self._activeWeapon then return end

		local CurWeapon = self.WEAPONS[ self._activeWeapon ]

		if not CurWeapon then return end

		if CurWeapon.FinishAttack then
			CurWeapon.FinishAttack( self )
		end

		self._activeWeapon = nil
	end

	function ENT:WeaponUpdateNW()
		local CurWeapon = self:GetActiveWeapon()

		if not CurWeapon then return end

		self:SetNWAmmo( CurWeapon._CurAmmo or self:GetMaxAmmo() )
	end

	function ENT:GetMaxAmmo()
		local CurWeapon = self:GetActiveWeapon()

		return CurWeapon.Ammo
	end

	function ENT:GetAmmo()
		local CurWeapon = self:GetActiveWeapon()

		return CurWeapon._CurAmmo or self:GetMaxAmmo()
	end

	function ENT:TakeAmmo()
		local CurWeapon = self:GetActiveWeapon()

		CurWeapon._CurAmmo = self:GetAmmo() - 1
	end

	function ENT:CanAttack()
		local CurWeapon = self:GetActiveWeapon()

		return (CurWeapon._NextFire or 0) < CurTime()
	end

	function ENT:SetNextAttack( time )
		local CurWeapon = self:GetActiveWeapon()

		CurWeapon._NextFire = time
	end

	function ENT:WeaponsThink()
		local CurWeapon, SelectedID = self:GetActiveWeapon()
	
		for ID, Weapon in pairs( self.WEAPONS ) do
			if Weapon.OnThink then
				Weapon.OnThink( self, ID == SelectedID )
			end
		end

		local ply = self:GetDriver()

		if not IsValid( ply ) then return end

		if not CurWeapon then return end

		local ShouldFire = ply:lvsKeyDown( "ATTACK" )

		if self:GetMaxAmmo() > 0 then
			if self:GetAmmo() <= 0 then
				ShouldFire = false
			end
		end

		if ShouldFire ~= self.OldAttack then
			self.OldAttack = ShouldFire

			if ShouldFire then
				if CurWeapon.StartAttack then
					CurWeapon.StartAttack( self )
				end
				self._activeWeapon = SelectedID
			else
				self:WeaponsFinish()
			end
		end

		if ShouldFire then
			if not self:CanAttack() then return end

			self:SetNextAttack( CurTime() + CurWeapon.Delay )

			CurWeapon.Attack( self )

			self:TakeAmmo()
		end

		self:WeaponUpdateNW()
	end

	function ENT:SelectWeapon( ID )
		if not isnumber( ID ) then return end

		if self.WEAPONS[ ID ] then
			self:SetSelectedWeapon( ID )
		end

		local ply = self:GetDriver()

		if not IsValid( ply ) then return end

		net.Start( "lvs_select_weapon" )
		net.Send( ply )
	end

	function ENT:OnWeaponChanged( name, old, new)
		if new == old then return end

		self:WeaponsFinish()

		local PrevWeapon = self.WEAPONS[ old ]
		if PrevWeapon and PrevWeapon.OnDeselect then
			PrevWeapon.OnDeselect( self )
		end

		local NextWeapon = self.WEAPONS[ new ]
		if NextWeapon and NextWeapon.OnSelect then
			NextWeapon.OnSelect( self )
		end
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

	LVS:AddHudEditor( "WeaponInfo", ScrW() - 210, ScrH() - 85,  200, 75, 200, 75, "WEAPON INFO", 
		function( self, vehicle, X, Y, W, H, ScrX, ScrY, ply )
			if not vehicle.LVSHudPaintWeaponInfo then return end

			if ply ~= vehicle:GetDriver() then return end

			vehicle:LVSHudPaintWeaponInfo( X, Y, W, H, ScrX, ScrY, ply )
		end
	)

	function ENT:LVSHudPaintWeaponInfo( X, Y, w, h, ScrX, ScrY, ply )
		draw.RoundedBox(5, X, Y, w, h, Color(0,0,0,150) )

		draw.DrawText( self:GetNWAmmo(), "TargetID", X + 50, Y, color_white, TEXT_ALIGN_CENTER )
		draw.DrawText( self:GetNWHeat(), "TargetID", X + 90, Y + 40, color_white, TEXT_ALIGN_CENTER )
	end

	function ENT:LVSHudPaintWeapons( X, Y, w, h, ScrX, ScrY, ply )
		local num = #self.WEAPONS

		if num <= 1 then return end

		local CenterY = (Y + h * 0.5)
		local CenterX = (X + w * 0.5)

		local FlatSelector = CenterX > ScrX * 0.333 and CenterX < ScrX * 0.666

		local T = CurTime()
		local FT = RealFrameTime()

		local gap = 4
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
			surface.SetMaterial( self.WEAPONS[ID].Icon )
			surface.DrawTexturedRect( xPos, yPos, SizeY * 2, SizeY )
		end
	end
end