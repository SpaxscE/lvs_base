

TOOL.Category		= "LVS"
TOOL.Name			= "#Tuning Remover"

TOOL.Information = {
	{ name = "left" },
	{ name = "right" },
}

if CLIENT then
	language.Add( "tool.lvscartuningremover.name", "Tuning Remover" )
	language.Add( "tool.lvscartuningremover.desc", "A tool used to remove Turbo + Compressor on [LVS-Cars]" )
	language.Add( "tool.lvscartuningremover.left", "Remove Turbo" )
	language.Add( "tool.lvscartuningremover.right", "Remove Compressor" )
end

function TOOL:IsValidTarget( ent )
	if not IsValid( ent ) then return false end

	if not ent.LVS or not ent.GetCompressor or not ent.GetTurbo then return false end

	return true
end

local function DoRemoveEntity( ent )
	timer.Simple( 1, function() if ( IsValid( ent ) ) then ent:Remove() end end )

	ent:SetNotSolid( true )
	ent:SetMoveType( MOVETYPE_NONE )
	ent:SetNoDraw( true )

	local ed = EffectData()
		ed:SetOrigin( ent:GetPos() )
		ed:SetEntity( ent )
	util.Effect( "entity_remove", ed, true, true )
end

function TOOL:LeftClick( trace )
	local ent = trace.Entity

	if not self:IsValidTarget( ent ) then return false end

	local Turbo = ent:GetTurbo()
	local Compressor = ent:GetCompressor()

	local Removed = false

	if IsValid( Turbo ) and not Turbo._RemoveRememberThis then
		Turbo._RemoveRememberThis = true

		if SERVER then DoRemoveEntity( Turbo ) end

		Removed = true
	end

	return Removed
end

function TOOL:RightClick( trace )
	local ent = trace.Entity

	if not self:IsValidTarget( ent ) then return false end

	local Turbo = ent:GetTurbo()
	local Compressor = ent:GetCompressor()

	local Removed = false

	if IsValid( Compressor ) and not Compressor._RemoveRememberThis then
		Compressor._RemoveRememberThis = true

		if SERVER then DoRemoveEntity( Compressor ) end

		Removed = true
	end

	return Removed
end

function TOOL:Reload( trace )
	return false
end
