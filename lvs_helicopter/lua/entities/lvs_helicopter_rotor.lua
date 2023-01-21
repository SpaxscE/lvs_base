AddCSLuaFile()

ENT.Type            = "anim"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.DoNotDuplicate = true

ENT._LVS = true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )
	self:NetworkVar( "Float",0, "Radius" )
	self:NetworkVar( "Int",0, "Speed" )
	self:NetworkVar( "Int",1, "HP" )
	self:NetworkVar( "Bool",0, "Disabled" )

	if SERVER then
		self:SetSpeed( 4000 )
		self:SetHP( 10 )
	end
end

function ENT:CheckRotorClearance()
	if self:GetDisabled() then self:DeleteRotorWash() return end

	local base = self:GetBase()

	if not IsValid( base ) then self:DeleteRotorWash() return end

	if not base:GetEngineActive() then self:DeleteRotorWash() return end

	local Radius = self:GetRadius()

	if base:GetThrottle() > 0.5 and Radius > 250 then
		self:CreateRotorWash()
	else
		self:DeleteRotorWash()
	end

	local pos = self:GetPos()

	local FT = FrameTime()

	self.Yaw = self.Yaw and self.Yaw + FT * self:GetSpeed() * base:GetThrottle() or 0

	if self.Yaw >= 360 then
		self.Yaw = self.Yaw - 360
	end
	if self.Yaw <= -360 then
		self.Yaw = self.Yaw +	360
	end

	local dir = self:LocalToWorldAngles( Angle(0,self.Yaw,0) ):Forward()

	local tr = util.TraceLine( {
		start = pos,
		endpos = (pos + dir * Radius),
		filter = base:GetCrosshairFilterEnts(),
		mask = MASK_SOLID_BRUSHONLY,
	} )

	if SERVER then
		self.RotorHitCount = self.RotorHitCount or 0

		local Hit = base._SteerOverride and tr.Hit or (tr.Hit and not tr.HitSky)

		if Hit then
			self.RotorHit = true
			
			self.RotorHitCount = self.RotorHitCount + 1
		else 
			self.RotorHit = false
			
			self.RotorHitCount = math.max(self.RotorHitCount - 1 * FT,0)
		end

		if self.RotorHitCount > self:GetHP() then
			self:Destroy()
		end
	else
		if tr.Hit and not tr.HitSky then
			self.RotorHit = true
		else 
			self.RotorHit = false
		end
	end

	if self.RotorHit ~= self.oldRotorHit then
		if not isbool( self.oldRotorHit ) then self.oldRotorHit = self.RotorHit return end

		if self.RotorHit then
			self:OnStartCollide( base, tr.HitPos, tr.HitNormal )
		else
			self:OnFinishCollide( base, tr.HitPos, tr.HitNormal )
		end

		self.oldRotorHit = self.RotorHit
	end
end

function ENT:GetVehicle()
	return self:GetBase()
end

if SERVER then
	function ENT:Initialize()	
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false )
		debugoverlay.Cross( self:GetPos(), 50, 5, Color( 255, 0, 255 ) )
	end

	function ENT:Destroy()
		if self:GetDisabled() then return end

		self:SetDisabled( true )
		self:OnDestroyed( self:GetBase() )

		local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
			effectdata:SetNormal( self:GetForward() )
			effectdata:SetMagnitude( self:GetRadius() )
		util.Effect( "lvs_rotor_destruction", effectdata, true, true )

		self:DeleteRotorWash()
	end

	function ENT:OnDestroyed( base )
		self:EmitSound( "physics/metal/metal_box_break2.wav" )
	end

	function ENT:OnFinishCollide( base, Pos, Dir, Fraction )
	end

	function ENT:OnStartCollide( base, Pos, Dir, Fraction )
	end

	function ENT:OnTakeDamage( dmginfo )
		local damage = dmginfo:GetDamage()

		self.RotorHitCount = (self.RotorHitCount or 0) + damage

		if self.RotorHitCount > self:GetHP() then
			self:Destroy()
		end
	end

	function ENT:Think()
		self:NextThink( CurTime() )

		self:CheckRotorClearance()

		return true
	end

	function ENT:OnRemove()
		self:DeleteRotorWash()
	end

	function ENT:UpdateTransmitState() 
		return TRANSMIT_ALWAYS
	end

	function ENT:CreateRotorWash()
		if IsValid( self.RotorWashEnt ) then return end

		local RotorWash = ents.Create( "env_rotorwash_emitter" )

		if not IsValid( RotorWash ) then return end

		RotorWash:SetPos( self:GetPos() )
		RotorWash:SetAngles( self:GetAngles() )
		RotorWash:Spawn()
		RotorWash:Activate()
		RotorWash:SetParent( self )
		RotorWash.DoNotDuplicate = true
	
		self:DeleteOnRemove( RotorWash )

		self.RotorWashEnt = RotorWash

		local Base = self:GetBase()

		if IsValid( Base ) then
			Base:TransferCPPI( RotorWash )
		end
	end

	function ENT:DeleteRotorWash()
		if not IsValid( self.RotorWashEnt ) then return end

		self.RotorWashEnt:Remove()
	end

	return
end

function ENT:CreateRotorWash()
end

function ENT:DeleteRotorWash()
end

function ENT:OnStartCollide( base, Pos, Dir )
	local effectdata = EffectData()
		effectdata:SetOrigin( Pos + Dir )
		effectdata:SetNormal( Dir )
	util.Effect( "stunstickimpact", effectdata, true, true )

	self:EmitSound( "physics/metal/metal_computer_impact_bullet"..math.random(1,3)..".wav", 75, 80 + base:GetThrottle() * 20, 0.4 )
end

function ENT:OnFinishCollide( base, Pos, Dir )
	local effectdata = EffectData()
		effectdata:SetOrigin( Pos )
		effectdata:SetNormal( -self:LocalToWorldAngles( Angle(0,self.Yaw,0) ):Right() * 2 * base:Sign( self:GetSpeed() ) )
	util.Effect( "manhacksparks", effectdata, true, true )

	self:EmitSound( "ambient/materials/roust_crash"..math.random(1,2)..".wav", 75, 90 + base:GetThrottle() * 20, 0.2 )
end

function ENT:Think()
	self:CheckRotorClearance()
end

function ENT:Draw()
end

function ENT:DrawTranslucent()
end
