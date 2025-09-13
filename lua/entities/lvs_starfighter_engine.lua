AddCSLuaFile()

ENT.Type            = "anim"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.DoNotDuplicate = true

ENT._LVS = true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )
	self:NetworkVar( "Float",1, "HP" )
	self:NetworkVar( "Float",2, "MaxHP" )

	self:NetworkVar( "Bool",0, "Destroyed" )

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
		debugoverlay.Cross( self:GetPos(), 50, 5, Color( 0, 255, 255 ) )
	end

	function ENT:Think()
		local T = CurTime()
		local vehicle = self:GetBase()

		if not self:GetDestroyed() or not IsValid( vehicle ) or not vehicle:GetEngineActive() then self:NextThink( T + 1 ) return true end

		local PhysObj = vehicle:GetPhysicsObject()

		local Pos = self:GetPos()
		local Len = vehicle:WorldToLocal( Pos ):Length()

		PhysObj:ApplyForceOffset( -vehicle:GetVelocity() * (PhysObj:GetMass() / Len) * FrameTime() * 50, Pos )

		self:NextThink( T )

		return true
	end

	function ENT:OnTakeDamage( dmginfo )
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

	function ENT:UpdateTransmitState() 
		return TRANSMIT_ALWAYS
	end

	return
end

function ENT:Initialize()
end

function ENT:Think()
	local vehicle = self:GetBase()

	if not IsValid( vehicle ) then return end

	self:DamageFX( vehicle )
end

function ENT:OnRemove()
end

function ENT:Draw()
end

function ENT:DrawTranslucent()
end

function ENT:DamageFX( vehicle )
	local T = CurTime()
	local HP = vehicle:GetHP()
	local MaxHP = vehicle:GetMaxHP() 

	if HP <= 0 then return end

	if (self.nextDFX or 0) > T then return end

	self.nextDFX = T + 0.05

	local Destroyed = self:GetDestroyed()

	if Destroyed or HP < MaxHP * 0.5 then
		local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
			effectdata:SetEntity( vehicle )
		util.Effect( "lvs_engine_blacksmoke", effectdata )
	end

	if not Destroyed then return end

	if HP < MaxHP * 0.5 then
		local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
			effectdata:SetNormal( -self:GetForward() )
			effectdata:SetMagnitude( 2 )
			effectdata:SetEntity( vehicle )
		util.Effect( "lvs_exhaust_fire", effectdata )
	end
end
