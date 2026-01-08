
EFFECT.GlowMat = Material( "effects/yellowflare" )
EFFECT.FireMat = Material( "effects/muzzleflash2" )

function EFFECT:Init( data )
	self.Pos = data:GetOrigin()
	self.Ang = data:GetAngles()
	self.Ent = data:GetEntity()

	local volume = math.Clamp( data:GetMagnitude(), 0, 1 )

	local T = CurTime()

	self.LifeTime = 0.25
	self.LifeTimePop = 0.1

	self.DieTime = T + self.LifeTime
	self.DieTimePop = T + self.LifeTimePop

	self.Scale = math.Rand( 0.25, 1 )

	if not IsValid( self.Ent ) then return end

	local Pos = self.Ent:LocalToWorld( self.Pos )

	self:SetPos( Pos )

	local ply = LocalPlayer()

	if not IsValid( ply ) then return end

	local veh = ply:lvsGetVehicle()

	if IsValid( veh ) and veh == self.Ent then
		local pod = ply:GetVehicle()

		if IsValid( pod ) and not pod:GetThirdPersonMode() then
			sound.Play( "lvs/vehicles/generic/exhaust_pop"..math.random(1,16)..".ogg", Pos, 75, math.random(98,105), volume )

			return
		end
	end

	local dlight = DynamicLight( self.Ent:EntIndex() * math.random(1,4), true )

	if dlight then
		dlight.pos = Pos
		dlight.r = 255
		dlight.g = 180
		dlight.b = 100
		dlight.brightness = 1
		dlight.Decay = 2000
		dlight.Size = 400
		dlight.DieTime = CurTime() + 0.2
	end

	sound.Play( "lvs/vehicles/generic/exhaust_pop"..math.random(1,16)..".ogg", Pos, 75, math.random(98,105), volume )
end

function EFFECT:Think()
	if not IsValid( self.Ent ) then return false end

	if self.DieTime < CurTime() then return false end

	self:SetPos( self.Ent:LocalToWorld( self.Pos ) )

	return true
end


function EFFECT:Render()
	if not IsValid( self.Ent ) or not self.Pos then return end

	self:RenderSmoke()
end

function EFFECT:RenderSmoke()
	if not self.Pos or not self.Ang or not self.Scale then return end

	local T = CurTime()

	local ScalePop = math.Clamp( (self.DieTimePop - T) / self.LifeTimePop, 0, 1 )
	local InvScalePop = 1 - ScalePop

	local Scale = (self.DieTime - T) / self.LifeTime
	local InvScale = 1 - Scale

	local Pos = self.Ent:LocalToWorld( self.Pos )
	local Ang = self.Ent:LocalToWorldAngles( self.Ang )

	local FlameSize = 5 * Scale ^ 2
	render.SetMaterial( self.FireMat )
	for i = 1, 12 do
		render.DrawSprite( Pos + Ang:Forward() * InvScale * 20 + VectorRand() * 2, FlameSize, FlameSize, color_white )
	end

	if InvScalePop <= 0 then return end

	local GlowSize = 60 * InvScalePop * self.Scale
	local A255 = 255 * ScalePop

	render.SetMaterial( self.GlowMat )
	render.DrawSprite( Pos, GlowSize, GlowSize, Color(A255,A255,A255,A255) )
end

