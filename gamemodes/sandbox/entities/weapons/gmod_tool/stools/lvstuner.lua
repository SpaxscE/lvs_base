

TOOL.Category		= "LVS"
TOOL.Name			= "#Vehicle Editor"

TOOL.Information = {
	{ name = "left" },
	{ name = "right" },
	{ name = "reload" }
}

if CLIENT then
	language.Add( "tool.lvstuner.name", "Vehicle Editor" )
	language.Add( "tool.lvstuner.desc", "Edit internal variables of LVS-Vehicles" )
	language.Add( "tool.lvstuner.left", "Select Vehicle" )
	language.Add( "tool.lvstuner.right", "Edit Vehicle" )
	language.Add( "tool.lvstuner.reload", "Open Editor" )

	local function EditProperties( target )
		if not istable( target.lvsEditables ) then return end

		local frame = vgui.Create( "DFrame" )
		frame:SetSize( 512, ScrH() / 1.5 )
		frame:Center()
		frame:SetTitle("Editing: "..target.PrintName.." ("..target:GetVehicleType()..")" )
		frame:MakePopup()

		--target.lvsEditables

		local DScrollPanel = vgui.Create( "DScrollPanel", frame )
		DScrollPanel:Dock( FILL )

		for i=0, 100 do
			local DButton = DScrollPanel:Add( "DButton" )
			DButton:SetText( "Button #" .. i )
			DButton:Dock( TOP )
			DButton:DockMargin( 0, 0, 0, 5 )
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