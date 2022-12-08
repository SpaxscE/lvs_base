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

local MatDebris = {
	"particle/particle_debris_01",
	"particle/particle_debris_02",
}

function EFFECT:Init( data )
	local Ent = data:GetEntity()

	if not IsValid( Ent ) then return end

	local CenterPos = Ent:LocalToWorld( Ent:OBBCenter() )

	local trace = util.TraceLine( {
		start = CenterPos + Vector(0,0,25),
		endpos = CenterPos - Vector(0,0,300),
		filter = Ent,
	} )

	local traceWater = util.TraceLine( {
		start = CenterPos + Vector(0,0,25),
		endpos = CenterPos - Vector(0,0,300),
		filter = Ent,
		mask = MASK_WATER,
	} )

	if traceWater.Hit and trace.HitPos.z < traceWater.HitPos.z then 
		self.LifeTime = math.Rand(1.5,3)
		self.DieTime = CurTime() + self.LifeTime

		self.Splash = {
			Pos = traceWater.HitPos,
			Mat = Material("effects/splashwake1"),
			RandomAng = math.random(0,360),
		}

		local Pos = traceWater.HitPos

		local emitter = Ent:GetParticleEmitter()

		if emitter and emitter.Add then
			local particle = emitter:Add( "effects/splash4", Pos + VectorRand(-10,10) - Vector(0,0,20) )
			if particle then
				particle:SetVelocity( Vector(0,0,250) )
				particle:SetDieTime( 0.8 )
				particle:SetAirResistance( 60 ) 
				particle:SetStartAlpha( 255 )
				particle:SetEndAlpha( 0 )
				particle:SetStartSize( 50 )
				particle:SetEndSize( 100 )
				particle:SetRoll( math.Rand(-1,1) * 100 )
				particle:SetColor( 255,255,255 )
				particle:SetGravity( Vector( 0, 0, -600 ) )
				particle:SetCollide( false )
			end
		end

		return
	end

	self.DieTime = CurTime()

	if not trace.Hit then return end

	local Pos = trace.HitPos
	local Dir = Ent:GetForward()

	local emitter = Ent:GetParticleEmitter()

	local VecCol = render.GetLightColor( Pos + Vector(0,0,10) ) * 0.5 + Vector(0.3,0.25,0.15)

	if emitter and emitter.Add then
		for i = 1, 3 do
			local particle = emitter:Add( MatDebris[math.random(1,#MatDebris)], Pos + VectorRand(-10,10) )
			if particle then
				particle:SetVelocity( Vector(0,0,150) - Dir * 150 )
				particle:SetDieTime( 0.2 )
				particle:SetAirResistance( 60 ) 
				particle:SetStartAlpha( 255 )
				particle:SetEndAlpha( 255 )
				particle:SetStartSize( 15 )
				particle:SetEndSize( 50 )
				particle:SetRoll( math.Rand(-1,1) * 100 )
				particle:SetColor( VecCol.x * 130,VecCol.y * 100,VecCol.z * 60 )
				particle:SetGravity( Vector( 0, 0, -600 ) )
				particle:SetCollide( false )
			end
		end

		local Right = Ent:GetRight() 
		Right.z = 0
		Right:Normalize()

		for i = -1,1,2 do
			local particle = emitter:Add( Materials[math.random(1,#Materials)], Pos + Vector(0,0,10)  )
			if particle then
				particle:SetVelocity( -Dir * 400 + Right * 150 * i )
				particle:SetDieTime( math.Rand(0.5,1) )
				particle:SetAirResistance( 150 ) 
				particle:SetStartAlpha( 50 )
				particle:SetStartSize( -80 )
				particle:SetEndSize( 400 )
				particle:SetColor( VecCol.x * 255,VecCol.y * 255,VecCol.z * 255 )
				particle:SetGravity( Vector( 0, 0, 100 ) )
				particle:SetCollide( false )
			end
		end
	end
end


function EFFECT:Think()
	if CurTime() > self.DieTime then
		return false
	end
	return true
end

function EFFECT:Render()
	if self.Splash and self.LifeTime then
		local Scale = (self.DieTime - self.LifeTime - CurTime()) / self.LifeTime
		local S = 200 - Scale * 600
		local Alpha = 100 + 100 * Scale

		cam.Start3D2D( self.Splash.Pos + Vector(0,0,1), Angle(0,0,0), 1 )
			surface.SetMaterial( self.Splash.Mat )
			surface.SetDrawColor( 255, 255, 255 , Alpha )
			surface.DrawTexturedRectRotated( 0, 0, S , S, self.Splash.RandomAng )
		cam.End3D2D()
	end
end