
hook.Add( "PopulateVehicles", "!!!add_lvs_to_vehicles", function( pnlContent, tree, node )
	local Categorised = {}
	local CarsSubCategories

	local SpawnableEntities = list.Get( "SpawnableEntities" )
	local Variants = {
		[1] = "[LVS] - ",
		[2] = "[LVS] -",
		[3] = "[LVS]- ",
		[4] = "[LVS]-",
		[5] = "[LVS] ",
	}

	if SpawnableEntities then
		for k, v in pairs( SpawnableEntities ) do

			local Category = v.Category

			if not isstring( Category ) then continue end

			if not Category:StartWith( "[LVS]" ) and not v.LVS then continue end

			v.SpawnName = k

			if Category:StartWith( "[LVS] - Cars" ) then

				local List = list.Get( "simfphys_vehicles" )[ v.ClassName ]

				if List then
					CarsSubCategories = CarsSubCategories or {}

					CarsSubCategories[ List.Category ] = CarsSubCategories[ List.Category ] or {}

					table.insert( CarsSubCategories[ List.Category ], v )
				end

				continue
			end

			for _, start in pairs( Variants ) do
				if Category:StartWith( start ) then
					Category = string.Replace(Category, start, "")

					break
				end
			end

			Categorised[ Category ] = Categorised[ Category ] or {}

			table.insert( Categorised[ Category ], v )
		end
	end

	local lvsNode = tree:AddNode( "[LVS]", "icon16/cog.png" )

	if CarsSubCategories then
		local carNode = lvsNode:AddNode( "Cars", "icon16/car.png" )
		carNode.DoClick = function( self )
			pnlContent:SwitchPanel( self.PropPanel )
		end

		for CategoryName, v in SortedPairs( CarsSubCategories ) do

			local node = carNode:AddNode( CategoryName, "icon16/bricks.png" )

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
	end

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

	for CategoryName, v in SortedPairs( Categorised ) do
		if CategoryName:StartWith( "[LVS]" ) then continue end

		local node = lvsNode:AddNode( CategoryName, "icon16/bricks.png" )

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
