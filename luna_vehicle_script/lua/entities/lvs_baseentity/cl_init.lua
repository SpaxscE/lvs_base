include("shared.lua")

ENT.IconVehicleLocked = Material( "lvs_locked.png" )

function ENT:LVSHudPaint( X, Y, ply )
	self:LVSHudPaintSeatSwitcher( X, Y, ply )
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
	ply.oldPassengers = ply.oldPassengers or {}
	
	local Time = CurTime()
	for k, v in pairs( Passengers ) do
		if ply.oldPassengers[k] ~= v then
			ply.oldPassengers[k] = v
			ply.SwitcherTime = Time + 2
		end
	end
	for k, v in pairs( ply.oldPassengers ) do
		if not Passengers[k] then
			ply.oldPassengers[k] = nil
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

function ENT:LVSCalcViewFirstPerson( view, ply )
	view.drawviewer = true

	return self:LVSCalcViewThirdPerson( view, ply )
end

function ENT:LVSCalcViewThirdPerson( view, ply )
	self._lerpPos = self._lerpPos or self:GetPos()

	local Delta = RealFrameTime()

	local TargetPos = self:LocalToWorld( Vector(500,0,250) )

	local Sub = TargetPos - self._lerpPos
	local Dir = Sub:GetNormalized()
	local Dist = Sub:Length()

	self._lerpPos = self._lerpPos + (TargetPos - self:GetForward() * 900 - Dir * 100 - self._lerpPos) * Delta * 12

	local vel = self:GetVelocity()

	view.origin = self._lerpPos
	view.angles = self:GetAngles()

	return view
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:DrawTranslucent()
end

function ENT:Initialize()
end

function ENT:Think()
end

function ENT:OnRemove()
end

function ENT:GetCrosshairFilterEnts()
	if not istable( self.CrosshairFilterEnts ) then
		self.CrosshairFilterEnts = {self}

		-- lets ask the server to build the filter for us because it has access to constraint.GetAllConstrainedEntities() 
		net.Start( "lvs_player_request_filter" )
			net.WriteEntity( self )
		net.SendToServer()
	end

	return self.CrosshairFilterEnts
end
