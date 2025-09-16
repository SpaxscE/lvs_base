AddCSLuaFile()

ENT.Type            = "anim"
ENT.DoNotDuplicate = true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )

	self:NetworkVar( "Float",0, "HP" )
	self:NetworkVar( "Float",1, "MaxHP" )

	self:NetworkVar( "Bool",0, "Destroyed" )

	self:NetworkVar( "Vector",0, "EffectPosition" )

	if SERVER then
		self:SetMaxHP( 100 )
		self:SetHP( 100 )
	end
end

if SERVER then
	function ENT:Initialize()	
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false )
	end

	function ENT:Think()
		self:NextThink( CurTime() + 1 )

		if self:GetDestroyed() then
			local Base = self:GetBase()

			if not IsValid( Base ) then return end

			local dmg = DamageInfo()
			dmg:SetDamage( 100 )
			dmg:SetAttacker( IsValid( Base.LastAttacker ) and Base.LastAttacker or game.GetWorld() )
			dmg:SetInflictor( IsValid(  Base.LastInflictor ) and Base.LastInflictor or game.GetWorld() )
			dmg:SetDamageType( DMG_BURN )
			Base:TakeDamageInfo( dmg )
		end

		return true
	end

	function ENT:TakeTransmittedDamage( dmginfo )
		if self:GetDestroyed() then return end

		local Damage = dmginfo:GetDamage()

		if Damage <= 0 then return end

		local CurHealth = self:GetHP()

		local NewHealth = math.Clamp( CurHealth - Damage, 0, self:GetMaxHP() )

		self:SetHP( NewHealth )

		if NewHealth <= 0 then
			self:SetDestroyed( true )

			local Base = self:GetBase()

			if not IsValid( Base ) then return end

			Base:Lock()

			for _, ply in pairs( Base:GetEveryone() ) do
				Base:HurtPlayer( ply, ply:Health() + ply:Armor(), dmginfo:GetAttacker(), dmginfo:GetInflictor() )
			end
		end
	end

	function ENT:OnTakeDamage( dmginfo )
		if not dmginfo:IsDamageType( DMG_BURN ) then return end

		dmginfo:ScaleDamage( 0.5 )

		self:TakeTransmittedDamage( dmginfo )
	end

	return
end

function ENT:Initialize()
end

function ENT:RemoveFireSound()
	if self.FireBurnSND then
		self.FireBurnSND:Stop()
		self.FireBurnSND = nil
	end

	self.ShouldStopFire = nil
end

function ENT:StopFireSound()
	if self.ShouldStopFire or not self.FireBurnSND then return end

	self.ShouldStopFire = true

	self:EmitSound("ambient/fire/mtov_flame2.wav")

	self.FireBurnSND:ChangeVolume( 0, 0.5 )

	timer.Simple( 1, function()
		if not IsValid( self ) then return end

		self:RemoveFireSound()
	end )
end

function ENT:StartFireSound()
	if self.ShouldStopFire or self.FireBurnSND then return end

	self.FireBurnSND = CreateSound( self, "lvs/ammo_fire_loop.wav" )
	self.FireBurnSND:SetSoundLevel( 85 )

	self.FireBurnSND:PlayEx(0,100)

	self.FireBurnSND:ChangeVolume( 1, 1 )

	self:EmitSound("lvs/ammo_fire.wav")

	self.StartFireTime = CurTime()
end

function ENT:OnRemove()
	self:RemoveFireSound()
end

function ENT:Draw()
end

function ENT:Think()
	local T = CurTime()

	self:SetNextClientThink( T + 0.05 )
 
	if not self:GetDestroyed() then
		self:StopFireSound()

		return true
	end

	self:StartFireSound()

	local Scale = math.min( (T - (self.StartFireTime or T)) / 2, 1 )

	local Base = self:GetBase()

	local effectdata = EffectData()
		effectdata:SetOrigin( Base:LocalToWorld( self:GetEffectPosition() ) )
		effectdata:SetEntity( Base )
		effectdata:SetMagnitude( Scale )
	util.Effect( "lvs_ammorack_fire", effectdata )

	return true
end
