
local GlowMat = Material( "sprites/light_glow02_add" )
local FireMat = Material( "effects/fire_cloud1" )
local HeatMat = Material( "sprites/heatwave" )
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

function EFFECT:Init( data )
	self.Entity = data:GetEntity()

	if not IsValid( self.Entity ) then return end

	local Pos = self:GetPos()

	self._Particles = {}
	self.Emitter = ParticleEmitter( Pos, false )
	self.Emitter3D = ParticleEmitter( Pos, true )
	self._LastParticlePos = vector_origin
end

function EFFECT:AddParticle( particle )
	table.insert( self._Particles, particle )

	for id, particle in pairs( self._Particles ) do
		if not particle or particle:GetLifeTime() > particle:GetDieTime() then
			self._Particles[ id ] = nil
		end
	end
end

function EFFECT:GetPosition()
	local ent = self.Entity

	if not IsValid( ent ) then return vector_origin, vector_origin end

	local Pos = ent:GetPos()
	local Dir = ent:GetForward()

	local Target = ent:GetTarget()
	local Attachment = ent:GetTargetAttachment()

	if IsValid( Target ) and Attachment ~= "" then
		local ID = Target:LookupAttachment( Attachment )
		local Muzzle = Target:GetAttachment( ID )

		if not Muzzle then return vector_origin, vector_origin end

		Pos = Muzzle.Pos
		Dir = Muzzle.Ang:Forward()
	end

	return Pos, Dir
end

function EFFECT:Think()
	local ent = self.Entity
	local emitter = self.Emitter
	local emitter3D = self.Emitter3D

	if not IsValid( emitter ) or not IsValid( emitter3D ) then return true end

	local T = CurTime()

	if IsValid( ent ) and not self._KillSwitch then
		if not ent:GetActive() then
			self._KillSwitch = true
			self._KillSwitchTime = CurTime() + 2
		end

		if (self.nextDFX or 0) < T then
			self.nextDFX = T + 0.01

			local Pos, Dir = self:GetPosition()

			self:MakeFlameStream( emitter, emitter3D, Pos, Dir )
			self:MakeFlameMuzzle( emitter, emitter3D, Pos, Dir )
			self:SetRenderBoundsWS( Pos, Pos + Dir * 50000 )
		end

		return true
	end

	if self._KillSwitch and IsValid( emitter ) and IsValid( emitter3D ) then
		if self._KillSwitchTime > T then
			return true
		end
	end

	if emitter then
		emitter:Finish()
	end

	if emitter3D then
		emitter3D:Finish()
	end

	return false
end

function EFFECT:MakeFlameImpact( Pos, Dir, Size )
	local emitter3D = self.Emitter3D

	if not IsValid( emitter3D ) then return end

	local hitparticle = emitter3D:Add( "effects/lvs_base/flamelet"..math.random(1,5), Pos + Dir )
	if hitparticle then
		hitparticle:SetStartSize( Size * 0.25 )
		hitparticle:SetEndSize( Size )
		hitparticle:SetDieTime( math.Rand(0.5,1) )
		hitparticle:SetStartAlpha( 255 )
		hitparticle:SetEndAlpha( 0 )
		hitparticle:SetRollDelta( math.Rand(-2,2) )
		hitparticle:SetAngles( Dir:Angle() )
	end
end

function EFFECT:MakeFlameImpactWater( Pos, Dir, Size )
	local emitter3D = self.Emitter3D
	local emitter = self.Emitter

	if not IsValid( emitter ) or not IsValid( emitter3D ) then return end

	local sparticle = emitter:Add( Materials[ math.random(1, #Materials ) ], Pos )
	if sparticle then
		sparticle:SetVelocity( Vector(0,0,400) + VectorRand() * 100 )
		sparticle:SetDieTime( Size * 0.01 )
		sparticle:SetAirResistance( 500 ) 
		sparticle:SetStartAlpha( 40 )
		sparticle:SetStartSize( 0 )
		sparticle:SetEndSize( Size * 4 )
		sparticle:SetRoll( math.Rand(-3,3)  )
		sparticle:SetRollDelta( math.Rand(-1,1) )
		sparticle:SetColor( 255, 255, 255 )
		sparticle:SetGravity( Vector( 0, 0, 800 ) )
		sparticle:SetCollide( false )
	end

	local hitparticle = emitter3D:Add( "effects/lvs_base/flamelet"..math.random(1,5), Pos + Dir )
	if hitparticle then
		hitparticle:SetStartSize( Size * 0.25 )
		hitparticle:SetEndSize( Size )
		hitparticle:SetDieTime( math.Rand(0.5,1) )
		hitparticle:SetStartAlpha( 255 )
		hitparticle:SetEndAlpha( 0 )
		hitparticle:SetRollDelta( math.Rand(-2,2) )
		hitparticle:SetAngles( Dir:Angle() )
	end
end

function EFFECT:MakeFlameBurst( Pos, Vel, Size )
	local emitter = self.Emitter

	if not IsValid( emitter ) then return end

	local fparticle = emitter:Add( "effects/lvs_base/fire", Pos )
	if fparticle then
		fparticle:SetVelocity( VectorRand() * 15 + Vector( 0, 0, 200 ) + Vel )
		fparticle:SetDieTime( math.Rand(0.6,0.8) )
		fparticle:SetAirResistance( 0 ) 

		fparticle:SetStartAlpha( 255 )
		fparticle:SetEndAlpha( 255 )

		fparticle:SetStartSize( 40 )
		fparticle:SetEndSize( 0 )

		fparticle:SetRollDelta( math.Rand(-2,2) )
		fparticle:SetColor( 255,255,255 )
		fparticle:SetGravity( Vector( 0, 0, 0 ) )
		fparticle:SetCollide( false )

		self:AddParticle( fparticle )
	end

	local fparticle = emitter:Add( "effects/lvs_base/flamelet"..math.random(1,5), Pos )
	if fparticle then
		fparticle:SetVelocity( VectorRand() * 25 + Vel )
		fparticle:SetDieTime( math.Rand(0.4,0.8) )
		fparticle:SetStartAlpha( 150 )
		fparticle:SetEndAlpha( 0 )
		fparticle:SetStartSize( 0 )
		fparticle:SetEndSize( math.Rand(60,120) )
		fparticle:SetColor( 255, 255, 255 )
		fparticle:SetGravity( Vector(0,0,100) )
		fparticle:SetRollDelta( math.Rand(-2,2) )
		fparticle:SetAirResistance( 0 )
	end

	for i = 0, 6 do
		local eparticle = emitter:Add( "effects/fire_embers"..math.random(1,2), Pos )

		if not eparticle then continue end

		eparticle:SetVelocity( VectorRand() * 400 + Vel )
		eparticle:SetDieTime( math.Rand(0.4,0.6) )
		eparticle:SetStartAlpha( 255 )
		eparticle:SetEndAlpha( 0 )
		eparticle:SetStartSize( 20 )
		eparticle:SetEndSize( 0 )
		eparticle:SetColor( 255, 255, 255 )
		eparticle:SetGravity( Vector(0,0,600) )
		eparticle:SetRollDelta( math.Rand(-8,8) )
		eparticle:SetAirResistance( 300 )
	end

	local Dist = (self._LastParticlePos - Pos):Length()
	self._LastParticlePos = Pos

	if Dist < 250 then
		if math.random(1,8) ~= 1 then return end
	end

	local sparticle = emitter:Add( Materials[ math.random(1, #Materials ) ], Pos )
	if sparticle then
		sparticle:SetVelocity( Vector(0,0,400) + Vel )
		sparticle:SetDieTime( math.Rand(2,4)  * Size )
		sparticle:SetAirResistance( 500 ) 
		sparticle:SetStartAlpha( 125 )
		sparticle:SetStartSize( 0 )
		sparticle:SetEndSize( 200 * Size )
		sparticle:SetRoll( math.Rand(-3,3)  )
		sparticle:SetRollDelta( math.Rand(-1,1) )
		sparticle:SetColor( 0, 0, 0 )
		sparticle:SetGravity( Vector( 0, 0, 800 ) )
		sparticle:SetCollide( false )
	end
end

function EFFECT:MakeFlameMuzzle( emitter, emitter3D, pos, dir )
	local particle = emitter:Add( "effects/lvs_base/flamelet"..math.random(1,5), pos )

	if not particle then return end

	local ent = self.Entity

	if not IsValid( ent ) then return end

	local velDesired = ent:GetFlameVelocity()
	local vel = dir * velDesired

	local DieTime = 0.075

	particle:SetVelocity( VectorRand() * 30 + vel )
	particle:SetDieTime( DieTime )
	particle:SetAirResistance( 0 ) 
	particle:SetStartAlpha( 255 )
	particle:SetEndLength( velDesired * 0.1 )
	particle:SetStartLength( velDesired * 0.04 )
	particle:SetStartSize( 10 )
	particle:SetEndSize( 0 )
	particle:SetRollDelta( math.Rand(-5,5) )
	particle:SetColor( 50, 50, 255 )
	particle:SetGravity( Vector( 0, 0, -600 ) )
	particle:SetCollide( true )
end

function EFFECT:MakeFlameStream( emitter, emitter3D, pos, dir )
	local particle = emitter:Add( "effects/lvs_base/flamelet"..math.random(1,5), pos )

	if not particle then return end

	local ent = self.Entity

	if not IsValid( ent ) then return end

	local velDesired = ent:GetFlameVelocity()
	local vel = dir * velDesired

	local DieTime = math.Rand( ent:GetFlameLifeTime() * 0.5, ent:GetFlameLifeTime() )

	particle:SetVelocity( VectorRand() * 30 + vel )
	particle:SetDieTime( DieTime )
	particle:SetAirResistance( 0 ) 
	particle:SetStartAlpha( 255 )
	particle:SetEndLength( velDesired * 0.1 )
	particle:SetStartLength( velDesired * 0.04 )
	particle:SetStartSize( 2 )
	particle:SetEndSize( ent:GetFlameSize() )
	particle:SetRollDelta( math.Rand(-5,5) )
	particle:SetColor( 255, 255, 255 )
	particle:SetGravity( Vector( 0, 0, -600 ) )
	particle:SetCollide( true )
	local Delay = math.Rand( DieTime * 0.5, DieTime )
	local Size = (Delay / DieTime) ^ 2
	timer.Simple( Delay, function()
		if not IsValid( self ) or not particle or particle.NoSmokeSpawn then return end

		local ParticlePos = particle:GetPos()

		self:MakeFlameBurst( ParticlePos, vel * 0.2, Size )
	end)
	particle:SetNextThink( CurTime() )
	particle:SetThinkFunction( function( p )
		if not IsValid( self ) then return end

		p:SetNextThink( CurTime() + 0.05 )

		local pos = p:GetPos()
		local vel = p:GetVelocity()
		local dir = vel:GetNormalized()
		local speed = vel:Length() * 0.06

		local traceData = {
			start = pos,
			endpos = pos + dir * speed,
			filter =  self.Entity,
		}
		local trace = util.TraceLine( traceData )

		traceData.mask = MASK_WATER
		local traceWater = util.TraceLine( traceData )

		if traceWater.Hit and not trace.Hit then
			p:SetDieTime( 0 )
			p.NoSmokeSpawn = true
			local RandomSize = math.Rand(60,80)
			self:MakeFlameImpactWater( traceWater.HitPos, traceWater.HitNormal, RandomSize )
		end

		if trace.HitWorld or not trace.Hit then return end

		p:SetDieTime( 0 )
		p.NoSmokeSpawn = true
		local RandomSize = math.Rand(40,60)
		self:MakeFlameImpact( trace.HitPos, trace.HitNormal, RandomSize )
		self:MakeFlameBurst( trace.HitPos, vector_origin, RandomSize / 60 )
	end )
	particle:SetCollideCallback( function( p, hitpos, hitnormal )
		if p.NoSmokeSpawn then return end

		p:SetDieTime( 0 )
		p.NoSmokeSpawn = true

		if not IsValid( emitter3D ) then return end

		local RandomSize = math.Rand(40,60)

		self:MakeFlameImpact( hitpos, hitnormal, RandomSize )
		self:MakeFlameBurst( hitpos + hitnormal, vector_origin, RandomSize / 60 )
	end )

	particle.NoFade = true
	self:AddParticle( particle )

	local particle = emitter:Add( "effects/lvs_base/fire", pos )
	if particle then
		particle:SetVelocity( VectorRand() * 4 + dir * math.Rand(velDesired * 0.8,velDesired * 1.6) )
		particle:SetDieTime( math.Rand(0.75,1.5) )
		particle:SetAirResistance( 40 ) 
		particle:SetStartAlpha( 255 )
		particle:SetStartSize( 4 )
		particle:SetEndSize( 0 )
		particle:SetRoll( math.Rand(-3,3) )
		particle:SetRollDelta( math.Rand(-6,6) )
		particle:SetColor( 255, 255, 255 )
		particle:SetGravity( VectorRand() * 400 - Vector(0,0,600) )
		particle:SetCollide( true )
	end
end

function EFFECT:Render()
	local ent = self.Entity

	if not IsValid( ent ) then return end

	if ent:GetActive() and not self._KillSwitch then
		local Scale = 1
		local Pos, Dir = self:GetPosition()

		local scroll = -CurTime() * 5

		local Up = Dir + VectorRand() * 0.08

		render.UpdateRefractTexture()
		render.SetMaterial( HeatMat )
		render.StartBeam( 3 )
			render.AddBeam( Pos, 8 * Scale, scroll, Color( 0, 0, 255, 200 ) )
			render.AddBeam( Pos + Up * 32 * Scale, 32 * Scale, scroll + 2, color_white )
			render.AddBeam( Pos + Up * 128 * Scale, 32 * Scale, scroll + 5, Color( 0, 0, 0, 0 ) )
		render.EndBeam()
	end

	if not istable( self._Particles ) then return end

	for id, particle in pairs( self._Particles ) do
		if not particle then continue end

		local S = particle:GetLifeTime() / particle:GetDieTime()
		local A = ((1 - S) ^ 2) * 0.5
		local Size = particle:GetStartSize() * A * 8

		if particle.NoFade then
			Size = particle:GetEndSize() * S * 8
		end

		render.SetMaterial( GlowMat )
		render.DrawSprite( particle:GetPos(), Size, Size, Color( 255 * A, 150 * A, 75 * A, 255 * A) )
	end
end
