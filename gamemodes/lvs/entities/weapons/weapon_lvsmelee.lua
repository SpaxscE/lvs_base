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

SWEP.SprintTime = 10
SWEP.SprintSpeedAdd = 300

SWEP.MeleeThirdPerson = true
SWEP.MeleeAnimations = true

function SWEP:SetupDataTables()
	self:NetworkVar( "Bool", 1, "Sprinting" )
	self:NetworkVar( "Float", 1, "SprintTime" )
end

function SWEP:IsSprinting()
	local ply = self:GetOwner()

	if not IsValid( ply ) then return false end

	return ply:KeyDown( IN_SPEED ) and ply:KeyDown( IN_FORWARD ) and ply:GetVelocity():Length2D() > ply:GetWalkSpeed()
end

function SWEP:GetSpeedMultiplier()
	if not self:IsSprinting() then return 0 end

	return math.Clamp( 1 - (self:GetSprintTime() - CurTime()) / self.SprintTime, 0, 1 )
end

if CLIENT then
	SWEP.PrintName		= "#GMOD_Fists"
	SWEP.Author			= "Blu-x92"

	SWEP.Slot				= 3
	SWEP.SlotPos			= 1

	function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
		draw.SimpleText( "D", "WeaponIcons", x + wide/2, y + tall*0.2, Color( 255, 210, 0, 255 ), TEXT_ALIGN_CENTER )
	end

	local ColorNormal = color_white
	local ColorLow = Color(255,0,0,255)

	local function DrawPlayerHud( X, Y, ply )
		local kmh = math.Round(ply:GetVelocity():Length2D() * 0.09144,0)
		draw.DrawText( "km/h ", "LVS_FONT", X + 72, Y + 35, color_white, TEXT_ALIGN_RIGHT )
		draw.DrawText( kmh, "LVS_FONT_HUD_LARGE", X + 72, Y + 20, color_white, TEXT_ALIGN_LEFT )
	end

	function SWEP:DrawHUD()
		local ply = self:GetOwner()

		if not IsValid( ply ) or ply:InVehicle() or not ply:Alive() then return end

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
		if not ply:Alive() or ply:GetViewEntity() ~= ply then return false end

		local weapon = ply:GetActiveWeapon()

		if not IsValid( weapon ) or not weapon.MeleeThirdPerson or not isfunction( weapon.GetSpeedMultiplier ) then return false end

		if ply:InVehicle() and not ply:GetAllowWeaponsInVehicle() then return false end

		return weapon:GetSpeedMultiplier()
	end

	local function GetViewOrigin()
		local ply = LocalPlayer()

		if not IsValid( ply ) then return vector_origin end

		local angles = ply:EyeAngles()
		local pos = ply:GetShootPos()

		local clamped_angles = Angle( math.max( angles.p, -60 ), angles.y, angles.r )

		local endpos = pos - clamped_angles:Forward() * 100 + clamped_angles:Up() * 12

		local trace = util.TraceHull({
			start = pos,
			endpos = endpos,
			mask = MASK_SOLID_BRUSHONLY,
			mins = Vector(-5,-5,-5),
			maxs = Vector(5,5,5),
			filter = { ply },
		})

		return trace.HitPos
	end

	function SWEP:DoDrawCrosshair( x, y )
		return true
	end

	function SWEP:CalcView( ply, pos, angles, fov )
		if not IsValid( ply ) or ply:GetViewEntity() ~= ply or not ply:Alive() or ply:IsPlayingTaunt() then return end

		return GetViewOrigin(), ply:EyeAngles(), fov
	end

	local smFov = 0

	hook.Add( "CalcView", "!!!!!!!!!!!!simple_thirdperson",  function( ply, pos, angles, fov )
		local Multiplier = GetSpeedMultiplier( ply )

		if not Multiplier or ply:IsPlayingTaunt() then smFov = fov return end

		smFov = smFov + (fov * (1 - Multiplier) + 100 * Multiplier - smFov) * math.min( FrameTime() * 10, 1 )

		local view = {}
		view.origin = GetViewOrigin()
		view.angles = ply:EyeAngles()
		view.fov = smFov
		view.drawviewer = true

		return view
	end )

end

function SWEP:Think()
	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

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
