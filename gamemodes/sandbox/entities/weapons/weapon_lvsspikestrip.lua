AddCSLuaFile()

SWEP.Category				= "[LVS]"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= false

SWEP.ViewModel			= "models/weapons/c_scrubriglvs.mdl"
SWEP.WorldModel			= "models/diggercars/shared/spikestrip_fold.mdl"

SWEP.UseHands				= true
SWEP.ViewModelFlip			= false
SWEP.ViewModelFOV			= 60
SWEP.AutoSwitchTo 			= true
SWEP.AutoSwitchFrom 		= true

SWEP.HoldType				= "physgun"

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip		= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic		= false
SWEP.Secondary.Ammo		= "none"

cleanup.Register( "lvsspikestrip" )

if CLIENT then
	SWEP.PrintName		= "Spike Strip"
	SWEP.Slot				= 4
	SWEP.SlotPos			= 2

	SWEP.DrawWeaponInfoBox 	= false

	SWEP.pViewModel = ClientsideModel("models/diggercars/shared/spikestrip_fold.mdl", RENDERGROUP_OPAQUE)
	SWEP.pViewModel:SetNoDraw( true )

	function SWEP:ViewModelDrawn()
		local ply = self:GetOwner()

		if not IsValid( ply ) then return end

		local vm = ply:GetViewModel()
		local bm = vm:GetBoneMatrix(0)

		if not bm then return end

		local pos =  bm:GetTranslation()
		local ang =  bm:GetAngles()	
		
		pos = pos + ang:Up() * 28
		pos = pos + ang:Right() * 8
		pos = pos + ang:Forward() * -5
		
		ang:RotateAroundAxis(ang:Forward(), -210)
		ang:RotateAroundAxis(ang:Right(),-60)
		ang:RotateAroundAxis(ang:Up(), 90)
		
		self.pViewModel:SetPos( pos )
		self.pViewModel:SetAngles( ang )
		self.pViewModel:DrawModel()
		self.pViewModel:SetModelScale( 0.5 )
	end

	function SWEP:DrawWorldModel()
		local ply = self:GetOwner()

		if not IsValid( ply ) then self:DrawModel() return end

		local id = ply:LookupAttachment("anim_attachment_rh")
		local attachment = ply:GetAttachment( id )
		
		if not attachment then return end

		local pos = attachment.Pos + attachment.Ang:Forward() * 3 - attachment.Ang:Up() * 30
		local ang = attachment.Ang
		ang:RotateAroundAxis(attachment.Ang:Up(), -40)
		ang:RotateAroundAxis(attachment.Ang:Right(), -90)
		ang:RotateAroundAxis(attachment.Ang:Forward(), 0)

		self:SetRenderOrigin( pos )
		self:SetRenderAngles( ang )

		self:DrawModel()
	end

	function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
		draw.SimpleText( "P", "WeaponIcons", x + wide/2, y + tall*0.2, Color( 255, 210, 0, 255 ), TEXT_ALIGN_CENTER )
	end
end

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:OwnerChanged()
end

function SWEP:Think()
end

if SERVER then
	function SWEP:PlaceStrip()
		local ply = self:GetOwner()

		ply:EmitSound( "npc/zombie/claw_miss1.wav" )

		local ent = ents.Create( "lvs_item_spikestrip_foldable" )

		if not IsValid( ent ) then return end

		ent:SetAngles( Angle(0,180 + ply:EyeAngles().y,0) )
		ent:SetPos( ply:GetShootPos() - Vector(0,0,10) )
		ent:Spawn()
		ent:Activate()
		ent:SetAttacker( ply )
		ent:SetOwner( ply )

		ply:AddCleanup( "lvsspikestrip", ent )

		undo.Create("Spike Strip")
			undo.AddEntity( ent )
			undo.SetPlayer( ply )
		undo.Finish()

		local PhysObj = ent:GetPhysicsObject()

		if not IsValid( PhysObj ) then return end

		PhysObj:SetVelocityInstantaneous( ply:GetAimVector() * 200 + Vector(0,0,75) )
	end
end

function SWEP:PrimaryAttack()
	local ply = self:GetOwner()

	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	ply:SetAnimation( PLAYER_ATTACK1 )

	self:SetNextPrimaryFire( CurTime() + 1.5 )

	if SERVER then
		self:PlaceStrip()

		ply:StripWeapon( "weapon_lvsspikestrip" ) 
	end
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

function SWEP:OnRemove()
end