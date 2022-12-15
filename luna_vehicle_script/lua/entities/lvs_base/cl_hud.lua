
ENT.IconVehicleLocked = Material( "lvs_locked.png" )

function ENT:LVSHudPaint( X, Y, ply )
end

function ENT:LVSHudPaintSeatSwitcher( X, Y, ply )
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
	local HiderOffset = 300 * ply.smHider
	local Offset = -50
	local yPos = Y - (SeatCount + 1) * 30 - 10

	for _, Pod in pairs( pSeats ) do
		local I = Pod:GetNWInt( "pPodIndex", -1 )
		if I >= 0 then
			if I == MySeat then
				draw.RoundedBox(5, X + Offset - HiderOffset, yPos + I * 30, 35 + HiderOffset, 25, Color(LVS.ThemeColor.r, LVS.ThemeColor.g, LVS.ThemeColor.b,100 + 50 * ply.smHider) )
			else
				draw.RoundedBox(5, X + Offset - HiderOffset, yPos + I * 30, 35 + HiderOffset, 25, Color(0,0,0,100 + 50 * ply.smHider) )
			end
			if I == SeatCount then
				if self:GetlvsLockedStatus() then
					surface.SetDrawColor( 255, 255, 255, 255 )
					surface.SetMaterial( self.IconVehicleLocked  )
					surface.DrawTexturedRect( X + Offset - HiderOffset - 25, yPos + I * 30, 25, 25 )
				end
			end
			if Hide then
				if Passengers[I] then
					draw.DrawText( Passengers[I], "LVS_FONT_SWITCHER", X + 40 + Offset - HiderOffset, yPos + I * 30 + 2.5, Color( 255, 255, 255,  Alpha1 ), TEXT_ALIGN_LEFT )
				else
					draw.DrawText( "-", "LVS_FONT_SWITCHER", X + 40 + Offset - HiderOffset, yPos + I * 30 + 2.5, Color( 255, 255, 255,  Alpha1 ), TEXT_ALIGN_LEFT )
				end
				
				draw.DrawText( "["..I.."]", "LVS_FONT_SWITCHER", X + 17 + Offset - HiderOffset, yPos + I * 30 + 2.5, Color( 255, 255, 255, Alpha1 ), TEXT_ALIGN_CENTER )
			else
				if Passengers[I] then
					draw.DrawText( "[^"..I.."]", "LVS_FONT_SWITCHER", X + 17 + Offset - HiderOffset, yPos + I * 30 + 2.5, Color( 255, 255, 255, Alpha1 ), TEXT_ALIGN_CENTER )
				else
					draw.DrawText( "["..I.."]", "LVS_FONT_SWITCHER", X + 17 + Offset - HiderOffset, yPos + I * 30 + 2.5, Color( 255, 255, 255, Alpha1 ), TEXT_ALIGN_CENTER )
				end
			end
		end
	end
end

function ENT:HitMarker( LastHitMarker )
	self.LastHitMarker = LastHitMarker

	local ply = LocalPlayer()
	ply:EmitSound( table.Random( {"physics/metal/metal_sheet_impact_bullet2.wav","physics/metal/metal_sheet_impact_hard2.wav","physics/metal/metal_sheet_impact_hard6.wav",} ), 140, 140, 0.3, CHAN_ITEM2 )
end

function ENT:GetHitMarker()
	return self.LastHitMarker or 0
end

function ENT:KillMarker( LastKillMarker )
	self.LastKillMarker = LastKillMarker

	local ply = LocalPlayer()

	--util.ScreenShake( ply:GetPos(), 4, 2, 2, 50000 )

	--ply:EmitSound( table.Random( {"lfs/plane_preexp1.ogg","lfs/plane_preexp3.ogg"} ), 140, 100, 0.5, CHAN_WEAPON )

	ply:EmitSound( "physics/metal/metal_solid_impact_bullet4.wav", 140, 255, 0.3, CHAN_VOICE )
end

function ENT:GetKillMarker()
	return self.LastKillMarker or 0
end