
EFFECT.SmokeMat = {
	[1] = Material( "particle/smokesprites_0001" ),
	[2] = Material( "particle/smokesprites_0002" ),
	[3] = Material( "particle/smokesprites_0003" ),
	[4] = Material( "particle/smokesprites_0004" ),
	[5] = Material( "particle/smokesprites_0005" ),
	[6] = Material( "particle/smokesprites_0006" ),
	[7] = Material( "particle/smokesprites_0007" ),
	[8] = Material( "particle/smokesprites_0008" ),
	[9] = Material( "particle/smokesprites_0009" ),
	[10] = Material( "particle/smokesprites_0010" ),
	[11] = Material( "particle/smokesprites_0011" ),
	[12] = Material( "particle/smokesprites_0012" ),
	[13] = Material( "particle/smokesprites_0013" ),
	[14] = Material( "particle/smokesprites_0014" ),
	[15] = Material( "particle/smokesprites_0015" ),
	[16] = Material( "particle/smokesprites_0016" ),
}

function EFFECT:Init( data )
	local Pos = data:GetOrigin()
	local Ent = data:GetEntity()
	local Mag = data:GetMagnitude()

	self.LifeTime = 0.5 + Mag * 0.5
	self.DieTime = CurTime() + self.LifeTime

	if not IsValid( Ent ) then return end

	self.Mag = Mag
	self.Ent = Ent
	self.Pos = Ent:WorldToLocal( Pos + VectorRand() * 15 )
	self.RandomSize = math.Rand( 0.8, 1.6 )
	self.Vel = self.Ent:GetVelocity()
end

function EFFECT:Think()
	if not IsValid( self.Ent ) then return false end

	if self.DieTime < CurTime() then return false end

	self:SetPos( self.Ent:LocalToWorld( self.Pos ) )

	return true
end

function EFFECT:Render()
	if not IsValid( self.Ent ) or not self.Pos then return end

	self:RenderSmoke()
end

function EFFECT:RenderSmoke()
	local Scale = (self.DieTime - CurTime()) / self.LifeTime

	local Pos = self.Ent:LocalToWorld( self.Pos )

	local InvScale = 1 - Scale

	local Num = #self.SmokeMat - math.Clamp(math.ceil( Scale * #self.SmokeMat ) - 1,0, #self.SmokeMat - 1)

	local A = (50 + 100 * (1 - self.Mag)) * Scale
	local C = (20 + 30 * self.RandomSize * self.Mag)

	local Size = (25 + 30 * InvScale) * self.RandomSize
	local Offset = (self.Vel * InvScale ^ 2) * 0.15

	render.SetMaterial( self.SmokeMat[ Num ] )
	render.DrawSprite( Pos + Vector(0,0,InvScale ^ 2 * (20 + self.Vel:Length() / 25) * self.RandomSize) - Offset, Size, Size, Color( C, C, C, A ) )
end
