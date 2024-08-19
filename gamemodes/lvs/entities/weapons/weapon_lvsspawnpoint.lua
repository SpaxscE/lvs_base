AddCSLuaFile()

SWEP.Category				= "[LVS]"
SWEP.Spawnable			= true
SWEP.AdminSpawnable		= false
SWEP.ViewModel			= "models/weapons/c_arms.mdl"
SWEP.WorldModel			= ""
SWEP.ViewModelFOV			= 54
SWEP.UseHands				= false

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

function SWEP:GetRemoveTime()
	return 1
end

function SWEP:SetupDataTables()
	self:NetworkVar( "Float", 1, "SpawnRemoveTime" )
	self:NetworkVar( "Bool", 1, "SpawnValid" )
end

function SWEP:IsRequestingDelete()
	local ply = self:GetOwner()

	if not IsValid( ply ) then return false end

	if ply:InVehicle() and not ply:GetAllowWeaponsInVehicle() then return false end

	return ply:KeyDown( IN_ATTACK2 ) or ply:KeyDown( IN_RELOAD )
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

	local circles = include("includes/circles/circles.lua")

	local Circle = circles.New(CIRCLE_OUTLINED, 30, 0, 0, 5)
	Circle:SetColor( color_white )
	Circle:SetX( ScrW() * 0.5 )
	Circle:SetY( ScrH() * 0.5 )
	Circle:SetStartAngle( 0 )
	Circle:SetEndAngle( 0 )

	local ColorText = Color(255,255,255,255)

	local function DrawText( x, y, text, col )
		local font = "TargetIDSmall"

		draw.DrawText( text, font, x + 1, y + 1, Color( 0, 0, 0, 120 ), TEXT_ALIGN_CENTER )
		draw.DrawText( text, font, x + 2, y + 2, Color( 0, 0, 0, 50 ), TEXT_ALIGN_CENTER )
		draw.DrawText( text, font, x, y, col or color_white, TEXT_ALIGN_CENTER )
	end

	function SWEP:DoDrawCrosshair( x, y )
		if not self:GetSpawnValid() then return end

		local ply = LocalPlayer()

		if not self:IsRequestingDelete() then return end

		local Time = self:GetSpawnRemoveTime() - CurTime()
	
		local TimeLeft = math.Round( Time, Time > 1 and 0 or 1 )

		if TimeLeft < 0 then return end

		draw.DrawText( TimeLeft, "LVS_FONT_HUD_LARGE", x, y - 20, color_white, TEXT_ALIGN_CENTER )

		return true
	end

	function SWEP:DrawHUD()
		if not self:GetSpawnValid() then return end

		local ply = LocalPlayer()

		if not self:IsRequestingDelete() then return end

		local X = ScrW() * 0.5
		local Y = ScrH() * 0.5

		local RemoveTime = math.min( (self:GetSpawnRemoveTime() - CurTime()) / self:GetRemoveTime(), 1 )

		if RemoveTime < 0 then return end

		draw.NoTexture()

		Circle:SetX( X )
		Circle:SetY( Y )
		Circle:SetStartAngle( -360 * RemoveTime )
		Circle:SetEndAngle( 0 )
		Circle()
	end

	function SWEP:PrimaryAttack()
	end

	function SWEP:SecondaryAttack()
	end

	function SWEP:Reload()
	end

	return
end

function SWEP:Think()
	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	local Delete = self:IsRequestingDelete()
	local SpawnValid = IsValid( ply:GetSpawnPoint() )

	if self._oldDelete ~= Delete then
		self._oldDelete = Delete

		self:SetSpawnValid( SpawnValid )

		if Delete then
			self:SetSpawnRemoveTime( CurTime() + self:GetRemoveTime() )
		end
	end

	if not Delete or not SpawnValid then return end

	local RemoveTime = (self:GetSpawnRemoveTime() - CurTime()) / self:GetRemoveTime()

	if RemoveTime > 0 then return end

	self:DeleteSpawn()
end

function SWEP:PrimaryAttack()
	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	local GoalEnt = GAMEMODE:GetGoalEntity()

	if IsValid( GoalEnt ) and GoalEnt:GetHoldingPlayer() == ply then
		ply:ChatPrint("#lvs_tool_spawnpoint_fail_objective")

		return
	end

	if IsValid( ply:GetSpawnPoint() ) then
		ply:ChatPrint("#lvs_tool_spawnpoint_fail")

		return
	end

	if ply:WaterLevel() >= 1 then
		ply:ChatPrint("#lvs_tool_spawnpoint_underwater")

		return
	end

	ply:CreateSpawnPoint()

	ply:ChatPrint("#lvs_tool_spawnpoint_success")

	ply:EmitSound("buttons/lightswitch2.wav")
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
end

function SWEP:DeleteSpawn()
	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	local oldSpawn = ply:GetSpawnPoint()

	if IsValid( oldSpawn ) then
		if GAMEMODE:GetGameState() == GAMESTATE_MAIN then
			local GoalEnt = GAMEMODE:GetGoalEntity()

			if IsValid( GoalEnt ) and GoalEnt:GetLinkedSpawnPoint() == oldSpawn then

				ply:ChatPrint("#lvs_tool_spawnpoint_hint_active_game")

				return
			end
		end
	
		if GAMEMODE:GetGameState() == GAMESTATE_BUILD then

			local MyTeam = ply:lvsGetAITeam()

			local CountTeam = 0

			for _, spawnpoint in ipairs( ents.FindByClass( "lvs_spawnpoint" ) ) do
				if spawnpoint:GetAITEAM() ~= MyTeam then continue end

				CountTeam = CountTeam + 1
			end

			if CountTeam <= 1 then

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
