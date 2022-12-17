
hook.Add( "InitPostEntity", "!!!lvs_load_hud", function()
	LVS:LoadHUD()
end )

function LVS:HudDefaults()
	LVS.SwitcherX = ScrW() - 10
	LVS.SwitcherY = ScrH() - 10
	LVS.SwitcherFrameX = 350
	LVS.SwitcherFrameY = 30
end

function LVS:LoadHUD()
	local data = file.Read( "lvs_hud_settings.txt" )
	local tbl_data = string.Explode( "\n", data )

	if not tbl_data then 

		LVS:HudDefaults()

		return
	end

	local W = ScrW()
	local H = ScrH()

	local switcher = string.Explode( ":", tbl_data[1] )
	local FramePos = string.Explode( "/", switcher[1] )
	local FrameSize = string.Explode( "/", switcher[2] )
	LVS.SwitcherX = math.min( tonumber( FramePos[1] ), W )
	LVS.SwitcherY = math.min( tonumber( FramePos[2] ), H )
	LVS.SwitcherFrameX = math.min( tonumber( FrameSize[1] ), W )
	LVS.SwitcherFrameY = math.min( tonumber( FrameSize[2] ), H )
end

function LVS:SaveHUD()
	local data = ""

	data = data..LVS.SwitcherX.."/"..LVS.SwitcherY..":"..LVS.SwitcherFrameX.."/"..LVS.SwitcherFrameY.."\n"

	file.Write( "lvs_hud_settings.txt", data )
end

hook.Add( "OnContextMenuOpen", "!!!!!LVS_hud", function()
	if not IsValid( LocalPlayer():lvsGetVehicle() ) then return end

	if not IsValid( LVS.SeatSwitcher ) then
		LVS.SeatSwitcher = vgui.Create("DFrame")
		LVS.SeatSwitcher:SetSize(LVS.SwitcherFrameX, LVS.SwitcherFrameY)
		LVS.SeatSwitcher:SetPos(LVS.SwitcherX - LVS.SwitcherFrameX, LVS.SwitcherY - LVS.SwitcherFrameY)
		LVS.SeatSwitcher:SetTitle("")
		LVS.SeatSwitcher:SetScreenLock( true )
		LVS.SeatSwitcher:MakePopup()
		LVS.SeatSwitcher:SetSizable( true )
		LVS.SeatSwitcher:SetMinWidth( 350 )
		LVS.SeatSwitcher:SetMinHeight( 30 )
		LVS.SeatSwitcher.OnClose = function( self )
			LVS:HudDefaults()
			LVS:SaveHUD()
		end

		LVS.SeatSwitcher.Paint = function(self, w, h )
			surface.SetDrawColor(0,0,0,150)
			surface.DrawRect(0, 0, w, h)

			surface.SetDrawColor(80,80,80,255)
			surface.DrawRect(0, 0, 2, h)
			surface.DrawRect(w - 2, 0, 2, h)
			surface.DrawRect(0, 0, w, 2)
			surface.DrawRect(0, h - 2, w, 2)

			draw.DrawText( "LVS SEAT SWITCHER", "LVS_FONT", w * 0.5 - 24, h * 0.5 - 12, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			LVS.SwitcherFrameX = LVS.SeatSwitcher:GetWide()
			LVS.SwitcherFrameY = LVS.SeatSwitcher:GetTall()

			LVS.SwitcherX = self:GetX() + LVS.SwitcherFrameX
			LVS.SwitcherY = self:GetY() + LVS.SwitcherFrameY
		end
	end
end )

hook.Add( "OnContextMenuClose", "!!!!!LVS_hud", function()
	if IsValid( LVS.SeatSwitcher ) then
		LVS:SaveHUD()
		LVS.SeatSwitcher:Remove()
	end
end )