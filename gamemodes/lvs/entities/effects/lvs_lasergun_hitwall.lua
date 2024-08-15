
local Materials = {
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

local NextPlay = 0
local OldPos = vector_origin

local DecalMat = Material( util.DecalMaterial( "FadingScorch" ) )
function EFFECT:Init( data )
	self.Pos = data:GetOrigin()
	self.Col = data:GetStart() or Vector(255,100,0)

	local T = CurTime()

	local Volume = math.min( (OldPos - self.Pos):LengthSqr() , 1)

	if Volume > 0.01 then
		if NextPlay < T then
			sound.Play( "ambient/energy/zap"..math.random(1,9)..".wav", self.Pos, 75, 100, 1 * Volume )

			NextPlay = T + 0.05
		end
	end

	OldPos = self.Pos


	self.mat = Material( "sprites/light_glow02_add" )
	
	self.LifeTime = 0.25
	self.DieTime = T + self.LifeTime

	local Col = self.Col
	local Pos = self.Pos
	local Dir = data:GetNormal()
	
	local emitter = ParticleEmitter( Pos, false )

	local trace = util.TraceLine( {
		start = Pos + Dir * 5,
		endpos = Pos - Dir * 5,
		filter = function( ent ) 
			if ent.GetOwningEnt then return false end
			return true
		end
	} )

	if trace.Hit and not trace.HitNonWorld then
		self.RenderGlow = {
			Pos = trace.HitPos,
			Normal = trace.HitNormal,
			Angle = trace.HitNormal:Angle() + Angle(90,0,0),
			RandomAng = math.random(0,360),
		}

		util.DecalEx( DecalMat, trace.Entity, trace.HitPos + trace.HitNormal, trace.HitNormal, color_white, math.Rand(0.25,0.3), math.Rand(0.25,0.3) )
	end

	if not trace.Hit then return end

	local particle = emitter:Add( Materials[ math.random(1,table.Count( Materials )) ], Pos )
	
	local vel = VectorRand() * 100 + Dir * 40
	
	if particle then			
		particle:SetVelocity( vel )
		particle:SetDieTime( 0.5 )
		particle:SetAirResistance( 1000 ) 
		particle:SetStartAlpha( 50 )
		particle:SetStartSize( 2 )
		particle:SetEndSize( 6 )
		particle:SetRoll( math.Rand(-1,1) )
		particle:SetColor( 40,40,40 )
		particle:SetGravity( Dir * 10 )
		particle:SetCollide( false )
	end

	local particle = emitter:Add( "effects/spark", Pos )
	
	local vel = VectorRand() * 100 + Dir * 40
	
	if particle then
		particle:SetVelocity( vel )
		particle:SetAngles( vel:Angle() + Angle(0,90,0) )
		particle:SetDieTime( 1 )
		particle:SetStartAlpha( math.Rand( 200, 255 ) )
		particle:SetEndAlpha( 0 )
		particle:SetStartSize( 2 )
		particle:SetEndSize( 0 )
		particle:SetRoll( math.Rand(-100,100) )
		particle:SetRollDelta( math.Rand(-100,100) )
		particle:SetCollide( true )
		particle:SetBounce( 0.5 )
		particle:SetStartLength( 5 )
		particle:SetAirResistance( 0 )
		particle:SetColor( 150, 200, 255 )
		particle:SetGravity( Vector(0,0,-600) )
	end

	emitter:Finish()
end

function EFFECT:Think()
	if self.DieTime < CurTime() then 
		return false
	end

	return true
end

local Mat = Material("particle/particle_glow_05_addnofog")

function EFFECT:Render()
	if self.RenderGlow then
		local Timed = 1 - (self.DieTime - CurTime()) / self.LifeTime
		local Scale = math.max(math.min(2 - Timed * 2,1),0)

		cam.Start3D2D( self.RenderGlow.Pos + self.RenderGlow.Normal * 0.5, self.RenderGlow.Angle, 0.1 )
			surface.SetMaterial( Mat )
			surface.SetDrawColor( 150 * Scale, 200 * Scale, 255 * Scale, 200 * Scale )
			surface.DrawTexturedRectRotated( 0, 0, 300 , 300 , self.RenderGlow.RandomAng )
		cam.End3D2D()
	end
end
