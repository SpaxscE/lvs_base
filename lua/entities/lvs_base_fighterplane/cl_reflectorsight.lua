
ENT.ReflectorSight = false
ENT.ReflectorSightPos = vector_origin
ENT.ReflectorSightColor = color_white
ENT.ReflectorSightColorBG = color_black
ENT.ReflectorSightMaterial = Material("lvs/sights/german.png")
ENT.ReflectorSightMaterialRes = 128
ENT.ReflectorSightHeight = 3
ENT.ReflectorSightWidth = 1.5
ENT.ReflectorSightGlow = false
ENT.ReflectorSightGlowMaterial = Material( "sprites/light_glow02_add" )
ENT.ReflectorSightGlowMaterialRes = 600
ENT.ReflectorSightGlowColor = color_white

function ENT:PaintReflectorSight( Pos2D, Ang, Origin2D )
	if self.ReflectorSightGlow then
		surface.SetDrawColor( self.ReflectorSightGlowColor )
		surface.SetMaterial( self.ReflectorSightGlowMaterial )
		surface.DrawTexturedRectRotated( Pos2D.x, Pos2D.y, self.ReflectorSightGlowMaterialRes, self.ReflectorSightGlowMaterialRes, -Ang )
	end

	surface.SetDrawColor( self.ReflectorSightColor )
	surface.SetMaterial( self.ReflectorSightMaterial )
	surface.DrawTexturedRectRotated( Pos2D.x, Pos2D.y, self.ReflectorSightMaterialRes, self.ReflectorSightMaterialRes, -Ang )
end

function ENT:IsDrawingReflectorSight()
	if not self.ReflectorSight then return false end

	local Pod = self:GetDriverSeat()

	if not IsValid( Pod ) then return false end

	return not Pod:GetThirdPersonMode()
end

function ENT:DrawReflectorSight( Pos2D )
	local Pos = self:LocalToWorld( self.ReflectorSightPos )
	local Up = self:GetUp()
	local Right = self:GetRight()

	local Width = self.ReflectorSightWidth
	local Height = self.ReflectorSightHeight

	local TopLeft = (Pos + Up * Height - Right * Width):ToScreen()
	local TopRight = (Pos + Up * Height + Right * Width):ToScreen()
	local BottomLeft = (Pos - Right * Width):ToScreen()
	local BottomRight = (Pos + Right * Width):ToScreen()

	Pos = Pos:ToScreen()

	if not Pos.visible then return end

	local poly = {
		{ x = TopLeft.x, y = TopLeft.y },
		{ x = TopRight.x, y = TopRight.y },
		{ x = BottomRight.x, y = BottomRight.y },
		{ x = BottomLeft.x, y = BottomLeft.y },
	}

	local Ang = 0

	if TopLeft.x < TopRight.x then
		Ang = (Vector( TopLeft.x, 0, TopLeft.y ) - Vector( TopRight.x, 0, TopRight.y )):Angle().p
	else
		Ang = (Vector( TopRight.x, 0, TopRight.y ) - Vector( TopLeft.x, 0, TopLeft.y )):Angle().p - 180
	end

	draw.NoTexture()
	surface.SetDrawColor( self.ReflectorSightColorBG )
	surface.DrawPoly( poly )

	render.SetStencilWriteMask( 0xFF )
	render.SetStencilTestMask( 0xFF )
	render.SetStencilReferenceValue( 0 )
	render.SetStencilPassOperation( STENCIL_KEEP )
	render.SetStencilZFailOperation( STENCIL_KEEP )
	render.ClearStencil()

	render.SetStencilEnable( true )
	render.SetStencilReferenceValue( 1 )
	render.SetStencilCompareFunction( STENCIL_NEVER )
	render.SetStencilFailOperation( STENCIL_REPLACE )

	draw.NoTexture()
	surface.SetDrawColor( color_white )
	surface.DrawPoly( poly )

	render.SetStencilCompareFunction( STENCIL_EQUAL )
	render.SetStencilFailOperation( STENCIL_KEEP )

	self:PaintReflectorSight( Pos2D, Ang, Pos )

	render.SetStencilEnable( false )
end
