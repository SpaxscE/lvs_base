AddCSLuaFile()

SWEP.Base            = "weapon_lvsbasegun"

SWEP.Category				= "[LVS]"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= false

SWEP.ViewModel			= "models/weapons/c_rpg.mdl"
SWEP.WorldModel			= "models/weapons/w_rocket_launcher.mdl"
SWEP.UseHands				= true

SWEP.HoldType				= "rpg"

SWEP.Primary.ClipSize		= 2
SWEP.Primary.DefaultClip		= 2
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "RPG_Round"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic		= false
SWEP.Secondary.Ammo		= "none"

SWEP.DisableBallistics = false

SWEP.AmmoWarningCountClip = 0
SWEP.AmmoWarningCountMag = 1

function SWEP:SetupDataTables()
	self:NetworkVar( "Float", 0, "ReloadTime" )
end

if CLIENT then
	SWEP.PrintName		= "#lvs_weapon_antitankgun"
	SWEP.Author			= "Blu-x92"

	SWEP.Slot				= 1
	SWEP.SlotPos			= 1

	function SWEP:DrawWorldModel( flags )
		if self:GetReloadTime() > CurTime() then return end

		self:DrawModel( flags )
	end

	function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
		draw.SimpleText( "i", "WeaponIcons", x + wide/2, y + tall*0.2, Color( 255, 210, 0, 255 ), TEXT_ALIGN_CENTER )
	end

	function SWEP:DoDrawCrosshair( x, y )

		local Mul = self:GetBulletSpreadMultiplicator()

		if Mul <= 0.1 then return end

		surface.DrawCircle( x, y, 4 + 55 * Mul, color_black )
		surface.DrawCircle( x, y, 5 + 55 * Mul, color_white )

		return true
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
			self.ActivityTranslate[ ACT_MP_RELOAD_STAND ]				= ACT_HL2MP_IDLE_SMG1 + 6
			self.ActivityTranslate[ ACT_MP_RELOAD_CROUCH ]				= ACT_HL2MP_IDLE_SMG1 + 6
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

function SWEP:GetBulletSpreadMultiplicator()
	local ply = self:GetOwner()

	if not IsValid( ply ) then return 0 end

	return math.min( ply:GetVelocity():Length() / 300, 1 )
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	self:SetNextPrimaryFire( CurTime() + 0.5 )

	self:TakePrimaryAmmo( 1 )

	self:ShootEffects()

	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	if IsFirstTimePredicted() then
		self:EmitSound("^weapons/smg1/npc_smg1_fire1.wav",100, 60, 1, CHAN_STATIC )

		ply:ViewPunch( Angle(-math.Rand(3,5),-math.Rand(3,5),0) )

		local Dir = ply:GetAimVector()

		if ply:OnGround() then
			Dir.z = 0
			Dir:Normalize()
		end

		ply:SetVelocity( -Dir * 200 )
	end

	if CLIENT then return end

	local bullet = {}
	bullet.Src = ply:GetShootPos() + ply:EyeAngles():Right() * 7

	bullet.Dir = (ply:GetEyeTrace().HitPos - bullet.Src):GetNormalized()

	bullet.Spread 	= Vector(0.1,0.1,0.1) * self:GetBulletSpreadMultiplicator()

	bullet.TracerName = "lvs_tracer_antitankgun"
	bullet.Force	= 4000
	bullet.Force1km	= 0
	bullet.HullSize 	= 2
	bullet.Damage	= 100

	bullet.Velocity = 8000
	bullet.Entity = self
	bullet.Attacker 	= ply
	bullet.Callback = function(att, tr, dmginfo)
		if tr.Entity:IsPlayer() then
			dmginfo:ScaleDamage( 2 )
		end

		dmginfo:SetDamageType( DMG_SNIPER + DMG_ALWAYSGIB )
	end

	LVS:FireBullet( bullet )
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
	local Clip = self:Clip1()

	if Clip >= self.Primary.ClipSize or self:GetOwner():GetAmmoCount( self.Primary.Ammo ) == 0 then return end

	self:TakePrimaryAmmo( Clip )

	if self:DefaultReload( ACT_VM_DRAW ) then
		self:SetReloadTime( CurTime() + 1 )

		if CLIENT then return end

		local ent = ents.Create( "weapon_lvsbasegun_gib" )
		ent:SetModel( "models/weapons/w_rocket_launcher.mdl" )
		ent:SetPos( self.Owner:GetShootPos() )
		ent:SetAngles( self.Owner:EyeAngles() )
		ent:SetAmmo( Clip, self.Primary.Ammo )
		ent:Spawn()
		ent:Activate()

		ent:EmitSound("npc/zombie/claw_miss1.wav")

		local PhysObj = ent:GetPhysicsObject()

		local ply = self:GetOwner()

		if not IsValid( ply ) or not IsValid( PhysObj) then return end

		PhysObj:SetVelocityInstantaneous( ply:GetAimVector() * 400 + ply:GetVelocity() )

		PhysObj:AddAngleVelocity( VectorRand() * 500 ) 
	end
end

function SWEP:Think()
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
