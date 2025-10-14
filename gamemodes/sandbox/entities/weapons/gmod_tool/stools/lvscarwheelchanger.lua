

TOOL.Category		= "LVS"
TOOL.Name			= "#Wheel Editor"

TOOL.ClientConVar[ "model" ] = "models/diggercars/kubel/kubelwagen_wheel.mdl"
TOOL.ClientConVar[ "camber" ] = 0
TOOL.ClientConVar[ "caster" ] = 0
TOOL.ClientConVar[ "toe" ] = 0
TOOL.ClientConVar[ "height" ] = 0
TOOL.ClientConVar[ "stiffness" ] = 0
TOOL.ClientConVar[ "skin" ] = 0
TOOL.ClientConVar[ "bodygroup0" ] = 0
TOOL.ClientConVar[ "bodygroup1" ] = 0
TOOL.ClientConVar[ "bodygroup2" ] = 0
TOOL.ClientConVar[ "bodygroup3" ] = 0
TOOL.ClientConVar[ "bodygroup4" ] = 0
TOOL.ClientConVar[ "bodygroup5" ] = 0
TOOL.ClientConVar[ "bodygroup6" ] = 0
TOOL.ClientConVar[ "bodygroup7" ] = 0
TOOL.ClientConVar[ "bodygroup8" ] = 0
TOOL.ClientConVar[ "bodygroup9" ] = 0
TOOL.ClientConVar[ "pp0" ] = 0
TOOL.ClientConVar[ "pp1" ] = 0
TOOL.ClientConVar[ "pp2" ] = 0
TOOL.ClientConVar[ "pp3" ] = 0
TOOL.ClientConVar[ "pp4" ] = 0
TOOL.ClientConVar[ "pp5" ] = 0
TOOL.ClientConVar[ "pp6" ] = 0
TOOL.ClientConVar[ "pp7" ] = 0
TOOL.ClientConVar[ "pp8" ] = 0
TOOL.ClientConVar[ "pp9" ] = 0
TOOL.ClientConVar[ "r" ] = 255
TOOL.ClientConVar[ "g" ] = 255
TOOL.ClientConVar[ "b" ] = 255
TOOL.ClientConVar[ "a" ] = 255

TOOL.Information = {
	{ name = "left" },
	{ name = "right" },
	{ name = "reload" }
}

if CLIENT then
	language.Add( "tool.lvscarwheelchanger.name", "Wheel Editor" )
	language.Add( "tool.lvscarwheelchanger.desc", "A tool used to edit [LVS-Cars] Wheels" )
	language.Add( "tool.lvscarwheelchanger.left", "Apply wheel. Click again to flip 180 degrees" )
	language.Add( "tool.lvscarwheelchanger.right", "Copy wheel" )
	language.Add( "tool.lvscarwheelchanger.reload", "Apply camber/caster/toe/height/stiffness. Click again to flip camber and toe" )

	local ContextMenuPanel

	local skins = 0
	local bodygroups = {}
	local poseparameters = {}

	local ConVarsDefault = TOOL:BuildConVarList()
	local function BuildContextMenu()
		if not IsValid( ContextMenuPanel ) then return end

		ContextMenuPanel:Clear()

		if IsValid( ContextMenuPanel.modelpanel ) then
			ContextMenuPanel.modelpanel:Remove()
		end

		ContextMenuPanel:AddControl( "Header", { Text = "#tool.lvscarwheelchanger.name", Description = "#tool.lvscarwheelchanger.desc" } )
		ContextMenuPanel:AddControl( "ComboBox", { MenuButton = 1, Folder = "lvswheels", Options = { [ "#preset.default" ] = ConVarsDefault }, CVars = table.GetKeys( ConVarsDefault ) } )

		ContextMenuPanel:ColorPicker( "Wheel Color", "lvscarwheelchanger_r", "lvscarwheelchanger_g", "lvscarwheelchanger_b", "lvscarwheelchanger_a" )

		if skins > 0 then
			ContextMenuPanel:AddControl( "Label",  { Text = "" } )
			ContextMenuPanel:AddControl( "Label",  { Text = "Skins" } )
			ContextMenuPanel:AddControl("Slider", { Label = "Skin", Type = "int", Min = "0", Max = tostring( skins ), Command = "lvscarwheelchanger_skin" } )
		end

		local icon = vgui.Create( "DModelPanel", ContextMenuPanel )
		icon:SetSize(200,200)
		icon:SetFOV( 30 )
		icon:SetAnimated( true )
		icon:SetModel( GetConVar( "lvscarwheelchanger_model" ):GetString() )
		icon:Dock( TOP )
		icon:SetCamPos( Vector(80,0,0) )
		icon:SetLookAt( vector_origin )
		icon.Angles = angle_zero
		function icon:DragMousePress()
			self.PressX, self.PressY = gui.MousePos()
			self.Pressed = true
		end
		function icon:DragMouseRelease()
			self.Pressed = false
		end
		function icon:LayoutEntity( ent )
			if self.Pressed then
				local mx, my = gui.MousePos()

				self.Angles:RotateAroundAxis( Vector(0,0,-1), ((self.PressX or mx) - mx) / 2 )
				self.Angles:RotateAroundAxis( Vector(0,-1,0), ((self.PressY or my) - my) / 2 )

				self.PressX, self.PressY = gui.MousePos()
			end

			ent:SetSkin( GetConVar( "lvscarwheelchanger_skin" ):GetInt() )

			local R = GetConVar( "lvscarwheelchanger_r" ):GetInt()
			local G = GetConVar( "lvscarwheelchanger_g" ):GetInt()
			local B = GetConVar( "lvscarwheelchanger_b" ):GetInt()
			local A = GetConVar( "lvscarwheelchanger_a" ):GetInt()
			self:SetColor( Color(R,G,B,A) )

			ent:SetAngles( self.Angles )

			for id = 0, 9 do
				ent:SetBodygroup( id, GetConVar( "lvscarwheelchanger_bodygroup"..id ):GetInt() )
			end

			for id, data in pairs( poseparameters ) do
				if id > 9 then break end

				if data.name == "#scale" then
					local bonescale = math.Clamp( GetConVar( "lvscarwheelchanger_pp"..id ):GetFloat(), data.min, data.max )
					local num = ent:GetBoneCount() - 1

					for boneid = 0, num do
						local bonename = ent:GetBoneName( boneid )

						if not bonename or bonename == "__INVALIDBONE__" or not string.StartsWith( bonename, "#" ) then continue end

						ent:ManipulateBoneScale( boneid, Vector(bonescale,bonescale,1) )
					end

					continue
				end

				ent:SetPoseParameter( data.name, GetConVar( "lvscarwheelchanger_pp"..id ):GetFloat() )
			end
		end
		ContextMenuPanel.modelpanel = icon

		if table.Count( poseparameters ) > 0 then
			ContextMenuPanel:AddControl( "Label",  { Text = "" } )
			ContextMenuPanel:AddControl( "Label",  { Text = "PoseParameters" } )

			for id, data in pairs( poseparameters ) do
				ContextMenuPanel:AddControl("Slider", { Label = data.name, Type = "float", Min = tostring( data.min ), Max = tostring( data.max ), Command = "lvscarwheelchanger_pp"..id } )
			end
		end

		if #bodygroups > 0 then
			ContextMenuPanel:AddControl( "Label",  { Text = "" } )
			ContextMenuPanel:AddControl( "Label",  { Text = "BodyGroup" } )
	
			for group, data in pairs( bodygroups ) do
				local maxvalue = tostring( data.submodels )

				if maxvalue == "0" then continue end

				ContextMenuPanel:AddControl("Slider", { Label = data.name, Type = "int", Min = "0", Max = maxvalue, Command = "lvscarwheelchanger_bodygroup"..group } )
			end
		end

		ContextMenuPanel:AddControl( "Label",  { Text = "" } )
		ContextMenuPanel:AddControl( "Label",  { Text = "Alignment Specs" } )
		ContextMenuPanel:AddControl( "Label",  { Text = "- Wheel" } )
		ContextMenuPanel:AddControl("Slider", { Label = "Camber", Type = "float", Min = "-15", Max = "15", Command = "lvscarwheelchanger_camber" } )
		ContextMenuPanel:AddControl("Slider", { Label = "Caster", Type = "float", Min = "-15", Max = "15", Command = "lvscarwheelchanger_caster" } )
		ContextMenuPanel:AddControl("Slider", { Label = "Toe", Type = "float", Min = "-30", Max = "30", Command = "lvscarwheelchanger_toe" } )
		ContextMenuPanel:AddControl( "Label",  { Text = "- Suspension" } )
		ContextMenuPanel:AddControl("Slider", { Label = "Height", Type = "float", Min = "-1", Max = "1", Command = "lvscarwheelchanger_height" } )
		ContextMenuPanel:AddControl("Slider", { Label = "Stiffness", Type = "float", Min = "-1", Max = "1", Command = "lvscarwheelchanger_stiffness" } )

		-- purpose: avoid bullshit concommand system and avoid players abusing it
		for mdl, _ in pairs( list.Get( "lvs_wheels" ) or {} ) do
			list.Set( "lvs_wheels_selection", mdl, {} )
		end
		ContextMenuPanel:AddControl( "Label",  { Text = "" } )
		ContextMenuPanel:AddControl( "Label",  { Text = "Wheel Models" } )
		ContextMenuPanel:AddControl( "PropSelect", { Label = "", ConVar = "lvscarwheelchanger_model", Height = 0, Models = list.Get( "lvs_wheels_selection" ) } )
	end

	local function SetModel( name )
		local ModelInfo = util.GetModelInfo( name )

		if ModelInfo and ModelInfo.SkinCount then
			skins = ModelInfo.SkinCount - 1
		else
			skins = 0
		end

		local bgroupmdl = ents.CreateClientProp()
		bgroupmdl:SetModel( name )
		bgroupmdl:Spawn()

		table.Empty( bodygroups )
		table.Empty( poseparameters )

		for _, bgroup in pairs( bgroupmdl:GetBodyGroups() ) do
			bodygroups[ bgroup.id ] = {
				name = bgroup.name,
				submodels = #bgroup.submodels,
			}
		end

		local num = bgroupmdl:GetNumPoseParameters()

		if num > 0 then
			for i = 0, num - 1 do
				local min, max = bgroupmdl:GetPoseParameterRange( i )

				local name = bgroupmdl:GetPoseParameterName( i )

				local pp_cvar = GetConVar( "lvscarwheelchanger_pp"..i )
				if name == "#scale" and pp_cvar then
					local val = pp_cvar:GetFloat()

					if val > max or val < min then
						pp_cvar:SetFloat( math.Clamp( 1, min, max ) )
					end
				end

				poseparameters[ i ] = {
					name = name,
					min = min,
					max = max,
				}
			end
		end

		bgroupmdl:Remove()

		BuildContextMenu()
	end

	function TOOL.BuildCPanel( panel )
		ContextMenuPanel = panel

		BuildContextMenu()
	end

	cvars.AddChangeCallback( "lvscarwheelchanger_model", function( convar, oldValue, newValue ) 
		SetModel( newValue )
	end)
end

local function DuplicatorSaveCarWheels( ent )
	if CLIENT then return end

	local base = ent:GetBase()

	if not IsValid( base ) then return end

	local data = {}

	for id, wheel in pairs( base:GetWheels() ) do
		if not IsValid( wheel ) then continue end

		local wheeldata = {}
		wheeldata.ID = id
		wheeldata.Model = wheel:GetModel()
		wheeldata.ModelScale = wheel:GetModelScale()
		wheeldata.Skin = wheel:GetSkin()
		wheeldata.Camber = wheel:GetCamber()
		wheeldata.Caster = wheel:GetCaster()
		wheeldata.Toe = wheel:GetToe()
		wheeldata.Height = wheel:GetSuspensionHeight()
		wheeldata.Stiffness = wheel:GetSuspensionStiffness()
		wheeldata.AlignmentAngle = wheel:GetAlignmentAngle()
		wheeldata.Color = wheel:GetColor()

		wheeldata.BodyGroups = {}
		for id = 0, 9 do
			wheeldata.BodyGroups[ id ] = wheel:GetBodygroup( id )
		end

		wheeldata.PoseParameters = {}
		for id = 0, 9 do
			wheeldata.PoseParameters[ id ] = wheel:GetPoseParameter( wheel:GetPoseParameterName( id ) )
		end

		table.insert( data, wheeldata )
	end
 
	if not duplicator or not duplicator.StoreEntityModifier then return end

	duplicator.StoreEntityModifier( base, "lvsCarWheels", data )
end

local function DuplicatorApplyCarWheels( ply, ent, data )
	if CLIENT then return end

	timer.Simple(0.1, function()
		if not IsValid( ent ) then return end

		for id, wheel in pairs( ent:GetWheels() ) do
			for _, wheeldata in pairs( data ) do
				if not wheeldata or wheeldata.ID ~= id then continue end

				if wheeldata.Model then wheel:SetModel( wheeldata.Model ) end
				if wheeldata.ModelScale then wheel:SetModelScale( wheeldata.ModelScale ) end
				if wheeldata.Skin then wheel:SetSkin( wheeldata.Skin ) end
				if wheeldata.Camber then wheel:SetCamber( wheeldata.Camber ) end
				if wheeldata.Caster then wheel:SetCaster( wheeldata.Caster ) end
				if wheeldata.Toe then wheel:SetToe( wheeldata.Toe ) end
				if wheeldata.AlignmentAngle then wheel:SetAlignmentAngle( wheeldata.AlignmentAngle ) end
				if wheeldata.Color then wheel:SetColor( wheeldata.Color ) end
				if wheeldata.Height then wheel:SetSuspensionHeight( wheeldata.Height ) end
				if wheeldata.Stiffness then wheel:SetSuspensionStiffness( wheeldata.Stiffness ) end

				timer.Simple(0, function()
					if not IsValid( wheel ) then return end

					if wheeldata.BodyGroups then
						for group, subgroup in pairs( wheeldata.BodyGroups ) do
							if subgroup == 0 then continue end

							wheel:SetBodygroup( group, subgroup )
						end
					end

					if wheeldata.PoseParameters and wheel:GetNumPoseParameters() > 0 then
						for id, pose in pairs( wheeldata.PoseParameters ) do
							local name = wheel:GetPoseParameterName( id )

							wheel:StartThink()
							wheel:SetPoseParameter( name, pose )

							if name == "#scale" then
								local min, max = wheel:GetPoseParameterRange( id )
								local num = wheel:GetBoneCount() - 1

								local bonescale = math.Clamp( pose, min, max )

								for boneid = 0, num do
									local bonename = wheel:GetBoneName( boneid )

									if not bonename or bonename == "__INVALIDBONE__" or not string.StartsWith( bonename, "#" ) then continue end

									wheel:ManipulateBoneScale( boneid, Vector(bonescale,bonescale,1) )
								end

								continue
							end
						end
					end
				end)

				wheel:CheckAlignment()
				wheel:PhysWake()
			end
		end
	end)
end
if duplicator and duplicator.RegisterEntityModifier then
	duplicator.RegisterEntityModifier( "lvsCarWheels", DuplicatorApplyCarWheels )
end

function TOOL:IsValidTarget( ent )
	if not IsValid( ent ) then return false end

	local class = ent:GetClass()

	return class == "lvs_wheeldrive_wheel"
end

function TOOL:GetData( ent )
	if CLIENT then return end

	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	self.radius = ent:GetRadius() * (1 / ent:GetModelScale())
	self.ang = ent:GetAlignmentAngle()
	self.mdl = ent:GetModel()

	ply:ConCommand( [[lvscarwheelchanger_model "]]..self.mdl..[["]] )
	ply:ConCommand( "lvscarwheelchanger_skin "..ent:GetSkin() )

	local clr = ent:GetColor()
	ply:ConCommand( "lvscarwheelchanger_r " .. clr.r )
	ply:ConCommand( "lvscarwheelchanger_g " .. clr.g )
	ply:ConCommand( "lvscarwheelchanger_b " .. clr.b )
	ply:ConCommand( "lvscarwheelchanger_a " .. clr.a )

	for id = 0, 9 do
		local group = ent:GetBodygroup( id ) or 0
		ply:ConCommand( "lvscarwheelchanger_bodygroup"..id.." "..group )
	end

	for id = 0, 9 do
		local pp = ent:GetPoseParameter( ent:GetPoseParameterName( id ) )

		ply:ConCommand( "lvscarwheelchanger_pp"..id.." "..pp )
	end

	ply:ConCommand( "lvscarwheelchanger_camber "..ent:GetCamber() )
	ply:ConCommand( "lvscarwheelchanger_caster "..ent:GetCaster() )
	ply:ConCommand( "lvscarwheelchanger_toe "..ent:GetToe() )

	ply:ConCommand( "lvscarwheelchanger_height "..ent:GetSuspensionHeight() )
	ply:ConCommand( "lvscarwheelchanger_stiffness "..ent:GetSuspensionStiffness() )
end

function TOOL:SetData( ent )
	if CLIENT then return end

	local mdl = self:GetClientInfo("model")

	if mdl ~= "" then
		local data = list.Get( "lvs_wheels" )[ mdl ]

		if data then
			self.mdl = mdl
			self.ang = data.angle
			self.radius = data.radius
		end
	end

	if not isstring( self.mdl ) or not isangle( self.ang ) or not isnumber( self.radius ) then return end

	local r = self:GetClientNumber( "r", 0 )
	local g = self:GetClientNumber( "g", 0 )
	local b = self:GetClientNumber( "b", 0 )
	local a = self:GetClientNumber( "a", 0 )

	ent:SetColor( Color( r, g, b, a ) )
	ent:SetSkin( self:GetClientNumber( "skin", 0 ) )

	timer.Simple(0, function()
		if not IsValid( ent ) then return end

		for id = 0, 9 do
			ent:SetBodygroup( id, self:GetClientNumber( "bodygroup"..id, 0 ) )
		end

		local num = ent:GetNumPoseParameters()
		if num > 0 then
			for id = 0, 9 do
				if id > num - 1 then break end

				local name = ent:GetPoseParameterName( id )

				local pose = self:GetClientNumber( "pp"..id, 0 )

				ent:StartThink()
				ent:SetPoseParameter( name, pose )

				if name == "#scale" then
					local min, max = ent:GetPoseParameterRange( id )
					local num = ent:GetBoneCount() - 1

					local bonescale = math.Clamp( pose, min, max )

					for boneid = 0, num do
						local bonename = ent:GetBoneName( boneid )

						if not bonename or bonename == "__INVALIDBONE__" or not string.StartsWith( bonename, "#" ) then continue end

						ent:ManipulateBoneScale( boneid, Vector(bonescale,bonescale,1) )
					end

					continue
				end
			end
		end
	end)

	if ent:GetModel() == self.mdl then
		local Ang = ent:GetAlignmentAngle()
		Ang:RotateAroundAxis( Vector(0,0,1), 180 )

		ent:SetAlignmentAngle( Ang )
	else
		ent:SetModel( self.mdl )
		ent:SetAlignmentAngle( self.ang )

		timer.Simple(0.05, function()
			if not IsValid( ent ) then return end

			ent:SetModelScale( ent:GetRadius() / self.radius )
		end)
	end

	timer.Simple(0.1, function()
		if not IsValid( ent ) then return end

		DuplicatorSaveCarWheels( ent )
	end)
end

function TOOL:LeftClick( trace )
	if not self:IsValidTarget( trace.Entity ) then return false end

	self:SetData( trace.Entity )

	if CLIENT then return true end

	local ent = trace.Entity

	timer.Simple(0, function()
		if not IsValid( ent ) then return end
		local effectdata = EffectData()
		effectdata:SetOrigin( ent:GetPos() )
		effectdata:SetEntity( ent )
		util.Effect( "lvs_upgrade", effectdata )
	end)

	return true
end

function TOOL:RightClick( trace )
	if not self:IsValidTarget( trace.Entity ) then return false end

	self:GetData( trace.Entity )

	if CLIENT then return true end

	local ent = trace.Entity

	timer.Simple(0, function()
		if not IsValid( ent ) then return end
		local effectdata = EffectData()
		effectdata:SetOrigin( ent:GetPos() )
		effectdata:SetEntity( ent )
		util.Effect( "lvs_update", effectdata )
	end)

	return true
end

function TOOL:Reload( trace )
	local ent = trace.Entity

	if not self:IsValidTarget( ent ) then return false end

	if CLIENT then return true end

	timer.Simple(0, function()
		if not IsValid( ent ) then return end
		local effectdata = EffectData()
		effectdata:SetOrigin( ent:GetPos() )
		effectdata:SetEntity( ent )
		util.Effect( "lvs_downgrade", effectdata )
	end)

	local camber = math.Round( self:GetClientNumber("camber",0) , 2 )
	local caster = math.Round( self:GetClientNumber("caster",0) , 2 )
	local toe = math.Round( self:GetClientNumber("toe",0) , 2 )

	if math.Round( ent:GetCamber(), 2 ) == camber and math.Round( ent:GetToe(), 2 ) == toe and math.Round( ent:GetCaster(), 2 ) == caster then
		ent:SetCamber( -camber )
		ent:SetToe( -toe )
	else
		ent:SetCamber( camber )
		ent:SetToe( toe )
	end

	ent:SetCaster( caster )

	local NewTraction = math.min( math.Round( (ent:CheckAlignment() or 0) * 100, 0 ), 120 )

	local ply = self:GetOwner()

	if IsValid( ply ) and ply:IsPlayer() then
		ply:ChatPrint( "Estimated Traction: "..NewTraction.."%" )
	end

	ent:SetSuspensionHeight( self:GetClientInfo("height") )
	ent:SetSuspensionStiffness( self:GetClientInfo("stiffness") )
	ent:PhysWake()

	DuplicatorSaveCarWheels( ent )

	return true
end

list.Set( "lvs_wheels", "models/props_vehicles/carparts_wheel01a.mdl", {angle = Angle(0,90,0), radius = 16} )