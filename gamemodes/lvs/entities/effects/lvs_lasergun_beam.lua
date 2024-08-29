
function EFFECT:Init( data )

	self.StartPos = data:GetStart()
	self.EndPos = data:GetOrigin()

	self.Ent = data:GetEntity()

	if not IsValid( self.Ent ) then return end

	self.Player = self.Ent:GetOwner()

	self:SetRenderBoundsWS( data:GetStart(), data:GetOrigin() )
end

function EFFECT:Think()
	if not IsValid( self.Ent ) or not IsValid( self.Player ) or not self.Ent:GetActive() then
		return false
	end

	return true
end

local BeamMat = Material( "effects/tool_tracer" )
local BeamColor = Color( 150, 200, 255, 255 )

local TipMat = Material( "particle/particle_glow_05_addnofog" )
local MuzzleFX = Material( "effects/select_ring" )
local MuzzleFX2 = Material( "sprites/light_glow02_add" )

local LastSND = 0

local BlindDuration = 0.1
local BlindTime = 0

hook.Add( "HUDPaint", "!lvs_laser_beam_blindness", function()
	local T = CurTime()

	if BlindTime < T then return end

	surface.SetDrawColor( 150, 200, 255, 25 * (math.max( (BlindTime - T) / BlindDuration, 0 ) ^ 2) )
	surface.DrawRect( 0, 0, ScrW(), ScrH() )
end )

function EFFECT:DoImpactEffect( EndPos, Dir )
	local trace = util.TraceLine( {
		start = EndPos - Dir,
		endpos = EndPos + Dir,
		filter = {self.Player,self.Ent,self}
	} )

	local ply = LocalPlayer()

	if trace.Hit and trace.HitWorld then
		if self.Player == ply then
			local effectdata = EffectData()
				effectdata:SetOrigin( trace.HitPos )
				effectdata:SetNormal( trace.HitNormal )
			util.Effect( "lvs_lasergun_hitwall", effectdata )
		else
			local effectdata = EffectData()
				effectdata:SetOrigin( trace.HitPos )
				effectdata:SetNormal( trace.HitNormal )
			util.Effect( "lvs_lasergun_hitwall_other", effectdata )
		end
	end

	if ply ~= self.Player then return end

	local traceHull = util.TraceHull( {
		mins = Vector(-8,-8,-8),
		maxs = Vector(8,8,8),
		start = EndPos - Dir,
		endpos = EndPos + Dir,
		filter = {self.Player,self.Ent,self}
	} )

	if traceHull.Hit then
		local T = CurTime()

		if (trace.Entity:IsPlayer() or trace.Entity._lvsLaserGunDetectHit) and LastSND < T then

			self.Player:EmitSound("lvs/tournament/weapons/lasergun/hit"..math.random(1,5)..".wav",90,100,1,CHAN_ITEM)

			LastSND = T + 0.05
			BlindTime = T + BlindDuration
		end
	end
end

function EFFECT:RenderBeamSmall( StartPos, EndPos )
	local T = CurTime() * 2

	render.SetMaterial( BeamMat )
	render.DrawBeam( StartPos, EndPos, math.Rand(4.5,5), T - 1, T, color_white )

	render.SetMaterial( TipMat )
	render.DrawSprite( EndPos, math.Rand(10,12), math.Rand(10,12), BeamColor )
end

function EFFECT:RenderBeam( StartPos, EndPos )
	render.SetMaterial( BeamMat )

	local T = CurTime() * 2

	local EyeAng = self.Player:EyeAngles()
	local Right = EyeAng:Right()
	local Up = EyeAng:Up()

	local Sub = (EndPos - StartPos)
	local Dir = Sub:GetNormalized()
	local Dist = Sub:Length()
	local Len = math.Clamp( math.Round( Dist / 100, 0 ), 10,100 )

	local Num = math.Round( Dist / Len, 0 )

	if not self.OldPos then
		self:DoImpactEffect( EndPos, Dir )

		self.OldPos = EndPos
		self.OldDir = self.Dir
	else
		local dist = (self.OldPos - EndPos):Length()

		if Len > 11 or dist <= 1 or self.Player ~= LocalPlayer() then
			self:DoImpactEffect( EndPos, Dir )
		else
			local steps = dist > 100 and 5 or 2

			local NumFX = 0
			for i = 0, dist, steps do
				local Pos = (self.OldPos / dist) * i + (EndPos / dist) * (dist - i)
		
				self:DoImpactEffect( Pos, Dir )

				NumFX = NumFX + 1

				if NumFX > 50 then break end

			end
		end

		self.OldPos = EndPos
		self.OldDir = self.Dir
	end

	render.StartBeam( Num )
	render.AddBeam( StartPos, math.Rand(9,10), T, color_white )
	for I = 1, Num do
		local P = StartPos + (Right * math.sin( -T * 10 + math.rad(I * 45) ) * 10 + Up * math.cos( -T * 10 + math.rad(I * 45) ) * 10) * (1 - (I / Num))
		render.AddBeam( P + Dir * I * Len, math.Rand(9,10), T - I * 0.05, color_white )
	end
	render.AddBeam( EndPos, math.Rand(9,10), T - (Num + 1) * 0.05, color_white )
	render.EndBeam()

	render.StartBeam( Num )
	for I = 0, Num do
		render.AddBeam( StartPos + Dir * I * Len, math.Rand(18,20) * (1 - (I / Num)), T + I * 0.05, color_white )
	end
	render.EndBeam()

	self:SetRenderBoundsWS( StartPos, EndPos )

	render.SetMaterial( MuzzleFX )
	render.DrawSprite( StartPos, math.Rand(8,9), math.Rand(8,9), BeamColor )

	render.SetMaterial( MuzzleFX2 )
	render.DrawSprite( StartPos, math.Rand(120,124), math.Rand(120,124), BeamColor )

	render.SetMaterial( TipMat )
	render.DrawSprite( StartPos, math.Rand(30,34), math.Rand(30,34), BeamColor )

	for i = 1, 5 do
		render.SetMaterial( MuzzleFX2 )
		render.DrawSprite( EndPos - Dir * 4 + VectorRand() * math.Rand(-5,5), math.Rand(20,30), math.Rand(20,30), BeamColor )
	end
end

function EFFECT:Render()
	if self.Player == LocalPlayer() and self.Player:GetViewEntity() == self.Player and not self.Player:ShouldDrawLocalPlayer() then
		local vm = self.Player:GetViewModel()

		if not IsValid( vm ) then return end

		local att = vm:GetAttachment( vm:LookupAttachment( "muzzle" ) )

		if not att then return end

		local StartPos = att.Pos
		local EndPos = self.Player:GetEyeTrace().HitPos

		if IsValid( self.Ent ) then
			local HoldEntity = self.Ent:GetHoldEntity()

			if IsValid( HoldEntity ) then
				EndPos = HoldEntity:LocalToWorld( self.Ent:GetHoldPos() )
			end
		end

		self:RenderBeam( StartPos, EndPos )

		local att1 = vm:GetAttachment( vm:LookupAttachment( "fork1t" ) )
		local att2 = vm:GetAttachment( vm:LookupAttachment( "fork2t" ) )

		if not att1 or not att2 then return end

		self:RenderBeamSmall( StartPos, att1.Pos )
		self:RenderBeamSmall( StartPos, att2.Pos )

		return
	end

	if not IsValid( self.Ent ) then return end

	local att = self.Ent:GetAttachment( self.Ent:LookupAttachment( "core" ) )

	if not att then return end

	local StartPos = att.Pos
	local EndPos = self.Player:GetEyeTrace().HitPos

	local HoldEntity = self.Ent:GetHoldEntity()

	if IsValid( HoldEntity ) then
		EndPos = HoldEntity:LocalToWorld( self.Ent:GetHoldPos() )
	end

	self:RenderBeam( StartPos, EndPos )

	local att1 = self.Ent:GetAttachment( self.Ent:LookupAttachment( "fork1t" ) )
	local att2 = self.Ent:GetAttachment( self.Ent:LookupAttachment( "fork2t" ) )
	local att3 = self.Ent:GetAttachment( self.Ent:LookupAttachment( "fork3t" ) )

	if not att1 or not att2 or not att3 then return end

	self:RenderBeamSmall( StartPos, att1.Pos )
	self:RenderBeamSmall( StartPos, att2.Pos )
	self:RenderBeamSmall( StartPos, att3.Pos )
end
