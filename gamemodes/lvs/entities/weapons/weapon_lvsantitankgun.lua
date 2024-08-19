AddCSLuaFile()

SWEP.Base            = "weapon_lvsbasegun"

SWEP.Category				= "[LVS]"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= false

SWEP.ViewModel			= "models/weapons/c_rpg.mdl"
SWEP.WorldModel			= "models/weapons/w_rocket_launcher.mdl"
SWEP.UseHands				= true

SWEP.HoldType				= "rpg"

SWEP.Primary.ClipSize		= 4
SWEP.Primary.DefaultClip		= 4
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "SniperRound"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic		= false
SWEP.Secondary.Ammo		= "none"

function SWEP:SetupDataTables()
end

if CLIENT then
	SWEP.PrintName		= "#lvs_weapon_antitankgun"
	SWEP.Author			= "Blu-x92"

	SWEP.Slot				= 2
	SWEP.SlotPos			= 1

	function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
		draw.SimpleText( "i", "WeaponIcons", x + wide/2, y + tall*0.2, Color( 255, 210, 0, 255 ), TEXT_ALIGN_CENTER )
	end

	function SWEP:SetWeaponHoldType( t )
		t = string.lower( t )

		local index = ACT_HL2MP_IDLE_RPG

		self.ActivityTranslate = {}
		self.ActivityTranslate[ ACT_MP_STAND_IDLE ]					= index
		self.ActivityTranslate[ ACT_MP_WALK ]						= index + 1
		self.ActivityTranslate[ ACT_MP_RUN ]						= index + 2
		self.ActivityTranslate[ ACT_MP_CROUCH_IDLE ]				= index + 3
		self.ActivityTranslate[ ACT_MP_CROUCHWALK ]					= index + 4
		self.ActivityTranslate[ ACT_MP_ATTACK_STAND_PRIMARYFIRE ]	= index + 5
		self.ActivityTranslate[ ACT_MP_ATTACK_CROUCH_PRIMARYFIRE ]	= index + 5
		
		if t == "rpg" then
			self.ActivityTranslate[ ACT_MP_RELOAD_STAND ]				= ACT_HL2MP_IDLE_PISTOL + 6
			self.ActivityTranslate[ ACT_MP_RELOAD_CROUCH ]				= ACT_HL2MP_IDLE_PISTOL + 6
		end
		
		self.ActivityTranslate[ ACT_MP_JUMP ]						= index + 7
		self.ActivityTranslate[ ACT_RANGE_ATTACK1 ]					= index + 8
		self.ActivityTranslate[ ACT_MP_SWIM ]						= index + 9

		self:SetupWeaponHoldTypeForAI( t )

	end
end

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	self:SetNextPrimaryFire( CurTime() + 1 )

	self:TakePrimaryAmmo( 1 )

	self:ShootEffects()

	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	if IsFirstTimePredicted() then
		self:EmitSound("weapons/ar2/ar2_altfire.wav",75,80,1,CHAN_ITEM)
		self:EmitSound("weapons/flaregun/fire.wav",75,255,1)

		ply:ViewPunch( Angle(-math.Rand(3,5),-math.Rand(3,5),0) )
	end

	if CLIENT then return end

	local bullet = {}
	bullet.Src = ply:GetShootPos() + ply:EyeAngles():Right() * 7

	bullet.Dir = (ply:GetEyeTrace().HitPos - bullet.Src):GetNormalized()

	bullet.Spread 	= Vector(0.1,0.1,0.1) * math.min( ply:GetVelocity():Length() / 300, 1 )

	bullet.TracerName = "lvs_tracer_antitankgun"
	bullet.Force	= 4000
	bullet.HullSize 	= 1
	bullet.Damage	= 100

	bullet.Velocity = 8000
	bullet.Entity = self
	bullet.Attacker 	= ply
	bullet.Callback = function(att, tr, dmginfo)
		if tr.Entity:IsPlayer() then
			dmginfo:ScaleDamage( 2 )
		end

		dmginfo:SetDamageType( DMG_SNIPER + DMG_ALWAYSGIB )

		local effectdata = EffectData()
		effectdata:SetOrigin( tr.HitPos )
		util.Effect(  "lvs_fortification_explosion_mine", effectdata )
	end

	LVS:FireBullet( bullet )
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
	if self:DefaultReload( ACT_VM_RELOAD ) then
		self:EmitSound("npc/sniper/reload1.wav")
	end
end

function SWEP:Think()
end

function SWEP:OnRemove()
end

function SWEP:OnDrop()
end

function SWEP:Holster( wep )
	return true
end
