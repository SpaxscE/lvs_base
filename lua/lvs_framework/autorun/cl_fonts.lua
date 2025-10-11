local THE_FONT = {
	font = "Verdana",
	extended = false,
	size = 14,
	weight = 600,
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
surface.CreateFont( "LVS_VERSION", THE_FONT )

THE_FONT.extended = false
THE_FONT.size = 20
THE_FONT.weight = 2000
surface.CreateFont( "LVS_FONT", THE_FONT )

THE_FONT.size = 16
surface.CreateFont( "LVS_FONT_SWITCHER", THE_FONT )

THE_FONT.font = "Arial"
THE_FONT.size = 14
THE_FONT.weight = 1
THE_FONT.shadow = false
surface.CreateFont( "LVS_FONT_PANEL", THE_FONT )

THE_FONT.size = 20
THE_FONT.weight = 2000
surface.CreateFont( "LVS_FONT_HUD", THE_FONT )

THE_FONT.size = 40
THE_FONT.weight = 2000
THE_FONT.shadow = true
surface.CreateFont( "LVS_FONT_HUD_LARGE", THE_FONT )

THE_FONT.size = 80
surface.CreateFont( "LVS_FONT_HUD_HUMONGOUS", THE_FONT )