
LVS.HudEditors = LVS.HudEditors or {}

local function ResetFrame( id )
	if not LVS.HudEditors[ id ] then return end

	LVS.HudEditors[ id ].w = LVS.HudEditors[ id ].DefaultWidth
	LVS.HudEditors[ id ].h = LVS.HudEditors[ id ].DefaultHeight
	LVS.HudEditors[ id ].X = LVS.HudEditors[ id ].DefaultX
	LVS.HudEditors[ id ].Y = LVS.HudEditors[ id ].DefaultY
end

local function MakeFrame( id, X, Y, w, h, minw, minh, text )
	local Frame = vgui.Create("DFrame")
	Frame:SetSize( w, h )
	Frame:SetPos( X, Y)
	Frame:SetTitle("")
	Frame:SetScreenLock( true )
	Frame:MakePopup()
	Frame:SetSizable( true )
	Frame:SetMinWidth( minw )
	Frame:SetMinHeight( minh )
	Frame.id = id
	Frame.OnClose = function( self )
		ResetFrame( self.id )
	end
	Frame.Paint = function(self, w, h )
		surface.SetDrawColor(0,0,0,150)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(80,80,80,255)
		surface.DrawRect(0, 0, 2, h)
		surface.DrawRect(w - 2, 0, 2, h)
		surface.DrawRect(0, 0, w, 2)
		surface.DrawRect(0, h - 2, w, 2)

		draw.DrawText( text, "LVS_FONT", w * 0.5 - 24, h * 0.5 - 12, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		if not LVS.HudEditors[ self.id ] then return end

		LVS.HudEditors[ self.id ].w = self:GetWide()
		LVS.HudEditors[ self.id ].h = self:GetTall()

		LVS.HudEditors[ self.id ].X = self:GetX()
		LVS.HudEditors[ self.id ].Y = self:GetY()
	end

	LVS.HudEditors[ id ].Frame = Frame

	return Frame
end

local function SaveEditors()
end

function LVS:AddHudEditor( id, X, Y, w, h, minw, minh, text, func )
	LVS.HudEditors[ id ] = {
		DefaultX = X,
		DefaultY = Y,
		DefaultWidth = w,
		DefaultHeight = h,
		X = X,
		Y = Y,
		w = w,
		h = h,
		minw = minw,
		minh = minh,
		text = text,
		func = func,
	}
end

--hook.Add( "LVS:Initialize", "!!!!lvs_addSwitchers", function()
	LVS:AddHudEditor( "SeatSwitcher", ScrW() - 360, ScrH() - 40,  350, 30, 350, 30, "LVS SEAT SWITCHER", 
		function( self, vehicle, X, Y, W, H, ScrX, ScrY, ply )
			if not vehicle.LVSHudPaintSeatSwitcher then return end

			vehicle:LVSHudPaintSeatSwitcher( X, Y, W, H, ScrX, ScrY, ply )
		end
	)

	LVS:AddHudEditor( "WeaponSwitcher", 500, 500,  350, 200, 350, 200, "LVS WEAPON SELECTOR", 
		function( self, vehicle, X, Y, W, H, ScrX, ScrY, ply )
			--if not vehicle.LVSHudPaintSeatSwitcher then return end
			--vehicle:LVSHudPaintSeatSwitcher( X, Y, W, H, ScrX, ScrY, ply )
		end
	)
--end )

hook.Add( "InitPostEntity", "!!!lvs_load_hud", function()
end )

hook.Add( "OnContextMenuOpen", "!!!!!LVS_hud", function()
	if not IsValid( LocalPlayer():lvsGetVehicle() ) then return end

	for id, editor in pairs( LVS.HudEditors ) do
		if IsValid( editor.Frame ) then continue end

		MakeFrame( id, editor.X, editor.Y, editor.w, editor.h, editor.minw, editor.minh, editor.text )
	end
end )

function LVS:CloseEditors()
	for id, editor in pairs( LVS.HudEditors ) do
		if not IsValid( editor.Frame ) then continue end
		editor.Frame:Remove()
	end
end

hook.Add( "OnContextMenuClose", "!!!!!LVS_hud", function()
	LVS:CloseEditors()
end )

hook.Add( "HUDPaint", "!!!!!LVS_hud", function()
	local ply = LocalPlayer()

	if ply:GetViewEntity() ~= ply then return end

	local Pod = ply:GetVehicle()
	local Parent = ply:lvsGetVehicle()

	if not IsValid( Pod ) or not IsValid( Parent ) then
		ply._lvsoldPassengers = {}

		return
	end

	local X = ScrW()
	local Y = ScrH()

	Parent:LVSHudPaint( X, Y, ply )

	for id, editor in pairs( LVS.HudEditors ) do
		local ScaleX = editor.w / editor.DefaultWidth
		local ScaleY = editor.h / editor.DefaultHeight

		local PosX = editor.X / ScaleX
		local PosY = editor.Y / ScaleY

		local Width = editor.w / ScaleX
		local Height = editor.h / ScaleY

		local ScrW = X / ScaleX
		local ScrH = Y / ScaleY

		local m = Matrix()
		m:Scale( Vector( ScaleX, ScaleY, 1 ) )

		cam.PushModelMatrix( m )
			editor:func( Parent, PosX, PosY, Width, Height, ScrW, ScrH, ply )
		cam.PopModelMatrix()
	end
end )