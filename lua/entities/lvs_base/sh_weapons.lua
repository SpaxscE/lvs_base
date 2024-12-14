
ENT.WEAPONS = {
	[1] = {},
}

function ENT:InitWeapons()
end

function ENT:AddWeapon( weaponData, PodID )
	if not istable( weaponData ) then print("[LVS] couldn't register weapon") return end

	local data = table.Copy( weaponData )

	if not PodID or PodID <= 1 then
		PodID = 1
	end

	if not self.WEAPONS[ PodID ] then
		self.WEAPONS[ PodID ] = {}
	end

	local default = LVS:GetWeaponPreset( "DEFAULT" )

	data.Icon = data.Icon or Material("lvs/weapons/bullet.png")
	data.Ammo = data.Ammo or -1
	data.Delay = data.Delay or 0
	data.HeatIsClip = data.HeatIsClip == true
	data.HeatRateUp = data.HeatRateUp or default.HeatRateUp
	data.HeatRateDown = data.HeatRateDown or default.HeatRateDown
	data.Attack = data.Attack or default.Attack
	data.StartAttack = data.StartAttack or default.StartAttack
	data.FinishAttack = data.FinishAttack or default.FinishAttack
	data.OnSelect = data.OnSelect or default.OnSelect
	data.OnDeselect = data.OnDeselect or default.OnDeselect
	data.OnThink = data.OnThink or default.OnThink
	data.OnOverheat = data.OnOverheat or default.OnOverheat
	data.OnRemove = data.OnRemove or default.OnRemove
	data.UseableByAI = data.UseableByAI ~= false

	table.insert( self.WEAPONS[ PodID ], data )
end

function ENT:UpdateWeapon( PodID, WeaponID, weaponData )
	if not self.WEAPONS[ PodID ] then return end

	if not self.WEAPONS[ PodID ][ WeaponID ] then return end

	table.Merge( self.WEAPONS[ PodID ][ WeaponID ], weaponData )
end

function ENT:HasWeapon( ID )
	return istable( self.WEAPONS[1][ ID ] )
end

function ENT:AIHasWeapon( ID )
	local weapon = self.WEAPONS[1][ ID ]
	if not istable( weapon ) then return false end

	return weapon.UseableByAI
end

function ENT:GetActiveWeapon()
	local SelectedID = self:GetSelectedWeapon()
	local CurWeapon = self.WEAPONS[1][ SelectedID ]

	return CurWeapon, SelectedID
end

function ENT:GetMaxAmmo()
	local CurWeapon = self:GetActiveWeapon()

	if not CurWeapon then return -1 end

	return CurWeapon.Ammo or -1
end

if SERVER then
	function ENT:WeaponRestoreAmmo()
		local AmmoIsSet = false

		for PodID, data in pairs( self.WEAPONS ) do
			for id, weapon in pairs( data ) do
				local MaxAmmo = weapon.Ammo or -1
				local CurAmmo = weapon._CurAmmo or -1

				if CurAmmo == MaxAmmo then continue end

				self.WEAPONS[PodID][ id ]._CurAmmo = MaxAmmo

				AmmoIsSet = true
			end
		end

		if AmmoIsSet then
			self:SetNWAmmo( self:GetAmmo() )

			for _, pod in pairs( self:GetPassengerSeats() ) do
				local weapon = pod:lvsGetWeapon()

				if not IsValid( weapon ) then continue end

				weapon:SetNWAmmo( weapon:GetAmmo() )
			end
		end

		return AmmoIsSet
	end
	
	function ENT:WeaponsOnRemove()
		for _, data in pairs( self.WEAPONS ) do
			for ID, Weapon in pairs( data ) do
				if not Weapon.OnRemove then continue end

				Weapon.OnRemove( self )
			end
		end
	end

	function ENT:WeaponsFinish()
		if not self._activeWeapon then return end

		local CurWeapon = self.WEAPONS[1][ self._activeWeapon ]

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

	function ENT:TakeAmmo( num )
		if self:GetMaxAmmo() <= 0 then return end

		local CurWeapon = self:GetActiveWeapon()

		CurWeapon._CurAmmo = math.max( self:GetAmmo() - (num or 1), 0 )

		self:SetNWAmmo( CurWeapon._CurAmmo )
	end

	function ENT:GetHeat( weaponid )
		local CurWeapon

		if isnumber( weaponid ) and weaponid > 0 then
			CurWeapon = self.WEAPONS[1][ weaponid ]
		else
			CurWeapon = self:GetActiveWeapon()
		end

		if not CurWeapon then return 0 end

		return (CurWeapon._CurHeat or 0)
	end

	function ENT:GetOverheated()
		local CurWeapon = self:GetActiveWeapon()

		if not CurWeapon then return false end

		return CurWeapon.Overheated == true
	end

	function ENT:SetOverheated( overheat )
		if self:GetOverheated() == overheat then return end

		local CurWeapon = self:GetActiveWeapon()

		if not CurWeapon then return end

		CurWeapon.Overheated = overheat

		self:SetNWOverheated( overheat )

		if self:GetHeat() == 0 then return end

		if CurWeapon.OnOverheat then
			CurWeapon.OnOverheat( self )
		end
	end

	function ENT:SetHeat( heat )
		local CurWeapon = self:GetActiveWeapon()

		if not CurWeapon then return end

		heat = math.Clamp( heat, 0, 1 )

		CurWeapon._CurHeat = heat

		if self:GetNWHeat() == heat then return end

		self:SetNWHeat( heat )
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
		local EntTable = self:GetTable()

		local T = CurTime()
		local FT = FrameTime()
		local CurWeapon, SelectedID = self:GetActiveWeapon()
	
		for ID, Weapon in pairs( EntTable.WEAPONS[1] ) do
			local IsActive = ID == SelectedID
			if Weapon.OnThink then Weapon.OnThink( self, IsActive ) end

			if IsActive then continue end

			-- cool all inactive weapons down
			Weapon._CurHeat = Weapon._CurHeat and Weapon._CurHeat - math.min( Weapon._CurHeat, (Weapon.HeatRateDown or 0.25) * FT ) or 0
		end

		if not CurWeapon then return end

		local ShouldFire = self:WeaponsShouldFire()
		local CurHeat = self:GetHeat()

		if self:GetOverheated() then
			if CurHeat <= 0 then
				self:SetOverheated( false )
			else
				ShouldFire = false
			end
		else
			if CurHeat >= 1 then
				self:SetOverheated( true )
				ShouldFire = false
			end
		end

		if self:GetMaxAmmo() > 0 then
			if self:GetAmmo() <= 0 then
				ShouldFire = false
			end
		end

		if ShouldFire ~= EntTable.OldAttack then
			EntTable.OldAttack = ShouldFire

			if ShouldFire then
				if CurWeapon.StartAttack then
					CurWeapon.StartAttack( self )
				end
				EntTable._activeWeapon = SelectedID
			else
				self:WeaponsFinish()
			end
		end

		if ShouldFire then
			if not self:CanAttack() then return end

			local ShootDelay = (CurWeapon.Delay or 0)

			self:SetNextAttack( T + ShootDelay )
			self:SetHeat( CurHeat + (CurWeapon.HeatRateUp or 0.2) * math.max(ShootDelay, FT) )

			if not CurWeapon.Attack then return end

			if CurWeapon.Attack( self ) then
				self:SetHeat( CurHeat - math.min( self:GetHeat(), (CurWeapon.HeatRateDown or 0.25) * FT ) )
				self:SetNextAttack( T )
			end

			EntTable._lvsNextActiveWeaponCoolDown = T + 0.25
		else
			if (EntTable._lvsNextActiveWeaponCoolDown or 0) > T then return end

			self:SetHeat( self:GetHeat() - math.min( self:GetHeat(), (CurWeapon.HeatRateDown or 0.25) * FT ) )
		end
	end

	function ENT:SelectWeapon( ID )
		if not isnumber( ID ) then return end

		if self.WEAPONS[1][ ID ] then
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

		local PrevWeapon = self.WEAPONS[1][ old ]
		if PrevWeapon and PrevWeapon.OnDeselect then
			PrevWeapon.OnDeselect( self, new )
		end

		local NextWeapon = self.WEAPONS[1][ new ]
		if NextWeapon and NextWeapon.OnSelect then
			NextWeapon.OnSelect( self, old )
			self:SetNWAmmo( NextWeapon._CurAmmo or NextWeapon.Ammo or -1 )
			self:SetNWOverheated( NextWeapon.Overheated == true )
		end
	end

	return
end

function ENT:DrawWeaponIcon( PodID, ID, x, y, width, height, IsSelected, IconColor )
end

function ENT:SelectWeapon( ID )
	if not isnumber( ID ) then return end

	net.Start( "lvs_select_weapon" )
		net.WriteInt( ID, 5 )
		net.WriteBool( false )
	net.SendToServer()
end

function ENT:NextWeapon()
	net.Start( "lvs_select_weapon" )
		net.WriteInt( 1, 5 )
		net.WriteBool( true )
	net.SendToServer()
end

function ENT:PrevWeapon()
	net.Start( "lvs_select_weapon" )
		net.WriteInt( -1, 5 )
		net.WriteBool( true )
	net.SendToServer()
end

LVS:AddHudEditor( "WeaponSwitcher", ScrW() - 210, ScrH() - 165,  200, 68, 200, 68, "WEAPON SELECTOR", 
	function( self, vehicle, X, Y, W, H, ScrX, ScrY, ply )
		if not vehicle.LVSHudPaintWeapons then return end
		vehicle:LVSHudPaintWeapons( X, Y, W, H, ScrX, ScrY, ply )
	end
)

LVS:AddHudEditor( "WeaponInfo", ScrW() - 230, ScrH() - 85,  220, 75, 220, 75, "WEAPON INFO", 
	function( self, vehicle, X, Y, W, H, ScrX, ScrY, ply )
		if not vehicle.LVSHudPaintWeaponInfo then return end

		vehicle:LVSHudPaintWeaponInfo( X, Y, W, H, ScrX, ScrY, ply )
	end
)

function ENT:GetAmmoID( ID )
	local ply = LocalPlayer()

	if not IsValid( ply ) then return end

	local Base = ply:lvsGetWeaponHandler()

	if not IsValid( Base ) then return -1 end

	local selected = Base:GetSelectedWeapon()
	local weapon = self.WEAPONS[ Base:GetPodIndex() ][ ID ]

	if ID == selected then
		weapon._CurAmmo = Base:GetNWAmmo()
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

local function DrawCircle( X, Y, target_radius, heatvalue, overheated )
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

local color_white = color_white
local color_red = Color(255,0,0,255)

function ENT:LVSHudPaintWeaponInfo( X, Y, w, h, ScrX, ScrY, ply )
	local Base = ply:lvsGetWeaponHandler()

	if not IsValid( Base ) then return end

	local ID = Base:GetSelectedWeapon()

	if not Base:HasWeapon( ID ) then return end

	local Weapon = Base:GetActiveWeapon()
	local Heat = Base:GetNWHeat()
	local OverHeated = Base:GetNWOverheated()
	local Ammo = Base:GetNWAmmo()

	if Weapon and Weapon.HeatIsClip then
		local Pod = ply:GetVehicle()

		if not IsValid( Pod ) then return end

		local PodID = Base:GetPodIndex()

		local FT = FrameTime()
		local ShootDelay = math.max(Weapon.Delay or 0, FT)
		local HeatIncrement = (Weapon.HeatRateUp or 0.2) * ShootDelay

		local Clip = math.min( math.ceil( math.Round( (1 - Heat) / HeatIncrement, 1 ) ), Ammo )
		Ammo = Ammo - Clip

		local ColDyn = (Clip == 0 or OverHeated) and color_red or color_white

		draw.DrawText( "AMMO ", "LVS_FONT", X + 72, Y + 35, ColDyn, TEXT_ALIGN_RIGHT )

		draw.DrawText( Clip, "LVS_FONT_HUD_LARGE", X + 72, Y + 20, ColDyn, TEXT_ALIGN_LEFT )

		local ColDyn2 = Ammo < Clip and color_red or color_white

		X = X + math.max( (#string.Explode( "", Clip ) - 1) * 18, 0 )

		draw.DrawText( "/", "LVS_FONT_HUD_LARGE", X + 96, Y + 30, ColDyn2, TEXT_ALIGN_LEFT )

		draw.DrawText( Ammo, "LVS_FONT", X + 110, Y + 40, ColDyn2, TEXT_ALIGN_LEFT )

		return
	end

	local hX = X + w - h * 0.5
	local hY = Y + h * 0.25 + h * 0.25
	local hAng = math.cos( CurTime() * 50 ) * 5 * (OverHeated and 1 or Heat ^ 2)

	surface.SetMaterial( self.HeatMat )
	surface.SetDrawColor( 0, 0, 0, 200 )
	surface.DrawTexturedRectRotated( hX + 4, hY + 1, h * 0.5, h * 0.5, hAng )

	if OverHeated then
		surface.SetDrawColor( 255, 0, 0, 255 )
	else
		surface.SetDrawColor( 255, 255 * (1 - Heat), 255 * math.max(1 - Heat * 1.5,0), 255 )
	end

	surface.DrawTexturedRectRotated( hX + 2, hY - 1, h * 0.5, h * 0.5, hAng )

	DrawCircle( hX, hY, h * 0.35, Heat )

	if Base:GetMaxAmmo() <= 0 then return end

	draw.DrawText( "AMMO ", "LVS_FONT", X + 72, Y + 35, color_white, TEXT_ALIGN_RIGHT )
	draw.DrawText( Ammo, "LVS_FONT_HUD_LARGE", X + 72, Y + 20, color_white, TEXT_ALIGN_LEFT )
end

function ENT:LVSHudPaintWeapons( X, Y, w, h, ScrX, ScrY, ply )
	local EntTable = self:GetTable()

	local Base = ply:lvsGetWeaponHandler()

	if not IsValid( Base ) then return end

	local Pod = ply:GetVehicle()

	if not IsValid( Pod ) then return end

	local PodID = Base:GetPodIndex()

	local num = #self.WEAPONS[ PodID ]

	if num <= 1 then return end

	local CenterY = (Y + h * 0.5)
	local CenterX = (X + w * 0.5)

	local FlatSelector = CenterX > ScrX * 0.333 and CenterX < ScrX * 0.666

	local T = CurTime()
	local FT = RealFrameTime()

	local gap = 4
	local SizeY = h - gap

	local Selected = Base:GetSelectedWeapon()
	if Selected ~= EntTable._OldSelected then
		EntTable._OldSelected = Selected
		Pod._SelectActiveTime = T + 2
	end

	local tAlpha = (Pod._SelectActiveTime or 0) > T and 1 or 0
	local tAlphaRate = FT * 15

	EntTable.smAlphaSW = EntTable.smAlphaSW and (EntTable.smAlphaSW + math.Clamp(tAlpha - EntTable.smAlphaSW,-tAlphaRate,tAlphaRate)) or 0

	if EntTable.smAlphaSW > 0.95 then
		EntTable._DisplaySelected = Selected
	else
		EntTable._DisplaySelected = EntTable._DisplaySelected or Selected
	end

	local A255 = 255 * EntTable.smAlphaSW
	local A150 = 150 * EntTable.smAlphaSW

	local Col = Color(0,0,0,A150)
	local ColSelect = Color(255,255,255,A150)

	local SwapY = 0

	if Y < (ScrY * 0.5 - h * 0.5) then
		SwapY = 1
	end

	for ID = 1, num do
		local IsSelected = EntTable._DisplaySelected == ID
		local n = num - ID
		local xPos = FlatSelector and X + (w + gap) * (ID - 1) - ((w + gap) * 0.5 * num - w * 0.5) or X
		local yPos = FlatSelector and Y - h * math.min(SwapY,0) or Y - h * n + (num - 1) * h * SwapY

		draw.RoundedBox(5, xPos, yPos, w, SizeY, IsSelected and ColSelect or Col )

		if IsSelected then
			surface.SetDrawColor( 0, 0, 0, A255 )
		else
			surface.SetDrawColor( 255, 255, 255, A255 )
		end

		if isbool( EntTable.WEAPONS[PodID][ID].Icon ) then
			local col = IsSelected and Color(255,255,255,A255) or Color(0,0,0,A255) 
			self:DrawWeaponIcon( PodID, ID, xPos, yPos, SizeY * 2, SizeY, IsSelected, col )
		else
			surface.SetMaterial( self.WEAPONS[PodID][ID].Icon )
			surface.DrawTexturedRect( xPos, yPos, SizeY * 2, SizeY )
		end

		local ammo = self:GetAmmoID( ID )

		if ammo > -1 then
			draw.DrawText( ammo, "LVS_FONT_HUD", xPos + w - 10, yPos + SizeY * 0.5 - 10, IsSelected and Color(0,0,0,A255) or Color(255,255,255,A255), TEXT_ALIGN_RIGHT )
		else
			draw.DrawText( "O", "LVS_FONT_HUD", xPos + w - 19, yPos + SizeY * 0.5 - 10, IsSelected and Color(0,0,0,A255) or Color(255,255,255,A255), TEXT_ALIGN_RIGHT )
			draw.DrawText( "O", "LVS_FONT_HUD", xPos + w - 10, yPos + SizeY * 0.5 - 10, IsSelected and Color(0,0,0,A255) or Color(255,255,255,A255), TEXT_ALIGN_RIGHT )
		end
	end
end