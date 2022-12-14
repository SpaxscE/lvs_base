--DO NOT EDIT OR REUPLOAD THIS FILE

function EFFECT:Init( data )
	self.Pos = data:GetOrigin()
	self.Dir = data:GetNormal()
	
	self:Spark( self.Pos )
end

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

function EFFECT:Spark( pos )
	local emitter = ParticleEmitter( pos, false )
	
	for i = 0, 10 do
		local particle = emitter:Add( "sprites/rico1", pos )
		
		local vel = VectorRand() * 400 - self.Dir  * 160
		
		if particle then
			particle:SetVelocity( vel )
			particle:SetAngles( vel:Angle() + Angle(0,90,0) )
			particle:SetDieTime( math.Rand(0.2,0.4) )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( math.Rand(6,12) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand(-100,100) )
			particle:SetRollDelta( math.Rand(-100,100) )
			particle:SetColor( 255,255,255 )
			particle:SetGravity( Vector(0,0,-1500) )

			particle:SetAirResistance( 0 )
			
			particle:SetCollide( true )
			particle:SetBounce( 1 )
		end
	end
	
	for i = 0,20 do
		local particle = emitter:Add( Materials[math.random(1,table.Count( Materials ))],pos )
		
		local rCol = 255
		
		if particle then
			particle:SetVelocity( VectorRand() * math.Rand(100,200) )
			particle:SetDieTime( math.Rand(0.05,0.2) )
			particle:SetAirResistance( math.Rand(50,100) ) 
			particle:SetStartAlpha( 20 )
			particle:SetStartSize( 4 )
			particle:SetEndSize( math.Rand(10,20) )
			particle:SetRoll( math.Rand(-1,1) )
			particle:SetColor( rCol,rCol,rCol )
			particle:SetGravity( VectorRand() * 200 + Vector(0,0,200) )
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
