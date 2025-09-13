
TOOL.Category		= "LVS"
TOOL.Name			= "#Transmission Editor"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if CLIENT then
	language.Add( "tool.lvstransmission.name", "Transmission Editor" )
	language.Add( "tool.lvstransmission.desc", "A tool used to enable/disable Manual Transmission on LVS-Cars" )
	language.Add( "tool.lvstransmission.0", "Left click on a LVS-Car to enable Manual Transmission. Right click to disable." )
	language.Add( "tool.lvstransmission.1", "Left click on a LVS-Car to enable Manual Transmission. Right click to disable." )
end

function TOOL:LeftClick( trace )
	local ent = trace.Entity

	if not IsValid( ent ) then return false end

	if not ent.LVS then return end

	if isfunction( ent.SetNWGear ) and isfunction( ent.SetReverse ) then
		ent:SetNWGear( 1 )
		ent:SetReverse( false )
	end

	return true
end

function TOOL:RightClick( trace )
	local ent = trace.Entity

	if not IsValid( ent ) then return false end

	if not ent.LVS then return end

	if isfunction( ent.SetNWGear ) then
		ent:SetNWGear( -1 )
	end

	return true
end

function TOOL:Reload( trace )
	return false
end
