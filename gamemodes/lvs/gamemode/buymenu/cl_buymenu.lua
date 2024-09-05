
local function BuildBuyMenu()
	if IsValid( BuyMenu ) then return BuyMenu end

	local FrameX = math.min( ScrW(), 1200 )
	local FrameY = math.min( ScrH(), 800 )

	BuyMenu = vgui.Create("DFrame")
	BuyMenu:SetSize( FrameX, FrameY )
	BuyMenu:Center()
	BuyMenu:SetTitle("")
	BuyMenu:SetDraggable( false )
	--BuyMenu:ShowCloseButton( false )
	BuyMenu:DockPadding(0,24,0,0)
	BuyMenu.Paint = function(self, w, h )
		draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 255 ) )
		draw.RoundedBoxEx( 8, 1, 26, w-2, h-27, Color( 120, 120, 120, 255 ), false, false, true, true )
		draw.RoundedBoxEx( 8, 0, 0, w, 25, LVS.ThemeColor, true, true )

		draw.SimpleText( "[LVS] - Vehicle Store", "LVS_FONT", 5, 11, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	end
	BuyMenu.OnClose = function( self )
		gui.EnableScreenClicker( false )
	end

	local CategoryPanel = vgui.Create( "DPanel", BuyMenu )
	CategoryPanel:SetSize(FrameX * 0.15,FrameY)
	CategoryPanel:Dock( LEFT )
	CategoryPanel:DockMargin(0,0,0,0)
	CategoryPanel:DockPadding(10,10,5,10)
	CategoryPanel.Paint = function(self, w, h )
	end

	local MainPanel = vgui.Create( "DPanel", BuyMenu )
	MainPanel:SetSize(FrameX * 0.85,FrameY)
	MainPanel:Dock( RIGHT )
	MainPanel:DockMargin(0,0,0,0)
	MainPanel:DockPadding(15,20,10,20)
	MainPanel.Paint = function(self, w, h )
		draw.RoundedBox( 5, 5, 10, w - 15, h - 20, color_white )
	end

	local ContentPanel = vgui.Create( "DScrollPanel", MainPanel )
	ContentPanel:Dock( FILL )
	ContentPanel.Paint = function(self, w, h )
	end
	function ContentPanel:SetContent( Vehicles )
		local Canvas = self:GetCanvas()

		self:SetPaintBackground( false )

		Canvas:Clear()

		local TileLayout = vgui.Create("DTileLayout", Canvas)
		TileLayout:SetBaseSize( 140 )
		TileLayout:Dock( TOP )

		for i=1, #Vehicles do
			local obj = Vehicles[ i ]

			local DButton = TileLayout:Add( "DButtonLVS" )
			DButton:SetSize( 128, 128 )
			DButton:SetName( obj.nicename )
			DButton:SetClassName( obj.classname )
			DButton:SetPrice( GAMEMODE:GetVehiclePrice( obj.classname ) )
			DButton:SetAdminOnly( obj.admin )
			DButton:SetMaterial( obj.material )
		end
	end

	local lvsNode  = vgui.Create( "DTree", CategoryPanel )
	lvsNode:Dock( FILL )
	lvsNode.Paint = function(self, w, h )
		draw.RoundedBox( 5, 0, 0, w, h, color_white )
	end

	local ply = LocalPlayer()

	local CategoryNameTranslate = {}
	local Categorised = {}
	local SubCategorised = {}

	local SpawnableEntities = table.Copy( list.Get( "SpawnableEntities" ) )
	local Variants = {
		[1] = "[LVS] - ",
		[2] = "[LVS] -",
		[3] = "[LVS]- ",
		[4] = "[LVS]-",
		[5] = "[LVS] ",
	}

	for _, v in pairs( scripted_ents.GetList() ) do
		if not v.t or not v.t.ClassName or not v.t.VehicleCategory then continue end

		if not isstring( v.t.ClassName ) or v.t.ClassName == "" or not SpawnableEntities[ v.t.ClassName ] then continue end

		SpawnableEntities[ v.t.ClassName ].Category = "[LVS] - "..v.t.VehicleCategory

		if not v.t.VehicleSubCategory then continue end

		SpawnableEntities[ v.t.ClassName ].SubCategory = v.t.VehicleSubCategory
	end

	if SpawnableEntities then
		for k, v in pairs( SpawnableEntities ) do

			local Category = v.Category

			if not isstring( Category ) then continue end

			if not Category:StartWith( "[LVS]" ) and not v.LVS then continue end

			v.SpawnName = k

			for _, start in pairs( Variants ) do
				if Category:StartWith( start ) then
					local NewName = string.Replace(Category, start, "")
					CategoryNameTranslate[ NewName ] = Category
					Category = NewName

					break
				end
			end

			if v.SubCategory then
				SubCategorised[ Category ] = SubCategorised[ Category ] or {}
				SubCategorised[ Category ][ v.SubCategory ] = SubCategorised[ Category ][ v.SubCategory ] or {}

				table.insert( SubCategorised[ Category ][ v.SubCategory ], v )
			end

			Categorised[ Category ] = Categorised[ Category ] or {}

			table.insert( Categorised[ Category ], v )
		end
	end

	local IconList = list.Get( "ContentCategoryIcons" )

	for CategoryName, v in SortedPairs( Categorised ) do
		if CategoryName:StartWith( "[LVS]" ) then continue end

		local Icon = "icon16/lvs_noicon.png"

		if IconList and IconList[ CategoryNameTranslate[ CategoryName ] ] then
			Icon = IconList[ CategoryNameTranslate[ CategoryName ] ]
		end

		local node = lvsNode:AddNode( CategoryName, Icon )
		node.DoClick = function( self )
			local Vehicles = {}
			local Index = 1

			for k, ent in SortedPairsByMemberValue( v, "PrintName" ) do
				if ent.SubCategory then
					continue
				end

				if not ply:VehicleClassAllowed( ent.ClassName ) then continue end

				Vehicles[ Index ] = {
					nicename	= ent.PrintName or ent.ClassName,
					classname = ent.ClassName,
					spawnname	= ent.SpawnName,
					material	= ent.IconOverride or "entities/" .. ent.SpawnName .. ".png",
					admin		= ent.AdminOnly
				}
				Index = Index + 1
			end

			ContentPanel:SetContent( Vehicles )
		end

		local SubCat = SubCategorised[ CategoryName ]

		if not SubCat then continue end

		for SubName, data in SortedPairs( SubCat ) do

			local SubIcon = "icon16/lvs_noicon.png"

			if IconList then
				if IconList[ "[LVS] - "..CategoryName.." - "..SubName ] then
					SubIcon = IconList[ "[LVS] - "..CategoryName.." - "..SubName ]
				else
					if IconList[ "[LVS] - "..SubName ] then
						SubIcon = IconList[ "[LVS] - "..SubName ]
					end
				end
			end

			local subnode = node:AddNode( SubName, SubIcon )
			subnode.DoClick = function( self )
				local Vehicles = {}
				local Index = 1

				for k, ent in SortedPairsByMemberValue( data, "PrintName" ) do
					if not ply:VehicleClassAllowed( ent.ClassName ) then continue end

					Vehicles[ Index ] = {
						nicename	= ent.PrintName or ent.ClassName,
						classname = ent.ClassName,
						spawnname	= ent.SpawnName,
						material	= ent.IconOverride or "entities/" .. ent.SpawnName .. ".png",
						admin		= ent.AdminOnly
					}

					Index = Index + 1
				end

				ContentPanel:SetContent( Vehicles )
			end
		end
	end

	-- CONTROLS
	local node = lvsNode:AddNode( "Controls", "icon16/keyboard.png" )
	node.DoClick = function( self )
		LVS:OpenMenu()
		LVS:OpenClientControls()
	end

	-- CLIENT SETTINGS
	local node = lvsNode:AddNode( "Client Settings", "icon16/wrench.png" )
	node.DoClick = function( self )
		LVS:OpenMenu()
		LVS:OpenClientSettings()
	end

	-- SERVER SETTINGS
	local node = lvsNode:AddNode( "Server Settings", "icon16/wrench_orange.png" )
	node.DoClick = function( self )
		if LocalPlayer():IsSuperAdmin() then
			LVS:OpenMenu()
			LVS:OpenServerMenu()
		else
			surface.PlaySound( "buttons/button11.wav" )
		end
	end

	return BuyMenu
end

function GM:OpenBuyMenu()
	if LocalPlayer():Team() == TEAM_SPECTATOR then
		GAMEMODE:OpenJoinMenu()

		return
	end

	gui.EnableScreenClicker( true )

	BuildBuyMenu():SetVisible( true )
end

function GM:CloseBuyMenu()
	if not IsValid( BuyMenu ) then return end

	gui.EnableScreenClicker( false )

	BuyMenu:SetVisible( false )
end

function GM:ResetBuyMenu()
	if not IsValid( BuyMenu ) then return end

	BuyMenu:Remove()
	BuyMenu = nil
end

concommand.Add( "buymenu_reload", function( ply, cmd, args )
	GAMEMODE:ResetBuyMenu()
end )
