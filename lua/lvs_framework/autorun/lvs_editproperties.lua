
if SERVER then
	util.AddNetworkString( "lvs_variable_editor" )

	return
end

local function MakeSlider( parent, data )
	if not data.name or not data.min or not data.max then return end

	local DNumSlider = vgui.Create( "DNumSlider", parent )
	DNumSlider:DockMargin( 16, 4, 16, 0 )
	DNumSlider:Dock( TOP )
	DNumSlider:SetText( data.name )
	DNumSlider:SetMin( data.min )
	DNumSlider:SetMax( data.max )
	DNumSlider:SetDecimals( data.type == "float" and 2 or 0 )
	function DNumSlider:OnValueChanged( val )
	end

	return DNumSlider
end

local function MakeCheckbox( parent, data )
	local DPanel = vgui.Create( "DPanel", parent )
	DPanel:DockMargin( 16, 4, 16, 0 )
	DPanel:SetSize( 512, 32 )
	DPanel:Dock( TOP )
	DPanel.Paint = function(self, w, h ) end

	local DCheckBoxLabel = vgui.Create( "DCheckBoxLabel", DPanel )
	DCheckBoxLabel:DockMargin( 0, 0, 240, 0 )
	DCheckBoxLabel:SetSize( 256, 32 )
	DCheckBoxLabel:Dock( RIGHT )
	DCheckBoxLabel:SetText( "" )
	DCheckBoxLabel:SizeToContents()
	function DCheckBoxLabel:OnValueChanged( val )
	end
	function DCheckBoxLabel:OnChange( val )
		self:OnValueChanged( val )
	end

	local DLabel = vgui.Create( "DLabel", DPanel )
	DLabel:Dock( LEFT )
	DLabel:SetSize( 256, 32 )
	DLabel:SetText( data.name )

	return DCheckBoxLabel
end

local gradient = Material( "gui/gradient" )
local gradient_down = Material( "gui/gradient_down" )

function LVS:EditProperties( target )
	if not istable( target.lvsEditables ) then return end

	local frame = vgui.Create( "DFrame" )
	frame:SetSize( 512, ScrH() / 1.5 )
	frame:Center()
	frame:SetTitle("")
	frame:MakePopup()
	frame.Paint = function(self, w, h )
		draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 255 ) )
		draw.RoundedBoxEx( 8, 1, 26, w-2, h-27, Color( 120, 120, 120, 255 ), false, false, true, true )
		draw.RoundedBoxEx( 8, 0, 0, w, 25, LVS.ThemeColor, true, true )

		draw.SimpleText( "Editing: "..target.PrintName.." ("..target:GetVehicleType()..")", "LVS_FONT", 5, 11, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	end

	local DScrollPanel = vgui.Create( "DScrollPanel", frame )
	DScrollPanel:DockMargin( -4, -3, -4, 0 )
	DScrollPanel:Dock( FILL )

	for _, data in ipairs( target.lvsEditables ) do
		if not data.Category then continue end

		local DPanel = vgui.Create( "DPanel", DScrollPanel )
		DPanel:DockMargin( 0, 0, 0, 0 )
		DPanel:SetSize( 512, 32 )
		DPanel:Dock( TOP )
		DPanel.Paint = function(self, w, h ) 
			surface.SetMaterial( gradient_down )
			surface.SetDrawColor( 80, 80, 80, 255 )
			surface.DrawTexturedRect( 0, 0, w, h )

			surface.SetMaterial( gradient )
			surface.SetDrawColor( 0, 0, 0, 255 )
			surface.DrawTexturedRect( 0, 0, w, 2 )

			draw.DrawText( data.Category, "LVS_FONT", 8, 3, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		end

		if not istable( data.Options ) then continue end

		for _, entry in ipairs( data.Options ) do
			local Editor

			if entry.type == "int" or entry.type == "float" then
				Editor = MakeSlider( DScrollPanel, entry )
			else
				if entry.type == "bool" then
					Editor = MakeCheckbox( DScrollPanel, entry )
				end
			end

			if not Editor then continue end

			Editor:SetValue( target[ entry.name ] )

			function Editor:OnValueChanged( val )
				--PrintChat( val )
			end
		end
	end
end

if not properties or not isfunction( properties.Add ) then return end

properties.Add( "lvs_edit_vehicle", {
	MenuLabel = "[LVS] Viewer",
	Order = 90002,
	MenuIcon = "icon16/lvs.png",
	Filter = function( self, ent, ply )
		if not IsValid( ent ) then return false end
		if not istable( ent.lvsEditables ) then return false end
		if not gamemode.Call( "CanProperty", ply, "lvs_edit_vehicle", ent ) then return false end

		return true
	end,
	Action = function( self, ent )
		LVS:EditProperties( ent )
	end
} )
