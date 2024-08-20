local blur = Material("pp/blurscreen")

function GM:OpenJoinMenu()
	local ply = LocalPlayer()

	self:CloseJoinMenu()

	local X = ScrW()
	local Y = ScrH()

	local Canvas = vgui.Create( "DFrame" )
	Canvas:SetPos( 0, 0 )
	Canvas:SetSize( X, Y )
	Canvas:SetTitle( "" )
	Canvas:SetDraggable( false )
	Canvas:SetScreenLock( true )
	Canvas:MakePopup()
	Canvas:Center()
	Canvas:DockPadding( 0, 25, 0, 0 )
	Canvas.Paint = function(self, w, h )
		surface.SetMaterial( blur )

		blur:SetFloat( "$blur", 5 )
		blur:Recompute()

		if render then render.UpdateScreenEffectTexture() end

		surface.SetDrawColor( 255, 255, 255, 255 )

		surface.DrawTexturedRect( 0, 0, w, h )

		surface.SetDrawColor( LVS.ThemeColor )
		surface.DrawRect( 0, 0, w, 25 )

		draw.SimpleText( "[LVS] - Tournament", "LVS_FONT", 5, 11, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	end

	self.JoinBar = Canvas

	local PaddingW = (X - 400) * 0.5
	local PaddingH = (Y - 25 - 300) * 0.5

	local MainCanvas = vgui.Create("DPanel", Canvas )
	MainCanvas:Dock( FILL )
	MainCanvas:DockPadding( PaddingW, PaddingH, PaddingW, PaddingH )
	MainCanvas:SetPaintBackground( false )

	local CenterMenu = vgui.Create("DPanel", MainCanvas )
	CenterMenu:Dock( FILL )
	CenterMenu:DockPadding( 1, 1, 1, 1 )
	CenterMenu.Paint = function(self, w, h )
		surface.SetDrawColor( Color( 0, 0, 0, 255 ) )
		surface.DrawRect(0, 0, w, h)
	end

	local CenterTop = vgui.Create("DPanel", CenterMenu )
	CenterTop:Dock( TOP )
	CenterTop:SetSize( 400, 200 )
	CenterTop:SetPaintBackground( false )

	local CenterBottom = vgui.Create("DPanel", CenterMenu )
	CenterBottom:Dock( BOTTOM )
	CenterBottom:SetSize( 400, 98 )
	CenterBottom:SetPaintBackground( false )

	local ButtonTeam1 = vgui.Create( "DButton", CenterTop )
	ButtonTeam1:SetSize( 398, 98 )
	ButtonTeam1:SetText( "#lvs_swap_team" )
	ButtonTeam1:Dock( FILL )
	function ButtonTeam1:DoClick()
		GAMEMODE:CloseJoinMenu()

		if ply:Team() == TEAM_SPECTATOR then
			local NumTeam1 = #GAMEMODE:GameGetPlayersTeam1()
			local NumTeam2 = #GAMEMODE:GameGetPlayersTeam2()

			if NumTeam1 == NumTeam2 then
				RunConsoleCommand( "changeteam", math.random(1,2) )
			else
				if NumTeam1 < NumTeam2 then
					RunConsoleCommand( "changeteam", 1 )
				else
					RunConsoleCommand( "changeteam", 2 )
				end
			end
		else
			if ply:lvsGetAITeam() == 1 then
				RunConsoleCommand( "changeteam", 2 )
			else
				RunConsoleCommand( "changeteam", 1 )
			end
		end
	end

	local ButtonSpectate = vgui.Create( "DButton", CenterBottom )
	ButtonSpectate:SetText( "#lvs_join_team_spectator" )
	ButtonSpectate:Dock( FILL )
	function ButtonSpectate:DoClick()
		GAMEMODE:CloseJoinMenu()

		RunConsoleCommand( "changeteam", TEAM_SPECTATOR )
	end
end

function GM:CloseJoinMenu()
	if IsValid( self.JoinBar ) then
		self.JoinBar:Remove()
	end
end
