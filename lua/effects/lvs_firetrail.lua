
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
	self.Scale = data:GetScale()
	self.DieTime = CurTime() + data:GetMagnitude()
	self.Pos = data:GetStart()
	
	if not IsValid( self.Entity ) then return end

	self.Emitter = ParticleEmitter( self.Entity:LocalToWorld( self.Pos ), false )
end


function EFFECT:Think()
	if IsValid( self.Entity ) then
		local Pos = self.Entity:LocalToWorld( self.Pos )

		local T = CurTime()

		if (self.nextDFX or 0) < T then
			self.nextDFX = T + 0.05

			if self.Emitter then
				local particle = self.Emitter:Add( Materials[ math.random(1, #Materials ) ], Pos )

				if particle then
					particle:SetVelocity( VectorRand() * 100 * self.Scale )
					particle:SetDieTime( 3 )
					particle:SetAirResistance( 0 )
					particle:SetStartAlpha( 150 )
					particle:SetStartSize( 150 * self.Scale )
					particle:SetEndSize( math.Rand(200,300) * self.Scale )
					particle:SetRoll( math.Rand(-1,1) * 100 )
					particle:SetColor( 40,40,40 )
					particle:SetGravity( Vector( 0, 0, 0 ) )
					particle:SetCollide( false )
				end

				local particle = self.Emitter:Add( "effects/lvs_base/fire", Pos )

				if particle then
					particle:SetVelocity( VectorRand() * 100 * self.Scale )
					particle:SetDieTime( math.random(40,80) / 100 )
					particle:SetAirResistance( 0 ) 
					particle:SetStartAlpha( 255 )
					particle:SetStartSize( 130 * self.Scale )
					particle:SetEndSize( math.Rand(50,100) * self.Scale )
					particle:SetRoll( math.Rand(-1,1) * 180 )
					particle:SetColor( 255,255,255 )
					particle:SetGravity( Vector( 0, 0, 70 ) )
					particle:SetCollide( false )
				end

				for i = 0,3 do
					local particle = self.Emitter:Add( "effects/lvs_base/flamelet"..math.random(1,5), Pos + VectorRand() * 100 * self.Scale )

					if particle then
						particle:SetVelocity( VectorRand() * 100 * self.Scale )
						particle:SetDieTime( math.random(30,60) / 100 )
						particle:SetAirResistance( 0 ) 
						particle:SetStartAlpha( 255 )
						particle:SetStartSize( 70 * self.Scale )
						particle:SetEndSize( math.Rand(25,80) * self.Scale )
						particle:SetRoll( math.Rand(-1,1) * 180 )
						particle:SetColor( 255,255,255 )
						particle:SetGravity( Vector( 0, 0, 40 ) )
						particle:SetCollide( false )
					end
				end
			end
		end

		if self.DieTime < CurTime() then 
			if self.Emitter then
				self.Emitter:Finish()
			end

			return false
		end

		return true
	end

	if self.Emitter then
		self.Emitter:Finish()
	end

	return false
end

function EFFECT:Render()
end
