include("shared.lua")
include( "sh_turret.lua" )
include( "cl_prediction.lua" )

function ENT:DamageFX()
	self.nextDFX = self.nextDFX or 0

	if self.nextDFX < CurTime() then
		self.nextDFX = CurTime() + 0.05

		local HP = self:GetHP()
		local MaxHP = self:GetMaxHP()

		if HP > MaxHP * 0.5 then return end

		local effectdata = EffectData()
			effectdata:SetOrigin( self:LocalToWorld( Vector(-30,0,43) ) )
			effectdata:SetEntity( self )
		util.Effect( "lvs_engine_blacksmoke", effectdata )

		if HP <= MaxHP * 0.25 then
			local effectdata = EffectData()
				effectdata:SetOrigin( self:LocalToWorld( Vector(-85,65,14) ) )
				effectdata:SetNormal( self:GetUp() )
				effectdata:SetMagnitude( math.Rand(0.5,1.5) )
				effectdata:SetEntity( self )
			util.Effect( "lvs_exhaust_fire", effectdata )

			local effectdata = EffectData()
				effectdata:SetOrigin( self:LocalToWorld( Vector(-85,-65,14) ) )
				effectdata:SetNormal( self:GetUp() )
				effectdata:SetMagnitude( math.Rand(0.5,1.5) )
				effectdata:SetEntity( self )
			util.Effect( "lvs_exhaust_fire", effectdata )
		end
	end
end

function ENT:OnFrame()
	self:BTLProjector()
	self:PredictPoseParamaters()
	self:DamageFX()
end

function ENT:BTLProjector()
	local Fire = self:GetBTLFire()

	if Fire == self.OldFireBTL then return end

	self.OldFireBTL = Fire
	
	if Fire then
		local effectdata = EffectData()
		effectdata:SetEntity( self )
		util.Effect( "lvs_laat_left_projector", effectdata )
	end
end

function ENT:CalcViewOverride( ply, pos, angles, fov, pod )
	if ply == self:GetDriver() and not pod:GetThirdPersonMode() then
		return pos + self:GetForward() * 40 - self:GetUp() * 20, angles, fov
	end

	local GunnerPod = self:GetGunnerSeat()

	if pod == GunnerPod and pod:GetThirdPersonMode() then
		return GunnerPod:LocalToWorld( Vector(0,0,60) ), angles + Angle(6,0,0), fov
	end

	return pos, angles, fov
end

function ENT:RemoveLight()
	if IsValid( self.projector ) then
		self.projector:Remove()
		self.projector = nil
	end
end

function ENT:OnRemoved()
	self:RemoveLight()
end

function ENT:PreDraw()
	self:DrawDriverBTL()

	return true
end

ENT.LightMaterial = Material( "effects/lvs/laat_spotlight" )
ENT.GlowMaterial = Material( "sprites/light_glow02_add" )

function ENT:PreDrawTranslucent()
	if self:GetBodygroup( 2 ) ~= 1 then 
		self:RemoveLight()
		return false
	end

	if not IsValid( self.projector ) then
		local thelamp = ProjectedTexture()
		thelamp:SetBrightness( 10 ) 
		thelamp:SetTexture( "effects/flashlight/soft" )
		thelamp:SetColor( Color(255,255,255) ) 
		thelamp:SetEnableShadows( true ) 
		thelamp:SetFarZ( 2500 ) 
		thelamp:SetNearZ( 75 ) 
		thelamp:SetFOV( 60 )
		self.projector = thelamp
	end

	local Start1 = self:LocalToWorld( Vector(64,6,10.5) )
	local Start2 = self:LocalToWorld( Vector(64,-6,10.5) )

	local Dir1 = self:LocalToWorldAngles( Angle(0,5,0) ):Forward()
	local Dir2 = self:LocalToWorldAngles( Angle(0,-5,0) ):Forward()

	render.SetMaterial( self.GlowMaterial )
	render.DrawSprite( Start1, 32, 32, Color( 100, 100, 100, 255) )
	render.DrawSprite( Start2, 32, 32, Color( 100, 100, 100, 255) )

	render.SetMaterial( self.LightMaterial )
	render.DrawBeam( Start1,  Start1 + Dir1 * 400, 150, 0, 0.99, Color( 100, 100, 100, 5) ) 
	render.DrawBeam( Start2,  Start2 + Dir2 * 400, 150, 0, 0.99, Color( 100, 100, 100, 5) ) 

	if IsValid( self.projector ) then
		self.projector:SetPos( self:LocalToWorld( Vector(60,0,10.5) ) )
		self.projector:SetAngles( self:LocalToWorldAngles( Angle(15,0,0) ) )
		self.projector:Update()
	end

	return false
end

local COLOR_RED = Color(255,0,0,255)
local COLOR_WHITE = Color(255,255,255,255)

function ENT:LVSPreHudPaint( X, Y, ply )
	if self:GetIsCarried() then return false end

	if ply == self:GetDriver() then
		local Col = self:WeaponsInRange() and COLOR_WHITE or COLOR_RED

		local Pos2D = self:GetEyeTrace().HitPos:ToScreen() 

		self:PaintCrosshairCenter( Pos2D, Col )
		self:PaintCrosshairOuter( Pos2D, Col )
		self:LVSPaintHitMarker( Pos2D )
	end

	return true
end

function ENT:DrawDriverBTL()
	local pod = self:GetGunnerSeat()

	if not IsValid( pod ) then return end

	local plyL = LocalPlayer()
	local ply = pod:GetDriver()

	if not IsValid( ply ) or (ply == plyL and plyL:GetViewEntity() == plyL and not pod:GetThirdPersonMode()) then return end

	if self:GetBodygroup(1) == 2 then
		ply:SetRenderAngles( self:GetAngles() )
		ply:DrawModel()

		return
	end

	local ID = self:LookupAttachment( "muzzle_ballturret_left" )
	local Muzzle = self:GetAttachment( ID )

	if not Muzzle then return end

	local _,Ang = LocalToWorld( Vector(0,0,0), Angle(-90,0,-90), Muzzle.Pos, Muzzle.Ang )

	local LAng = self:WorldToLocalAngles( Ang )
	LAng.p = 0
	LAng.r = 0

	ply:SetSequence( "sit_rollercoaster" )
	ply:SetRenderAngles( self:LocalToWorldAngles( LAng ) )
	ply:DrawModel()
end
