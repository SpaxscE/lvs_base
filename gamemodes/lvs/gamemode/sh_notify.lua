if SERVER then
	util.AddNetworkString( "lvs_popup_notifications" )

	local meta = FindMetaTable( "Player" )

	function meta:SendGameNotify( text, color, lifetime )
		net.Start( "lvs_popup_notifications" )
			net.WriteString( text or "" )
			net.WriteColor( color or color_white )
			net.WriteFloat( lifetime or 5 )
		net.Send( self )
	end

	function GM:SendGameNotify( text, color, lifetime )
		net.Start( "lvs_popup_notifications" )
			net.WriteString( text or "" )
			net.WriteColor( color or color_white )
			net.WriteFloat( lifetime or 5 )
		net.Broadcast()
	end

	return
end

local THE_FONT = {
	font = "Verdana",
	extended = false,
	size = 50,
	weight = 2000,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = true,
	additive = false,
	outline = false,
}
surface.CreateFont( "LVS_FONT_SUPERBIG", THE_FONT )

local IconCenter = Material("materials/lvs/tournament/physgun_a.png")
local IconLeft = Material("materials/lvs/tournament/physgun_b.png")
local IconRight = Material("materials/lvs/tournament/physgun_c.png")

local function MakePopUp( Text, Col, LifeTime )
	local DPanel = vgui.Create( "DPanel" )
	DPanel:SetPos( 0, 0 )
	DPanel:SetSize( ScrW(), ScrH() )

	DPanel.LifeTime = LifeTime or 5
	DPanel.DieTime = CurTime() + DPanel.LifeTime

	DPanel.Text = Text or "no text"
	DPanel.Col = Col or color_white

	DPanel.Think = function( self )
		local T = CurTime()

		self._MulValue = (self.DieTime - T) / self.LifeTime

		if self.DieTime > T then return end

		self:Remove()
	end
	DPanel.GetValue = function( self )
		if not self._MulValue then return 1 end

		return math.Clamp(1 - self._MulValue,0,1)
	end
	DPanel.Paint = function(self, X, Y )
		local Border = 15

		local Mul = self:GetValue()

		local text = self.Text
		local col = self.Col

		if not text or not col then return end

		local font = "LVS_FONT_SUPERBIG"

		surface.SetFont( font )

		local w, h = surface.GetTextSize( text )

		local AlphaMul = math.min( math.sin( Mul * math.pi ) * self.LifeTime * 2, 1 )

		w = w * AlphaMul
		h = h * AlphaMul

		local x = X * 0.5
		local y = Y * 0.5 - h * 0.5

		draw.RoundedBox( Border, x - w * 0.5 - Border, y - Border, w + Border * 2, h + Border * 2, Color( 0, 0, 0, 200 * AlphaMul ) )
	
		if AlphaMul < 1 then return end

		draw.SimpleText( text, font, x - w * 0.5, y, Color( col.r, col.g, col.b, col.a * AlphaMul ) )
	end
end

net.Receive( "lvs_popup_notifications", function( len )
	surface.PlaySound( "common/bugreporter_succeeded.wav" )

	MakePopUp( net.ReadString(), net.ReadColor(), net.ReadFloat() )
end )
