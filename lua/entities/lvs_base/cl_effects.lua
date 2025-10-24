
function ENT:StartWindSounds()
	if not LVS.ShowEffects then return end

	self:StopWindSounds()

	if LocalPlayer():lvsGetVehicle() ~= self then return end

	local EntTable = self:GetTable()

	EntTable._WindSFX = CreateSound( self, "LVS.Physics.Wind" )
	EntTable._WindSFX:PlayEx(0,100)

	EntTable._WaterSFX = CreateSound( self, "LVS.Physics.Water" )
	EntTable._WaterSFX:PlayEx(0,100)
end

function ENT:StopWindSounds()
	local EntTable = self:GetTable()

	if EntTable._WindSFX then
		EntTable._WindSFX:Stop()
		EntTable._WindSFX = nil
	end

	if EntTable._WaterSFX then
		EntTable._WaterSFX:Stop()
		EntTable._WaterSFX = nil
	end
end

ENT.DustEffectSurfaces = {
	["sand"] = true,
	["dirt"] = true,
	["grass"] = true,
}

ENT.GroundEffectsMultiplier = 1

function ENT:DoVehicleFX()
	local EntTable = self:GetTable()

	if EntTable.GroundEffectsMultiplier <= 0 or not LVS.ShowEffects then self:StopWindSounds() return end

	local Vel = self:GetVelocity():Length() * EntTable.GroundEffectsMultiplier

	if EntTable._WindSFX then EntTable._WindSFX:ChangeVolume( math.Clamp( (Vel - 1200) / 2800,0,1 ), 0.25 ) end

	if Vel < 1500 then
		if EntTable._WaterSFX then EntTable._WaterSFX:ChangeVolume( 0, 0.25 ) end

		return
	end

	if (EntTable.nextFX or 0) < CurTime() then
		EntTable.nextFX = CurTime() + 0.05

		local LCenter = self:OBBCenter()
		LCenter.z = self:OBBMins().z

		local CenterPos = self:LocalToWorld( LCenter )

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

		if EntTable._WaterSFX then EntTable._WaterSFX:ChangePitch( math.Clamp((Vel / 1000) * 50,80,150), 0.5 ) end

		if traceWater.Hit and trace.HitPos.z < traceWater.HitPos.z then 
			local effectdata = EffectData()
				effectdata:SetOrigin( traceWater.HitPos )
				effectdata:SetEntity( self )
			util.Effect( "lvs_physics_water", effectdata )

			if EntTable._WaterSFX then EntTable._WaterSFX:ChangeVolume( 1 - math.Clamp(traceWater.Fraction,0,1), 0.5 ) end
		else
			if EntTable._WaterSFX then EntTable._WaterSFX:ChangeVolume( 0, 0.25 ) end
		end

		if trace.Hit and EntTable.DustEffectSurfaces[ util.GetSurfacePropName( trace.SurfaceProps ) ] then
			local effectdata = EffectData()
				effectdata:SetOrigin( trace.HitPos )
				effectdata:SetEntity( self )
			util.Effect( "lvs_physics_dust", effectdata )
		end
	end
end

function ENT:GetParticleEmitter( Pos )
	local EntTable = self:GetTable()

	local T = CurTime()

	if IsValid( EntTable.Emitter ) and (EntTable.EmitterTime or 0) > T then
		return EntTable.Emitter
	end

	self:StopEmitter()

	EntTable.Emitter = ParticleEmitter( Pos, false )
	EntTable.EmitterTime = T + 2

	return EntTable.Emitter
end

function ENT:StopEmitter()
	if IsValid( self.Emitter ) then
		self.Emitter:Finish()
	end
end

function ENT:GetParticleEmitter3D( Pos )
	local EntTable = self:GetTable()

	local T = CurTime()

	if IsValid( EntTable.Emitter3D ) and (EntTable.EmitterTime3D or 0) > T then
		return EntTable.Emitter3D
	end

	self:StopEmitter3D()

	EntTable.Emitter3D = ParticleEmitter( Pos, true )
	EntTable.EmitterTime3D = T + 2

	return EntTable.Emitter3D
end

function ENT:StopEmitter3D()
	if IsValid( self.Emitter3D ) then
		self.Emitter3D:Finish()
	end
end