
local default_animations = { "idle_all_01", "menu_walk" }

function GM:OpenPlayerEditor()
	local window = vgui.Create("DFrame")
	window:SetSize(  960, 700 )
	window:SetTitle( "" )
	window:SetSize( math.min( ScrW() - 16, window:GetWide() ), math.min( ScrH() - 16, window:GetTall() ) )
	window:SetSizable( true )
	window:SetMinWidth( window:GetWide() )
	window:SetMinHeight( window:GetTall() )
	window:Center()
	window:MakePopup()
	window.Paint = function(self, w, h )
		draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 255 ) )
		draw.RoundedBoxEx( 8, 1, 26, w-2, h-27, Color( 120, 120, 120, 255 ), false, false, true, true )
		draw.RoundedBoxEx( 8, 0, 0, w, 25, LVS.ThemeColor, true, true )

		draw.SimpleText( "#smwidget.playermodel_title", "LVS_FONT", 5, 11, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	end

	local mdl = window:Add( "DModelPanel" )
	mdl:Dock( FILL )
	mdl:SetFOV( 36 )
	mdl:SetCamPos( vector_origin )
	mdl:SetDirectionalLight( BOX_RIGHT, Color( 255, 160, 80, 255 ) )
	mdl:SetDirectionalLight( BOX_LEFT, Color( 80, 160, 255, 255 ) )
	mdl:SetAmbientLight( Vector( -64, -64, -64 ) )
	mdl:SetAnimated( true )
	mdl.Angles = angle_zero
	mdl:SetLookAt( Vector( -100, 0, -22 ) )

	local sheet = window:Add( "DPropertySheet" )
	sheet:Dock( RIGHT )
	sheet:SetSize( 430, 0 )

	local modelListPnl = window:Add( "DPanel" )
	modelListPnl:DockPadding( 8, 8, 8, 8 )

	local SearchBar = modelListPnl:Add( "DTextEntry" )
	SearchBar:Dock( TOP )
	SearchBar:DockMargin( 0, 0, 0, 8 )
	SearchBar:SetUpdateOnType( true )
	SearchBar:SetPlaceholderText( "#spawnmenu.quick_filter" )

	local PanelSelect = modelListPnl:Add( "DPanelSelect" )
	PanelSelect:Dock( FILL )

	for name, model in SortedPairs( player_manager.AllValidModels() ) do

		local icon = vgui.Create( "SpawnIcon" )
		icon:SetModel( model )
		icon:SetSize( 64, 64 )
		icon:SetTooltip( name )
		icon.playermodel = name
		icon.model_path = model
		icon.OpenMenu = function( button )
			local menu = DermaMenu()
			menu:AddOption( "#spawnmenu.menu.copy", function() SetClipboardText( model ) end ):SetIcon( "icon16/page_copy.png" )
			menu:Open()
		end

		PanelSelect:AddPanel( icon, { cl_playermodel = name } )

	end

	SearchBar.OnValueChange = function( s, str )
		for id, pnl in pairs( PanelSelect:GetItems() ) do
			if ( !pnl.playermodel:find( str, 1, true ) && !pnl.model_path:find( str, 1, true ) ) then
				pnl:SetVisible( false )
			else
				pnl:SetVisible( true )
			end
		end
		PanelSelect:InvalidateLayout()
	end

	sheet:AddSheet( "#smwidget.model", modelListPnl, "icon16/user.png" )

	local bdcontrols = window:Add( "DPanel" )
	bdcontrols:DockPadding( 8, 8, 8, 8 )

	local bdcontrolspanel = bdcontrols:Add( "DPanelList" )
	bdcontrolspanel:EnableVerticalScrollbar()
	bdcontrolspanel:Dock( FILL )

	local bgtab = sheet:AddSheet( "#smwidget.bodygroups", bdcontrols, "icon16/cog.png" )

	-- Helper functions
	local function PlayPreviewAnimation( panel, playermodel )

		if ( !panel or !IsValid( panel.Entity ) ) then return end

		local anims = list.Get( "PlayerOptionsAnimations" )

		local anim = default_animations[ math.random( 1, #default_animations ) ]
		if ( anims[ playermodel ] ) then
			anims = anims[ playermodel ]
			anim = anims[ math.random( 1, #anims ) ]
		end

		local iSeq = panel.Entity:LookupSequence( anim )
		if ( iSeq > 0 ) then panel.Entity:ResetSequence( iSeq ) end

	end

	-- Updating
	local function UpdateBodyGroups( pnl, val )
		if ( pnl.type == "bgroup" ) then

			mdl.Entity:SetBodygroup( pnl.typenum, math.Round( val ) )

			local str = string.Explode( " ", GetConVarString( "cl_playerbodygroups" ) )
			if ( #str < pnl.typenum + 1 ) then for i = 1, pnl.typenum + 1 do str[ i ] = str[ i ] or 0 end end
			str[ pnl.typenum + 1 ] = math.Round( val )
			RunConsoleCommand( "cl_playerbodygroups", table.concat( str, " " ) )

		elseif ( pnl.type == "skin" ) then

			mdl.Entity:SetSkin( math.Round( val ) )
			RunConsoleCommand( "cl_playerskin", math.Round( val ) )

		end
	end

	local function RebuildBodygroupTab()
		bdcontrolspanel:Clear()

		bgtab.Tab:SetVisible( false )

		local nskins = mdl.Entity:SkinCount() - 1
		if ( nskins > 0 ) then
			local skins = vgui.Create( "DNumSlider" )
			skins:Dock( TOP )
			skins:SetText( "Skin" )
			skins:SetDark( true )
			skins:SetTall( 50 )
			skins:SetDecimals( 0 )
			skins:SetMax( nskins )
			skins:SetValue( GetConVarNumber( "cl_playerskin" ) )
			skins.type = "skin"
			skins.OnValueChanged = UpdateBodyGroups

			bdcontrolspanel:AddItem( skins )

			mdl.Entity:SetSkin( GetConVarNumber( "cl_playerskin" ) )

			bgtab.Tab:SetVisible( true )
		end

		local groups = string.Explode( " ", GetConVarString( "cl_playerbodygroups" ) )
		for k = 0, mdl.Entity:GetNumBodyGroups() - 1 do
			if ( mdl.Entity:GetBodygroupCount( k ) <= 1 ) then continue end

			local bgroup = vgui.Create( "DNumSlider" )
			bgroup:Dock( TOP )
			bgroup:SetText( string.NiceName( mdl.Entity:GetBodygroupName( k ) ) )
			bgroup:SetDark( true )
			bgroup:SetTall( 50 )
			bgroup:SetDecimals( 0 )
			bgroup.type = "bgroup"
			bgroup.typenum = k
			bgroup:SetMax( mdl.Entity:GetBodygroupCount( k ) - 1 )
			bgroup:SetValue( groups[ k + 1 ] or 0 )
			bgroup.OnValueChanged = UpdateBodyGroups

			bdcontrolspanel:AddItem( bgroup )

			mdl.Entity:SetBodygroup( k, groups[ k + 1 ] or 0 )

			bgtab.Tab:SetVisible( true )
		end

		sheet.tabScroller:InvalidateLayout()
	end

	local function UpdateFromConvars()

		local model = LocalPlayer():GetInfo( "cl_playermodel" )
		local modelname = player_manager.TranslatePlayerModel( model )
		util.PrecacheModel( modelname )
		mdl:SetModel( modelname )
		mdl.Entity.GetPlayerColor = function() return LocalPlayer():GetPlayerColor() end
		mdl.Entity:SetPos( Vector( -100, 0, -61 ) )

		PlayPreviewAnimation( mdl, model )
		RebuildBodygroupTab()

	end

	UpdateFromConvars()

	function PanelSelect:OnActivePanelChanged( old, new )

		if ( old != new ) then -- Only reset if we changed the model
			RunConsoleCommand( "cl_playerbodygroups", "0" )
			RunConsoleCommand( "cl_playerskin", "0" )
		end

		timer.Simple( 0.1, function() UpdateFromConvars() end )

	end

	-- Hold to rotate

	function mdl:DragMousePress()
		self.PressX, self.PressY = input.GetCursorPos()
		self.Pressed = true
	end

	function mdl:DragMouseRelease() self.Pressed = false end

	function mdl:LayoutEntity( ent )
		if ( self.bAnimated ) then self:RunAnimation() end

		if ( self.Pressed ) then
			local mx, my = input.GetCursorPos()
			self.Angles = self.Angles - Angle( 0, ( ( self.PressX or mx ) - mx ) / 2, 0 )

			self.PressX, self.PressY = mx, my
		end

		ent:SetAngles( self.Angles )
	end
end

concommand.Add( "player_editor", function()
	GAMEMODE:OpenPlayerEditor()
end)