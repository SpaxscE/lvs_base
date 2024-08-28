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

SWEP.Primary.ClipSize		= 12
SWEP.Primary.DefaultClip		= 12
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "GaussEnergy"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic		= false
SWEP.Secondary.Ammo		= "none"

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

	self:SetNextPrimaryFire( CurTime() + 0.7 )

	self:TakePrimaryAmmo( 1 )

	self:ShootEffects()

	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	if IsFirstTimePredicted() then
		self:EmitSound("LVS.ION_CANNON_FIRE")

		-- make this a counter strike spread pattern?
		local Recoil = Angle(-1,-0.25,0)

		ply:ViewPunch( Recoil )

		local EyeAng = ply:EyeAngles()
		EyeAng.p = math.Clamp( EyeAng.p + Recoil.p, -90, 90 )
		EyeAng.y = EyeAng.y + Recoil.y

		ply:SetEyeAngles( EyeAng )

		local effectdata = EffectData()
		effectdata:SetStart( ply:GetEyeTrace().HitPos )
		effectdata:SetOrigin( self:GetPos() )
		effectdata:SetEntity( self )
		util.Effect( "lvs_laserrifle_tracer", effectdata )
	end

	if CLIENT then return end

	ply:LagCompensation( true )

	local trace = ply:GetEyeTrace()
	local traceHull = util.TraceHull( {
		start = ply:GetShootPos(),
		endpos = ply:GetShootPos() + ply:GetAimVector() * 500000,
		mins = Vector(-5,-5,-5),
		maxs = Vector(5,5,5),
		mask = MASK_SHOT_HULL,
		filter = ply,
	} )

	if not trace.Entity:IsPlayer() and traceHull.Entity:IsPlayer() then
		local dmg = DamageInfo()
		dmg:SetDamageForce( vector_origin )
		dmg:SetDamage( 25 )
		dmg:SetAttacker( ply )
		dmg:SetInflictor( self )
		dmg:SetDamageType( DMG_DISSOLVE )
		dmg:SetDamagePosition( traceHull.HitPos )
		traceHull.Entity:TakeDamageInfo( dmg )
	end

	if trace.Entity:IsPlayer() or trace.Entity._lvsLaserGunDetectHit then
		local dmg = DamageInfo()
		dmg:SetDamageForce( vector_origin )
		dmg:SetDamage( 50 )
		dmg:SetAttacker( ply )
		dmg:SetInflictor( self )
		dmg:SetDamageType( DMG_ALWAYSGIB + DMG_DISSOLVE )
		dmg:SetDamagePosition( trace.HitPos )
		trace.Entity:TakeDamageInfo( dmg )
	end

	ply:LagCompensation( false )
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
	self:DefaultReload( ACT_VM_RELOAD )
end

function SWEP:OnRemove()
end

function SWEP:OnDrop()
end

function SWEP:Deploy()
	return true
end

function SWEP:Holster( wep )
	return true
end
