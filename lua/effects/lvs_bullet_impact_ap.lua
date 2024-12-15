
EFFECT.DustMat = {
	"effects/lvs_base/particle_debris_01",
	"effects/lvs_base/particle_debris_02",
}

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

EFFECT.SparkSurface = {
	["chainlink"] = true,
	["canister"] = true,
	["metal_barrel"] = true,
	["metalvehicle"] = true,
	["metal"] = true,
	["metalgrate"] = true,
	["rubbertire"] = true,
}

EFFECT.DustSurface = {
	["sand"] = true,
	["dirt"] = true,
	["grass"] = true,
	["antlionsand"] = true,
}

EFFECT.SmokeSurface = {
	["concrete"] = true,
	["tile"] = true,
	["plaster"] = true,
	["boulder"] = true,
	["plastic"] = true,
	["default"] = true,
	["glass"] = true,
	["brick"] = true,
}

function EFFECT:Init( data )
	local pos = data:GetOrigin()

	local bullet_dir = data:GetStart()
	local dir = data:GetNormal()
	local magnitude = data:GetMagnitude()

	local ent = data:GetEntity()
	local surface = data:GetSurfaceProp()
	local surfaceName = util.GetSurfacePropName( surface )

	local emitter = ParticleEmitter( pos, false )

	local VecCol = (render.GetLightColor( pos ) * 0.8 + Vector(0.17,0.15,0.1)) * 255

	local DieTime = math.Rand(0.8,1.4)

	for i = 1, 60 * magnitude do
		local spark = emitter:Add("effects/spark", pos + dir * 8)

		spark:SetStartAlpha( 255 )
		spark:SetEndAlpha( 0 )
		spark:SetCollide( true )
		spark:SetBounce( math.Rand(0,1) )
		spark:SetColor( 255, 255, 255 )
		spark:SetGravity( Vector(0,0,-600) )
		spark:SetEndLength(0)

		local size = math.Rand(4, 6) * magnitude
		spark:SetEndSize( size )
		spark:SetStartSize( size )

		spark:SetStartLength( math.Rand(20,40) * magnitude )
		spark:SetDieTime( math.Rand(0.4, 1.2) )
		spark:SetVelocity( (dir * math.Rand(300, 600) + VectorRand() * 300) * magnitude )
	end

	local flash = emitter:Add( "effects/yellowflare",pos )
	flash:SetPos( pos + dir * 15 )
	flash:SetStartAlpha( 200 )
	flash:SetEndAlpha( 0 )
	flash:SetColor( 255,255,255 )
	flash:SetEndSize( 0 )
	flash:SetDieTime( 0.075 )
	flash:SetStartSize( 300 * magnitude ^ 2 )
	
	if self.SparkSurface[ surfaceName ] then
		if IsValid( ent ) and ent.LVS then
			if (90 - math.deg( math.acos( math.Clamp( -dir:Dot( bullet_dir ) ,-1,1) ) )) > 10 then
				local effectdata = EffectData()
				effectdata:SetOrigin( pos )
				util.Effect( "cball_explode", effectdata, true, true )

				local Ax = math.acos( math.Clamp( dir:Dot( bullet_dir ) ,-1,1) )
				local Fx = math.cos( Ax )

				local effectdata = EffectData()
					effectdata:SetOrigin( pos )
					effectdata:SetNormal( (bullet_dir - dir * Fx * 2):GetNormalized() * 0.75 )
				util.Effect( "manhacksparks", effectdata, true, true )

				local effectdata = EffectData()
					effectdata:SetOrigin( pos )
					effectdata:SetNormal( -bullet_dir * 0.75 )
				util.Effect( "manhacksparks", effectdata, true, true )
			end
		else
			local effectdata = EffectData()
			effectdata:SetOrigin( pos )
			util.Effect( "cball_explode", effectdata, true, true )

			local effectdata = EffectData()
				effectdata:SetOrigin( pos )
				effectdata:SetNormal( dir )
			util.Effect( "manhacksparks", effectdata, true, true )

			local effectdata = EffectData()
				effectdata:SetOrigin( pos )
				effectdata:SetNormal( -bullet_dir )
			util.Effect( "manhacksparks", effectdata, true, true )
		end
	end

	if self.SmokeSurface[ surfaceName ] then
		for i = 1, 24 do
			local particle = emitter:Add( self.SmokeMat[ math.random(1, #self.SmokeMat ) ], pos )

			if not particle then continue end

			particle:SetStartAlpha( math.Rand(33, 66) )
			particle:SetEndAlpha( 0 )
			particle:SetColor( math.min( VecCol.r, 255 ), math.min( VecCol.g, 255 ), math.min( VecCol.b, 255 ) )
			particle:SetGravity( Vector(0,0,-math.Rand(33, 66)) )
			particle:SetRollDelta( math.random(0, 0.5 * math.pi) )
			particle:SetAirResistance( 175 )

			particle:SetStartSize( 15 )
			particle:SetDieTime( math.Rand(0.5, 1) )
			particle:SetEndSize( math.Rand(45, 90) )
			particle:SetVelocity( dir * math.Rand(40, 200) + VectorRand() * 150)
		end

		for i = 1,15 do
			local particle = emitter:Add("effects/fleck_cement" .. math.random(1, 2), pos + dir * 8)

			if not particle then continue end

			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetCollide( true )
			particle:SetBounce( math.Rand(0,1) )
			particle:SetColor( math.min( VecCol.r, 255 ), math.min( VecCol.g, 255 ), math.min( VecCol.b, 255 ) )
			particle:SetGravity(Vector(0,0,-600))
			particle:SetRollDelta( math.random(0, 0.5*math.pi) )

			particle:SetEndSize( 2 )
			particle:SetStartSize( 2 )

			particle:SetDieTime( math.Rand(1, 2) )
			particle:SetVelocity( dir * math.Rand(40, 200) + VectorRand() * 500 )
		end
	end

	if not self.DustSurface[ surfaceName ] then return end

	for i = 1, 10 do
		for i = 1, 15 do
			local particle = emitter:Add( self.SmokeMat[ math.random(1, #self.SmokeMat ) ], pos )

			if not particle then continue end

			particle:SetStartAlpha( math.Rand(40, 80) )
			particle:SetEndAlpha(0)
			particle:SetColor( math.min( VecCol.r, 255 ), math.min( VecCol.g, 255 ), math.min( VecCol.b, 255 ) )
			particle:SetGravity( Vector(0,0,-math.Rand(75, 150)) )
			particle:SetRollDelta( math.random(0, 0.5*math.pi) )
			particle:SetAirResistance( 175 )

			particle:SetStartSize( 5 )
			particle:SetDieTime( math.Rand(0.5, 1) )
			particle:SetEndSize( math.Rand(15, 30) )
			particle:SetVelocity( (dir * math.Rand(80, 400) + VectorRand() * 100) * 1.5 )
		end
    
		for n = 0,6 do
			local particle = emitter:Add( self.DustMat[ math.random(1,#self.DustMat) ] , pos )

			if not particle then continue end

			particle:SetVelocity( (dir * 50 * i + VectorRand() * 50) )
			particle:SetDieTime( (i / 8) * DieTime )
			particle:SetAirResistance( 10 ) 
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( 10 * i )
			particle:SetRollDelta( math.Rand(-1,1) )
			particle:SetColor( math.min( VecCol.r, 255 ), math.min( VecCol.g, 255 ), math.min( VecCol.b, 255 ) )
			particle:SetGravity( Vector(0,0,-600) )
			particle:SetCollide( false )
		end
	end

	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
