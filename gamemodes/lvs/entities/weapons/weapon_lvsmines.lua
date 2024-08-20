AddCSLuaFile()

SWEP.Base            = "weapon_lvsbasegun"

SWEP.Category				= "[LVS]"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= false

SWEP.ViewModel			= "models/weapons/v_slam.mdl"
SWEP.WorldModel			= "models/blu/lvsmine.mdl"

SWEP.UseHands				= false
SWEP.ViewModelFlip			= false
SWEP.ViewModelFOV			= 10
SWEP.AutoSwitchTo 			= true
SWEP.AutoSwitchFrom 		= true

SWEP.HoldType				= "slam"

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip		= 3
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "slam"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic		= false
SWEP.Secondary.Ammo		= "none"

if CLIENT then
	SWEP.PrintName		= "#lvs_weapon_mines"
	SWEP.Slot				= 2
	SWEP.SlotPos			= 1

	SWEP.DrawWeaponInfoBox 	= false

	SWEP.pViewModel = ClientsideModel("models/blu/lvsmine.mdl", RENDERGROUP_OPAQUE)
	SWEP.pViewModel:SetNoDraw( true )

	function SWEP:ViewModelDrawn()
		if self:Ammo1() <= 0 then return end

		local ply = self:GetOwner()

		if not IsValid( ply ) then return end

		local vm = ply:GetViewModel()
		local bm = vm:GetBoneMatrix(0)
		local pos =  bm:GetTranslation()
		local ang =  bm:GetAngles()	
		
		pos = pos + ang:Up() * 220
		pos = pos + ang:Right() * 2
		pos = pos + ang:Forward() * -12
		
		ang:RotateAroundAxis(ang:Forward(), 45)
		ang:RotateAroundAxis(ang:Right(),120)
		ang:RotateAroundAxis(ang:Up(), 0)
		
		self.pViewModel:SetPos( pos )
		self.pViewModel:SetAngles( ang )
		self.pViewModel:DrawModel()
	end

	function SWEP:DrawWorldModel()
		if self:Ammo1() <= 0 then return end

		local ply = self:GetOwner()

		if not IsValid( ply ) then self:DrawModel() return end

		local id = ply:LookupAttachment("anim_attachment_rh")
		local attachment = ply:GetAttachment( id )
		
		if not attachment then return end

		local pos = attachment.Pos + attachment.Ang:Forward() * 2
		local ang = attachment.Ang
		ang:RotateAroundAxis(attachment.Ang:Up(), 20)
		ang:RotateAroundAxis(attachment.Ang:Right(), -30)
		ang:RotateAroundAxis(attachment.Ang:Forward(), 0)

		self:SetRenderOrigin( pos )
		self:SetRenderAngles( ang )

		self:DrawModel()
	end

	function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
		draw.SimpleText( "z", "WeaponIcons", x + wide/2, y + tall*0.2, Color( 255, 210, 0, 255 ), TEXT_ALIGN_CENTER )
	end
end

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:OwnerChanged()
end

function SWEP:Think()
end

function SWEP:TakePrimaryAmmo( num )
	local ply = self:GetOwner()

	if self:Clip1() <= 0 then

		if self:Ammo1() <= 0 then return end

		ply:RemoveAmmo( num, self:GetPrimaryAmmoType() )

		return
	end

	self:SetClip1( math.max(self:Clip1() - num,0) )

end

function SWEP:CanPrimaryAttack()
	self.NextFire = self.NextFire or 0
	
	return self.NextFire <= CurTime() and self:Ammo1() > 0
end

function SWEP:SetNextPrimaryFire( time )
	self.NextFire = time
end

function SWEP:ThrowMine()
	if CLIENT then return end

	local ply = self:GetOwner()

	ply:EmitSound( "npc/zombie/claw_miss1.wav" )

	local ent = ents.Create( "lvs_fortification_mine" )

	if not IsValid( ent ) then return end

	ent:SetPos( ply:GetShootPos() - Vector(0,0,10) )
	ent:Spawn()
	ent:Activate()
	ent:SetAttacker( ply )

	ply:AddEntityList( ent )

	local PhysObj = ent:GetPhysicsObject()

	if not IsValid( PhysObj ) then return end

	PhysObj:SetVelocityInstantaneous( ply:GetAimVector() * 200 + Vector(0,0,150) )
	PhysObj:AddAngleVelocity( VectorRand() * 20 ) 
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	local ply = self:GetOwner()

	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	ply:SetAnimation( PLAYER_ATTACK1 )

	self:ThrowMine()

	self:SetNextPrimaryFire( CurTime() + 1.5 )

	self:TakePrimaryAmmo( 1 )
end

function SWEP:SecondaryAttack()
	return false
end

function SWEP:Deploy()
	self:SendWeaponAnim( ACT_VM_DRAW )
	
	return true
end

function SWEP:Holster()
	return true
end