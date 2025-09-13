
LVS:AddHudEditor( "VehicleHealth", 10, ScrH() - 85,  220, 75, 220, 75, "VEHICLE HEALTH", 
	function( self, vehicle, X, Y, W, H, ScrX, ScrY, ply )
		if not vehicle.LVSHudPaintVehicleHealth then return end

		vehicle:LVSHudPaintVehicleHealth( X, Y, W, H, ScrX, ScrY, ply )
	end
)

LVS:AddHudEditor( "VehicleInfo", ScrW() - 460, ScrH() - 85,  220, 75, 220, 75, "VEHICLE INFORMATION", 
	function( self, vehicle, X, Y, W, H, ScrX, ScrY, ply )
		if not vehicle.LVSHudPaintInfoText then return end

		vehicle:LVSHudPaintInfoText( X, Y, W, H, ScrX, ScrY, ply )
	end
)

function ENT:LVSHudPaintVehicleHealth( X, Y, W, H, ScrX, ScrY, ply )
	draw.DrawText( "HEALTH ", "LVS_FONT", X + 102, Y + 35, color_white, TEXT_ALIGN_RIGHT )
	draw.DrawText( math.Round( self:GetHP(), 0 ), "LVS_FONT_HUD_LARGE", X + 102, Y + 20, color_white, TEXT_ALIGN_LEFT )
end

ENT.VehicleIdentifierRange = 10000

function ENT:LVSHudPaintVehicleIdentifier( X, Y, In_Col )
	local HP = self:GetHP()

	surface.SetDrawColor( In_Col.r, In_Col.g, In_Col.b, In_Col.a )
	LVS:DrawDiamond( X + 1, Y + 1, 20, HP / self:GetMaxHP() )

	if self:GetMaxShield() > 0 and HP > 0 then
		surface.SetDrawColor( 200, 200, 255, In_Col.a )
		LVS:DrawDiamond( X + 1, Y + 1, 24, self:GetShield() / self:GetMaxShield() )
	end
end

function ENT:LVSPreHudPaint( X, Y, ply )
	return true
end

local zoom = 0
local zoom_mat = Material( "vgui/zoom" )
local zoom_switch = 0
local zoom_blinder = 0
local TargetZoom = 0

ENT.ZoomInSound = "weapons/sniper/sniper_zoomin.wav"
ENT.ZoomOutSound =  "weapons/sniper/sniper_zoomout.wav"

function ENT:GetZoom()
	return TargetZoom
end

function ENT:PaintZoom( X, Y, ply )
	TargetZoom = ply:lvsKeyDown( "ZOOM" ) and 1 or 0

	zoom = zoom + (TargetZoom - zoom) * RealFrameTime() * 10

	if self.OpticsEnable then
		if self:GetOpticsEnabled() then
			if zoom_switch ~= TargetZoom then
				zoom_switch = TargetZoom

				zoom_blinder = 1

				if TargetZoom == 1 then
					surface.PlaySound( self.ZoomInSound )
				else
					surface.PlaySound( self.ZoomOutSound )
				end
			end

			zoom_blinder = zoom_blinder - zoom_blinder * RealFrameTime() * 5

			surface.SetDrawColor( Color(0,0,0,255 * zoom_blinder) )
			surface.DrawRect( 0, 0, X, Y )

			self.ZoomFov = self.OpticsFov
		else
			self.ZoomFov = nil
		end
	end

	X = X * 0.5
	Y = Y * 0.5

	surface.SetDrawColor( Color(255,255,255,255 * zoom) )
	surface.SetMaterial(zoom_mat ) 
	surface.DrawTexturedRectRotated( X + X * 0.5, Y * 0.5, X, Y, 0 )
	surface.DrawTexturedRectRotated( X + X * 0.5, Y + Y * 0.5, Y, X, 270 )
	surface.DrawTexturedRectRotated( X * 0.5, Y * 0.5, Y, X, 90 )
	surface.DrawTexturedRectRotated( X * 0.5, Y + Y * 0.5, X, Y, 180 )
end

function ENT:LVSHudPaint( X, Y, ply )
	if not self:LVSPreHudPaint( X, Y, ply ) then return end

	self:PaintZoom( X, Y, ply )
end

function ENT:HurtMarker( intensity )
	LocalPlayer():EmitSound( "lvs/hit_receive"..math.random(1,2)..".wav", 75, math.random(95,105), 0.25 + intensity * 0.75, CHAN_STATIC )
	util.ScreenShake( Vector(0, 0, 0), 25 * intensity, 25 * intensity, 0.5, 1 )
end

function ENT:KillMarker()
	self.LastKillMarker = CurTime() + 0.5

	LocalPlayer():EmitSound( "lvs/hit_kill.wav", 85, 100, 0.4, CHAN_VOICE )
end

local LastMarker = 0
function ENT:ArmorMarker( IsDamage )
	local T = CurTime()

	local DontHurtEars = math.Clamp( T - LastMarker, 0, 1 ) ^ 2

	LastMarker = T

	local ArmorFailed = IsDamage and "takedamage" or "pen"
	local Volume = IsDamage and (0.3 * DontHurtEars) or 1

	LocalPlayer():EmitSound( "lvs/armor_"..ArmorFailed.."_"..math.random(1,3)..".wav", 85, math.random(95,105), Volume, CHAN_ITEM2 )
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

local Circles = {
	[1] = {r = -1, col = Color(0,0,0,200)},
	[2] = {r = 0, col = Color(255,255,255,200)},
	[3] = {r = 1, col = Color(255,255,255,255)},
	[4] = {r = 2, col = Color(255,255,255,200)},
	[5] = {r = 3, col = Color(0,0,0,200)},
}

function ENT:LVSDrawCircle( X, Y, target_radius, value )
	local endang = 360 * value

	if endang == 0 then return end

	for i = 1, #Circles do
		local data = Circles[ i ]
		local radius = target_radius + data.r
		local segmentdist = endang / ( math.pi * radius / 2 )

		for a = 0, endang, segmentdist do
			surface.SetDrawColor( data.col )

			surface.DrawLine( X - math.sin( math.rad( a ) ) * radius, Y + math.cos( math.rad( a ) ) * radius, X - math.sin( math.rad( a + segmentdist ) ) * radius, Y + math.cos( math.rad( a + segmentdist ) ) * radius )
		end
	end
end
