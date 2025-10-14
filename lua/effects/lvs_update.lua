
function EFFECT:Init( data )
	self.Ent = data:GetEntity()
	self.Pos = data:GetOrigin()

	local T = CurTime()

	self.LifeTime = 1
	self.DieTime = T + self.LifeTime

	if IsValid( self.Ent ) then
		self.Model = ClientsideModel( self.Ent:GetModel(), RENDERMODE_TRANSCOLOR )
		self.Model:SetMaterial("models/alyx/emptool_glow")
		self.Model:SetColor( Color(0,127,255,255) )
		self.Model:SetParent( self.Ent, 0 )
		self.Model:SetMoveType( MOVETYPE_NONE )
		self.Model:SetLocalPos( Vector( 0, 0, 0 ) )
		self.Model:SetLocalAngles( Angle( 0, 0, 0 ) )
		self.Model:AddEffects( EF_BONEMERGE )
		self.Model:SetModelScale( self.Ent:GetModelScale() )
	end
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
end
