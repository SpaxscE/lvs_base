
local cvarVolume = CreateClientConVar( "lvs_volume", 0.25, true, false)
local cvarDirectInput = CreateClientConVar( "lvs_mouseaim", 0, true, true)

local cvarShowPlaneIdent = CreateClientConVar( "lvs_show_identifier", 1, true, false)
local cvarHitMarker = CreateConVar( "lvs_hitmarker", 1, true, false)
LVS.cvarCamFocus = CreateClientConVar( "lvs_camerafocus", 0, true, false)

LVS.ShowPlaneIdent = cvarShowPlaneIdent and cvarShowPlaneIdent:GetBool() or true
LVS.ShowHitMarker = cvarHitMarker and cvarHitMarker:GetBool() or false
LVS.EngineVolume = cvarVolume and cvarVolume:GetFloat() or 0.25

cvars.AddChangeCallback( "lvs_volume", function( convar, oldValue, newValue ) 
	LVS.EngineVolume = math.Clamp( tonumber( newValue ), 0, 1 )
end)

cvars.AddChangeCallback( "lvs_show_identifier", function( convar, oldValue, newValue ) 
	LVS.ShowPlaneIdent = tonumber( newValue ) ~=0
end)

cvars.AddChangeCallback( "lvs_hitmarker", function( convar, oldValue, newValue ) 
	LVS.ShowHitMarker = tonumber( newValue ) ~=0
end)

local icon_load_version = Material("gui/html/refresh")
local bgMat = Material( "lvs_controlpanel_bg.png" )
local adminMat = Material( "icon16/shield.png" )
local gradient_mat = Material( "gui/gradient" )

local FrameSizeX = 600
local FrameSizeY = 400

local function ClientSettings( Canvas )
	local slider = vgui.Create( "DNumSlider", Canvas )
	slider:DockMargin( 16, 32, 16, 4 )
	slider:Dock( TOP )
	slider:SetText( "Engine Volume" )
	slider:SetMin( 0 )
	slider:SetMax( 1 )
	slider:SetDecimals( 2 )
	slider:SetConVar( "lvs_volume" )

	local slider = vgui.Create( "DNumSlider", Canvas )
	slider:DockMargin( 16, 32, 16, 4 )
	slider:Dock( TOP )
	slider:SetText( "Mouse Aim Camera Focus" )
	slider:SetMin( -1 )
	slider:SetMax( 1 )
	slider:SetDecimals( 2 )
	slider:SetConVar( "lvs_camerafocus" )

	local CheckBox = vgui.Create( "DCheckBoxLabel", Canvas )
	CheckBox:DockMargin( 16, 4, 4, 44 )
	CheckBox:SetSize( FrameSizeX, 30 )
	CheckBox:Dock( BOTTOM )
	CheckBox:SetText( "Use Mouse Aim when available" )
	CheckBox:SetConVar("lvs_mouseaim") 

	local CheckBox = vgui.Create( "DCheckBoxLabel", Canvas )
	CheckBox:DockMargin( 16, 4, 4, 16 )
	CheckBox:SetSize( FrameSizeX, 30 )
	CheckBox:Dock( BOTTOM )
	CheckBox:SetText( "Show Plane Identifier" )
	CheckBox:SetConVar("lvs_show_identifier") 

	local CheckBox = vgui.Create( "DCheckBoxLabel", Canvas )
	CheckBox:DockMargin( 16, 4, 4, 16 )
	CheckBox:SetSize( FrameSizeX, 30 )
	CheckBox:Dock( BOTTOM )
	CheckBox:SetText( "Show Hit/Kill Marker" )
	CheckBox:SetConVar("lvs_hitmarker") 
end

local function ClientControls( Canvas )
	local TextHint = vgui.Create("DPanel", Canvas)
	TextHint:DockMargin( 4, 20, 4, 2 )
	TextHint:SetText("")
	TextHint:Dock( TOP )
	TextHint.Paint = function(self, w, h ) 
		draw.DrawText( "You need to re-enter the vehicle in order for the changes to take effect!", "LVS_FONT_PANEL", w * 0.5, -1, Color( 255, 50, 50, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	local DScrollPanel = vgui.Create("DScrollPanel", Canvas)
	DScrollPanel:DockMargin( 0, 0, 0, 24 )
	DScrollPanel:Dock( FILL )

	for category, _ in pairs( LVS.KEYS_CATEGORIES ) do
		local Header = vgui.Create("DPanel", DScrollPanel )
		Header:DockMargin( 0, 4, 4, 2 )
		Header:SetText("")
		Header:Dock( TOP )
		Header.Paint = function(self, w, h ) 
			surface.SetMaterial( gradient_mat )
			surface.SetDrawColor( 80, 80, 80, 255 )
			surface.DrawTexturedRect( 0, 0, w, 1 )
	
			draw.DrawText( category, "LVS_FONT", 4, 0, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		end

		for _, entry in pairs( LVS.KEYS_REGISTERED ) do
			if entry.category ~= category then continue end

			local DPanel = vgui.Create( "DPanel", DScrollPanel )
			DPanel.Paint = function(self, w, h ) end
			DPanel:DockMargin( 4, 2, 4, 2 )
			DPanel:SetSize( FrameSizeX, 25 )
			DPanel:Dock( TOP )

			local ConVar = GetConVar( entry.cmd )

			local DLabel = vgui.Create("DLabel", DPanel)
			DLabel:DockMargin( 16, 0, 0, 0 )
			DLabel:SetText( entry.printname )
			DLabel:SetSize( FrameSizeX * 0.5, 32 )
			DLabel:Dock( LEFT )

			local DBinder = vgui.Create("DBinder", DPanel)
			DBinder:DockMargin( 0, 0, 0, 0 )
			DBinder:SetValue( ConVar:GetInt() )
			DBinder:SetSize( FrameSizeX * 0.5, 32 )
			DBinder:Dock( RIGHT )
			DBinder.ConVar = ConVar
			DBinder.OnChange = function(self,iNum)
				self.ConVar:SetInt(iNum)

				LocalPlayer():lvsBuildControls()
			end
		end
	end

	local Header = vgui.Create("DPanel", DScrollPanel )
	Header:DockMargin( 0, 16, 0, 0 )
	Header:SetText("")
	Header:Dock( TOP )
	Header.Paint = function(self, w, h ) 
		surface.SetMaterial( gradient_mat )
		surface.SetDrawColor( 80, 80, 80, 255 )
		surface.DrawTexturedRect( 0, 0, w, 1 )
	end

	local DButton = vgui.Create("DButton",DScrollPanel)
	DButton:SetText("Reset")
	DButton:DockMargin( 4, 0, 4, 4 )
	DButton:SetSize( FrameSizeX, 32 )
	DButton:Dock( TOP )
	DButton.DoClick = function() 
		surface.PlaySound( "buttons/button14.wav" )

		for _, entry in pairs( LVS.KEYS_REGISTERED ) do
			GetConVar( entry.cmd ):SetInt( entry.default ) 
		end

		LocalPlayer():lvsBuildControls()

		LVS:OpenClientControls()
	end
end

local function ServerSettings( Canvas )
end

function LVS:OpenClientSettings()
	if not IsValid( LVS.Frame ) then return end

	local BasePanel = LVS.Frame:CreatePanel()

	local DPanel = vgui.Create( "DPanel", BasePanel )
	DPanel.Paint = function(self, w, h ) end
	DPanel:DockMargin( 0, 0, 0, 0 )
	DPanel:SetSize( FrameSizeX, 25 )
	DPanel:Dock( TOP )

	local TabPanel = vgui.Create( "DPanel", BasePanel )
	TabPanel.Paint = function(self, w, h ) end
	TabPanel:DockMargin( 0, 0, 0, 0 )
	TabPanel:SetSize( FrameSizeX, 25 )
	TabPanel:Dock( TOP )

	local SettingsPanel = vgui.Create( "DPanel", TabPanel )
	SettingsPanel:DockMargin( 0, 0, 0, 0 )
	SettingsPanel:SetSize( FrameSizeX * 0.5, 32 )
	SettingsPanel:Dock( LEFT )
	SettingsPanel.Paint = function(self, w, h ) 
		draw.DrawText( "SETTINGS", "LVS_FONT", w * 0.5, 0, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	local DButton = vgui.Create( "DButton", TabPanel )
	DButton:DockMargin( 0, 0, 0, 0 )
	DButton:SetText( "" )
	DButton:SetSize( FrameSizeX * 0.5, 32 )
	DButton:Dock( RIGHT )
	DButton.DoClick = function()
		surface.PlaySound( "buttons/button14.wav" )
		LVS:OpenClientControls()
	end
	DButton.Paint = function(self, w, h ) 
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(0, 0, w, h)

		local Hovered = self:IsHovered()

		if Hovered then
			surface.SetDrawColor( 120, 120, 120, 255 )
		else
			surface.SetDrawColor( 80, 80, 80, 255 )
		end

		surface.DrawRect(1, 0, w-2, h-1)

		local Col = Hovered and Color( 255, 255, 255, 255 ) or Color( 150, 150, 150, 255 )
		draw.DrawText( "CONTROLS", "LVS_FONT", w * 0.5, 0, Col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	local DButton = vgui.Create( "DButton", DPanel )
	DButton:DockMargin( 0, 0, 0, 0 )
	DButton:SetText( "" )
	DButton:SetSize( FrameSizeX * 0.5, 32 )
	DButton:Dock( RIGHT )
	DButton.DoClick = function()
		if LocalPlayer():IsSuperAdmin() then
			surface.PlaySound( "buttons/button14.wav" )
			LVS:OpenServerMenu()
		else
			surface.PlaySound( "buttons/button11.wav" )
		end
	end
	DButton.Paint = function(self, w, h ) 
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(0, 0, w, h)

		local Hovered = self:IsHovered()

		if Hovered then
			draw.RoundedBox( 4, 1, 1, w-2, h-2, Color( 120, 120, 120, 255 ) )
		else
			draw.RoundedBox( 4, 1, 1, w-2, h-2, Color( 80, 80, 80, 255 ) )
		end

		surface.SetDrawColor( 255, 255, 255, Hovered and 255 or 50 )
		surface.SetMaterial( adminMat )
		surface.DrawTexturedRect( 3, 2, 16, 16 )

		local Col = Hovered and Color( 255, 255, 255, 255 ) or Color( 150, 150, 150, 255 )
		draw.DrawText( "SERVER", "LVS_FONT", w * 0.5, 0, Col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	local ClientPanel = vgui.Create( "DPanel", DPanel )
	ClientPanel.Paint = function(self, w, h ) end
	ClientPanel:DockMargin( 0, 0, 0, 0 )
	ClientPanel:SetSize( FrameSizeX * 0.5, 32 )
	ClientPanel:Dock( LEFT )
	ClientPanel.Paint = function(self, w, h ) 
		draw.DrawText( "CLIENT", "LVS_FONT", w * 0.5, 0, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	local Canvas = vgui.Create( "DPanel", BasePanel )
	Canvas.Paint = function(self, w, h ) end
	Canvas:DockMargin( 0, 0, 0, 0 )
	Canvas:SetSize( FrameSizeX, 25 )
	Canvas:Dock( FILL )

	ClientSettings( Canvas )
end

function LVS:OpenClientControls()
	if not IsValid( LVS.Frame ) then return end

	local BasePanel = LVS.Frame:CreatePanel()

	local DPanel = vgui.Create( "DPanel", BasePanel )
	DPanel.Paint = function(self, w, h ) end
	DPanel:DockMargin( 0, 0, 0, 0 )
	DPanel:SetSize( FrameSizeX, 25 )
	DPanel:Dock( TOP )

	local TabPanel = vgui.Create( "DPanel", BasePanel )
	TabPanel.Paint = function(self, w, h ) end
	TabPanel:DockMargin( 0, 0, 0, 0 )
	TabPanel:SetSize( FrameSizeX, 25 )
	TabPanel:Dock( TOP )

	local SettingsPanel = vgui.Create( "DPanel", TabPanel )
	SettingsPanel:DockMargin( 0, 0, 0, 0 )
	SettingsPanel:SetSize( FrameSizeX * 0.5, 32 )
	SettingsPanel:Dock( RIGHT )
	SettingsPanel.Paint = function(self, w, h ) 
		draw.DrawText( "CONTROLS", "LVS_FONT", w * 0.5, 0, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	local DButton = vgui.Create( "DButton", TabPanel )
	DButton:DockMargin( 0, 0, 0, 0 )
	DButton:SetText( "" )
	DButton:SetSize( FrameSizeX * 0.5, 32 )
	DButton:Dock( LEFT )
	DButton.DoClick = function()
		surface.PlaySound( "buttons/button14.wav" )
		LVS:OpenClientSettings()
	end
	DButton.Paint = function(self, w, h ) 
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(0, 0, w, h)

		local Hovered = self:IsHovered()

		if Hovered then
			surface.SetDrawColor( 120, 120, 120, 255 )
		else
			surface.SetDrawColor( 80, 80, 80, 255 )
		end

		surface.DrawRect(1, 1, w-2, h-2)

		local Col = Hovered and Color( 255, 255, 255, 255 ) or Color( 150, 150, 150, 255 )
		draw.DrawText( "SETTINGS", "LVS_FONT", w * 0.5, 0, Col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	local DButton = vgui.Create( "DButton", DPanel )
	DButton:DockMargin( 0, 0, 0, 0 )
	DButton:SetText( "" )
	DButton:SetSize( FrameSizeX * 0.5, 32 )
	DButton:Dock( RIGHT )
	DButton.DoClick = function()
		if LocalPlayer():IsSuperAdmin() then
			surface.PlaySound( "buttons/button14.wav" )
			LVS:OpenServerMenu()
		else
			surface.PlaySound( "buttons/button11.wav" )
		end
	end
	DButton.Paint = function(self, w, h ) 
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(0, 0, w, h)

		local Hovered = self:IsHovered()

		if Hovered then
			draw.RoundedBox( 4, 1, 1, w-2, h-2, Color( 120, 120, 120, 255 ) )
		else
			draw.RoundedBox( 4, 1, 1, w-2, h-2, Color( 80, 80, 80, 255 ) )
		end

		surface.SetDrawColor( 255, 255, 255, Hovered and 255 or 50 )
		surface.SetMaterial( adminMat )
		surface.DrawTexturedRect( 3, 2, 16, 16 )

		local Col = Hovered and Color( 255, 255, 255, 255 ) or Color( 150, 150, 150, 255 )
		draw.DrawText( "SERVER", "LVS_FONT", w * 0.5, 0, Col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	local ClientPanel = vgui.Create( "DPanel", DPanel )
	ClientPanel.Paint = function(self, w, h ) end
	ClientPanel:DockMargin( 0, 0, 0, 0 )
	ClientPanel:SetSize( FrameSizeX * 0.5, 32 )
	ClientPanel:Dock( LEFT )
	ClientPanel.Paint = function(self, w, h ) 
		draw.DrawText( "CLIENT", "LVS_FONT", w * 0.5, 0, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	local Canvas = vgui.Create( "DPanel", BasePanel )
	Canvas.Paint = function(self, w, h ) end
	Canvas:DockMargin( 0, 0, 0, 0 )
	Canvas:SetSize( FrameSizeX, 25 )
	Canvas:Dock( FILL )

	ClientControls( Canvas )
end

function LVS:OpenServerMenu()
	if not IsValid( LVS.Frame ) then return end

	local BasePanel = LVS.Frame:CreatePanel()

	local DPanel = vgui.Create( "DPanel", BasePanel )
	DPanel.Paint = function(self, w, h ) end
	DPanel:DockMargin( 0, 0, 0, 0 )
	DPanel:SetSize( FrameSizeX, 25 )
	DPanel:Dock( TOP )

	local ServerPanel = vgui.Create( "DPanel", DPanel )
	ServerPanel.Paint = function(self, w, h ) end
	ServerPanel:DockMargin( 0, 0, 0, 0 )
	ServerPanel:SetSize( FrameSizeX * 0.5, 32 )
	ServerPanel:Dock( RIGHT )
	ServerPanel.Paint = function(self, w, h ) 
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.SetMaterial( adminMat )
		surface.DrawTexturedRect( 3, 2, 16, 16 )
		draw.DrawText( "SERVER", "LVS_FONT", w * 0.5, 0, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	local DButton = vgui.Create( "DButton", DPanel )
	DButton:DockMargin( 0, 0, 0, 0 )
	DButton:SetText( "" )
	DButton:SetSize( FrameSizeX * 0.5, 32 )
	DButton:Dock( LEFT )
	DButton.DoClick = function()
		surface.PlaySound( "buttons/button14.wav" )
		LVS:OpenClientSettings()
	end
	DButton.Paint = function(self, w, h ) 
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(0, 0, w, h)

		local Hovered = self:IsHovered()

		if Hovered then
			draw.RoundedBox( 4, 1, 1, w-2, h-2, Color( 120, 120, 120, 255 ) )
		else
			draw.RoundedBox( 4, 1, 1, w-2, h-2, Color( 80, 80, 80, 255 ) )
		end

		local Col = Hovered and Color( 255, 255, 255, 255 ) or Color( 150, 150, 150, 255 )
		draw.DrawText( "CLIENT", "LVS_FONT", w * 0.5, 0, Col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	local Canvas = vgui.Create( "DPanel", BasePanel )
	Canvas.Paint = function(self, w, h ) end
	Canvas:DockMargin( 0, 0, 0, 0 )
	Canvas:SetSize( FrameSizeX, 25 )
	Canvas:Dock( FILL )

	ServerSettings( Canvas )
end

function LVS:OpenMenu()
	if IsValid( LVS.Frame ) then
		LVS.Frame:Close()
		LVS.Frame = nil
	end

	LVS.Frame = vgui.Create( "DFrame" )
	LVS.Frame:SetSize( FrameSizeX, FrameSizeY )
	LVS.Frame:SetTitle( "" )
	LVS.Frame:SetDraggable( true )
	LVS.Frame:SetScreenLock( true )
	LVS.Frame:MakePopup()
	LVS.Frame:Center()
	LVS.Frame.Paint = function(self, w, h )
		draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 255 ) )
		draw.RoundedBoxEx( 8, 1, 26, w-2, h-27, Color( 120, 120, 120, 255 ), false, false, true, true )
		draw.RoundedBoxEx( 8, 0, 0, w, 25, LVS.ThemeColor, true, true )

		draw.SimpleText( "[LVS] - Control Panel ", "LVS_FONT", 5, 11, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

		surface.SetDrawColor( 255, 255, 255, 50 )
		surface.SetMaterial( bgMat )
		surface.DrawTexturedRect( 0, -50, w, w )
	end
	LVS.Frame.CreatePanel = function( self )

		if IsValid( self.OldPanel ) then
			self.OldPanel:Remove()
			self.OldPanel = nil
		end

		local DPanel = vgui.Create( "DPanel", LVS.Frame )
		DPanel:SetPos( 0, 25 )
		DPanel:SetSize( FrameSizeX, FrameSizeY - 25 )
		DPanel.Paint = function(self, w, h )
			local Col = Color( 255, 191, 0, 255 ) 

			if LVS.VERSION_GITHUB == 0 then
				surface.SetMaterial( icon_load_version )
				surface.SetDrawColor( Col )
				surface.DrawTexturedRectRotated( w - 14, h - 14, 16, 16, -CurTime() * 200 )

				draw.SimpleText( "v"..LVS:GetVersion()..LVS.VERSION_TYPE, "LVS_VERSION", w - 23, h - 14, Col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
			else
				local Current = LVS:GetVersion()
				local Latest = LVS.VERSION_GITHUB

				local Pref = "v"

				if Current >= Latest then
					Col = Color(0,255,0,255)
				else
					Col = Color(255,0,0,255)
					Pref = "OUTDATED v"
				end

				draw.SimpleText( Pref..LVS:GetVersion()..LVS.VERSION_TYPE, "LVS_VERSION", w - 7, h - 14, Col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
			end
		end

		self.OldPanel = DPanel

		return DPanel
	end

	LVS:OpenClientSettings()
end

list.Set( "DesktopWindows", "LVSMenu", {
	title = "[LVS] Settings",
	icon = "icon64/iconlvs.png",
	init = function( icon, window )
		LVS:OpenMenu()
	end
} )

concommand.Add( "lvs_openmenu", function( ply, cmd, args ) LVS:OpenMenu() end )