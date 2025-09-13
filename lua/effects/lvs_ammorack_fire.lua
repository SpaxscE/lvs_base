
EFFECT.FireMat = Material( "effects/fire_cloud1" )
EFFECT.HeatMat = Material( "sprites/heatwave" )

EFFECT.Smoke = {
	"particle/smokesprites_0001",
	"particle/smokesprites_0002",
	"particle/smokesprites_0003",
	"particle/smokesprites_0004",
	"particle/smokesprites_0005",
	"particle/smokesprites_0006",
	"particle/smokesprites_0007",
	"particle/smokesprites_0008",
	"particle/smokesprites_0009",
	"particle/smokesprites_0010",
	"particle/smokesprites_0011",
	"particle/smokesprites_0012",
	"particle/smokesprites_0013",
	"particle/smokesprites_0014",
	"particle/smokesprites_0015",
	"particle/smokesprites_0016"
}

function EFFECT:Init( data )
	local Pos = data:GetOrigin()
	local Ent = data:GetEntity()

	self.LifeTime = 0.4
	self.DieTime = CurTime() + self.LifeTime

	if not IsValid( Ent ) then return end

	self.Ent = Ent
	self.Pos = Ent:WorldToLocal( Pos + VectorRand() * 3 )
	self.Seed = math.Rand( 0, 10000 )
	self.Magnitude = data:GetMagnitude()

	local emitter = Ent:GetParticleEmitter( self.Pos )

	if not IsValid( emitter ) then return end

	local VecCol = (render.GetLightColor( Pos ) * 0.8 + Vector(0.2,0.2,0.2)) * 255

	for i = 0, 20 do
		local particle = emitter:Add( "sprites/rico1", Pos )
		
		local vel = VectorRand() * 800
		
		if particle then
			particle:SetVelocity( Vector(0,0,500) + VectorRand() * 500 )
			particle:SetDieTime( 0.25 * self.Magnitude )
			particle:SetStartAlpha( 200 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 3 )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand(-1,1) * math.pi )
			particle:SetRollDelta( math.Rand(-1,1) * 3 )
			particle:SetColor( 255, 255, 255 )
			particle:SetAirResistance( 0 )
		end
	end

	for i = 1, 8 do
		local particle = emitter:Add( self.Smoke[ math.random(1, #self.Smoke ) ], Pos )

		local Dir = Angle(0,math.Rand(-180,180),0):Forward()
		Dir.z = -0.5
		Dir:Normalize()

		if particle then
			particle:SetVelocity( Dir * 250 )
			particle:SetDieTime( 0.5 + i * 0.01 )
			particle:SetAirResistance( 125 ) 
			particle:SetStartAlpha( 100 )
			particle:SetStartSize( 20 )
			particle:SetEndSize( 40 )
			particle:SetRoll( math.Rand(-1,1) * math.pi )
			particle:SetRollDelta( math.Rand(-1,1) * 3 )
			particle:SetColor( 0, 0, 0 )
			particle:SetGravity( Vector( 0, 0, 600 ) )
			particle:SetCollide( true )
			particle:SetBounce( 0 )
		end
	end

	for i = 0,22 do
		local particle = emitter:Add( "particles/flamelet"..math.random(1,5), Pos )

		local Dir = Angle(0,math.Rand(-180,180),0):Forward()

		if particle then
			particle:SetVelocity( Dir * math.Rand(600,900) * self.Magnitude )
			particle:SetDieTime( math.Rand(0.2,0.3) * self.Magnitude )
			particle:SetAirResistance( 400 ) 
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( math.Rand(20,25) )
			particle:SetEndSize( math.Rand(5,10) )
			particle:SetRoll( math.Rand(-1,1) * 180 )
			particle:SetRollDelta( math.Rand(-1,1) * 3 )
			particle:SetColor( 255, 200, 50 )
			particle:SetGravity( Vector( 0, 0, 1000 ) )
			particle:SetCollide( false )
		end
	end

	for i = 1, 4 do
		local particle = emitter:Add( self.Smoke[ math.random(1, #self.Smoke ) ], Pos )

		local Dir = Angle(0,math.Rand(-180,180),0):Forward()

		if particle then
			particle:SetVelocity( Dir * 500 * self.Magnitude )
			particle:SetDieTime( 0.5 + i * 0.01 )
			particle:SetAirResistance( 125 ) 
			particle:SetStartAlpha( 150 * self.Magnitude )
			particle:SetStartSize( 40 * self.Magnitude )
			particle:SetEndSize( 250 * self.Magnitude )
			particle:SetRoll( math.Rand(-1,1) * math.pi )
			particle:SetRollDelta( math.Rand(-1,1) * 3 )
			particle:SetColor( math.min( VecCol.r, 255 ), math.min( VecCol.g, 255 ), math.min( VecCol.b, 255 ) )
			particle:SetGravity( Vector( 0, 0, 600 ) )
			particle:SetCollide( true )
			particle:SetBounce( 0 )
		end
	end
end

function EFFECT:Think()
	if not IsValid( self.Ent ) then return false end

	if self.DieTime < CurTime() then return false end

	self:SetPos( self.Ent:LocalToWorld( self.Pos ) )

	return true
end

function EFFECT:Render()
	if not IsValid( self.Ent ) or not self.Pos then return end

	self:RenderFire()
end

function EFFECT:RenderFire()
	local Scale = ((self.DieTime - CurTime()) / self.LifeTime) * (self.Magnitude or 0)

	if Scale < 0 then return end

	local Pos = self.Ent:LocalToWorld( self.Pos )

	local scroll = -CurTime() * 10

	local Up = Vector(0,0,0.92) + VectorRand() * 0.08

	render.SetMaterial( self.FireMat )
	render.StartBeam( 3 )
		render.AddBeam( Pos, 64 * Scale, scroll, Color( 100, 100, 100, 100 ) )
		render.AddBeam( Pos + Up * 120 * Scale, 64 * Scale, scroll + 1, Color( 255, 200, 50, 150 ) )
		render.AddBeam( Pos + Up * 300 * Scale, 64 * Scale, scroll + 3, Color( 255, 191, 0, 0 ) )
	render.EndBeam()

	scroll = scroll * 0.5

	render.UpdateRefractTexture()
	render.SetMaterial( self.HeatMat )
	render.StartBeam( 3 )
		render.AddBeam( Pos, 64 * Scale, scroll, Color( 0, 0, 255, 200 ) )
		render.AddBeam( Pos + Up * 64 * Scale, 64 * Scale, scroll + 2, color_white )
		render.AddBeam( Pos + Up * 250 * Scale, 120 * Scale, scroll + 5, Color( 0, 0, 0, 0 ) )
	render.EndBeam()

	scroll = scroll * 1.3
	render.SetMaterial( self.FireMat )
	render.StartBeam( 3 )
		render.AddBeam( Pos, 32 * Scale, scroll, Color( 100, 100, 100, 100 ) )
		render.AddBeam( Pos + Up * 60 * Scale, 32 * Scale, scroll + 1, Color( 255, 200, 50, 150 ) )
		render.AddBeam( Pos + Up * 300 * Scale, 32 * Scale, scroll + 3, Color( 255, 191, 0, 0 ) )
	render.EndBeam()
end