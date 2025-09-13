
local MuzzleFX = Material("sprites/strider_blackball")
local BeamFX = Material("sprites/bluelaser1")
local WarpFX = Material("particle/warp5_warp")

function EFFECT:Init( data )
	self.Ent = data:GetEntity()

	if not IsValid( self.Ent ) then return end

	self.LifeTime = 2
	self.DieTime = CurTime() + self.LifeTime

	self.Ent:EmitSound( "NPC_Strider.Charge" )

	self:SetRenderBoundsWS( self.Ent:GetPos(), self.Ent:GetPos() - self.Ent:GetUp() * 50000 )
end

function EFFECT:Think()
	if (self.DieTime or 0) < CurTime() then return false end

	return true
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

	render.SetMaterial( MuzzleFX )
	render.DrawSprite( Muzzle.Pos, Delta * 32, Delta * 32, Color( 255, 255, 255, Delta * 255) )

	render.SetMaterial( BeamFX )
	render.DrawBeam( Muzzle.Pos, trace.HitPos, (Delta ^ 2) * 64, 0, 1, Color( 255, 255, 255 ) )

	render.SetMaterial( WarpFX )
	render.DrawSprite( Muzzle.Pos, (Delta ^ 2) * 256, (Delta ^ 2) * 256, Color( 255, 255, 255, 100) )

	local dlight = DynamicLight( self:EntIndex() * 1337 )
	if dlight then
		dlight.pos = Muzzle.Pos
		dlight.r = 0
		dlight.g = 255
		dlight.b = 255
		dlight.brightness = Delta * 10
		dlight.Decay = 100
		dlight.Size = 128
		dlight.DieTime = CurTime() + 0.2
	end
end
