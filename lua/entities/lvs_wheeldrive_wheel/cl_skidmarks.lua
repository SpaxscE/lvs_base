
ENT.SkidmarkMaterialDamaged = Material("sprites/lvs/skidmark_damaged")

ENT.SkidmarkTraceAdd = Vector(0,0,10)
ENT.SkidmarkDelay = 0.05
ENT.SkidmarkLifetime = 10

ENT.SkidmarkRed = 0
ENT.SkidmarkGreen = 0
ENT.SkidmarkBlue = 0
ENT.SkidmarkAlpha = 150

ENT.SkidmarkSurfaces = {
	[""] = true,
	["concrete"] = true,
	["plastic_barrel_buoyant"] = true,
	["phx_rubbertire2"] = true,
	["tile"] = true,
	["metal"] = true,
	["boulder"] = true,
	["default"] = true,
}

ENT.DustEffectSurfaces = {
	["sand"] = true,
	["dirt"] = true,
	["grass"] = true,
	["antlionsand"] = true,
	["gravel"] = true,
}

function ENT:GetSkidMarks()
	if not istable( self._activeSkidMarks ) then
		self._activeSkidMarks = {}
	end

	return self._activeSkidMarks
end

function ENT:StartSkidmark( pos )
	if self:GetWidth() <= 0 or self._SkidMarkID or not LVS.ShowTraileffects then return end

	local ID = 1
	for _,_ in ipairs( self:GetSkidMarks() ) do
		ID = ID + 1
	end

	self._activeSkidMarks[ ID ] = {
		active = true,
		startpos = pos + self.SkidmarkTraceAdd,
		delay = CurTime() + self.SkidmarkDelay,
		damaged = self:GetNWDamaged(),
		positions = {},
	}

	self._SkidMarkID = ID
end

function ENT:FinishSkidmark()
	if not self._SkidMarkID then return end

	self._activeSkidMarks[ self._SkidMarkID ].active = false

	self._SkidMarkID = nil
end

function ENT:RemoveSkidmark( id )
	if not id then return end

	self._activeSkidMarks[ id ] = nil
end

function ENT:CalcSkidmark( trace, Filter )
	local T = CurTime()
	local CurActive = self:GetSkidMarks()[ self._SkidMarkID ]

	if not CurActive or not CurActive.active or CurActive.delay >= T then return end

	CurActive.delay = T + self.SkidmarkDelay

	local W = self:GetWidth()

	local cur = trace.HitPos + self.SkidmarkTraceAdd * 0.5

	local prev = CurActive.positions[ #CurActive.positions ]

	if not prev then
		local sub = cur - CurActive.startpos

		local L = sub:Length() * 0.5
		local C = (cur + CurActive.startpos) * 0.5

		local Ang = sub:Angle()
		local Forward = Ang:Right()
		local Right = Ang:Forward()

		local p1 = C + Forward * W + Right * L
		local p2 = C - Forward * W + Right * L

		local t1 = util.TraceLine( { start = p1, endpos = p1 - self.SkidmarkTraceAdd } )
		local t2 = util.TraceLine( { start = p2, endpos = p2 - self.SkidmarkTraceAdd } )

		prev = {
			px = CurActive.startpos,
			p1 = t1.HitPos + t1.HitNormal,
			p2 = t2.HitPos + t2.HitNormal,
			lifetime = T + self.SkidmarkLifetime - self.SkidmarkDelay,
			alpha = 0,
		}
	end

	local sub = cur - prev.px

	local L = sub:Length() * 0.5
	local C = (cur + prev.px) * 0.5

	local Ang = sub:Angle()
	local Forward = Ang:Right()
	local Right = Ang:Forward()

	local p1 = C + Forward * W + Right * L
	local p2 = C - Forward * W + Right * L

	local t1 = util.TraceLine( { start = p1, endpos = p1 - self.SkidmarkTraceAdd, filter = Filter, } )
	local t2 = util.TraceLine( { start = p2, endpos = p2 - self.SkidmarkTraceAdd, filter = Filter, } )

	local nextID = #CurActive.positions + 1

	CurActive.positions[ nextID ] = {
		px = cur,
		p1 = t1.HitPos + t1.HitNormal,
		p2 = t2.HitPos + t2.HitNormal,
		lifetime = T + self.SkidmarkLifetime,
		alpha = math.min( nextID / 10, 1 ),
	}
end

function ENT:RenderSkidMarks()
	local T = CurTime()

	for id, skidmark in pairs( self:GetSkidMarks() ) do
		local prev
		local AmountDrawn = 0

		if skidmark.damaged then
			render.SetMaterial( self.SkidmarkMaterialDamaged )
		else
			render.SetColorMaterial()
		end

		for markID, data in pairs( skidmark.positions ) do
			if not prev then

				prev = data

				continue
			end

			local Mul = math.max( data.lifetime - CurTime(), 0 ) / self.SkidmarkLifetime

			if Mul > 0 then
				AmountDrawn = AmountDrawn + 1
				render.DrawQuad( data.p2, data.p1, prev.p1, prev.p2, Color( self.SkidmarkRed, self.SkidmarkGreen, self.SkidmarkBlue, math.min(255 * Mul * data.alpha,self.SkidmarkAlpha) ) )
			end

			prev = data
		end

		if not skidmark.active and AmountDrawn == 0 then
			self:RemoveSkidmark( id )
		end
	end
end

hook.Add( "PreDrawTranslucentRenderables", "!!!!lvs_skidmarks", function( bDepth, bSkybox )
	if bSkybox then return end

	for _, wheel in ipairs( ents.FindByClass("lvs_wheeldrive_wheel") ) do
		wheel:RenderSkidMarks()
	end
end)