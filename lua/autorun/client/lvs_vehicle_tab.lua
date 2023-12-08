
hook.Add( "PopulateVehicles", "!!!add_lvs_to_vehicles", function( pnlContent, tree, node )
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

	local lvsNode = tree:AddNode( "[LVS]", "icon16/lvs.png" )

	if Categorised["[LVS]"] then
		local v = Categorised["[LVS]"]

		lvsNode.DoPopulate = function( self )
			if self.PropPanel then return end

			self.PropPanel = vgui.Create( "ContentContainer", pnlContent )
			self.PropPanel:SetVisible( false )
			self.PropPanel:SetTriggerSpawnlistChange( false )

			for k, ent in SortedPairsByMemberValue( v, "PrintName" ) do
				spawnmenu.CreateContentIcon( ent.ScriptedEntityType or "entity", self.PropPanel, {
					nicename	= ent.PrintName or ent.ClassName,
					spawnname	= ent.SpawnName,
					material	= ent.IconOverride or "entities/" .. ent.SpawnName .. ".png",
					admin		= ent.AdminOnly
				} )
			end
		end

		lvsNode.DoClick = function( self )
			self:DoPopulate()
			pnlContent:SwitchPanel( self.PropPanel )
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

		node.DoPopulate = function( self )
			if self.PropPanel then return end

			self.PropPanel = vgui.Create( "ContentContainer", pnlContent )
			self.PropPanel:SetVisible( false )
			self.PropPanel:SetTriggerSpawnlistChange( false )

			for k, ent in SortedPairsByMemberValue( v, "PrintName" ) do
				if ent.SubCategory then
					continue
				end

				spawnmenu.CreateContentIcon( ent.ScriptedEntityType or "entity", self.PropPanel, {
					nicename	= ent.PrintName or ent.ClassName,
					spawnname	= ent.SpawnName,
					material	= ent.IconOverride or "entities/" .. ent.SpawnName .. ".png",
					admin		= ent.AdminOnly
				} )
			end
		end
		node.DoClick = function( self )
			self:DoPopulate()
			pnlContent:SwitchPanel( self.PropPanel )
		end

		local SubCat = SubCategorised[ CategoryName ]

		if not SubCat then continue end

		for SubName, data in pairs( SubCat ) do

			local SubIcon = "icon16/lvs_noicon.png"

			if IconList and IconList[ "[LVS] - "..SubName ] then
				SubIcon = IconList[ "[LVS] - "..SubName ]
			end

			local subnode = node:AddNode( SubName, SubIcon )

			subnode.DoPopulate = function( self )
				if self.PropPanel then return end

				self.PropPanel = vgui.Create( "ContentContainer", pnlContent )
				self.PropPanel:SetVisible( false )
				self.PropPanel:SetTriggerSpawnlistChange( false )

				for k, ent in SortedPairsByMemberValue( data, "PrintName" ) do
					spawnmenu.CreateContentIcon( ent.ScriptedEntityType or "entity", self.PropPanel, {
						nicename	= ent.PrintName or ent.ClassName,
						spawnname	= ent.SpawnName,
						material	= ent.IconOverride or "entities/" .. ent.SpawnName .. ".png",
						admin		= ent.AdminOnly
					} )
				end
			end
			subnode.DoClick = function( self )
				self:DoPopulate()
				pnlContent:SwitchPanel( self.PropPanel )
			end
		end
	end

	-- User Stuff
	hook.Run( "LVS.PopulateVehicles", lvsNode, pnlContent, tree )

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
end )

list.Set( "ContentCategoryIcons", "[LVS]", "icon16/lvs.png" )
list.Set( "ContentCategoryIcons", "[LVS] - Cars", "icon16/lvs_cars.png" )
list.Set( "ContentCategoryIcons", "[LVS] - Cars - Pack", "icon16/lvs_cars_pack.png" )

list.Set( "ContentCategoryIcons", "[LVS] - Combine", "icon16/lvs_combine.png" )
list.Set( "ContentCategoryIcons", "[LVS] - Resistance", "icon16/lvs_resistance.png" )

list.Set( "ContentCategoryIcons", "[LVS] - Armored", "icon16/lvs_armor.png" )
list.Set( "ContentCategoryIcons", "[LVS] - Civilian", "icon16/lvs_civilian.png" )
list.Set( "ContentCategoryIcons", "[LVS] - Military", "icon16/lvs_military.png" )

list.Set( "ContentCategoryIcons", "[LVS] - Bombers", "icon16/lvs_bomb.png" )
list.Set( "ContentCategoryIcons", "[LVS] - Fighters", "icon16/lvs_fighter.png" )

list.Set( "ContentCategoryIcons", "[LVS] - Helicopters", "icon16/lvs_helicopters.png" )
list.Set( "ContentCategoryIcons", "[LVS] - Planes", "icon16/lvs_planes.png" )

list.Set( "ContentCategoryIcons", "[LVS] - Tanks", "icon16/lvs_tanks.png" )
list.Set( "ContentCategoryIcons", "[LVS] - Light", "icon16/lvs_light.png" )
list.Set( "ContentCategoryIcons", "[LVS] - Medium", "icon16/lvs_medium.png" )
list.Set( "ContentCategoryIcons", "[LVS] - Heavy", "icon16/lvs_heavy.png" )

list.Set( "ContentCategoryIcons", "[LVS] - Artillery", "icon16/lvs_artillery.png" )

list.Set( "ContentCategoryIcons", "[LVS] - Star Wars", "icon16/lvs_starwars.png" )
list.Set( "ContentCategoryIcons", "[LVS] - Gunships", "icon16/lvs_sw_gunship.png" )
list.Set( "ContentCategoryIcons", "[LVS] - Hover Tanks", "icon16/lvs_sw_hover.png" )
list.Set( "ContentCategoryIcons", "[LVS] - Walkers", "icon16/lvs_sw_walker.png" )
list.Set( "ContentCategoryIcons", "[LVS] - Starfighters", "icon16/lvs_sw_starfighter.png" )
