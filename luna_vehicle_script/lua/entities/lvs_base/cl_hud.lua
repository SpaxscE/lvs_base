
ENT.IconVehicleLocked = Material( "lvs_locked.png" )

function ENT:LVSHudPaint( X, Y, ply )
end

function ENT:LVSHudPaintStats( X, Y, w, h, ScrX, ScrY, ply )
end

function ENT:LVSHudPaintWeapons( X, Y, w, h, ScrX, ScrY, ply )
	local gap = 5
	local num = #self._WEAPONS
	local SizeY = h - gap

	local Selected = self:GetSelectedWeapon()
	local Col = Color(0,0,0,150)
	local ColSelect = Color(255,255,255,150)

	local SwapY = 0

	if Y < (ScrY * 0.5 - h * 0.5) then
		SwapY = 1
	end

	for ID = 1, num do
		local IsSelected = Selected == ID
		local n = num - ID
		local yPos = Y - h * n + (num - 1) * h * SwapY

		draw.RoundedBox(5, X, yPos, w, SizeY, IsSelected and ColSelect or Col )

		if IsSelected then
			surface.SetDrawColor( 0, 0, 0, 255 )
		else
			surface.SetDrawColor( 255, 255, 255, 255 )
		end
		surface.SetMaterial( self._WEAPONS[ID].Icon )
		surface.DrawTexturedRect( X, yPos, SizeY * 2, SizeY )
	end
end

function ENT:LVSHudPaintSeatSwitcher( X, Y, w, h, ScrX, ScrY, ply )
	local pSeats = self:GetPassengerSeats()
	local SeatCount = table.Count( pSeats ) 

	if SeatCount <= 0 then return end

	pSeats[0] = self:GetDriverSeat()

	draw.NoTexture() 

	local MySeat = ply:GetVehicle():GetNWInt( "pPodIndex", -1 )

	local Passengers = {}
	for _, player in pairs( player.GetAll() ) do
		if player:lvsGetVehicle() == self then
			local Pod = player:GetVehicle()
			Passengers[ Pod:GetNWInt( "pPodIndex", -1 ) ] = player:GetName()
		end
	end
	if self:GetAI() then
		Passengers[1] = "[AI] "..self.PrintName
	end

	ply.SwitcherTime = ply.SwitcherTime or 0
	ply._lvsoldPassengers = ply._lvsoldPassengers or {}

	local Time = CurTime()
	for k, v in pairs( Passengers ) do
		if ply._lvsoldPassengers[k] ~= v then
			ply._lvsoldPassengers[k] = v
			ply.SwitcherTime = Time + 2
		end
	end
	for k, v in pairs( ply._lvsoldPassengers ) do
		if not Passengers[k] then
			ply._lvsoldPassengers[k] = nil
			ply.SwitcherTime = Time + 2
		end
	end
	for _, v in pairs( LVS.pSwitchKeysInv ) do
		if input.IsKeyDown(v) then
			ply.SwitcherTime = Time + 2
		end
	end

	local Hide = ply.SwitcherTime > Time

	ply.smHider = ply.smHider and (ply.smHider + ((Hide and 1 or 0) - ply.smHider) * RealFrameTime() * 15) or 0

	local Alpha1 = 135 + 110 * ply.smHider 
	local HiderOffset = 270 * ply.smHider
	local xPos = w - 35
	local yPos = Y - (SeatCount + 1) * 30 + h + 5

	local SwapY = false
	local SwapX = false

	local xHider = HiderOffset

	if X < (ScrX * 0.5 - w * 0.5) then
		SwapX = true
		xPos = 0
		xHider = 0
	end

	if Y < (ScrY * 0.5 - h * 0.5) then
		SwapY = true
		yPos = Y - h
	end

	for _, Pod in pairs( pSeats ) do
		local I = Pod:GetNWInt( "pPodIndex", -1 )

		if I <= 0 then continue end

		if I == MySeat then
			draw.RoundedBox(5, X + xPos - xHider, yPos + I * 30, 35 + HiderOffset, 25, Color(LVS.ThemeColor.r, LVS.ThemeColor.g, LVS.ThemeColor.b,100 + 50 * ply.smHider) )
		else
			draw.RoundedBox(5, X + xPos - xHider, yPos + I * 30, 35 + HiderOffset, 25, Color(0,0,0,100 + 50 * ply.smHider) )
		end

		if Hide then
			if Passengers[I] then
				draw.DrawText( Passengers[I], "LVS_FONT_SWITCHER", X + 40 + xPos - xHider, yPos + I * 30 + 2.5, Color( 255, 255, 255,  Alpha1 ), TEXT_ALIGN_LEFT )
			else
				draw.DrawText( "-", "LVS_FONT_SWITCHER", X + 40 + xPos - xHider, yPos + I * 30 + 2.5, Color( 255, 255, 255,  Alpha1 ), TEXT_ALIGN_LEFT )
			end
			
			draw.DrawText( "["..I.."]", "LVS_FONT_SWITCHER", X + 17 + xPos - xHider, yPos + I * 30 + 2.5, Color( 255, 255, 255, Alpha1 ), TEXT_ALIGN_CENTER )
		else
			if Passengers[I] then
				draw.DrawText( "[^"..I.."]", "LVS_FONT_SWITCHER", X + 17 + xPos - xHider, yPos + I * 30 + 2.5, Color( 255, 255, 255, Alpha1 ), TEXT_ALIGN_CENTER )
			else
				draw.DrawText( "["..I.."]", "LVS_FONT_SWITCHER", X + 17 + xPos - xHider, yPos + I * 30 + 2.5, Color( 255, 255, 255, Alpha1 ), TEXT_ALIGN_CENTER )
			end
		end

		if not self:GetlvsLockedStatus() then continue end

		local xLocker = SwapX and 35 + HiderOffset or -25 - HiderOffset

		if SwapY then
			if I == 1 then
				surface.SetDrawColor( 255, 255, 255, 255 )
				surface.SetMaterial( self.IconVehicleLocked  )
				surface.DrawTexturedRect( X + xPos + xLocker, yPos + I * 30, 25, 25 )
			end
		else
			if I == SeatCount then
				surface.SetDrawColor( 255, 255, 255, 255 )
				surface.SetMaterial( self.IconVehicleLocked  )
				surface.DrawTexturedRect( X + xPos + xLocker, yPos + I * 30, 25, 25 )
			end
		end
	end
end

function ENT:HitMarker( LastHitMarker, CriticalHit )
	self.LastHitMarker = LastHitMarker
	self.LastHitMarkerIsCrit = CriticalHit

	LocalPlayer():EmitSound( CriticalHit and "lvs/hit_crit.wav" or "lvs/hit.wav", 140, math.random(95,105), 1, CHAN_ITEM2 )
end

function ENT:GetHitMarker()
	return self.LastHitMarker or 0, self.LastHitMarkerIsCrit
end

function ENT:KillMarker( LastKillMarker )
	self.LastKillMarker = LastKillMarker
end

function ENT:GetKillMarker()
	return self.LastKillMarker or 0
end