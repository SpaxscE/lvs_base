EFFECT.MatBeam = Material( "effects/lvs_base/spark" )
EFFECT.MatSprite = Material( "sprites/light_glow02_add" )
EFFECT.MatSmoke = {
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
	local Dir = data:GetNormal()
	local Ent = data:GetEntity()
	local Vel = Dir * 10

	if IsValid( Ent ) then
		Vel = Ent:GetVelocity()
	end

	local emitter = ParticleEmitter( Pos, false )

	if not IsValid( emitter ) then return end

	for i = 0, 12 do
		local particle = emitter:Add( "effects/muzzleflash2", Pos + Dir * i * 0.7 * math.random(1,2) * 0.5 )
		local Size = 1

		if not particle then continue end

		particle:SetVelocity( Dir * 800 + Vel )
		particle:SetDieTime( 0.05 )
		particle:SetStartAlpha( 255 * Size )
		particle:SetStartSize( math.max( math.random(10,24) - i * 0.5,0.1 ) * Size )
		particle:SetEndSize( 0 )
		particle:SetRoll( math.Rand( -1, 1 ) )
		particle:SetColor( 255, 255, 255 )
		particle:SetCollide( false )
	end

	local VecCol = (render.GetLightColor( Pos ) * 0.8 + Vector(0.2,0.2,0.2)) * 255
	for i = 0,10 do
		local particle = emitter:Add( self.MatSmoke[math.random(1,#self.MatSmoke)], Pos )

		if not particle then continue end

		particle:SetVelocity( Dir * 700 + VectorRand() * 200 )
		particle:SetDieTime( math.Rand(2,3) )
		particle:SetAirResistance( 250 ) 
		particle:SetStartAlpha( 50 )
		particle:SetStartSize( 5 )
		particle:SetEndSize( 120 )
		particle:SetRollDelta( math.Rand(-1,1) )
		particle:SetColor( math.min( VecCol.r, 255 ), math.min( VecCol.g, 255 ), math.min( VecCol.b, 255 ) )
		particle:SetGravity( Vector(0,0,100) )
		particle:SetCollide( false )
	end

	local trace = util.TraceLine( {
		start = Pos,
		endpos = Pos - Vector(0,0,500),
		mask = MASK_SOLID_BRUSHONLY,
	} )

	if not trace.Hit then return end

	local VecCol = (render.GetLightColor( trace.HitPos + trace.HitNormal ) * 0.8 + Vector(0.17,0.15,0.1)) * 255
	for i = 1,24 do
		local particle = emitter:Add( self.MatSmoke[math.random(1,#self.MatSmoke)], trace.HitPos )
		
		if not particle then continue end

		local ang = i * 15
		local X = math.cos( math.rad(ang) )
		local Y = math.sin( math.rad(ang) )

		particle:SetVelocity( Vector(X,Y,0) * 3000 )
		particle:SetDieTime( math.Rand(0.5,1) )
		particle:SetAirResistance( 500 ) 
		particle:SetStartAlpha( 100 )
		particle:SetStartSize( 50 )
		particle:SetEndSize( 240 )
		particle:SetRollDelta( math.Rand(-1,1) )
		particle:SetColor( math.min( VecCol.r, 255 ), math.min( VecCol.g, 255 ), math.min( VecCol.b, 255 ) )
		particle:SetGravity( Vector(0,0,150) + Dir * 2000 )
		particle:SetCollide( false )
	end

	emitter:Finish()

	local ply = LocalPlayer()

	if not IsValid( ply ) then return end

	local ViewEnt = ply:GetViewEntity()

	if not IsValid( ViewEnt ) then return end

	local Intensity = 16
	local Ratio = math.min( 250 / (ViewEnt:GetPos() - trace.HitPos):Length(), 1 )

	if Ratio < 0 then return end

	util.ScreenShake( trace.HitPos, Intensity * Ratio, 0.1, 0.5, 250 )
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
