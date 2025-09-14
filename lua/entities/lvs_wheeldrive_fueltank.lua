AddCSLuaFile()

ENT.Type            = "anim"
ENT.DoNotDuplicate = true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )
	self:NetworkVar( "Entity",1, "DoorHandler" )

	self:NetworkVar( "Float",0, "Fuel" )
	self:NetworkVar( "Float",1, "Size" )
	self:NetworkVar( "Float",2, "HP" )
	self:NetworkVar( "Float",3, "MaxHP" )

	self:NetworkVar( "Int",0, "FuelType" )

	self:NetworkVar( "Bool",0, "Destroyed" )

	if SERVER then
		self:SetMaxHP( 100 )
		self:SetHP( 100 )
		self:SetFuel( 1 )
		self:NetworkVarNotify( "Fuel", self.OnFuelChanged )
	end
end

if SERVER then
	function ENT:Initialize()	
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false )
		debugoverlay.Cross( self:GetPos(), 20, 5, Color( 255, 93, 0 ) )
	end

	function ENT:ExtinguishAndRepair()
		self:SetHP( self:GetMaxHP() )
		self:SetDestroyed( false )
	end

	function ENT:Think()
		self:NextThink( CurTime() + 1 )

		if self:GetDestroyed() then
			local Base = self:GetBase()

			if not IsValid( Base ) then return end

			if self:GetFuel() > 0 then
				local dmg = DamageInfo()
				dmg:SetDamage( 10 )
				dmg:SetAttacker( IsValid( Base.LastAttacker ) and Base.LastAttacker or game.GetWorld() )
				dmg:SetInflictor( IsValid(  Base.LastInflictor ) and Base.LastInflictor or game.GetWorld() )
				dmg:SetDamageType( DMG_BURN )
				Base:TakeDamageInfo( dmg )

				self:SetFuel( math.max( self:GetFuel() - 0.05, 0 ) )
			else
				self:SetDestroyed( false )
			end
		else
			local base = self:GetBase()

			if IsValid( base ) and base:GetEngineActive() then
				self:SetFuel( math.max( self:GetFuel() - (1 / self:GetSize()) * base:GetThrottle() ^ 2, 0 ) )
			end
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
		end
	end

	function ENT:OnTakeDamage( dmginfo )
		if not dmginfo:IsDamageType( DMG_BURN ) then return end

		self:TakeTransmittedDamage( dmginfo )
	end

	function ENT:OnFuelChanged( name, old, new)
		if new == old then return end

		if new <= 0 then
			local base = self:GetBase()

			if not IsValid( base ) then return end

			base:ShutDownEngine()

			local engine = base:GetEngine()

			if not IsValid( engine ) then return end

			engine:EmitSound("vehicles/jetski/jetski_off.wav")
		end
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

	self.FireBurnSND = CreateSound( self, "ambient/fire/firebig.wav" )
	self.FireBurnSND:PlayEx(0,100)
	self.FireBurnSND:ChangeVolume( LVS.EngineVolume, 1 )

	self:EmitSound("ambient/fire/gascan_ignite1.wav")
end

function ENT:OnRemove()
	self:RemoveFireSound()
end

function ENT:Draw()
end

function ENT:Think()
	self:SetNextClientThink( CurTime() + 0.05 )

	self:DamageFX()

	return true
end

function ENT:DamageFX()
	if not self:GetDestroyed() or self:GetFuel() <= 0  then
		self:StopFireSound()

		return
	end

	self:StartFireSound()

	local effectdata = EffectData()
		effectdata:SetOrigin( self:GetPos() )
		effectdata:SetEntity( self:GetBase() )
	util.Effect( "lvs_carfueltank_fire", effectdata )
end

