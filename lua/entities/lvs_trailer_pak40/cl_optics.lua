
ENT.OpticsFov = 30
ENT.OpticsEnable = true
ENT.OpticsZoomOnly = true
ENT.OpticsFirstPerson = true
ENT.OpticsThirdPerson = false
ENT.OpticsPodIndex = {
	[1] = true,
}

ENT.OpticsProjectileSize = 7.5

local RotationOffset = 0
local circle = Material( "lvs/circle_hollow.png" )
local tri1 = Material( "lvs/triangle1.png" )
local tri2 = Material( "lvs/triangle2.png" )
local pointer = Material( "gui/point.png" )
local scope = Material( "lvs/scope_viewblocked.png" )

function ENT:PaintOpticsCrosshair( Pos2D )
	surface.SetDrawColor( 255, 255, 255, 5 )
	surface.SetMaterial( tri1 )
	surface.DrawTexturedRect( Pos2D.x - 17, Pos2D.y - 1, 32, 32 )
	surface.SetDrawColor( 0, 0, 0, 255 )
	surface.DrawTexturedRect( Pos2D.x - 16, Pos2D.y, 32, 32 )

	for i = -3, 3, 1 do
		if i == 0 then continue end

		surface.SetMaterial( tri2 )
		surface.SetDrawColor( 255, 255, 255, 5 )
		surface.DrawTexturedRect( Pos2D.x - 11 + i * 32, Pos2D.y - 1, 20, 20 )
		surface.SetDrawColor( 0, 0, 0, 255 )
		surface.DrawTexturedRect( Pos2D.x - 10 + i * 32, Pos2D.y, 20, 20 )
	end

	local ScrH = ScrH()

	local Y = Pos2D.y + 64
	local height = ScrH - Y

	surface.SetDrawColor( 0, 0, 0, 100 )
	surface.DrawRect( Pos2D.x - 2,  Y, 4, height )
end

ENT.OpticsCrosshairMaterial = Material( "lvs/circle_filled.png" )
ENT.OpticsCrosshairColor = Color(0,0,0,150)
ENT.OpticsCrosshairSize = 4

function ENT:PaintOptics( Pos2D, Col, PodIndex, Type )

	if Type == 1 then
		self:DrawRotatedText( "MG", Pos2D.x + 30, Pos2D.y + 30, "LVS_FONT_PANEL", Color(0,0,0,220), 0)
	else
		self:DrawRotatedText( Type == 3 and "HE" or "AP", Pos2D.x + 30, Pos2D.y + 30, "LVS_FONT_PANEL", Color(0,0,0,220), 0)
	end

	local size = self.OpticsCrosshairSize

	surface.SetMaterial( self.OpticsCrosshairMaterial )
	surface.SetDrawColor( self.OpticsCrosshairColor )
	surface.DrawTexturedRect( Pos2D.x - size * 0.5, Pos2D.y - size * 0.5, size, size )

	local ScrW = ScrW()
	local ScrH = ScrH()

	surface.SetDrawColor( 0, 0, 0, 200 )

	local TargetOffset = 0

	if OldTargetOffset ~= TargetOffset then
		OldTargetOffset = TargetOffset
		surface.PlaySound( "lvs/optics.wav" )
	end

	RotationOffset = RotationOffset + (TargetOffset + math.max( self:GetTurretCompensation() / 15, -130 ) - RotationOffset) * RealFrameTime() * 8

	local R = ScrH * 0.5 - 64
	local R0 = R + 30
	local R1 = R - 8
	local R2 = R - 23
	local R3 = R - 30
	local R4 = R - 18

	for i = 0, 40 do
		local ang = -90 + (180 / 40) * i + RotationOffset

		local x = math.cos( math.rad( ang ) )
		local y = math.sin( math.rad( ang ) )

		if i == 2 then
			self:DrawRotatedText( self.OpticsProjectileSize, Pos2D.x + x * R0, Pos2D.y + y * R0, "LVS_FONT", Color(0,0,0,200), 90 + ang)
		end
		if i == 3 then
			self:DrawRotatedText( "cm", Pos2D.x + x * R0, Pos2D.y + y * R0, "LVS_FONT", Color(0,0,0,200), 90 + ang)
		end
		if i == 5 then
			self:DrawRotatedText( "Pzgr", Pos2D.x + x * R0, Pos2D.y + y * R0, "LVS_FONT", Color(0,0,0,200), 90 + ang)
		end
	
		surface.SetMaterial( circle )
		surface.DrawTexturedRectRotated( Pos2D.x + x * R, Pos2D.y + y * R, 16, 16, 0 )

		surface.DrawLine( Pos2D.x + x * R1, Pos2D.y + y * R1, Pos2D.x + x * R2, Pos2D.y + y * R2 )

		self:DrawRotatedText( i, Pos2D.x + x * R3, Pos2D.y + y * R3, "LVS_FONT_PANEL", Color(0,0,0,255), ang + 90)

		if i == 40 then continue end

		local ang = - 90 + (180 / 40) * (i + 0.5) + RotationOffset

		local x = math.cos( math.rad( ang ) )
		local y = math.sin( math.rad( ang ) )

		surface.DrawLine( Pos2D.x + x * R1, Pos2D.y + y * R1, Pos2D.x + x * R4, Pos2D.y + y * R4 )
	end

	surface.SetDrawColor( 0, 0, 0, 100 )
	surface.SetMaterial( pointer )
	surface.DrawTexturedRect( Pos2D.x - 16, 0, 32, 64 )

	local diameter = ScrH + 64
	local radius = diameter * 0.5

	surface.SetMaterial( scope )
	surface.SetDrawColor( 0, 0, 0, 255 )
	surface.DrawTexturedRect( Pos2D.x - radius, Pos2D.y - radius, diameter, diameter )

	-- black bar left + right
	surface.DrawRect( 0, 0, Pos2D.x - radius, ScrH )
	surface.DrawRect( Pos2D.x + radius, 0, Pos2D.x - radius, ScrH )

end
