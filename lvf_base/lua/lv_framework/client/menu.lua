
surface.CreateFont( "LVF_FONT", {
	font = "Verdana",
	extended = false,
	size = 20,
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

surface.CreateFont( "LVF_FONT_PANEL", {
	font = "Arial",
	extended = false,
	size = 14,
	weight = 1,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

local Frame
local bgMat = Material( "lvf_controlpanel_bg.png" )
local adminMat = Material( "icon16/shield.png" )
local soundPreviewMat = Material( "materials/icon16/sound.png" )

globLVF.IsClientSelected = true

function globLVF.OpenClientSettings( Frame )
	globLVF.IsClientSelected = true
end

function globLVF.OpenServerSettings( Frame )
	globLVF.IsClientSelected = false
end

local function OpenMenu()
	if not IsValid( Frame ) then
		Frame = vgui.Create( "DFrame" )
		Frame:SetSize( 400, 220 )
		Frame:SetTitle( "" )
		Frame:SetDraggable( true )
		Frame:MakePopup()
		Frame:Center()
		Frame.Paint = function(self, w, h )
			draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 255 ) )
			draw.RoundedBox( 8, 1, 46, w-2, h-47, Color( 120, 120, 120, 255 ) )

			local ColorSelected = Color( 120, 120, 120, 255 )

			local Col_C = globLVF.IsClientSelected and Color( 120, 120, 120, 255 ) or Color( 80, 80, 80, 255 )
			local Col_S = globLVF.IsClientSelected and Color( 80, 80, 80, 255 ) or Color( 120, 120, 120, 255 )

			draw.RoundedBox( 4, 1, 26, 199, globLVF.IsClientSelected and 36 or 19, Col_C )
			draw.RoundedBox( 4, 201, 26, 198, globLVF.IsClientSelected and 19 or 36, Col_S )

			draw.RoundedBox( 8, 0, 0, w, 25, Color( globLVF.ThemeColor.r, globLVF.ThemeColor.g, globLVF.ThemeColor.b, 255 ) )
			draw.SimpleText( "[LVF] - Control Panel ", "LVF_FONT", 5, 11, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

			surface.SetDrawColor( 255, 255, 255, 50 )
			surface.SetMaterial( bgMat )
			surface.DrawTexturedRect( 0, -50, w, w )

			draw.DrawText( "v1", "LVF_FONT_PANEL", w - 15, h - 20, Color( 255, 191, 0, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM )
		end
		globLVF.OpenClientSettings( Frame )

		local DermaButton = vgui.Create( "DButton", Frame )
		DermaButton:SetText( "" )
		DermaButton:SetPos( 0, 25 )
		DermaButton:SetSize( 200, 20 )
		DermaButton.DoClick = function()
			surface.PlaySound( "buttons/button14.wav" )
			globLVF.OpenClientSettings( Frame )
		end
		DermaButton.Paint = function(self, w, h ) 
			if not globLVF.IsClientSelected and self:IsHovered() then
				draw.RoundedBox( 4, 1, 1, w - 1, h - 1, Color( 120, 120, 120, 255 ) )
			end

			local Col = (self:IsHovered() or globLVF.IsClientSelected) and Color( 255, 255, 255, 255 ) or Color( 150, 150, 150, 255 )
			draw.DrawText( "CLIENT", "LVF_FONT", w * 0.5, 0, Col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end

		local DermaButton = vgui.Create( "DButton", Frame )
		DermaButton:SetText( "" )
		DermaButton:SetPos( 200, 25 )
		DermaButton:SetSize( 200, 20 )
		DermaButton.DoClick = function()
			if LocalPlayer():IsSuperAdmin() then
				surface.PlaySound( "buttons/button14.wav" )
				globLVF.OpenServerSettings( Frame )
			else
				surface.PlaySound( "buttons/button11.wav" )
			end
		end
		DermaButton.Paint = function(self, w, h ) 
			if globLVF.IsClientSelected and self:IsHovered() then
				draw.RoundedBox( 4, 1, 1, w - 2, h - 1, Color( 120, 120, 120, 255 ) )
			end

			local Highlight = (self:IsHovered() or not globLVF.IsClientSelected)

			local Col = Highlight and Color( 255, 255, 255, 255 ) or Color( 150, 150, 150, 255 )
			draw.DrawText( "SERVER", "LVF_FONT", w * 0.5, 0, Col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			surface.SetDrawColor( 255, 255, 255, Highlight and 255 or 50 )
			surface.SetMaterial( adminMat )
			surface.DrawTexturedRect( 3, 2, 16, 16 )
		end
	end
end

list.Set( "DesktopWindows", "LVFMenu", {
	title = "[LVF] Settings",
	icon = "icon64/iconlvf.png",
	init = function( icon, window )
		OpenMenu()
	end
} )

concommand.Add( "lvf_openmenu", function( ply, cmd, args ) OpenMenu() end )
