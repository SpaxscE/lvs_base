
function ENT:StartWindSounds()
	self._WindSFX = CreateSound( self, "LVS.Physics.Wind" )
	self._WindSFX:PlayEx(0,100)

	self._WaterSFX = CreateSound( self, "LVS.Physics.Water" )
	self._WaterSFX:PlayEx(0,100)
end

function ENT:StopWindSounds()
	if self._WindSFX then
		self._WindSFX:Stop()
		self._WindSFX = nil
	end

	if self._WaterSFX then
		self._WaterSFX:Stop()
		self._WaterSFX = nil
	end
end

function ENT:DoVehicleFX()
	local Vel = self:GetVelocity():Length()

	if self._WindSFX then self._WindSFX:ChangeVolume( math.Clamp( (Vel - 1200) / 2800,0,1 ), 0.25 ) end

	if Vel < 1500 then
		if self._WaterSFX then self._WaterSFX:ChangeVolume( 0, 0.25 ) end

		return
	end

	if (self.nextFX or 0) < CurTime() then
		self.nextFX = CurTime() + 0.05

		local CenterPos = self:LocalToWorld( self:OBBCenter() )

		local trace = util.TraceLine( {
			start = CenterPos + Vector(0,0,25),
			endpos = CenterPos - Vector(0,0,450),
			filter = self:GetCrosshairFilterEnts(),
		} )

		local traceWater = util.TraceLine( {
			start = CenterPos + Vector(0,0,25),
			endpos = CenterPos - Vector(0,0,450),
			filter = self:GetCrosshairFilterEnts(),
			mask = MASK_WATER,
		} )

		if traceWater.Hit and trace.HitPos.z < traceWater.HitPos.z then 
			local effectdata = EffectData()
				effectdata:SetOrigin( traceWater.HitPos )
				effectdata:SetEntity( self )
			util.Effect( "lvs_physics_water", effectdata )

			if self._WaterSFX then self._WaterSFX:ChangeVolume( 1, 1 ) end
		else
			if self._WaterSFX then self._WaterSFX:ChangeVolume( 0, 0.25 ) end
		end

		if trace.Hit then
			local effectdata = EffectData()
				effectdata:SetOrigin( trace.HitPos )
				effectdata:SetEntity( self )
			util.Effect( "lvs_physics_dust", effectdata )
		end
	end
end

function ENT:GetParticleEmitter( Pos )
	if self.Emitter then
		if self.EmitterTime > CurTime() then
			return self.Emitter
		end
	end

	if IsValid( self.Emitter ) then
		self.Emitter:Finish()
	end

	self.Emitter = ParticleEmitter( Pos, false )
	self.EmitterTime = CurTime() + 2

	return self.Emitter
end

function ENT:StopEmitter()
	if IsValid( self.Emitter ) then
		self.Emitter:Finish()
	end
end