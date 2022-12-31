AddCSLuaFile()

ENT.Type            = "anim"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.DoNotDuplicate = true

ENT.RenderGroup = RENDERGROUP_BOTH 

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )
end

if SERVER then
	function ENT:Initialize()	
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false )
		debugoverlay.Cross( self:GetPos(), 15, 5, Color( 50, 50, 50 ) )
	end

	function ENT:Think()
		return false
	end

	function ENT:OnTakeDamage( dmginfo )
	end

	function ENT:UpdateTransmitState() 
		return TRANSMIT_ALWAYS
	end

	return
end

function ENT:Initialize()
end

function ENT:Think()
end

ENT.ExhaustSprite = Material( "effects/muzzleflash2" )

function ENT:Draw()
end

function ENT:DrawTranslucent()
	local vehicle = self:GetBase()

	if not IsValid( vehicle ) or not vehicle:GetEngineActive() then return end

	local Throttle = vehicle:GetThrottle()

	self.PosOffset = (self.PosOffset or 0) + RealFrameTime() * (8 + 4 * Throttle)

	local T = CurTime()

	if (self.NextFX or 0) < T then
		self.NextFX = T + 0.05 + (1 - Throttle) / 10

		if math.random(0,1) == 1 then
			self.PosOffset = 0

			local HP = vehicle:GetHP()
			local MaxHP = vehicle:GetMaxHP() 

			if HP <= 0 then return end

			if HP > MaxHP * 0.25 then
				local effectdata = EffectData()
					effectdata:SetOrigin( self:GetPos() )
					effectdata:SetNormal( self:GetUp() )
					effectdata:SetMagnitude( Throttle )
					effectdata:SetEntity( vehicle )
				util.Effect( "lvs_exhaust", effectdata )
			else
				local effectdata = EffectData()
					effectdata:SetOrigin( self:GetPos() )
					effectdata:SetNormal( self:GetUp() )
					effectdata:SetMagnitude( Throttle )
					effectdata:SetEntity( vehicle )
				util.Effect( "lvs_exhaust_fire", effectdata )
			end
		end
	end

	if self.PosOffset > 1 or Throttle < 0.5 then return end

	local Dir = self:GetUp() * self.PosOffset
	local Pos = self:GetPos() + Dir * (5 + 5 * Throttle)

	local Size = math.min( 10 * (1 - self.PosOffset ) ^ 2, 5 + 5 * Throttle )

	render.SetMaterial( self.ExhaustSprite )
	render.DrawSprite( Pos, Size, Size, color_white )
end
