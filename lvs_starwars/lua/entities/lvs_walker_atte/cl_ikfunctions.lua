
function ENT:OnRemoved()
	self:LegClearAll()
end

local debugred = Color(255,0,0,255)
local debugblue = Color(0,0,255,255)
local debuggreen = Color(0,255,0,255)

function ENT:LegClearAll()
	if istable( self.IK_Joints ) then 
		for _, tab in pairs( self.IK_Joints ) do
			for _,prop in pairs( tab ) do
				if IsValid( prop ) then
					prop:Remove()
				end
			end
		end
		
		self.IK_Joints = nil
	end
end

function ENT:GetLegEnts( index, L1, L2, JOINTANG, STARTPOS, ENDPOS, ATTACHMENTS )
	if not istable( self.IK_Joints ) then self.IK_Joints = {} end

	if self.IK_Joints[ index ] then
		if IsValid( self.IK_Joints[ index ].LegBaseRot ) and IsValid( self.IK_Joints[ index ].LegRotCalc ) then
			if (self.IK_Joints[ index ].LegBaseRot:GetPos() - STARTPOS):Length() > 1 or (self.IK_Joints[ index ].LegRotCalc:GetPos() - STARTPOS):Length() > 1 then
				for k, v in pairs( self.IK_Joints[ index ] ) do
					if IsValid( v ) then
						v:Remove()
					end
				end
				self.IK_Joints[ index ] = nil
			end
		end
	end

	if not self.IK_Joints[ index ] then
		self.IK_Joints[ index ] = {}

		local BaseProp = ents.CreateClientProp()
		BaseProp:SetPos( STARTPOS )
		BaseProp:SetAngles( JOINTANG )
		BaseProp:SetModel( "models/Combine_Helicopter/helicopter_bomb01.mdl" )
		BaseProp:SetParent( self )
		BaseProp:Spawn()

		local LegRotCalc = ents.CreateClientProp()
		LegRotCalc:SetPos( STARTPOS )
		LegRotCalc:SetAngles( JOINTANG )
		LegRotCalc:SetModel( "models/Combine_Helicopter/helicopter_bomb01.mdl" )
		LegRotCalc:SetParent( self )
		LegRotCalc:Spawn()

		local prop1 = ents.CreateClientProp()
		prop1:SetPos( BaseProp:LocalToWorld( Vector(0,0,L1 * 0.5) ) )
		prop1:SetAngles( JOINTANG )
		prop1:SetModel( "models/Combine_Helicopter/helicopter_bomb01.mdl" )
		prop1:SetParent( self )
		prop1:Spawn()

		local prop2 = ents.CreateClientProp()
		prop2:SetPos( BaseProp:LocalToWorld( Vector(0,0,L1 + L2) ) )
		prop2:SetAngles( JOINTANG )
		prop2:SetModel( "models/Combine_Helicopter/helicopter_bomb01.mdl" )
		prop2:SetParent( self )
		prop2:Spawn()

		local prop3 = ents.CreateClientProp()
		prop3:SetPos( STARTPOS )
		prop3:SetAngles( JOINTANG )
		prop3:SetModel( "models/Combine_Helicopter/helicopter_bomb01.mdl" )
		prop3:SetParent( LegRotCalc )
		prop1:SetParent( prop3 )
		prop3:Spawn()

		local prop4 = ents.CreateClientProp()
		prop4:SetPos( BaseProp:LocalToWorld( Vector(0,0,L1) ) )
		prop4:SetAngles( JOINTANG )
		prop4:SetModel( "models/Combine_Helicopter/helicopter_bomb01.mdl" )
		prop4:SetParent( prop1 )
		prop2:SetParent( prop4 )
		prop4:Spawn()
		
		self.IK_Joints[ index ].LegBaseRot = BaseProp
		self.IK_Joints[ index ].LegRotCalc = LegRotCalc
		self.IK_Joints[ index ].LegEnt1 = prop1
		self.IK_Joints[ index ].LegEnt2 = prop2
		self.IK_Joints[ index ].LegEnt3 = prop3
		self.IK_Joints[ index ].LegEnt4 = prop4

		for _, v in pairs( self.IK_Joints[ index ] ) do
			v:SetColor( Color( 0, 0, 0, 0 ) )
			v:SetRenderMode( RENDERMODE_TRANSALPHA )
		end

		if ATTACHMENTS then
			if ATTACHMENTS.Leg1 then
				local prop = ents.CreateClientProp()
				prop:SetPos( prop3:LocalToWorld( ATTACHMENTS.Leg1.Pos ) )
				prop:SetAngles( prop3:LocalToWorldAngles( ATTACHMENTS.Leg1.Ang ) )
				prop:SetModel( ATTACHMENTS.Leg1.MDL )
				prop:SetParent( prop3 )
				prop:Spawn()
				self.IK_Joints[ index ].Attachment1 = prop
			end
			if ATTACHMENTS.Leg2 then
				local prop = ents.CreateClientProp()
				prop:SetPos( prop4:LocalToWorld( ATTACHMENTS.Leg2.Pos ) )
				prop:SetAngles( prop4:LocalToWorldAngles( ATTACHMENTS.Leg2.Ang ) )
				prop:SetModel( ATTACHMENTS.Leg2.MDL )
				prop:SetParent( prop4 )
				prop:Spawn()
				self.IK_Joints[ index ].Attachment2 = prop
			end
			if ATTACHMENTS.Foot then
				local prop = ents.CreateClientProp()
				prop:SetModel( ATTACHMENTS.Foot.MDL )
				prop:SetParent( prop2 )
				prop:Spawn()
				self.IK_Joints[ index ].Attachment3 = prop
			end
		end
	end

	if not IsValid( self.IK_Joints[ index ].LegRotCalc ) or not IsValid( self.IK_Joints[ index ].LegBaseRot ) or not IsValid( self.IK_Joints[ index ].LegEnt1 ) or not IsValid( self.IK_Joints[ index ].LegEnt2 ) or not IsValid( self.IK_Joints[ index ].LegEnt3 ) or not IsValid( self.IK_Joints[ index ].LegEnt4 ) then
		self:LegClearAll()

		return
	end

	self.IK_Joints[ index ].LegRotCalc:SetAngles(self.IK_Joints[ index ].LegBaseRot:LocalToWorldAngles( self.IK_Joints[ index ].LegBaseRot:WorldToLocal( ENDPOS ):Angle() ) )

	local LegRotCalcPos = self.IK_Joints[ index ].LegRotCalc:GetPos()

	local Dist = math.min( (LegRotCalcPos - ENDPOS ):Length(), L1 + L2)
	local Angle1 = 90 - math.deg( math.acos( (Dist ^ 2 + L1 ^ 2 - L2 ^ 2) / (2 * Dist * L1) ) )
	local Angle2 = math.deg( math.acos( (Dist ^ 2 + L2 ^ 2 - L1 ^ 2) / (2 * Dist * L2) ) ) + 90

	self.IK_Joints[ index ].LegEnt3:SetAngles( self.IK_Joints[ index ].LegRotCalc:LocalToWorldAngles( Angle(Angle1,180,180) ) )
	self.IK_Joints[ index ].LegEnt4:SetAngles( self.IK_Joints[ index ].LegRotCalc:LocalToWorldAngles( Angle(Angle2,180,180) ) )

	if self.IK_Joints[ index ].Attachment3 then
		self.IK_Joints[ index ].Attachment3:SetAngles( self:LocalToWorldAngles( ATTACHMENTS.Foot.Ang ) )
		self.IK_Joints[ index ].Attachment3:SetPos(self.IK_Joints[ index ].LegEnt2:GetPos() + self:GetForward() * ATTACHMENTS.Foot.Pos.x  + self:GetRight() * ATTACHMENTS.Foot.Pos.y + self:GetUp() * ATTACHMENTS.Foot.Pos.z )
	end


	--debug code
	local RFT = RealFrameTime()
	debugoverlay.Cross( self.IK_Joints[ index ].LegBaseRot:GetPos(), 15, RFT, debugred, true )
	debugoverlay.Line( self.IK_Joints[ index ].LegRotCalc:GetPos(), self.IK_Joints[ index ].LegEnt4:GetPos(), RFT, debuggreen, true )
	debugoverlay.Cross( self.IK_Joints[ index ].LegEnt4:GetPos(), 15, RFT, debugred, true )
	debugoverlay.Line( self.IK_Joints[ index ].LegEnt4:GetPos(), self.IK_Joints[ index ].LegEnt2:GetPos(), RFT, debuggreen, true )
	debugoverlay.Cross( self.IK_Joints[ index ].LegEnt2:GetPos(), 15, RFT, debugred, true )
	debugoverlay.Cross( self.IK_Joints[ index ].LegEnt1:GetPos(), 4, RFT, debugblue, true )
	debugoverlay.Sphere( self.IK_Joints[ index ].LegEnt3:GetPos(), 10, RFT, debugblue, true )
end
