include("shared.lua")

local up = Vector(0,0,1)
local down = Vector(0,0,-1)

function ENT:DoVehicleFX()
	local EntTable = self:GetTable()

	local Vel = self:GetVelocity():Length()

	if EntTable._WindSFX then
		EntTable._WindSFX:ChangeVolume( math.Clamp( (Vel * EntTable.GroundEffectsMultiplier - 1200) / 2800,0,1 ), 0.25 )
	end

	local T = CurTime()

	if (EntTable.nextFX or 0) < T then
		EntTable.nextFX = T + 0.01

		self:DoAdvancedWaterEffects( EntTable, Vel )
	end
end

function ENT:DoAdvancedWaterEffects( EntTable, Vel )
	local pos = self:LocalToWorld( self:OBBCenter() )

	local traceSky = util.TraceLine( {
		start = pos,
		endpos = pos + up * 50000,
		filter = self:GetCrosshairFilterEnts()
	} )

	local traceWater = util.TraceLine( {
		start = traceSky.HitPos,
		endpos = pos + down * 50000,
		filter = self:GetCrosshairFilterEnts(),
		mask = MASK_WATER
	} )

	local traceSoil = util.TraceLine( {
		start = traceSky.HitPos,
		endpos = pos + down * 50000,
		filter = self:GetCrosshairFilterEnts(),
		mask = MASK_ALL
	} )

	if traceSoil.HitPos.z > traceWater.HitPos.z then
		if EntTable._WaterSFX then
			EntTable._WaterSFX:ChangeVolume( 0, 0.25 )
		end

		return
	end

	if EntTable._WaterSFX then
		EntTable._WaterSFX:ChangeVolume( math.min(Vel / EntTable.MaxVelocity,1) ^ 2, 0.25 )
		EntTable._WaterSFX:ChangePitch( math.Clamp((Vel / EntTable.MaxVelocity) * 50,80,150), 0.5 )
	end

	local effectdata = EffectData()
		effectdata:SetOrigin( traceWater.HitPos )
		effectdata:SetEntity( self )
	util.Effect( "lvs_physics_water_advanced", effectdata )
end