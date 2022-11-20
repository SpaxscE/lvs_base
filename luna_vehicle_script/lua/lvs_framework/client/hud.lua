
surface.CreateFont( "LVS_FONT_SWITCHER", {
	font = "Verdana",
	extended = false,
	size = 16,
	weight = 2000,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = true,
	additive = false,
	outline = false,
} )

local LockText = Material( "lvs_locked.png" )
local smHider = 0
local function PaintSeatSwitcher( ent, X, Y )
	local me = LocalPlayer()

	if not IsValid( ent ) then return end

	local pSeats = ent:GetPassengerSeats()
	local SeatCount = table.Count( pSeats ) 

	if SeatCount <= 0 then return end
	
	pSeats[0] = ent:GetDriverSeat()

	draw.NoTexture() 

	local MySeat = me:GetVehicle():GetNWInt( "pPodIndex", -1 )

	local Passengers = {}
	for _, ply in pairs( player.GetAll() ) do
		if ply:lvsGetVehicle() == ent then
			local Pod = ply:GetVehicle()
			Passengers[ Pod:GetNWInt( "pPodIndex", -1 ) ] = ply:GetName()
		end
	end
	if ent:GetAI() then
		Passengers[1] = "[AI] "..ent.PrintName
	end
	
	me.SwitcherTime = me.SwitcherTime or 0
	me.oldPassengers = me.oldPassengers or {}
	
	local Time = CurTime()
	for k, v in pairs( Passengers ) do
		if me.oldPassengers[k] ~= v then
			me.oldPassengers[k] = v
			me.SwitcherTime = Time + 2
		end
	end
	for k, v in pairs( me.oldPassengers ) do
		if not Passengers[k] then
			me.oldPassengers[k] = nil
			me.SwitcherTime = Time + 2
		end
	end

	for _, v in pairs( LVS.pSwitchKeysInv ) do
		if input.IsKeyDown(v) then
			me.SwitcherTime = Time + 2
		end
	end

	local Hide = me.SwitcherTime > Time
	smHider = smHider + ((Hide and 1 or 0) - smHider) * RealFrameTime() * 15
	local Alpha1 = 135 + 110 * smHider 
	local HiderOffset = 300 * smHider
	local Offset = -50
	local yPos = Y - (SeatCount + 1) * 30 - 10

	for _, Pod in pairs( pSeats ) do
		local I = Pod:GetNWInt( "pPodIndex", -1 )
		if I >= 0 then
			if I == MySeat then
				draw.RoundedBox(5, X + Offset - HiderOffset, yPos + I * 30, 35 + HiderOffset, 25, Color(LVS.ThemeColor.r, LVS.ThemeColor.g, LVS.ThemeColor.b,100 + 50 * smHider) )
			else
				draw.RoundedBox(5, X + Offset - HiderOffset, yPos + I * 30, 35 + HiderOffset, 25, Color(0,0,0,100 + 50 * smHider) )
			end
			if I == SeatCount then
				if ent:GetlvsLockedStatus() then
					surface.SetDrawColor( 255, 255, 255, 255 )
					surface.SetMaterial( LockText  )
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

hook.Add( "HUDPaint", "!!!!!LVS_hud", function()
	local ply = LocalPlayer()
	
	if ply:GetViewEntity() ~= ply then return end
	
	local Pod = ply:GetVehicle()
	local Parent = ply:lvsGetVehicle()

	if not IsValid( Pod ) or not IsValid( Parent ) then 
		ply.oldPassengers = {}
		
		return
	end

	local X = ScrW()
	local Y = ScrH()

	PaintSeatSwitcher( Parent, X, Y )

	Parent:LVSHudPaint( X, Y, ply )
end )
