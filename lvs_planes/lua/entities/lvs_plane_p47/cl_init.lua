include("shared.lua")

function ENT:OnSpawn()
	self:RegisterTrail( Vector(63,220,67), 0, 20, 2, 1000, 400 )
	self:RegisterTrail( Vector(63,-220,67), 0, 20, 2, 1000, 400 )
end

function ENT:OnFrame()
	local FT = RealFrameTime()

	self:AnimControlSurfaces( FT )
	self:AnimLandingGear( FT )
	self:AnimCabin( FT )
	self:AnimRotor( FT )
end

function ENT:AnimRotor( frametime )
	if not self.RotorRPM then return end

	local PhysRot = self.RotorRPM < 470

	self._rRPM = self._rRPM and (self._rRPM + self.RotorRPM *  frametime * (PhysRot and 4 or 1)) or 0

	local Rot = Angle(self._rRPM,0,0)
	Rot:Normalize() 

	self:ManipulateBoneAngles( 39, Rot )

	self:SetBodygroup( 12, PhysRot and 1 or 0 ) 
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

	self:ManipulateBoneAngles( 10, Angle( self.smRoll,0,0) )
	self:ManipulateBoneAngles( 11, Angle( self.smRoll,0,0) )

	self:ManipulateBoneAngles( 12, Angle( 0,0,self.smPitch) )

	self:ManipulateBoneAngles( 38, Angle( self.smYaw,0,0 ) )
end

function ENT:AnimCabin( frametime )
	local bOn = self:GetActive()
	
	local TVal = bOn and 0 or 1
	
	local Speed = frametime * 4
	
	self.SMcOpen = self.SMcOpen and self.SMcOpen + math.Clamp(TVal - self.SMcOpen,-Speed,Speed) or 0

	self:ManipulateBonePosition( 40, Vector( 0,0,-self.SMcOpen * 25.6) ) 
end

function ENT:AnimLandingGear( frametime )
	self._smLandingGear = self._smLandingGear and self._smLandingGear + ((1 - self:GetLandingGear()) - self._smLandingGear) * frametime * 8 or 0

	local gExp = self._smLandingGear ^ 15

	self:ManipulateBoneAngles( 13, Angle( -30 + 30 * self._smLandingGear,0,0) )
	self:ManipulateBoneAngles( 14, Angle( 30 - 30 * self._smLandingGear,0,0) )
	
	self:ManipulateBoneAngles( 42, Angle( 3.5,88,24.5) * self._smLandingGear )
	self:ManipulateBoneAngles( 45, Angle( 0,-90,2.8) * gExp )
	
	self:ManipulateBoneAngles( 43, Angle( -3.5,-88,24.5) * self._smLandingGear )
	self:ManipulateBoneAngles( 44, Angle( 0,90,2.8) * (self._smLandingGear ^ 15) )
	
	self:ManipulateBoneAngles( 47, Angle( -5.5,90,-16) * gExp )
	self:ManipulateBoneAngles( 48, Angle( 5,-90,-16) * gExp )
	
	self:ManipulateBoneAngles( 46, Angle( 0,0,160) * self._smLandingGear )
end

