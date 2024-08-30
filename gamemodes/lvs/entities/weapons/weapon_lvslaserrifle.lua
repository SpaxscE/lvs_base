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

SWEP.Primary.ClipSize		= 8
SWEP.Primary.DefaultClip		= 16
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

local AllowedClasses = {
	["prop_door_rotating"] = true,
}

function SWEP:Vaporize( target, pos, dir )
	if not AllowedClasses[ target:GetClass() ] then return end

	local gib = ents.Create( "lvs_vaporized_door" )
	gib:SetPos( target:GetPos() )
	gib:SetAngles( target:GetAngles() )
	gib:SetModel( target:GetModel() )
	gib:SetSkin( target:GetSkin() )
	gib:SetHolePos( target:WorldToLocal( pos ) )
	gib:SetHoleDir( dir )
	gib:Spawn()

	target:Extinguish()
	target:SetNoDraw( true )
	target:SetNotSolid( true )

	target:Fire("unlock", "", 0)
	target:Fire("open", "", 0.05)
	target:Fire("kill", "", 0.1)
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

	ply:LagCompensation( true )

	local trace = util.TraceLine( {
		start = Pos,
		endpos = Pos + Dir * 5000000,
		filter = ply,
		mask = MASK_SHOT_PORTAL
	} )

	local traceWater = util.TraceLine( {
		start = Pos,
		endpos = Pos + Dir * 5000000,
		filter = ply,
		mask = MASK_WATER,
	} )

	if traceWater.Hit then
		local effectdata = EffectData()
		effectdata:SetOrigin( traceWater.HitPos )
		effectdata:SetScale( 5 )
		effectdata:SetFlags( 2 )
		util.Effect( "WaterSplash", effectdata, true, true )
	end

	local dmgMul = (math.Clamp( 2000 - (Pos - trace.HitPos):Length(), 0,1500 ) / 1500) ^ 2

	if SERVER and IsValid( trace.Entity ) then
		self:Vaporize( trace.Entity, trace.HitPos, trace.HitNormal )

		local dmg = DamageInfo()
		dmg:SetDamage( 35 + 35 * dmgMul )
		dmg:SetAttacker( ply )
		dmg:SetInflictor( self )
		dmg:SetDamageType( DMG_BULLET + DMG_DISSOLVE )
		dmg:SetDamagePosition( trace.HitPos )

		if trace.Entity:IsPlayer() then
			dmg:SetDamageForce( Dir * 40000 * dmgMul )

			trace.Entity:SetVelocity( Dir * 250 * dmgMul )
		else
			dmg:SetDamageForce( Dir * 4000 * dmgMul )
		end

		SuppressHostEvents( NULL ) 
		trace.Entity:TakeDamageInfo( dmg )
		SuppressHostEvents( ply )
	end

	ply:LagCompensation( false )

	self:TakePrimaryAmmo( 1 )

	if IsFirstTimePredicted() then
		self:EmitSound("LVS.ION_CANNON_FIRE")

		ply:ViewPunch( Angle(-1,0,0) + Angle(-2,-1,0) * dmgMul )

		if ply:OnGround() then
			Dir.z = 0
			Dir:Normalize()
		end

		ply:SetVelocity( -Dir * 200 * dmgMul )

		local effectdata = EffectData()
		effectdata:SetStart( trace.HitPos )
		effectdata:SetOrigin( self:GetPos() )
		effectdata:SetEntity( self )
		util.Effect( "lvs_laserrifle_tracer", effectdata )
	end
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
	self:SendWeaponAnim( ACT_VM_DRAW )

	return true
end

function SWEP:Holster( wep )
	return true
end
