AddCSLuaFile()

SWEP.Base            = "weapon_lvsbasegun"

SWEP.Category				= "[LVS]"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= false

SWEP.ViewModel			= "models/weapons/c_superphyscannon.mdl"
SWEP.WorldModel			= "models/weapons/w_physics.mdl"
SWEP.UseHands				= true
SWEP.ViewModelFOV = 52

SWEP.HoldType				= "physgun"

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip		= 2000
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "Uranium"

SWEP.ChargeUpDelay = 2
SWEP.ChargeDnDelay = 0.5

SWEP.AmmoWarningCountClip = 250
SWEP.AmmoWarningCountMag = 250

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic		= false
SWEP.Secondary.Ammo		= "none"

function SWEP:SetupDataTables()
	self:NetworkVar( "Float", 0, "Charge" )
	self:NetworkVar( "Bool", 0, "Active" )
	self:NetworkVar( "Bool", 1, "ShootActive" )
end

if CLIENT then
	SWEP.PrintName		= "#lvs_weapon_lasergun"
	SWEP.Author			= "Blu-x92"

	SWEP.Slot				= 0
	SWEP.SlotPos			= 1

	function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
		draw.SimpleText( "h", "WeaponIcons", x + wide/2, y + tall*0.2, Color( 255, 210, 0, 255 ), TEXT_ALIGN_CENTER )
	end

	local oldwep
	hook.Add("PlayerBindPress", "!!!!!HL2WeaponSelector", function(ply, bind, pressed)
		if bind == "phys_swap" and pressed then
			local wep = ply:GetActiveWeapon()
			local deswep = ply:GetWeapon( "weapon_lvslasergun" )

			if not IsValid( wep ) then return end

			if deswep == wep then
				if IsValid( oldwep ) then
					input.SelectWeapon( oldwep )
				else
					local antitank = ply:GetWeapon( "weapon_lvsantitankgun" )

					if IsValid( antitank ) then
						input.SelectWeapon( antitank )
					end
				end
			else
				oldwep = wep

				input.SelectWeapon( deswep )
			end

			return true
		end
	end)
end

function SWEP:UpdateAnimation( ply )
	if not IsFirstTimePredicted() then return end

	local active = math.sin( math.rad( self:GetCharge() * 120 ) )
	local vm = ply:GetViewModel()

	if IsValid( vm ) then
		vm:SetPoseParameter( "active", active )
	end

	self:SetPoseParameter( "active", active )
end

function SWEP:UpdateInput( KeyAttack )
	local T = CurTime()

	if not isbool( self._oldKeyAttack ) then
		self._oldKeyAttack = false
	end

	if not IsFirstTimePredicted() then return end

	if self._oldKeyAttack ~= KeyAttack then
		self._oldKeyAttack = KeyAttack

		if KeyAttack then
			self.ChargeStartTime = T
			self.ChargeFinishTime = nil

			self:SetShootActive( true )

			local effectdata = EffectData()
			effectdata:SetStart( self:GetPos() )
			effectdata:SetOrigin( self:GetPos() )
			effectdata:SetEntity( self )
			util.Effect( "lvs_lasergun_beam_charge", effectdata )

			self:EmitSound("lvs/tournament/weapons/lasergun/fire_charge.wav")
		else
			self:SetShootActive( false )

			self.ChargeStartTime = nil
			self.ChargeFinishTime = T

			self:EmitSound("lvs/tournament/weapons/lasergun/fire_stop.wav",75,100,1,CHAN_STATIC)
		end
	end
end

function SWEP:ResetFire()
	self:SetCharge( 0 )
	self:SetActive( false )

	self.ChargeStartTime = nil
	self.ChargeFinishTime = 0

	self._oldKeyAttack = false

	self:EmitSound("common/null.wav")
end

function SWEP:StartFire()
	self:EmitSound("lvs/tournament/weapons/lasergun/fire_loop.wav")

	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	if not IsFirstTimePredicted() then return end

	local effectdata = EffectData()
	effectdata:SetStart( ply:GetEyeTrace().HitPos )
	effectdata:SetOrigin( self:GetPos() )
	effectdata:SetEntity( self )
	util.Effect( "lvs_lasergun_beam", effectdata )

	ply:ViewPunch( Angle(-math.Rand(3,5),-math.Rand(3,5),0) )
end

function SWEP:StopFire()
	self:StopSound("lvs/tournament/weapons/lasergun/fire_loop.wav")

	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	if not IsFirstTimePredicted() then return end

	ply:ViewPunch( Angle(math.Rand(2,3),math.Rand(2,3),0) )
end

function SWEP:CalcCharge( KeyAttack )
	local T = CurTime()

	local ChargeTime = 0

	if self.ChargeStartTime then 
		ChargeTime = (T - self.ChargeStartTime) / self.ChargeUpDelay

		if ChargeTime < 1 then
			KeyAttack = true
		end
	else
		if not self.ChargeFinishTime then

			self:UpdateInput( KeyAttack )

			return
		end

		ChargeTime = 1 - (T - self.ChargeFinishTime) / self.ChargeDnDelay
	end

	self:UpdateInput( KeyAttack )

	self:SetCharge( math.Clamp( ChargeTime, 0, 1 ) )

	local TargetActive = self:GetCharge() == 1

	if self:GetActive() ~= TargetActive then
		self:SetActive( TargetActive )

		if TargetActive then
			self:StartFire()
		else
			self:StopFire()
		end
	end
end

function SWEP:GetMaxAmmo()
	return self.Primary.DefaultClip
end

function SWEP:GetAmmo()
	local ply = self:GetOwner()

	if not IsValid( ply ) then return 0 end

	return ply:GetAmmoCount( self.Primary.Ammo )
end

function SWEP:CanPrimaryAttack()
	return self:GetAmmo() > 0
end

function SWEP:Think()
	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	self:UpdateAnimation( ply )

	local KeyAttack = ply:KeyDown( IN_ATTACK )

	if not self:CanPrimaryAttack() then
		KeyAttack = false
	end

	self:CalcCharge( KeyAttack )
end

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
	self:SetSkin( 1 )
end

function SWEP:PrimaryAttack()
	if not self:GetActive() then return end

	self:TakePrimaryAmmo( 1 )

	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )

	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	ply:SetAnimation( PLAYER_ATTACK1 )

	if CLIENT then return end

	local T = CurTime()
	local FT = FrameTime()

	local P = math.cos( T * 20.5 ) * FT * 3
	local Y = math.cos( T * 21 ) * FT * 3
	local R = math.sin( -T * 19.98 ) * FT * 3

	ply:ViewPunch( Angle(P,Y,R) )

	ply:LagCompensation( true )

	local trace = ply:GetEyeTrace()

	local distMul = math.Clamp( 2000 - (ply:GetShootPos() - trace.HitPos):Length(), 0,1500 ) / 1500

	local dmgMul = (math.Clamp( self:GetAmmo() / self:GetMaxAmmo(), 0, 1 ) ^ 2) * distMul

	if not IsValid( trace.Entity ) then

		ply:LagCompensation( false )

		return
	end

	if trace.Entity:IsPlayer() or trace.Entity._lvsLaserGunDetectHit then
		local dmg = DamageInfo()
		dmg:SetDamageForce( vector_origin )
		dmg:SetDamage( math.max( 200 * FrameTime() * dmgMul, 0.5 ) )
		dmg:SetAttacker( ply )
		dmg:SetInflictor( self )

		if dmgMul < 0.1 then
			dmg:SetDamageType( DMG_SHOCK )
		else
			dmg:SetDamageType( DMG_ALWAYSGIB + DMG_DISSOLVE )
		end

		dmg:SetDamagePosition( trace.HitPos )

		trace.Entity:TakeDamageInfo( dmg )
	end

	local class =  trace.Entity:GetClass()

	if class == "lvs_objective" then
		trace.Entity:SetPos( trace.Entity:GetPos() - ply:GetAimVector() * FrameTime() * 1200 )
		trace.Entity:SetLastTouched( T )
	end

	if class == "lvs_spawnpoint" then
		trace.Entity:SetLastTouched( T )
	end

	ply:LagCompensation( false )
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
end

function SWEP:OnRemove()
	self:ResetFire()
end

function SWEP:OnDrop()
	self:ResetFire()
end

function SWEP:Deploy()
	self:SendWeaponAnim( ACT_VM_DRAW )

	return true
end

function SWEP:Holster( wep )
	self:ResetFire()

	return true
end
