LVS:AddHudEditor( "VehicleInfo", ScrW() - 460, ScrH() - 85,  220, 75, 220, 75, "VEHICLE INFORMATION", 
	function( self, vehicle, X, Y, W, H, ScrX, ScrY, ply )
		if not vehicle.LVSHudPaintInfoText then return end

		vehicle:LVSHudPaintInfoText( X, Y, W, H, ScrX, ScrY, ply )
	end
)

function ENT:LVSHudPaintInfoText( X, Y, W, H, ScrX, ScrY, ply )
end

function ENT:LVSHudPaintVehicleIdentifier( X, Y, In_Col, target_ent )
	if not IsValid( target_ent ) then return end

	local HP = target_ent:GetHP()

	surface.SetDrawColor( In_Col.r, In_Col.g, In_Col.b, In_Col.a )
	LVS:DrawDiamond( X + 1, Y + 1, 20, HP / target_ent:GetMaxHP() )

	if target_ent:GetMaxShield() > 0 and HP > 0 then
		surface.SetDrawColor( 200, 200, 255, In_Col.a )
		LVS:DrawDiamond( X + 1, Y + 1, 24, target_ent:GetShield() / target_ent:GetMaxShield() )
	end
end

function ENT:LVSHudPaint( X, Y, ply )
end

function ENT:HurtMarker( intensity )
	LocalPlayer():EmitSound( "lvs/hit_receive"..math.random(1,2)..".wav", 75, math.random(95,105), 0.25 + intensity * 0.75, CHAN_STATIC )
	util.ScreenShake( Vector(0, 0, 0), 25 * intensity, 25 * intensity, 0.5, 1 )
end

function ENT:KillMarker()
	self.LastKillMarker = CurTime() + 0.5

	LocalPlayer():EmitSound( "lvs/hit_kill.wav", 85, 100, 0.4, CHAN_VOICE )
end

function ENT:HitMarker()
	self.LastHitMarker = CurTime() + 0.15

	LocalPlayer():EmitSound( "lvs/hit.wav", 85, math.random(95,105), 0.4, CHAN_ITEM )
end

function ENT:CritMarker()
	self.LastCritMarker = CurTime() + 0.15

	LocalPlayer():EmitSound(  "lvs/hit_crit.wav", 85, math.random(95,105), 0.4, CHAN_ITEM2 )
end

function ENT:GetHitMarker()
	return self.LastHitMarker or 0
end

function ENT:GetCritMarker()
	return self.LastCritMarker or 0
end

function ENT:GetKillMarker()
	return self.LastKillMarker or 0
end

function ENT:LVSPaintHitMarker( scr )
	local T = CurTime()

	local aV = math.cos( math.rad( math.max(((self:GetHitMarker() - T) / 0.15) * 360,0) ) )
	if aV ~= 1 then
		local Start = 12 + (1 - aV) * 8
		local dst = 10

		surface.SetDrawColor( 255, 255, 0, 255 )

		surface.DrawLine( scr.x + Start, scr.y + Start, scr.x + Start, scr.y + Start - dst )
		surface.DrawLine( scr.x + Start, scr.y + Start, scr.x + Start - dst, scr.y + Start )

		surface.DrawLine( scr.x + Start, scr.y - Start, scr.x + Start, scr.y - Start + dst )
		surface.DrawLine( scr.x + Start, scr.y - Start, scr.x + Start - dst, scr.y - Start )

		surface.DrawLine( scr.x - Start, scr.y + Start, scr.x - Start, scr.y + Start - dst )
		surface.DrawLine( scr.x - Start, scr.y + Start, scr.x - Start + dst, scr.y + Start )

		surface.DrawLine( scr.x - Start, scr.y - Start, scr.x - Start, scr.y - Start + dst )
		surface.DrawLine( scr.x - Start, scr.y - Start, scr.x - Start + dst, scr.y - Start )

		scr.x = scr.x + 1
		scr.y = scr.y + 1

		surface.SetDrawColor( 0, 0, 0, 80 )

		surface.DrawLine( scr.x + Start, scr.y + Start, scr.x + Start, scr.y + Start - dst )
		surface.DrawLine( scr.x + Start, scr.y + Start, scr.x + Start - dst, scr.y + Start )

		surface.DrawLine( scr.x + Start, scr.y - Start, scr.x + Start, scr.y - Start + dst )
		surface.DrawLine( scr.x + Start, scr.y - Start, scr.x + Start - dst, scr.y - Start )

		surface.DrawLine( scr.x - Start, scr.y + Start, scr.x - Start, scr.y + Start - dst )
		surface.DrawLine( scr.x - Start, scr.y + Start, scr.x - Start + dst, scr.y + Start )

		surface.DrawLine( scr.x - Start, scr.y - Start, scr.x - Start, scr.y - Start + dst )
		surface.DrawLine( scr.x - Start, scr.y - Start, scr.x - Start + dst, scr.y - Start )
	end

	local aV = math.sin( math.rad( math.max(((self:GetCritMarker() - T) / 0.15) * 180,0) ) )
	if aV > 0.01 then
		local Start = 10 + aV * 40
		local End = 20 + aV * 45

		surface.SetDrawColor( 255, 100, 0, 255 )
		surface.DrawLine( scr.x + Start, scr.y + Start, scr.x + End, scr.y + End )
		surface.DrawLine( scr.x - Start, scr.y + Start, scr.x - End, scr.y + End ) 
		surface.DrawLine( scr.x + Start, scr.y - Start, scr.x + End, scr.y - End )
		surface.DrawLine( scr.x - Start, scr.y - Start, scr.x - End, scr.y - End ) 

		draw.NoTexture()
		surface.DrawTexturedRectRotated( scr.x + Start, scr.y + Start, 3, 20, 45 )
		surface.DrawTexturedRectRotated( scr.x - Start, scr.y + Start, 20, 3, 45 )
		surface.DrawTexturedRectRotated(  scr.x + Start, scr.y - Start, 20, 3, 45 )
		surface.DrawTexturedRectRotated( scr.x - Start, scr.y - Start, 3, 20, 45 )
	end

	local aV = math.sin( math.rad( math.sin( math.rad( math.max(((self:GetKillMarker() - T) / 0.2) * 90,0) ) ) * 90 ) )
	if aV > 0.01 then
		surface.SetDrawColor( 255, 255, 255, 15 * (aV ^ 4) )
		surface.DrawRect( 0, 0, ScrW(), ScrH() )

		local Start = 10 + aV * 40
		local End = 20 + aV * 45
		surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawLine( scr.x + Start, scr.y + Start, scr.x + End, scr.y + End )
		surface.DrawLine( scr.x - Start, scr.y + Start, scr.x - End, scr.y + End ) 
		surface.DrawLine( scr.x + Start, scr.y - Start, scr.x + End, scr.y - End )
		surface.DrawLine( scr.x - Start, scr.y - Start, scr.x - End, scr.y - End ) 

		draw.NoTexture()
		surface.DrawTexturedRectRotated( scr.x + Start, scr.y + Start, 5, 20, 45 )
		surface.DrawTexturedRectRotated( scr.x - Start, scr.y + Start, 20, 5, 45 )
		surface.DrawTexturedRectRotated(  scr.x + Start, scr.y - Start, 20, 5, 45 )
		surface.DrawTexturedRectRotated( scr.x - Start, scr.y - Start, 5, 20, 45 )
	end
end
