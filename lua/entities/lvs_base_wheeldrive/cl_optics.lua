
DEFINE_BASECLASS( "lvs_base" )

ENT.OpticsFov = 30
ENT.OpticsEnable = false
ENT.OpticsZoomOnly = true
ENT.OpticsFirstPerson = true
ENT.OpticsThirdPerson = true
ENT.OpticsPodIndex = {
	[1] = true,
}

ENT.OpticsCrosshairMaterial = Material( "vgui/circle" )
ENT.OpticsCrosshairColor = Color(0,0,0,255)
ENT.OpticsCrosshairSize = 5

function ENT:PaintOpticsCrosshair( Pos2D )
	if not Pos2D.visible then return end

	local size = self.OpticsCrosshairSize

	surface.SetMaterial( self.OpticsCrosshairMaterial )
	surface.SetDrawColor( self.OpticsCrosshairColor )
	surface.DrawTexturedRect( Pos2D.x - size * 0.5, Pos2D.y - size * 0.5, size, size )
end

function ENT:CalcOpticsCrosshairDot( Pos2D )
	self:PaintOpticsCrosshair( Pos2D )
end

function ENT:GetOpticsEnabled()
	local EntTable = self:GetTable()

	if not EntTable.OpticsEnable then return false end

	local ply = LocalPlayer()

	if not IsValid( ply ) then return false end

	local pod = ply:GetVehicle()
	local PodIndex = pod:lvsGetPodIndex()
	if pod == self:GetDriverSeat() then
		PodIndex = 1
	end

	if EntTable.OpticsPodIndex[ PodIndex ] then
		if pod:GetThirdPersonMode() then
			return EntTable.OpticsThirdPerson
		else
			return EntTable.OpticsFirstPerson
		end
	end

	return false
end

function ENT:UseOptics()
	if self.OpticsZoomOnly and self:GetZoom() ~= 1 then return false end

	return self:GetOpticsEnabled()
end

function ENT:PaintCrosshairCenter( Pos2D, Col )
	if self:UseOptics() then
		if self.OpticsScreenCentered then
			self:CalcOpticsCrosshairDot( Pos2D )

			local ScreenCenter2D = {
				x = ScrW() * 0.5,
				y = ScrH() * 0.5,
				visible = true,
			}

			self:PaintOptics( ScreenCenter2D, Col, LocalPlayer():GetVehicle():GetNWInt( "pPodIndex", -1 ), 1 )
		else
			self:PaintOptics( Pos2D, Col, LocalPlayer():GetVehicle():GetNWInt( "pPodIndex", -1 ), 1 )
		end

		return
	end

	BaseClass.PaintCrosshairCenter( self, Pos2D, Col )
end

function ENT:PaintCrosshairOuter( Pos2D, Col )
	if self:UseOptics() then
		if self.OpticsScreenCentered then
			self:CalcOpticsCrosshairDot( Pos2D )

			local ScreenCenter2D = {
				x = ScrW() * 0.5,
				y = ScrH() * 0.5,
				visible = true,
			}

			self:PaintOptics( ScreenCenter2D, Col, LocalPlayer():GetVehicle():GetNWInt( "pPodIndex", -1 ), 2 )
		else
			self:PaintOptics( Pos2D, Col, LocalPlayer():GetVehicle():GetNWInt( "pPodIndex", -1 ), 2 )
		end

		return
	end

	BaseClass.PaintCrosshairOuter( self, Pos2D, Col )
end

function ENT:PaintCrosshairSquare( Pos2D, Col )
	if self:UseOptics() then
		if self.OpticsScreenCentered then
			self:CalcOpticsCrosshairDot( Pos2D )

			local ScreenCenter2D = {
				x = ScrW() * 0.5,
				y = ScrH() * 0.5,
				visible = true,
			}

			self:PaintOptics( ScreenCenter2D, Col, LocalPlayer():GetVehicle():GetNWInt( "pPodIndex", -1 ), 3 )
		else
			self:PaintOptics( Pos2D, Col, LocalPlayer():GetVehicle():GetNWInt( "pPodIndex", -1 ), 3 )
		end

		return
	end

	BaseClass.PaintCrosshairSquare( self, Pos2D, Col )
end

function ENT:DrawRotatedText( text, x, y, font, color, ang)
	render.PushFilterMag( TEXFILTER.ANISOTROPIC )
	render.PushFilterMin( TEXFILTER.ANISOTROPIC )

	local m = Matrix()
	m:Translate( Vector( x, y, 0 ) )
	m:Rotate( Angle( 0, ang, 0 ) )

	surface.SetFont( font )
	local w, h = surface.GetTextSize( text )

	m:Translate( -Vector( w / 2, h / 2, 0 ) )

	cam.PushModelMatrix( m )
		draw.DrawText( text, font, 0, 0, color )
	cam.PopModelMatrix()

	render.PopFilterMag()
	render.PopFilterMin()
end

function ENT:PaintOptics( Pos2D, Col, PodIndex, Type )
end
