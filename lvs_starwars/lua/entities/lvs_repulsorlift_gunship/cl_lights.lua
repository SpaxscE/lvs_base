
ENT.LightMaterial = Material( "effects/lvs/laat_spotlight" )
ENT.GlowMaterial = Material( "sprites/light_glow02_add" )

function ENT:OnRemoved()
	self:RemoveLight()
end

function ENT:RemoveLight()
	if IsValid( self.projector_L ) then
		self.projector_L:Remove()
		self.projector_L = nil
	end

	if IsValid( self.projector_R ) then
		self.projector_R:Remove()
		self.projector_R = nil
	end
end

function ENT:PostDrawTranslucent()
	if self:GetBodygroup( 5 ) ~= 2 or not self:GetLightsActive() then 
		self:RemoveLight()

		return
	end

	if not IsValid( self.projector_L ) then
		local thelamp = ProjectedTexture()
		thelamp:SetBrightness( 10 ) 
		thelamp:SetTexture( "effects/flashlight/soft" )
		thelamp:SetColor( Color(255,255,255) ) 
		thelamp:SetEnableShadows( false ) 
		thelamp:SetFarZ( 5000 ) 
		thelamp:SetNearZ( 75 ) 
		thelamp:SetFOV( 40 )
		self.projector_L = thelamp
	end

	if not IsValid( self.projector_R ) then
		local thelamp = ProjectedTexture()
		thelamp:SetBrightness( 10 ) 
		thelamp:SetTexture( "effects/flashlight/soft" )
		thelamp:SetColor( Color(255,255,255) ) 
		thelamp:SetEnableShadows( false ) 
		thelamp:SetFarZ( 5000 ) 
		thelamp:SetNearZ( 75 ) 
		thelamp:SetFOV( 40 )
		self.projector_R = thelamp
	end

	if not self.SpotlightID_L then
		self.SpotlightID_L = self:LookupAttachment( "spotlight_left" )
	else
		local attachment = self:GetAttachment( self.SpotlightID_L )

		if attachment then
			local StartPos = attachment.Pos
			local Dir = attachment.Ang:Up()

			render.SetMaterial( self.GlowMaterial )
			render.DrawSprite( StartPos + Dir * 20, 400, 400, Color( 255, 255, 255, 255) )

			render.SetMaterial( self.LightMaterial )
			render.DrawBeam(  StartPos - Dir * 10,  StartPos + Dir * 1500, 350, 0, 0.99, Color( 255, 255, 255, 10) ) 
			
			if IsValid( self.projector_L ) then
				self.projector_L:SetPos( StartPos )
				self.projector_L:SetAngles( Dir:Angle() )
				self.projector_L:Update()
			end
		end
	end

	if not self.SpotlightID_R then
		self.SpotlightID_R = self:LookupAttachment( "spotlight_right" )
	else
		local attachment = self:GetAttachment( self.SpotlightID_R )

		if attachment then
			local StartPos = attachment.Pos
			local Dir = attachment.Ang:Up()

			render.SetMaterial( self.GlowMaterial )
			render.DrawSprite( StartPos + Dir * 20, 400, 400, Color( 255, 255, 255, 255) )

			render.SetMaterial( self.LightMaterial )
			render.DrawBeam(  StartPos - Dir * 10,  StartPos + Dir * 1500, 350, 0, 0.99, Color( 255, 255, 255, 10 ) ) 

			if IsValid( self.projector_R ) then
				self.projector_R:SetPos( StartPos )
				self.projector_R:SetAngles( Dir:Angle() )
				self.projector_R:Update()
			end
		end
	end
end

function ENT:AnimLights()
	if self:GetBodygroup( 5 ) ~= 2 then return end

	local TargetValue = self:HitGround() and 0 or 1
	local Rate = FrameTime() * 10

	self.smSpotLight = isnumber( self.smSpotLight ) and (self.smSpotLight + math.Clamp(TargetValue - self.smSpotLight,-Rate,Rate * 0.1)) or 0

	if not self.SpotLightID_L then
		self.SpotLightID_L = self:LookupBone( "spotlight_left" ) 
	else
		self:ManipulateBoneAngles( self.SpotLightID_L, Angle(10,-30,5) * self.smSpotLight )	
	end

	if not self.SpotLightID_R then
		self.SpotLightID_R = self:LookupBone( "spotlight_right" ) 
	else
		self:ManipulateBoneAngles( self.SpotLightID_R, Angle(-10,30,5) * self.smSpotLight )	
	end
end