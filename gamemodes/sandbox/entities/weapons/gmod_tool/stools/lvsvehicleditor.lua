

TOOL.Category		= "LVS"
TOOL.Name			= "#Vehicle Editor"

TOOL.Information = {
	{ name = "left" },
	{ name = "right" },
	{ name = "reload" }
}

if CLIENT then
	language.Add( "tool.lvsvehicleditor.name", "Vehicle Editor" )
	language.Add( "tool.lvsvehicleditor.desc", "Edit internal variables of LVS-Vehicles" )
	language.Add( "tool.lvsvehicleditor.left", "Select Vehicle" )
	language.Add( "tool.lvsvehicleditor.right", "Edit Vehicle" )
	language.Add( "tool.lvsvehicleditor.reload", "Open Editor" )

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
	local function EditProperties( target )
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

			draw.SimpleText( "Editing: "..target.PrintName.." ("..target:GetVehicleType()..")", "LVS_FONT", 5, 11, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		end

		local DScrollPanel = vgui.Create( "DScrollPanel", frame )
		DScrollPanel:Dock( FILL )

		for _, data in ipairs( target.lvsEditables ) do
			if not data.Category then continue end

			local DPanel = vgui.Create( "DPanel", DScrollPanel )
			DPanel:DockMargin( 0, 0, 0, 0 )
			DPanel:SetSize( 512, 32 )
			DPanel:Dock( TOP )
			DPanel.Paint = function(self, w, h ) 
				surface.SetMaterial( gradient )
				surface.SetDrawColor( 80, 80, 80, 255 )
				surface.DrawTexturedRect( 0, h - 2, w, 2 )

				draw.DrawText( data.Category, "LVS_FONT", 0, 3, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
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

	function TOOL:Reload( trace )
		local ent = self:GetSelectedEntity()

		if IsValid( ent ) then
			EditProperties( ent )
		end

		return false
	end

	function TOOL:DrawHUD()
		local ent = self:GetSelectedEntity()

		if not IsValid( ent ) then return end

		local t = { ent }

		if ent.GetCrosshairFilterEnts then
			for _, e in pairs( ent:GetCrosshairFilterEnts() ) do
				table.insert( t, e )
			end
		end

		halo.Add( t, Color(255,255,255,255), 2, 2, 1 )
	end
else
	function TOOL:Reload( trace )
		return false
	end
end

function TOOL:GetSelectedEntity()
	return self:GetWeapon():GetNWEntity( 1 )
end

function TOOL:SetSelectedEntity( ent )
	if not IsValid( ent ) or not ent.LVS then
		self:GetWeapon():SetNWEntity( 1, NULL )

		return
	end

	self:GetWeapon():SetNWEntity( 1, ent )
end

function TOOL:LeftClick( trace )

	if self:GetSelectedEntity() == trace.Entity then
		self:SetSelectedEntity( NULL )
	else
		self:SetSelectedEntity( trace.Entity )
	end

	return true
end

function TOOL:RightClick( trace )

	self:SetSelectedEntity( trace.Entity )

	self:Reload( trace )

	return true
end