
local LastImpact = 0

function EFFECT:Init( data )
	self.Ent = data:GetEntity()
	self.Pos = data:GetOrigin()

	self.mat = Material( "sprites/light_glow02_add" )

	local T = CurTime()

	self.LifeTime = 0.2
	self.DieTime = T + self.LifeTime

	local DontHurtEars = math.Clamp( T - LastImpact, 0.4, 1 ) ^ 2

	LastImpact = T

	sound.Play( "lvs/shield_deflect.ogg", self.Pos, 120, 100, DontHurtEars )

	self:Spark( self.Pos )

	if IsValid( self.Ent ) then
		self.Model = ClientsideModel( self.Ent:GetModel(), RENDERMODE_TRANSCOLOR )
		self.Model:SetMaterial("models/alyx/emptool_glow")
		self.Model:SetColor( Color(200,220,255,255) )
		self.Model:SetParent( self.Ent, 0 )
		self.Model:SetMoveType( MOVETYPE_NONE )
		self.Model:SetLocalPos( Vector( 0, 0, 0 ) )
		self.Model:SetLocalAngles( Angle( 0, 0, 0 ) )
		self.Model:AddEffects( EF_BONEMERGE )
	end
end

function EFFECT:Spark( pos )
	local emitter = ParticleEmitter( pos, false )

	for i = 0, 20 do
		local particle = emitter:Add( "sprites/rico1", pos )

		local vel = VectorRand() * 500

		if not particle then continue end

		particle:SetVelocity( vel )
		particle:SetAngles( vel:Angle() + Angle(0,90,0) )
		particle:SetDieTime( math.Rand(0.2,0.4) )
		particle:SetStartAlpha( math.Rand( 200, 255 ) )
		particle:SetEndAlpha( 0 )
		particle:SetStartSize( math.Rand(10,20) )
		particle:SetEndSize( 0 )
		particle:SetRoll( math.Rand(-100,100) )
		particle:SetRollDelta( math.Rand(-100,100) )
		particle:SetColor( 0, 127, 255 )

		particle:SetAirResistance( 0 )
	end

	emitter:Finish()
end

function EFFECT:Think()
	if not IsValid( self.Ent ) then
		if IsValid( self.Model ) then
			self.Model:Remove()
		end
	end

	if self.DieTime < CurTime() then 
		if IsValid( self.Model ) then
			self.Model:Remove()
		end

		return false
	end
	
	return true
end

function EFFECT:Render()
	local Scale = (self.DieTime - CurTime()) / self.LifeTime
	render.SetMaterial( self.mat )
	render.DrawSprite( self.Pos, 800 * Scale, 800 * Scale, Color( 0, 127, 255, 255) )
	render.DrawSprite( self.Pos, 200 * Scale, 200 * Scale, Color( 255, 255, 255, 255) )
end
