include("shared.lua")

function ENT:OnSpawn()
	self:RegisterTrail( Vector(-25,-219,84), 0, 20, 2, 1000, 600 )
	self:RegisterTrail( Vector(-25,219,84), 0, 20, 2, 1000, 600 )
end

function ENT:OnFrame()
	local FT = RealFrameTime()

	self:AnimControlSurfaces( FT )
	self:AnimLandingGear( FT )
	self:AnimRotor( FT )
end

function ENT:AnimRotor( frametime )
	if not self.RotorRPM then return end

	local PhysRot = self.RotorRPM < 470

	self._rRPM = self._rRPM and (self._rRPM + self.RotorRPM *  frametime * (PhysRot and 4 or 1)) or 0

	local Rot = Angle(0,0,self._rRPM)
	Rot:Normalize() 
	self:ManipulateBoneAngles( 7, Rot )

	self:SetBodygroup( 1, PhysRot and 0 or 1 ) 
end

function ENT:AnimControlSurfaces( frametime )
	local FT = frametime * 10

	local Steer = self:GetSteer()

	local Pitch = -Steer.y * 30
	local Yaw = -Steer.z * 20
	local Roll = math.Clamp(-Steer.x * 60,-30,30)

	self.smPitch = self.smPitch and self.smPitch + (Pitch - self.smPitch) * FT or 0
	self.smYaw = self.smYaw and self.smYaw + (Yaw - self.smYaw) * FT or 0
	self.smRoll = self.smRoll and self.smRoll + (Roll - self.smRoll) * FT or 0

	self:ManipulateBoneAngles( 3, Angle( 0,self.smRoll,0) )
	self:ManipulateBoneAngles( 4, Angle( 0,-self.smRoll,0) )

	self:ManipulateBoneAngles( 6, Angle( 0,-self.smPitch,0) )

	self:ManipulateBoneAngles( 5, Angle( self.smYaw,0,0 ) )
end

function ENT:AnimLandingGear( frametime )
	self._smLandingGear = self._smLandingGear and self._smLandingGear + (30 *  (1 - self:GetLandingGear()) - self._smLandingGear) * frametime * 8 or 0

	self:ManipulateBoneAngles( 1, Angle( 0,30 - self._smLandingGear,0) )
	self:ManipulateBoneAngles( 2, Angle( 0,30 - self._smLandingGear,0) )
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

ENT.Red = Color( 255, 0, 0, 255)
ENT.SignalSprite = Material( "sprites/light_glow02_add" )
ENT.Spotlight = Material( "effects/lvs/spotlight_projectorbeam" )

function ENT:HandleLights()
	if not self:GetLightsEnabled() then 
		self:RemoveLight()
		return
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

		return
	end

	local StartPos = self:LocalToWorld( Vector(20,114,80) )
	local Dir = self:LocalToWorldAngles( Angle(10,-5,0) ):Forward()

	render.SetMaterial( self.SignalSprite )
	render.DrawSprite( StartPos + Dir * 20, 250, 250, Color( 255, 255, 255, 255) )

	render.SetMaterial( self.Spotlight )
	render.DrawBeam( StartPos - Dir * 10,  StartPos + Dir * 800, 250, 0, 0.99, Color( 255, 255, 255, 10) ) 

	self.projector:SetPos( StartPos )
	self.projector:SetAngles( Dir:Angle() )
	self.projector:Update()
end

function ENT:HandleSignals()
	if not self:GetEngineActive() then return end

	local T4 = CurTime() * 4 + self:EntIndex() * 1337

	local OY = math.cos( T4 )
	local A = math.max( math.sin( T4 ), 0 )

	local R = A * 64
	render.SetMaterial( self.SignalSprite )
	render.DrawSprite( self:LocalToWorld( Vector(11,-219,84) ), R, R, self.Red )
	render.DrawSprite( self:LocalToWorld( Vector(11,219,84) ), R, R, self.Red )
	render.DrawSprite( self:LocalToWorld( Vector(-203,0,122) ), R, R, self.Red )
end

function ENT:PostDrawTranslucent()
	self:HandleSignals()
	self:HandleLights()
end
