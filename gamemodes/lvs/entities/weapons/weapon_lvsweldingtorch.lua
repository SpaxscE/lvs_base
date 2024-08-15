AddCSLuaFile()

SWEP.Base = "weapon_lvsrepair"
DEFINE_BASECLASS( "weapon_lvsrepair" )

if CLIENT then
	SWEP.PrintName		= "#lvs_tool_weldingtorch"
	SWEP.Author			= "Blu-x92"

	SWEP.Slot				= 5
	SWEP.SlotPos			= 1

	SWEP.Purpose			= "#lvs_tool_weldingtorch_info"
	SWEP.Instructions		= "#lvs_tool_weldingtorch_instructions"
	SWEP.DrawWeaponInfoBox 	= true

	SWEP.WepSelectIcon 			= surface.GetTextureID( "weapons/lvsrepair" )
end

function SWEP:GetLVS()
	local ply = self:GetOwner()

	if not IsValid( ply ) then return NULL end

	local ent = ply:GetEyeTrace().Entity

	if not IsValid( ent ) then return NULL end

	if ent.LVS or ent.IsFortification or ent._lvsPlayerSpawnPoint then return ent end

	if not ent.GetBase then return NULL end

	ent = ent:GetBase()

	if IsValid( ent ) and ent.LVS then return ent end

	return NULL
end