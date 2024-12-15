
EFFECT.GlowMat = Material( "sprites/light_glow02_add" )
EFFECT.SmokeMat = {
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

EFFECT.DustMat = {
	"effects/lvs_base/particle_debris_01",
	"effects/lvs_base/particle_debris_02",
}

EFFECT.DecalMat = Material( util.DecalMaterial( "Scorch" ) )

function EFFECT:Init( data )
	self.Dir = Vector(0,0,1)
	self.Pos = data:GetOrigin()
	self.LifeTime = 0.35
	self.DieTime = CurTime() + self.LifeTime

	local scale = 3

	local emitter = ParticleEmitter( self.Pos, false )

	local VecCol = (render.GetLightColor( self.Pos + self.Dir ) * 0.5 + Vector(0.1,0.09,0.075)) * 255

	local DieTime = math.Rand(0.8,1.6)

	local traceSky = util.TraceLine( {
		start = self.Pos,
		endpos = self.Pos + Vector(0,0,50000),
		filter = self,
	} )

	local traceWater = util.TraceLine( {
		start = traceSky.HitPos,
		endpos = self.Pos - Vector(0,0,100),
		filter = self,
		mask = MASK_WATER,
	} )

	if traceWater.Hit then
		local effectdata = EffectData()
		effectdata:SetOrigin( traceWater.HitPos )
		effectdata:SetScale( 100 )
		effectdata:SetFlags( 2 )
		util.Effect( "WaterSplash", effectdata, true, true )
	else
		local trace = util.TraceLine( {
			start = self.Pos + Vector(0,0,100),
			endpos = self.Pos - Vector(0,0,100),
		} )

		if trace.Hit and not trace.HitNonWorld then
			for i = 1, 3 do
				local StartPos = trace.HitPos + Vector(math.random(-200,200),math.random(-200,200),0)
				local decalTrace = util.TraceLine( {
					start = StartPos + Vector(0,0,100),
					endpos = StartPos - Vector(0,0,100),
				} )

				util.DecalEx( self.DecalMat, trace.Entity, decalTrace.HitPos + decalTrace.HitNormal, decalTrace.HitNormal, Color(255,255,255,255), math.Rand(3,6), math.Rand(3,6) )
			end
		end
	end

	local Pos = self.Pos
	local Dist = (traceWater.HitPos - Pos):Length()
	local ply = LocalPlayer():GetViewEntity()

	if not IsValid( ply ) then return end

	local delay = (Pos - ply:GetPos()):Length() / 13503.9

	if traceWater.Hit and Dist > 150 then
		timer.Simple( delay, function()
			local effectdata = EffectData()
			effectdata:SetOrigin( Pos )
			util.Effect( "WaterSurfaceExplosion", effectdata, true, true )
		end )

		if Dist > 300 then return end
	else
		timer.Simple( delay, function()
			sound.Play( "LVS.BOMB_EXPLOSION", Pos )
			sound.Play( "LVS.BOMB_EXPLOSION_DYNAMIC", Pos )
		end )
	end

	for i = 1, 10 do
		for n = 0,6 do
			local particle = emitter:Add( self.DustMat[ math.random(1,#self.DustMat) ], self.Pos )

			if not particle then continue end

			particle:SetVelocity( (self.Dir * 50 * i + VectorRand() * 25) * scale )
			particle:SetDieTime( (i / 8) * DieTime )
			particle:SetAirResistance( 10 ) 
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( 10 * scale )
			particle:SetEndSize( 20 * i * scale )
			particle:SetRollDelta( math.Rand(-1,1) )
			particle:SetColor( VecCol.r, VecCol.g, VecCol.b )
			particle:SetGravity( Vector(0,0,-600) * scale )
			particle:SetCollide( false )
		end
	end

	for i = 1, 10 do
		local particle = emitter:Add( self.SmokeMat[ math.random(1,#self.SmokeMat) ], self.Pos )

		if not particle then continue end

		particle:SetVelocity( (self.Dir * 50 * i + VectorRand() * 40) * scale )
		particle:SetDieTime( (i / 8) * DieTime )
		particle:SetAirResistance( 10 ) 
		particle:SetStartAlpha( 255 )
		particle:SetStartSize( 10 * scale )
		particle:SetEndSize( 20 * i * scale )
		particle:SetRollDelta( math.Rand(-1,1) )
		particle:SetColor( VecCol.r, VecCol.g, VecCol.b )
		particle:SetGravity( Vector(0,0,-600) * scale )
		particle:SetCollide( false )
	end

	for i = 1,24 do
		local particle = emitter:Add( self.SmokeMat[ math.random(1,#self.SmokeMat) ] , self.Pos )
		
		if particle then
			local ang = i * 15
			local X = math.cos( math.rad(ang) )
			local Y = math.sin( math.rad(ang) )

			local Vel = Vector(X,Y,0) * math.Rand(1500,2000)

			particle:SetVelocity( Vel * scale )
			particle:SetDieTime( math.Rand(1,3) )
			particle:SetAirResistance( 600 ) 
			particle:SetStartAlpha( 100 )
			particle:SetStartSize( 40 * scale )
			particle:SetEndSize( 200 * scale )
			particle:SetRollDelta( math.Rand(-1,1) )
			particle:SetColor( VecCol.r, VecCol.g, VecCol.b )
			particle:SetGravity( Vector(0,0,60) * scale )
			particle:SetCollide( true )
		end
	end

	for i = 0, 15 do
		local particle = emitter:Add( self.SmokeMat[ math.random(1, #self.SmokeMat ) ], self.Pos )
		
		if particle then
			particle:SetVelocity( VectorRand(-1,1) * 1000 )
			particle:SetDieTime( math.Rand(2,3) )
			particle:SetAirResistance( 200 ) 
			particle:SetStartAlpha( 100 )
			particle:SetStartSize( 200 )
			particle:SetEndSize( 600 )
			particle:SetRoll( math.Rand(-1,1) )
			particle:SetRollDelta( math.Rand(-1,1) )
			particle:SetColor( VecCol.r, VecCol.g, VecCol.b )
			particle:SetGravity( Vector( 0, 0, -600 ) )
			particle:SetCollide( false )
		end
	end

	for i = 0, 15 do
		local particle = emitter:Add( "effects/lvs_base/flamelet"..math.random(1,5), self.Pos )
		
		if particle then
			particle:SetVelocity( VectorRand(-1,1) * 500 )
			particle:SetDieTime( math.Rand(0.15,0.3) )
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( 25 )
			particle:SetEndSize( math.Rand(70,100) )
			particle:SetEndAlpha( 100 )
			particle:SetRoll( math.Rand( -1, 1 ) )
			particle:SetColor( 200,150,150 )
			particle:SetCollide( false )
		end
	end

	for i = 0, 20 do
		local particle = emitter:Add( "sprites/rico1", self.Pos )
		
		local vel = VectorRand() * 800
		
		if particle then
			particle:SetVelocity( vel )
			particle:SetAngles( vel:Angle() + Angle(0,90,0) )
			particle:SetDieTime( math.Rand(0.2,0.4) )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( math.Rand(20,40) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand(-100,100) )
			particle:SetRollDelta( 0 )
			particle:SetColor( 255, 255, 255 )

			particle:SetAirResistance( 0 )
		end
	end
	
	for i = 0,60 do
		local particle = emitter:Add( "effects/fleck_tile"..math.random(1,2), self.Pos )
		local vel = VectorRand() * math.Rand(800,1600)
		vel.z = math.Rand(1000,4000)

		if particle then
			particle:SetVelocity( vel )
			particle:SetDieTime( math.random(5,15) )
			particle:SetAirResistance( 10 ) 
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( 5 )
			particle:SetRoll( math.Rand(-1,1) )
			particle:SetColor( 0,0,0 )
			particle:SetGravity( Vector( 0, 0, -2000 ) )
			particle:SetCollide( true )
			particle:SetBounce( 0.3 )
		end
	end

	emitter:Finish()
end

function EFFECT:Explosion( pos , scale )
	local emitter = ParticleEmitter( pos, false )
	
	if not IsValid( emitter ) then return end

	for i = 0, 40 do
		local particle = emitter:Add( "effects/lvs_base/flamelet"..math.random(1,5), pos )

		if particle then
			particle:SetVelocity( VectorRand() * 1500 * scale )
			particle:SetDieTime( 0.2 )
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( 20 * scale )
			particle:SetEndSize( math.Rand(180,240) * scale )
			particle:SetEndAlpha( 100 )
			particle:SetRoll( math.Rand( -1, 1 ) )
			particle:SetColor( 200,150,150 )
			particle:SetCollide( false )
		end
	end

	emitter:Finish()

	local dlight = DynamicLight( math.random(0,9999) )
	if dlight then
		dlight.pos = pos
		dlight.r = 255
		dlight.g = 180
		dlight.b = 100
		dlight.brightness = 8
		dlight.Decay = 2000
		dlight.Size = 300
		dlight.DieTime = CurTime() + 1
	end
end

function EFFECT:Think()
	if self.DieTime < CurTime() then return false end

	return true
end

function EFFECT:Render()
	local Scale = (self.DieTime - CurTime()) / self.LifeTime
	render.SetMaterial( self.GlowMat )
	render.DrawSprite( self.Pos, 2000 * Scale, 2000 * Scale, Color( 255, 200, 150, 255) )

	local Scale = (self.DieTime - self.LifeTime + 0.25 - CurTime()) / 0.25
	local InvScale = 1 - Scale
	if Scale > 0 then
		render.SetColorMaterial()
		render.DrawSphere( self.Pos, -450 * InvScale, 30,30, Color( 255, 200, 150, 150 * (Scale ^ 2) ) )
		render.DrawSphere( self.Pos, -500 * InvScale, 30,30, Color( 255, 200, 150, 100 * (Scale ^ 2) ) )
		render.DrawSphere( self.Pos, -550 * InvScale, 30,30, Color( 255, 200, 150, 25 * (Scale ^ 2) ) )
		render.DrawSphere( self.Pos, 600 * InvScale, 30,30, Color( 255, 200, 150, 25 * (Scale ^ 2) ) )
	end
end
