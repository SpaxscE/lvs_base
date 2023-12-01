
hook.Add( "PopulateVehicles", "!!!add_lvs_to_vehicles", function( pnlContent, tree, node )
	local Categorised = {}

	local SpawnableEntities = list.Get( "SpawnableEntities" )
	local Variants = {
		[1] = "[LVS] - ",
		[2] = "[LVS] -",
		[3] = "[LVS]- ",
		[4] = "[LVS]-",
		[5] = "[LVS] ",
	}
	local originalName = {}

	if SpawnableEntities then
		for k, v in pairs( SpawnableEntities ) do

			local Category = v.Category

			if not isstring( Category ) then continue end

			if not Category:StartWith( "[LVS]" ) and not v.LVS then continue end

			v.SpawnName = k

			for _, start in pairs( Variants ) do
				if Category:StartWith( start ) then
					local NewName = string.Replace(Category, start, "")
					originalName[ NewName ] = Category
					Category = NewName

					break
				end
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

		if IconList and IconList[ originalName[ CategoryName ] ] then
			Icon = IconList[ originalName[ CategoryName ] ]
		end

		local node = lvsNode:AddNode( CategoryName, Icon )

		node.DoPopulate = function( self )
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
		node.DoClick = function( self )
			self:DoPopulate()
			pnlContent:SwitchPanel( self.PropPanel )
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
end )

list.Set( "ContentCategoryIcons", "[LVS]", "icon16/lvs.png" )
list.Set( "ContentCategoryIcons", "[LVS] - Cars", "icon16/lvs_cars.png" )
list.Set( "ContentCategoryIcons", "[LVS] - Cars - Pack", "icon16/lvs_cars_pack.png" )
list.Set( "ContentCategoryIcons", "[LVS] - Helicopters", "icon16/lvs_helicopters.png" )
list.Set( "ContentCategoryIcons", "[LVS] - Planes", "icon16/lvs_planes.png" )
list.Set( "ContentCategoryIcons", "[LVS] - Star Wars", "icon16/lvs_starwars.png" )
