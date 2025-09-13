
EFFECT.BeamMaterial = Material( "particle/smokesprites_0003" )
EFFECT.SmokeMaterials = {
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
	self.Pos = data:GetOrigin()
	self.Radius = data:GetMagnitude()
	self.SpawnTime = CurTime()

	self:SetAngles( data:GetNormal():Angle() )

	self:Debris()
	self:Explosion()
end


function EFFECT:Debris()
	local emitter = ParticleEmitter( self.Pos, false )

	if not IsValid( emitter ) then return end

	for i = 0,30 do
		local particle = emitter:Add( "effects/fleck_tile"..math.random(1,2), self.Pos )

		local vel = (self:GetRight() * math.Rand(-1,1) + self:GetForward() * math.Rand(-1,1) + self:GetUp() * math.Rand(-0.25,0.25)):GetNormalized() * self.Radius * 5

		if particle then
			particle:SetVelocity( vel )
			particle:SetDieTime( 0.6 )
			particle:SetAirResistance( 25 ) 
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( 5 )
			particle:SetRoll( math.Rand(-1,1) )
			particle:SetRollDelta( math.Rand(-1,1) * 10 )
			particle:SetColor( 0,0,0 )
			particle:SetGravity( Vector( 0, 0, -600 ) )
			particle:SetCollide( true )
			particle:SetBounce( 0.3 )
		end
	end
	
	emitter:Finish()
end


function EFFECT:Explosion()
	local emitter = ParticleEmitter( self.Pos, false )
	
	if not IsValid( emitter ) then return end

	local scale = 0.1 + self.Radius / 1000

	for i = 0,10 do
		local particle = emitter:Add( self.SmokeMaterials[ math.random(1, #self.SmokeMaterials ) ], self.Pos )

		if not particle then continue end

		particle:SetVelocity( VectorRand() * 1500 * scale )
		particle:SetDieTime( math.Rand(0.75,1.5) * scale )
		particle:SetAirResistance( math.Rand(200,600) ) 
		particle:SetStartAlpha( 255 )
		particle:SetStartSize( math.Rand(60,120) * scale )
		particle:SetEndSize( math.Rand(220,320) * scale )
		particle:SetRoll( math.Rand(-1,1) )
		particle:SetColor( 40,40,40 )
		particle:SetGravity( Vector( 0, 0, 100 ) )
		particle:SetCollide( false )
	end

	emitter:Finish()
end

function EFFECT:Think()
	if (self.SpawnTime + 0.15) < CurTime() then return false end

	return true
end

function EFFECT:Render()
	if not self.SpawnTime then return end

	local pos = self:GetPos()

	render.SetMaterial( self.BeamMaterial )

	local segmentdist = 360 / 30
	local overlap = 10
	local Mul = math.Clamp(self.SpawnTime + 0.15 - CurTime(),0,0.15) / 0.15

	do
		local Width = self.Radius / 2
		local Alpha = Mul * 255
		local radius = self.Radius * 0.5 * ((1 - Mul) ^ 5)
		local AngOffset = Mul * 360

		if Alpha > 0 then
			for a = segmentdist, 360, segmentdist do
				local Ang = a + AngOffset
				local StartPos = self:LocalToWorld( Vector( math.cos( math.rad( -Ang - overlap ) ) * radius,  -math.sin( math.rad( -Ang - overlap ) ) * radius, 0 ) )
				local EndPos = self:LocalToWorld( Vector( math.cos( math.rad( -Ang + overlap + segmentdist ) ) * radius, -math.sin( math.rad( -Ang + overlap + segmentdist ) ) * radius, 0 ) )

				render.DrawBeam( StartPos, EndPos, Width, 0, 1, Color( 255, 255, 255, Alpha ) )
			end
		end
	end

	do
		local Width = self.Radius / 2
		local Alpha = Mul * 255
		local radius = self.Radius * ((1 - Mul) ^ 5)
		local AngOffset = Mul * 360

		if Alpha > 0 then
			for a = segmentdist, 360, segmentdist do
				local Ang = a + AngOffset
				local StartPos = self:LocalToWorld( Vector( math.cos( math.rad( -Ang - overlap ) ) * radius,  -math.sin( math.rad( -Ang - overlap ) ) * radius, 0 ) )
				local EndPos = self:LocalToWorld( Vector( math.cos( math.rad( -Ang + overlap + segmentdist ) ) * radius, -math.sin( math.rad( -Ang + overlap + segmentdist ) ) * radius, 0 ) )

				render.DrawBeam( StartPos, EndPos, Width, 0, 1, Color( 255, 255, 255, Alpha ) )
			end
		end
	end
end
