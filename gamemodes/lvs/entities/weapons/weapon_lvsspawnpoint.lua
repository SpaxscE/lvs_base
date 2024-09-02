AddCSLuaFile()

SWEP.Base            = "weapon_lvsbasegun"

SWEP.Category				= "[LVS]"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= false

SWEP.ViewModel			= "models/weapons/c_arms.mdl"
SWEP.WorldModel			= "models/weapons/c_arms.mdl"
SWEP.UseHands				= true
SWEP.ViewModelFOV			= 90

SWEP.HoldType				= "normal"
SWEP.HoldTypeFlashlight		= "pistol"

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip		= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic		= false
SWEP.Secondary.Ammo		= "none"

SWEP.SprintTime = 3
SWEP.SprintSpeedAdd = 300

SWEP.MeleeThirdPerson = true
SWEP.MeleeAnimations = true

SWEP.SpawnDistance = 512
SWEP.SpawnDistanceEnemy = 2048

SWEP.RemoveTime = 10

function SWEP:GetRemoveTime()
	if GAMEMODE:GetGameState() <= GAMESTATE_BUILD then return 1 end

	return self.RemoveTime
end

function SWEP:SetupDataTables()
	self:NetworkVar( "Bool", 1, "Sprinting" )
	self:NetworkVar( "Float", 1, "SprintTime" )

	self:NetworkVar( "Float", 2, "SpawnRemoveTime" )
	self:NetworkVar( "Bool", 2, "SpawnValid" )
end

function SWEP:IsSprinting()
	local ply = self:GetOwner()

	if not IsValid( ply ) then return false end

	local IsSprinting = ply:KeyDown( IN_SPEED ) and ply:KeyDown( IN_FORWARD ) and ply:GetVelocity():Length2D() > ply:GetWalkSpeed()

	if not IsSprinting then return false end

	local GoalEnt = GAMEMODE:GetGoalEntity()

	if IsValid( GoalEnt ) and GoalEnt:GetHoldingPlayer() == ply then return false end

	return not IsValid( ply:GetSpawnPoint() )
end

function SWEP:GetSpeedMultiplier()
	if not self:IsSprinting() then return 0 end

	return math.Clamp( 1 - (self:GetSprintTime() - CurTime()) / self.SprintTime, 0, 1 )
end

function SWEP:IsRequestingDelete()
	local ply = self:GetOwner()

	if not IsValid( ply ) then return false end

	if ply:InVehicle() and not ply:GetAllowWeaponsInVehicle() then return false end

	return (ply:KeyDown( IN_ATTACK2 ) or ply:KeyDown( IN_RELOAD )) and not ply:KeyDown( IN_ATTACK )
end

if CLIENT then
	SWEP.PrintName		= "#lvs_tool_spawnpoint"
	SWEP.Author			= "Luna"

	SWEP.Slot				= 3
	SWEP.SlotPos			= 1

	SWEP.Purpose			= "#lvs_tool_spawnpoint_info"
	SWEP.Instructions		= "#lvs_tool_spawnpoint_instructions"

	SWEP.DrawWeaponInfoBox 	= true

	function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
		draw.SimpleText( "?", "WeaponIcons", x + wide/2, y + tall*0.2, Color( 255, 210, 0, 255 ), TEXT_ALIGN_CENTER )

		-- Borders
		y = y + 10
		x = x + 10
		wide = wide - 20

		-- Draw weapon info box
		self:PrintWeaponInfo( x + wide + 20, y + tall * 0.95, alpha )
	end

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
		if not self:GetSpawnValid() then return true end

		local ply = LocalPlayer()

		if not self:IsRequestingDelete() then return true end

		local Time = self:GetSpawnRemoveTime() - CurTime()
	
		local TimeLeft = math.Round( Time, Time > 1 and 0 or 1 )

		if TimeLeft < 0 then return true end

		draw.DrawText( TimeLeft, "LVS_FONT_HUD_LARGE", x, y - 20, color_white, TEXT_ALIGN_CENTER )

		return true
	end

	local ColorNormal = color_white
	local ColorLow = Color(255,0,0,255)

	local function DrawPlayerHud( X, Y, ply )
		local kmh = math.Round(ply:GetVelocity():Length2D() * 0.09144,0)
		draw.DrawText( "km/h ", "LVS_FONT", X + 72, Y + 35, color_white, TEXT_ALIGN_RIGHT )
		draw.DrawText( kmh, "LVS_FONT_HUD_LARGE", X + 72, Y + 20, color_white, TEXT_ALIGN_LEFT )
	end

	function SWEP:DrawHUDInfo( ply )
		if ply:InVehicle() or not ply:Alive() then return end

		local editor = LVS.HudEditors["VehicleInfo"]

		if not editor then return end

		local X = ScrW()
		local Y = ScrH()

		local ScaleX = editor.w / editor.DefaultWidth
		local ScaleY = editor.h / editor.DefaultHeight

		local PosX = editor.X / ScaleX
		local PosY = editor.Y / ScaleY

		local Width = editor.w / ScaleX
		local Height = editor.h / ScaleY

		local ScrW = X / ScaleX
		local ScrH = Y / ScaleY

		if ScaleX == 1 and ScaleY == 1 then
			DrawPlayerHud( PosX, PosY, ply )
		else
			local m = Matrix()
			m:Scale( Vector( ScaleX, ScaleY, 1 ) )

			cam.PushModelMatrix( m )
				DrawPlayerHud( PosX, PosY, ply )
			cam.PopModelMatrix()
		end
	end

	function SWEP:DrawHUD()
		local ply = self:GetOwner()

		if not IsValid( ply ) then return end

		self:DrawHUDInfo( ply )

		if not self:GetSpawnValid() or not self:IsRequestingDelete() then return end

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

	function SWEP:DrawWorldModel()
	end

	hook.Add("CalcMainActivity", "!!!!!lvs_testanim", function( ply )
		if ply:FlashlightIsOn() or ply:InVehicle() or not ply:OnGround() or ply:IsFlagSet( FL_ANIMDUCKING ) or ply.m_bInSwim then return end

		local weapon = ply:GetActiveWeapon() 

		if not IsValid( weapon ) or not weapon.MeleeAnimations then return end

		local vel = ply:GetVelocity()
		local velL = ply:WorldToLocal( ply:GetPos() + vel )

		if velL.x < 1 or velL.x < math.abs(velL.y) * 0.95 then return end

		if vel:Length2D() <= 250 then return end

		ply.CalcIdeal = ACT_MP_RUN
		ply.CalcSeqOverride = ply:LookupSequence( "run_all_02" )

		return ply.CalcIdeal, ply.CalcSeqOverride
	end)

	local function GetSpeedMultiplier( ply )
		local weapon = ply:GetActiveWeapon()

		if not IsValid( weapon ) or not weapon.MeleeThirdPerson or not isfunction( weapon.GetSpeedMultiplier ) then return false end

		if weapon.ShouldFirstPerson and weapon:ShouldFirstPerson() then return false end

		if ply:InVehicle() and not ply:GetAllowWeaponsInVehicle() then return false end

		return weapon:GetSpeedMultiplier()
	end

	local function GetViewOrigin( ply )
		if not ply then
			ply = LocalPlayer()
		end

		if not IsValid( ply ) then return vector_origin end

		local angles = ply:EyeAngles()
		local pos = ply:GetShootPos()

		local clamped_angles = Angle( math.max( angles.p, -60 ), angles.y, angles.r )

		local endpos = pos - clamped_angles:Forward() * 100 + clamped_angles:Up() * 12

		local trace = util.TraceHull({
			start = pos,
			endpos = endpos,
			mins = Vector(-5,-5,-5),
			maxs = Vector(5,5,5),
			filter = { ply },
		})

		return trace.HitPos
	end

	function SWEP:ShouldFirstPerson()
		local ply = self:GetOwner()

		if not IsValid( ply ) or ply:GetViewEntity() ~= ply or not ply:Alive() or ply:IsPlayingTaunt() then return true end

		local pos = ply:GetShootPos()

		if (GetViewOrigin( ply ) - pos):Length() < 20 then return true end

		return false
	end

	function SWEP:CalcView( ply, pos, angles, fov )
		if self:ShouldFirstPerson() then return end

		return GetViewOrigin(), ply:EyeAngles(), fov
	end

	local smFov = 0

	hook.Add( "CalcView", "!!!!!!!!!!!!simple_thirdperson",  function( ply, pos, angles, fov )
		local Multiplier = GetSpeedMultiplier( ply )

		if not Multiplier then smFov = fov return end

		smFov = smFov + (fov * (1 - Multiplier) + 100 * Multiplier - smFov) * math.min( FrameTime() * 10, 1 )

		local view = {}
		view.origin = GetViewOrigin()
		view.angles = ply:EyeAngles()
		view.fov = smFov
		view.drawviewer = true

		return view
	end )

end

function SWEP:SpawnDeleteThink( ply )
	local Delete = self:IsRequestingDelete()
	local SpawnValid = IsValid( ply:GetSpawnPoint() )

	if self._oldDelete ~= Delete then
		self._oldDelete = Delete

		self:SetSpawnValid( SpawnValid )

		if Delete then
			self:SetSpawnRemoveTime( CurTime() + self:GetRemoveTime() )

			self._HintedOnce = nil
		end
	end

	if not Delete or not SpawnValid then return end

	local RemoveTime = (self:GetSpawnRemoveTime() - CurTime()) / self:GetRemoveTime()

	if RemoveTime > 0 then return end

	self:DeleteSpawn()
end

function SWEP:Think()
	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	if SERVER then
		self:SpawnDeleteThink( ply )
	end

	local LightsOn = ply:FlashlightIsOn() 

	if ply._OldFlashLightOn ~= LightsOn then
		ply._OldFlashLightOn = LightsOn

		if LightsOn then
			self:SetHoldType( self.HoldTypeFlashlight )
		else
			self:SetHoldType( self.HoldType )
		end
	end

	local T = CurTime()

	local Sprinting = self:IsSprinting()

	if Sprinting ~= self:GetSprinting() then
		self:SetSprinting( Sprinting )

		if Sprinting then
			self:SetSprintTime( T + self.SprintTime )
		else
			self:ResetPlayerSpeed()
		end
	end

	if not Sprinting then return end

	self:SetPlayerSpeed( self:GetOriginalSpeed() + self.SprintSpeedAdd * self:GetSpeedMultiplier() )
end

function SWEP:Initialize()
	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	if ply:FlashlightIsOn() then
		self:SetHoldType( self.HoldTypeFlashlight )
	else
		self:SetHoldType( self.HoldType )
	end
end

function SWEP:PrimaryAttack()
	if CLIENT then return end

	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	local MyTeam = ply:lvsGetAITeam()
	local MyPos = ply:GetPos()
	for _, spawnpoint in ipairs( ents.FindByClass( "lvs_spawnpoint" ) ) do
		local Team = spawnpoint:GetAITEAM()

		if Team == MyTeam then continue end

		if (spawnpoint:GetPos() - MyPos):Length() < self.SpawnDistanceEnemy then
			ply:ChatPrint("#lvs_tool_spawnpoint_fail_enemy")

			return
		end
	end

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

function SWEP:OnRemove()
	self:ResetPlayerSpeed()
end

function SWEP:OnDrop()
	self:ResetPlayerSpeed()

	self:Remove() -- You can't drop fists
end

function SWEP:Deploy()

	local ply = self:GetOwner()

	if IsValid( ply ) then
		local vm = ply:GetViewModel()
		vm:SendViewModelMatchingSequence( vm:LookupSequence( "seq_admire" ) )
		vm:SetPlaybackRate( 1 )
	end

	self:ResetPlayerSpeed()
	self:SetSprinting( false )

	return true
end

function SWEP:Holster( wep )
	self:ResetPlayerSpeed()
	self:SetSprinting( false )

	return true
end

if CLIENT then return end

function SWEP:DeleteSpawn()
	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	local oldSpawn = ply:GetSpawnPoint()

	if IsValid( oldSpawn ) then
		if GAMEMODE:GetGameState() == GAMESTATE_MAIN then
			local GoalEnt = GAMEMODE:GetGoalEntity()

			if IsValid( GoalEnt ) and GoalEnt:GetLinkedSpawnPoint() == oldSpawn then

				if not self._HintedOnce then
					ply:ChatPrint("#lvs_tool_spawnpoint_hint_active_game")

					self._HintedOnce = true
				end

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

				if not self._HintedOnce then
					ply:ChatPrint("#lvs_tool_spawnpoint_hint_active_game")

					self._HintedOnce = true
				end

				return
			end
		end

		if not self._HintedOnce then
			ply:ChatPrint("#lvs_tool_spawnpoint_deleted")
			ply:EmitSound("buttons/lever7.wav")

			self._HintedOnce = true
		end

		oldSpawn:Remove()

		GAMEMODE:GameSpawnPointRemoved( ply, oldSpawn )
	end
end