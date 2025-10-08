
function ENT:StopWheelEffects()
	if not self._DoingWheelFx then return end

	self._DoingWheelFx = nil

	self:FinishSkidmark()
end

function ENT:StartWheelEffects( Base, trace, traceWater )
	self:DoWheelEffects( Base, trace, traceWater )

	if self._DoingWheelFx then return end

	self._DoingWheelFx = true
end

function ENT:DoWheelEffects( Base, trace, traceWater )
	if not trace.Hit then self:FinishSkidmark() return end

	local SurfacePropName = util.GetSurfacePropName( trace.SurfaceProps )
	local SkidValue = self:GetSkid()

	if traceWater.Hit then
		local Scale = math.min( 0.3 + (SkidValue - 100) / 4000, 1 ) ^ 2

		local effectdata = EffectData()
		effectdata:SetOrigin( trace.HitPos )
		effectdata:SetEntity( Base )
		effectdata:SetNormal( trace.HitNormal )
		effectdata:SetMagnitude( Scale )
		effectdata:SetFlags( 1 )
		util.Effect( "lvs_physics_wheeldust", effectdata, true, true )

		self:FinishSkidmark()

		return
	end

	if self.SkidmarkSurfaces[ SurfacePropName ] then
		local Scale = math.min( 0.3 + SkidValue / 4000, 1 ) ^ 2

		if Scale > 0.2 then
			self:StartSkidmark( trace.HitPos )
			self:CalcSkidmark( trace, Base:GetCrosshairFilterEnts() )
		else
			self:FinishSkidmark()
		end

		local effectdata = EffectData()
		effectdata:SetOrigin( trace.HitPos )
		effectdata:SetEntity( Base )
		effectdata:SetNormal( trace.HitNormal )
		util.Effect( "lvs_physics_wheelsmoke", effectdata, true, true )
	else
		self:FinishSkidmark()
	end

	if not LVS.ShowEffects then return end

	if self.DustEffectSurfaces[ SurfacePropName ] then
		local Scale = math.min( 0.3 + (SkidValue - 100) / 4000, 1 ) ^ 2

		local effectdata = EffectData()
		effectdata:SetOrigin( trace.HitPos )
		effectdata:SetEntity( Base )
		effectdata:SetNormal( trace.HitNormal )
		effectdata:SetMagnitude( Scale )
		effectdata:SetFlags( 0 )
		util.Effect( "lvs_physics_wheeldust", effectdata, true, true )
	end
end

function ENT:DoWaterEffects( Base, traceWater, Pos )
	local effectdata = EffectData()
		effectdata:SetOrigin( traceWater.Fraction > 0.5 and traceWater.HitPos or Pos )
		effectdata:SetEntity( Base )
		effectdata:SetMagnitude( self:GetRadius() )
		effectdata:SetFlags( 0 )
	util.Effect( "lvs_physics_wheelwatersplash", effectdata )
end

function ENT:DoWheelChainEffects( Base, trace )
	if not LVS.ShowEffects then return end

	if not self.DustEffectSurfaces[ util.GetSurfacePropName( trace.SurfaceProps ) ] then return end

	local effectdata = EffectData()
	effectdata:SetOrigin( trace.HitPos )
	effectdata:SetEntity( Base )
	effectdata:SetMagnitude( self:GetRadius() )
	effectdata:SetNormal( trace.HitNormal )
	util.Effect( "lvs_physics_trackdust", effectdata, true, true )
end

function ENT:CalcWheelEffects()
	local T = CurTime()

	if (self._NextFx or 0) > T then return end

	local Base = self:GetBase()

	if not IsValid( Base ) then return end

	self._NextFx = T + (Base:GetAI() and 0.1 or 0.05)

	local Radius = Base:GetWheelUp() * (self:GetRadius() + 1)

	local Vel = self:GetVelocity()
	local Pos =  self:GetPos() + Vel * 0.025

	local StartPos = Pos + Radius
	local EndPos = Pos - Radius

	local trace = util.TraceLine( {
		start = StartPos,
		endpos = EndPos,
		filter = Base:GetCrosshairFilterEnts(),
	} )

	local traceWater = util.TraceLine( {
		start = StartPos,
		endpos = EndPos,
		filter = Base:GetCrosshairFilterEnts(),
		mask = MASK_WATER,
	} )

	self:CalcWheelSounds( Base, trace, traceWater )

	if traceWater.Hit and trace.HitPos.z < traceWater.HitPos.z then 
		if math.abs( self:GetRPM() ) > 25 then
			self:DoWaterEffects( Base, traceWater, Pos )
		end
	else
		if self:GetWheelChainMode() and trace.Hit and math.abs( self:GetRPM() ) > 25 and Vel:LengthSqr() > 1500 then
			self:DoWheelChainEffects( Base, trace )
		end
	end

	if self:GetSlip() < 500 then self:StopWheelEffects() return end

	self:StartWheelEffects( Base, trace, traceWater )
end

function ENT:CalcWheelSounds( Base, trace, traceWater )
	if not trace.Hit then return end

	-- rejoin requires this
	if trace.Entity == self then
		if istable( Base.CrosshairFilterEnts ) and #Base.CrosshairFilterEnts > 1 then
			Base.CrosshairFilterEnts = nil
		end

		return
	end

	local RPM = math.abs( self:GetRPM() )

	if self:GetDamaged() and RPM > 30 then
		if self:GetWheelChainMode() then
			local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
			effectdata:SetNormal( self:GetForward() )
			util.Effect( "lvs_physics_trackscraping", effectdata, true, true )

			Base:DoTireSound( "tracks_damage_layer" )
		else
			local Ang = self:GetForward():Angle() + Angle(10,0,0)
			Ang:RotateAroundAxis( Base:GetUp(), -90 )

			local effectdata = EffectData()
			effectdata:SetOrigin( trace.HitPos + trace.HitNormal )
			effectdata:SetNormal( Ang:Forward() * math.min( self:GetSlip() / 10000, 3 ) * (self:GetRPM() > 0 and 1 or -1) )
			effectdata:SetMagnitude( 1 )
			util.Effect( "manhacksparks", effectdata, true, true )

			Base:DoTireSound( "tire_damage_layer" )

			return
		end
	end

	if not Base:GetEngineActive() and RPM < 50 then return end

	if traceWater.Hit then
		Base:DoTireSound( "roll_wet" )

		return
	end

	local surface = self.DustEffectSurfaces[ util.GetSurfacePropName( trace.SurfaceProps ) ] and "_dirt" or ""
	local snd_type = (self:GetSlip() > 500) and "skid" or "roll"

	if Base:GetRacingTires() and surface == "" then surface = "_racing" end

	if (istable( StormFox ) or istable( StormFox2 )) and surface ~= "_dirt" then
		local Rain = false

		if StormFox then
			Rain = StormFox.IsRaining()
		end

		if StormFox2 then
			Rain = StormFox2.Weather:IsRaining()
		end

		if Rain then
			local effectdata = EffectData()
				effectdata:SetOrigin( trace.HitPos )
				effectdata:SetEntity( Base )
				effectdata:SetMagnitude( self:BoundingRadius() )
				effectdata:SetFlags( 1 )
			util.Effect( "lvs_physics_wheelwatersplash", effectdata )

			Base:DoTireSound( snd_type.."_wet" )

			return
		end
	end

	if snd_type == "roll" and not self:GetWheelChainMode() and self:GetHP() ~= self:GetMaxHP() then
		surface = "_damaged"
	end

	Base:DoTireSound( snd_type..surface )
end