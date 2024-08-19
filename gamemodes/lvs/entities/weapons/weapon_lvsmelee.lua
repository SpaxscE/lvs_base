AddCSLuaFile()

SWEP.Base            = "weapon_lvsbasegun"

SWEP.Category				= "[LVS]"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= false

SWEP.ViewModel			= "models/weapons/c_arms.mdl"
SWEP.WorldModel			= ""
SWEP.UseHands				= true

SWEP.HoldType				= "fist"

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip		= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic		= false
SWEP.Secondary.Ammo		= "none"

SWEP.MeleeThirdPerson = true

if CLIENT then
	SWEP.PrintName		= "#GMOD_Fists"
	SWEP.Author			= "Blu-x92"

	SWEP.Slot				= 0
	SWEP.SlotPos			= 1

	function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
		draw.SimpleText( "D", "WeaponIcons", x + wide/2, y + tall*0.2, Color( 255, 210, 0, 255 ), TEXT_ALIGN_CENTER )
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

	local function Validate( ply )
		if not ply:Alive() or ply:GetViewEntity() ~= ply then return false end

		local weapon = ply:GetActiveWeapon()

		if not IsValid( weapon ) or not weapon.MeleeThirdPerson then return false end

		if ply:InVehicle() and not ply:GetAllowWeaponsInVehicle() then return false end

		return true
	end

	local circle = Material( "vgui/circle" )
	local size = 5

	function SWEP:DoDrawCrosshair( x, y )
		local ply = LocalPlayer()

		local pos = GetViewOrigin() + ply:EyeAngles():Forward() * 100

		local scr = pos:ToScreen()

		if scr.visible then
			surface.SetMaterial( circle )
			surface.SetDrawColor( 0, 0, 0, 255 )
			surface.DrawTexturedRect( scr.x - size * 0.5 + 1, scr.y - size * 0.5 + 1, size, size )

			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.DrawTexturedRect( scr.x - size * 0.5, scr.y - size * 0.5, size, size )
		end

		return true
	end

	function SWEP:CalcView( ply, pos, angles, fov )
		if not IsValid( ply ) or ply:GetViewEntity() ~= ply or not ply:Alive() then return end

		ply._lvsCalcViewTime = CurTime() + 0.1

		return GetViewOrigin(), ply:EyeAngles(), fov
	end

	-- this is used for when the CalcView hook somehow doesn't get called but the SWEP:CalcView function is. If the hook fails this will probably fail aswell tho
	hook.Add( "ShouldDrawLocalPlayer", "!!!!!!!!!!!!simple_thirdperson",  function( ply )
		if (ply._lvsCalcViewTime or 0) < CurTime() then return end

		if not Validate( ply ) then return end

		return true
	end )

	hook.Add( "CalcView", "!!!!!!!!!!!!simple_thirdperson",  function( ply, pos, angles, fov )
		if not Validate( ply ) then return end

		local view = {}
		view.origin = GetViewOrigin()
		view.angles = ply:EyeAngles()
		view.fov = fov
		view.drawviewer = true

		ply._lvsCalcViewTime = CurTime() + 0.1

		return view
	end )
end

function SWEP:Think()
end

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:PrimaryAttack()
	local ply = self:GetOwner()

	ply:SetAnimation( PLAYER_ATTACK1 )
end

function SWEP:SecondaryAttack()
	self:PrimaryAttack()
end

function SWEP:Reload()
end

function SWEP:OnRemove()
end

function SWEP:OnDrop()
end

function SWEP:OnDeploy()
	return true
end

function SWEP:Holster( wep )
	return true
end
