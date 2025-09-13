
local MuzzleFX = Material("sprites/strider_blackball")
local BeamFX = Material("sprites/bluelaser1")
local WarpFX = Material("particle/warp5_warp")

function EFFECT:Init( data )
	self.Ent = data:GetEntity()

	if not IsValid( self.Ent ) then return end

	self.LifeTime = 0.2
	self.DieTime = CurTime() + self.LifeTime

	self.Ent:EmitSound( "NPC_Strider.Shoot" )

	self:SetRenderBoundsWS( self.Ent:GetPos(), self.Ent:GetPos() - self.Ent:GetUp() * 50000 )
end

function EFFECT:Think()
	if (self.DieTime or 0) < CurTime() then
		self:DoImpactEffect()
		return false
	end

	return true
end

function EFFECT:DoImpactEffect()
	if not IsValid( self.Ent ) then return end

	local Muzzle =  self.Ent:GetAttachment( self.Ent:LookupAttachment( "bellygun" ) )

	if not Muzzle then return end

	local trace = util.TraceLine( {
		start = Muzzle.Pos,
		endpos = Muzzle.Pos + self.Ent:GetAimVector() * 50000,
		mask = MASK_SOLID_BRUSHONLY
	} )

	local effectdata = EffectData()
		effectdata:SetOrigin( trace.HitPos + trace.HitNormal )
		effectdata:SetRadius( 256 )
		effectdata:SetNormal( trace.HitNormal )
	util.Effect( "AR2Explosion", effectdata, true, true )
end

function EFFECT:Render()
	if not IsValid( self.Ent ) then return end

	local Muzzle =  self.Ent:GetAttachment( self.Ent:LookupAttachment( "bellygun" ) )

	if not Muzzle then return end

	local T = CurTime()
	local Delta = ((T + self.LifeTime) - self.DieTime) / self.LifeTime

	local trace = util.TraceLine( {
		start = Muzzle.Pos,
		endpos = Muzzle.Pos + self.Ent:GetAimVector() * 50000,
		mask = MASK_SOLID_BRUSHONLY
	} )

	self:SetRenderBoundsWS( Muzzle.Pos, trace.HitPos )

	render.SetMaterial( BeamFX )
	render.DrawBeam( Muzzle.Pos, trace.HitPos, (Delta ^ 2) * 64, 0, 1, Color( 255, 255, 255 ) )

	local Sub = trace.HitPos - Muzzle.Pos
	local Dir = Sub:GetNormalized()
	local Dist = Sub:Length()

	local Scale = 512 - Delta * 512
	render.SetMaterial( WarpFX )
	render.DrawSprite( Muzzle.Pos + Dir * Dist * Delta, Scale, Scale, Color( 255, 255, 255, 255) )
end
