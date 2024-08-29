
local mat1 = Material( "sprites/blueflare1_noz_gmod" )
local mat2 = Material( "effects/blueblacklargebeam" )
local mat3 = Material( "effects/gunshipmuzzle" )
local mat4 = Material( "effects/lvs_base/core_beam1" )
local mat5 = Material( "sprites/heatwave" )
local mat6 = Material("sprites/strider_blackball")

function EFFECT:FindAttachment()
	if not IsValid( self.Player ) or not IsValid( self.Ent ) then self.DieTime = nil return end

	if self.Player == LocalPlayer() and self.Player:GetViewEntity() == self.Player and not self.Player:ShouldDrawLocalPlayer() then
		local vm = self.Player:GetViewModel()

		if not IsValid( vm ) then self.DieTime = nil return end

		return vm:GetAttachment( vm:LookupAttachment( "muzzle" ) )
	end

	return self.Ent:GetAttachment( self.Ent:LookupAttachment( "muzzle" ) )
end

function EFFECT:Init( data )
	self.Ent = data:GetEntity()

	if not IsValid( self.Ent ) then return end

	self.Player = self.Ent:GetOwner()

	local T = CurTime()

	self.LifeTime = 0.75
	self.DieTime = T + self.LifeTime

	self.LifeTimeMuzzle = 0.25
	self.DieTimeMuzzle = T + self.LifeTimeMuzzle

	if not IsValid( self.Ent ) or not IsValid( self.Player ) then self.DieTime = nil return end

	local att = self:FindAttachment()

	self.StartPos = att and att.Pos or data:GetStart()
	self.EndPos = self.Player:GetEyeTrace().HitPos

	self.LifeTimeTracer = 0.1
	self.DieTimeTracer  = T + self.LifeTimeTracer

	self:SetRenderBoundsWS( self.StartPos, self.EndPos )

	self:DoImpactEffect()
end

function EFFECT:Think()
	if not IsValid( self.Ent ) or not IsValid( self.Player ) or (self.DieTime or 0) < CurTime() then
		return false
	end

	return true
end

function EFFECT:DoImpactEffect()
	local Dir = (self.EndPos - self.StartPos):GetNormalized()

	local trace = util.TraceLine( {
		start = self.StartPos,
		endpos = self.EndPos + Dir * 10,
		mask = MASK_SOLID_BRUSHONLY
	} )

	local effectdata = EffectData()
		effectdata:SetOrigin( trace.HitPos )
		effectdata:SetNormal( trace.HitNormal )
	util.Effect( "lvs_laserrifle_hitwall", effectdata )
end

function EFFECT:Render()
	local T = CurTime()

	if not self.DieTime then return end

	local TimeFrac = math.Clamp( (self.DieTime - T) / self.LifeTime, 0, 1 )
	local TimeFracMuzzle = math.Clamp( (self.DieTimeMuzzle - T) / self.LifeTimeMuzzle, 0, 1 )
	local TimeFracTracer = math.Clamp( (self.DieTimeTracer - T) / self.LifeTimeTracer, 0, 1 )
	local ScaleMuzzle = math.Clamp( math.sin( math.rad( TimeFracMuzzle * 90 ) ), 0, 1 ) ^ 2

	if TimeFrac < 0 then return end

	render.SetMaterial( mat2 )

	local Sub = self.EndPos - self.StartPos
	local Dist = Sub:Length()
	local Dir = Sub:GetNormalized()
	local Num = math.floor( Dist / 50 )

	local Scale = math.max( math.sin( math.rad( TimeFrac * 90 ) ), 0 ) ^ 2

	local C255 = 255 * Scale
	local ColorScaled = Color( C255, C255, C255, C255 )

	render.StartBeam( Num + 1 )

	for i = 0, Num do
		local Frac = i / Num

		local Width = (4 + 36 * ScaleMuzzle) * math.sin( Frac * math.pi )

		render.AddBeam( self.StartPos + Dir * Dist * Frac, Width, Frac, ColorScaled )
	end

	render.AddBeam( self.EndPos, Scale, 0, ColorScaled )
	render.EndBeam()

	render.SetMaterial( mat4 )
	render.DrawBeam( self.StartPos, self.EndPos, 50 * TimeFracTracer, 0, (TimeFracTracer * Dist) / 512, ColorScaled )

	local SizeMuzzle = ScaleMuzzle * 50

	render.SetMaterial( mat5 )
	render.DrawSprite( self.StartPos + Dir * Dist * (1 - TimeFracTracer), SizeMuzzle, SizeMuzzle, ColorScaled )

	local att = self:FindAttachment()

	if not att then return end

	render.SetMaterial( mat1 )
	render.DrawSprite( att.Pos, 20, 20, ColorScaled )

	render.SetMaterial( mat3 )
	render.DrawSprite( att.Pos, SizeMuzzle, SizeMuzzle, color_white )
end
