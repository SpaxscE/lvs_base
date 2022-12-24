
ENT.WEAPONS = {}

function ENT:GetActiveWeapon()
	local SelectedID = self:GetSelectedWeapon()
	local CurWeapon = self.WEAPONS[ SelectedID ]

	return CurWeapon, SelectedID
end

function ENT:GetMaxAmmo()
	local CurWeapon = self:GetActiveWeapon()

	return CurWeapon.Ammo or -1
end

if SERVER then
	util.AddNetworkString( "lvs_select_weapon" )

	net.Receive( "lvs_select_weapon", function( length, ply )
		if not IsValid( ply ) then return end

		local ID = net.ReadInt( 5 )

		local vehicle = ply:lvsGetVehicle()

		if not IsValid( vehicle ) or vehicle:GetDriver() ~= ply then return end

		vehicle:SelectWeapon( ID )
	end)

	function ENT:WeaponsFinish()
		if not self._activeWeapon then return end

		local CurWeapon = self.WEAPONS[ self._activeWeapon ]

		if not CurWeapon then return end

		if CurWeapon.FinishAttack then
			CurWeapon.FinishAttack( self )
		end

		self._activeWeapon = nil
		self.OldAttack = false
	end

	function ENT:GetAmmo()
		if self:GetAI() then return self:GetMaxAmmo() end

		local CurWeapon = self:GetActiveWeapon()

		if not CurWeapon then return -1 end

		return CurWeapon._CurAmmo or self:GetMaxAmmo()
	end

	function ENT:TakeAmmo()
		if self:GetMaxAmmo() <= 0 then return end

		local CurWeapon = self:GetActiveWeapon()

		CurWeapon._CurAmmo = self:GetAmmo() - 1

		self:SetNWAmmo( CurWeapon._CurAmmo )
	end

	function ENT:CanAttack()
		local CurWeapon = self:GetActiveWeapon()

		return (CurWeapon._NextFire or 0) < CurTime()
	end

	function ENT:SetNextAttack( time )
		local CurWeapon = self:GetActiveWeapon()

		CurWeapon._NextFire = time
	end

	function ENT:WeaponsShouldFire()
		if self:GetAI() then return self._AIFireInput end

		local ply = self:GetDriver()

		if not IsValid( ply ) then return false end

		return ply:lvsKeyDown( "ATTACK" )
	end

	function ENT:WeaponsThink()
		local T = CurTime()
		local FT = FrameTime()
		local CurWeapon, SelectedID = self:GetActiveWeapon()
	
		for ID, Weapon in pairs( self.WEAPONS ) do
			local IsActive = ID == SelectedID
			if Weapon.OnThink then Weapon.OnThink( self, IsActive ) end

			if IsActive then continue end

			Weapon._CurHeat = Weapon._CurHeat and Weapon._CurHeat - math.min( Weapon._CurHeat, (Weapon.HeatRateDown or 0.25) * FT ) or 0
		end

		if not CurWeapon then return end

		local ShouldFire = self:WeaponsShouldFire()

		if CurWeapon.Overheated then
			if CurWeapon._CurHeat <= 0 then
				CurWeapon.Overheated = false
			else
				ShouldFire = false
			end
		else
			if (CurWeapon._CurHeat or 0) >= 1 then
				CurWeapon.Overheated = true
				ShouldFire = false
			end
		end

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

			local ShootDelay = (CurWeapon.Delay or 0)

			self:SetNextAttack( CurTime() + ShootDelay )

			CurWeapon._CurHeat = math.min( (CurWeapon._CurHeat or 0) + (CurWeapon.HeatRateUp or 0.2) * math.max(ShootDelay, FT), 1)
			self:SetNWHeat( CurWeapon._CurHeat )

			CurWeapon.Attack( self )

			self:TakeAmmo()
		else
			CurWeapon._CurHeat = CurWeapon._CurHeat and CurWeapon._CurHeat - math.min( CurWeapon._CurHeat, (CurWeapon.HeatRateDown or 0.25) * FT ) or 0

			if self:GetNWHeat() == CurWeapon._CurHeat then return end

			self:SetNWHeat( CurWeapon._CurHeat )
		end
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
			self:SetNWAmmo( NextWeapon._CurAmmo or NextWeapon.Ammo or -1 )
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

	LVS:AddHudEditor( "WeaponInfo", ScrW() - 230, ScrH() - 85,  220, 75, 220, 75, "WEAPON INFO", 
		function( self, vehicle, X, Y, W, H, ScrX, ScrY, ply )
			if not vehicle.LVSHudPaintWeaponInfo then return end

			if ply ~= vehicle:GetDriver() then return end

			vehicle:LVSHudPaintWeaponInfo( X, Y, W, H, ScrX, ScrY, ply )
		end
	)

	function ENT:GetAmmoID( ID )
		local selected = self:GetSelectedWeapon()
		local weapon = self.WEAPONS[ ID ]

		if ID == selected then
			weapon._CurAmmo = self:GetNWAmmo()
		else
			weapon._CurAmmo = weapon._CurAmmo or weapon.Ammo or -1
		end

		return weapon._CurAmmo
	end


	local Circles = {
		[1] = {r = -1, col = Color(0,0,0,200)},
		[2] = {r = 0, col = Color(255,255,255,200)},
		[3] = {r = 1, col = Color(255,255,255,255)},
		[4] = {r = 2, col = Color(255,255,255,200)},
		[5] = {r = 3, col = Color(0,0,0,200)},
	}

	local function DrawCircle( X, Y, target_radius, heatvalue )
		local endang = 360 * heatvalue

		if endang == 0 then return end

		for i = 1, #Circles do
			local data = Circles[ i ]
			local radius = target_radius + data.r
			local segmentdist = endang / ( math.pi * radius / 2 )

			for a = 0, endang, segmentdist do
				local r = data.col.r
				local g = data.col.g * (1 - math.min(a / 270,1))
				local b = data.col.b * (1 - math.min(a / 90,1))

				surface.SetDrawColor( r, g, b, data.col.a )

				surface.DrawLine( X - math.sin( math.rad( a ) ) * radius, Y + math.cos( math.rad( a ) ) * radius, X - math.sin( math.rad( a + segmentdist ) ) * radius, Y + math.cos( math.rad( a + segmentdist ) ) * radius )
			end
		end
	end

	ENT.HeatMat = Material( "lvs/heat.png" )

	function ENT:LVSHudPaintWeaponInfo( X, Y, w, h, ScrX, ScrY, ply )
		local Heat = self:GetNWHeat()
		local hX = X + w - h * 0.5
		local hY = Y + h * 0.25 + h * 0.25
		local hAng = math.cos( CurTime() * 50 ) * 5 * Heat ^ 2

		surface.SetMaterial( self.HeatMat )
		surface.SetDrawColor( 0, 0, 0, 200 )
		surface.DrawTexturedRectRotated( hX + 4, hY + 1, h * 0.5, h * 0.5, hAng )
		surface.SetDrawColor( 255, 255 * (1 - Heat), 255 * math.max(1 - Heat * 1.5,0), 255 )
		surface.DrawTexturedRectRotated( hX + 2, hY - 1, h * 0.5, h * 0.5, hAng )

		DrawCircle( hX, hY, h * 0.35, Heat )

		if self:GetMaxAmmo() <= 0 then return end

		draw.DrawText( "AMMO ", "LVS_FONT", X + 80, Y + 35, color_white, TEXT_ALIGN_RIGHT )
		draw.DrawText( self:GetNWAmmo(), "LVS_FONT_HUD_LARGE", X + 80, Y + 20, color_white, TEXT_ALIGN_LEFT )
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
		local tAlphaRate = FT * 15

		self.smAlphaSW = self.smAlphaSW and (self.smAlphaSW + math.Clamp(tAlpha - self.smAlphaSW,-tAlphaRate,tAlphaRate)) or 0

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

			local ammo = self:GetAmmoID( ID )

			if ammo > -1 then
				draw.DrawText( ammo, "LVS_FONT_HUD", xPos + w - 10, yPos + SizeY * 0.5 - 10, IsSelected and Color(0,0,0,A255) or Color(255,255,255,A255), TEXT_ALIGN_RIGHT )
			end
		end
	end
end