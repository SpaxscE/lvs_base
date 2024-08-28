AddCSLuaFile()

SWEP.Base            = "weapon_lvsbasegun"

SWEP.Category				= "[LVS]"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= false

SWEP.ViewModel			= "models/weapons/c_irifle.mdl"
SWEP.WorldModel			= "models/weapons/w_irifle.mdl"
SWEP.UseHands				= true
SWEP.ViewModelFOV = 42

SWEP.HoldType				= "shotgun"

SWEP.Primary.ClipSize		= 6
SWEP.Primary.DefaultClip		= 12
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "GaussEnergy"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic		= false
SWEP.Secondary.Ammo		= "none"

SWEP.AmmoWarningCountClip = 1
SWEP.AmmoWarningCountMag = 5

if CLIENT then
	SWEP.PrintName		= "#lvs_weapon_laserrifle"
	SWEP.Author			= "Blu-x92"

	SWEP.Slot				= 1
	SWEP.SlotPos			= 2

	function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
		draw.SimpleText( "l", "WeaponIcons", x + wide/2, y + tall*0.2, Color( 255, 210, 0, 255 ), TEXT_ALIGN_CENTER )
	end
end

function SWEP:Think()
end

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	local T = CurTime()

	self:SetNextPrimaryFire( T + 0.6 )

	self:ShootEffects()

	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	local Pos = ply:GetShootPos()
	local Dir = ply:GetAimVector()

	if SERVER then
		ply:LagCompensation( true )

		local trace = ply:GetEyeTrace()

		if trace.Entity:IsPlayer() then
			local dmg = DamageInfo()
			dmg:SetDamageForce( vector_origin )
			dmg:SetDamage( 25 + (self:Clip1() / self.Primary.ClipSize) * 175 )
			dmg:SetAttacker( ply )
			dmg:SetInflictor( self )
			dmg:SetDamageType( DMG_ALWAYSGIB + DMG_DISSOLVE )
			dmg:SetDamagePosition( trace.HitPos )
			trace.Entity:TakeDamageInfo( dmg )
		end

		ply:LagCompensation( false )
	end

	self:TakePrimaryAmmo( 1 )

	if IsFirstTimePredicted() then
		self:EmitSound("LVS.ION_CANNON_FIRE")

		-- make this a counter strike spread pattern?
		local Recoil = Angle(-1,-0.25,0)

		ply:ViewPunch( Recoil )

		local EyeAng = ply:EyeAngles()
		EyeAng.p = math.Clamp( EyeAng.p + Recoil.p, -90, 90 )
		EyeAng.y = EyeAng.y + Recoil.y

		ply:SetEyeAngles( EyeAng )

		Dir.z = 0
		Dir:Normalize()

		ply:SetVelocity( -Dir * 150 )

		local effectdata = EffectData()
		effectdata:SetStart( ply:GetEyeTrace().HitPos )
		effectdata:SetOrigin( self:GetPos() )
		effectdata:SetEntity( self )
		util.Effect( "lvs_laserrifle_tracer", effectdata )
	end
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
	if self:Clip1() >= self.Primary.ClipSize or self:GetOwner():GetAmmoCount( self.Primary.Ammo ) == 0 then return end

	self:TakePrimaryAmmo( self:Clip1() )

	self:DefaultReload( ACT_VM_RELOAD )
end

function SWEP:OnRemove()
end

function SWEP:OnDrop()
end

function SWEP:Deploy()
	self:SendWeaponAnim( ACT_VM_DRAW )

	return true
end

function SWEP:Holster( wep )
	return true
end
