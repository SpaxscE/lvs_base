AddCSLuaFile()

SWEP.Category				= "[LVS]"
SWEP.Spawnable			= true
SWEP.AdminSpawnable		= false
SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = ""
SWEP.ViewModelFOV = 54
SWEP.UseHands = false

SWEP.HoldType				= "normal"

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip		= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic		= false
SWEP.Secondary.Ammo		= "none"

SWEP.SpawnDistance = 512

function SWEP:SetupDataTables()
end

if CLIENT then
	SWEP.PrintName		= "#lvs_tool_spawnpoint"
	SWEP.Author			= "Luna"

	SWEP.Slot				= 4
	SWEP.SlotPos			= 3

	SWEP.Purpose			= "#lvs_tool_spawnpoint_info"
	SWEP.Instructions		= "#lvs_tool_spawnpoint_instructions"

	SWEP.DrawWeaponInfoBox 	= true

	--SWEP.WepSelectIcon 			= surface.GetTextureID( "weapons/lvsrepair" )

	function SWEP:PrimaryAttack()
	end

	function SWEP:SecondaryAttack()
	end

	function SWEP:Reload()
	end

	return
end

function SWEP:Think()
end

function SWEP:PrimaryAttack()
	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	if IsValid( ply:GetSpawnPoint() ) then
		ply:ChatPrint("#lvs_tool_spawnpoint_fail")

		return
	end

	ply:CreateSpawnPoint()

	ply:ChatPrint("#lvs_tool_spawnpoint_success")

	ply:EmitSound("buttons/lightswitch2.wav")
end

function SWEP:SecondaryAttack()
	self:Reload()
end

function SWEP:Reload()
	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	local oldSpawn = ply:GetSpawnPoint()

	if IsValid( oldSpawn ) then
		if GAMEMODE:GetGameState() >= GAMESTATE_BUILD then

			local MyTeam = ply:lvsGetAITeam()

			local CountTeam = 0

			for _, spawnpoint in ipairs( ents.FindByClass( "lvs_spawnpoint" ) ) do
				if spawnpoint:GetAITEAM() ~= MyTeam then continue end

				CountTeam = CountTeam + 1
			end

			local GoalEnt = GAMEMODE:GetGoalEntity()

			if CountTeam <= 1 or (IsValid( GoalEnt ) and GoalEnt:GetLinkedSpawnPoint() == oldSpawn) then

				ply:ChatPrint("#lvs_tool_spawnpoint_hint_active_game")

				return
			end
		end

		ply:ChatPrint("#lvs_tool_spawnpoint_deleted")
		ply:EmitSound("buttons/lever7.wav")

		oldSpawn:Remove()

		GAMEMODE:GameSpawnPointRemoved( ply, oldSpawn )
	end
end

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:Deploy()
	return true
end

function SWEP:Holster( wep )
	return true
end

function SWEP:OnRemove()
end

function SWEP:OnDrop()
end
