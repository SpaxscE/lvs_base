local meta = FindMetaTable( "Player" )

function meta:lvsGetAITeam()
	return self:GetNWInt( "lvsAITeam", LVS.PlayerDefaultTeam:GetInt() )
end

function meta:lvsGetVehicle()
	local Pod = self:GetVehicle()

	if not IsValid( Pod ) then return NULL end

	if Pod.LVSchecked then

		return Pod.LVSBaseEnt

	else
		local Parent = Pod:GetParent()
		
		if not IsValid( Parent ) then return NULL end

		if not Parent.LVS then
			Pod.LVSchecked = LVS.MapDoneLoading
			Pod.LVSBaseEnt = NULL

			return NULL
		end

		Pod.LVSchecked = LVS.MapDoneLoading
		Pod.LVSBaseEnt = Parent

		return Parent
	end
end

function meta:lvsGetWeaponHandler()
	local Pod = self:GetVehicle()

	if not IsValid( Pod ) then return NULL end

	local weapon = Pod:lvsGetWeapon()

	if IsValid( weapon ) then
		return weapon
	else
		local veh = self:lvsGetVehicle()

		if not IsValid( veh ) then return NULL end

		if veh:GetDriver() == self then
			return veh
		else
			return NULL
		end
	end
end

function meta:lvsGetControls()
	if not istable( self.LVS_BINDS ) then
		self:lvsBuildControls()
	end
	
	return self.LVS_BINDS
end

function meta:lvsMouseAim()
	if LVS:IsDirectInputForced() then
		return false
	end

	return self._lvsMouseAim
end

function meta:lvsMouseSensitivity()
	local X = self._lvsMouseX or 1
	local Y = self._lvsMouseY or 1
	local delta = self._lvsReturnDelta or 1

	return X, Y, delta
end

function meta:lvsBuildControls()
	if istable( self.LVS_BINDS ) then
		table.Empty( self.LVS_BINDS )
	end

	if SERVER then
		self._lvsMouseAim = self:GetInfoNum( "lvs_mouseaim", 0 ) == 1

		self.LVS_BINDS = table.Copy( LVS.KEYS_CATEGORIES )

		for _,v in pairs( LVS.KEYS_REGISTERED ) do
			local ButtonID = self:GetInfoNum( v.cmd, 0 )

			if not self.LVS_BINDS[v.category][ ButtonID ] then
				self.LVS_BINDS[v.category][ ButtonID ] = {}
			end

			table.insert( self.LVS_BINDS[v.category][ ButtonID ], v.id )
		end

		net.Start( "lvs_buildcontrols" )
		net.Send( self )

		self._lvsMouseX = self:GetInfoNum( "lvs_sensitivity_x", 1 )
		self._lvsMouseY = self:GetInfoNum( "lvs_sensitivity_y", 1 )
		self._lvsReturnDelta = self:GetInfoNum( "lvs_return_delta", 1 )
	else
		self._lvsMouseAim = GetConVar( "lvs_mouseaim" ):GetInt() == 1
		self._lvsMouseX = GetConVar(  "lvs_sensitivity_x" ):GetFloat()
		self._lvsMouseY = GetConVar( "lvs_sensitivity_y" ):GetFloat()
		self._lvsReturnDelta = GetConVar( "lvs_return_delta" ):GetFloat()

		self.LVS_BINDS = {}

		local KeySpawnMenu = input.LookupBinding( "+menu" )
		if isstring( KeySpawnMenu ) then
			KeySpawnMenu = input.GetKeyCode( KeySpawnMenu )
		end

		local KeyContextMenu = input.LookupBinding( "+menu_context" )
		if isstring( KeyContextMenu ) then
			KeyContextMenu = input.GetKeyCode( KeyContextMenu )
		end

		self._lvsDisableSpawnMenu = nil
		self._lvsDisableContextMenu = nil

		for _,v in pairs( LVS.KEYS_REGISTERED ) do
			local KeyCode = GetConVar( v.cmd ):GetInt()

			self.LVS_BINDS[ v.id ] = KeyCode

			if KeyCode == KeySpawnMenu then
				self._lvsDisableSpawnMenu = true
			end
			if KeyCode == KeyContextMenu then
				self._lvsDisableContextMenu = true
			end
		end
	end
end

local IS_MOUSE_ENUM = {
	[MOUSE_LEFT] = true,
	[MOUSE_RIGHT] = true,
	[MOUSE_MIDDLE] = true,
	[MOUSE_4] = true,
	[MOUSE_5] = true,
	[MOUSE_WHEEL_UP] = true,
	[MOUSE_WHEEL_DOWN] = true,
}

local function GetInput( ply, name )
	if SERVER then
		if not ply._lvsKeyDown then
			ply._lvsKeyDown = {}
		end

		return ply._lvsKeyDown[ name ]
	else
		local Key = ply:lvsGetControls()[ name ]

		if IS_MOUSE_ENUM[ Key ] then
			return input.IsMouseDown( Key ) 
		else
			return input.IsKeyDown( Key ) 
		end
	end
end

function meta:lvsKeyDown( name )
	if not self:lvsGetInputEnabled() then return false end

	local Pressed = GetInput( self, name )
	local NewPressed = hook.Run( "LVS.PlayerKeyDown", self, name, Pressed )

	if isbool( NewPressed ) then
		return NewPressed
	else
		return Pressed
	end
end

function meta:lvsGetInputEnabled()
	return (self._lvsKeyDisabler or 0) < CurTime()
end

function meta:lvsSetInputDisabled( disable )
	if CLIENT then
		net.Start( "lvs_buildcontrols" )
			net.WriteBool( disable )
		net.SendToServer()
	end

	if disable then
		self._lvsKeyDisabler = CurTime() + 120
	else
		self._lvsKeyDisabler = CurTime() + 0.25
	end
end

if CLIENT then
	net.Receive( "lvs_buildcontrols", function( len )
		local ply = LocalPlayer()
		if not IsValid( ply ) then return end
		ply:lvsBuildControls()
	end )

	local OldVisible = false
	hook.Add("PostDrawHUD", "!!!lvs_keyblocker", function()
		local Visible = gui.IsGameUIVisible() or vgui.CursorVisible()

		if Visible ~= OldVisible then
			OldVisible = Visible

			local ply = LocalPlayer()

			if not IsValid( ply ) then return end

			if Visible then
				ply:lvsSetInputDisabled( true )
			else
				ply:lvsSetInputDisabled( false )
			end
		end
	end )

	return
end

util.AddNetworkString( "lvs_buildcontrols" )

net.Receive( "lvs_buildcontrols", function( len, ply )
	if not IsValid( ply ) then return end

	ply:lvsSetInputDisabled( net.ReadBool() )
end )

function meta:lvsSetInput( name, value )
	if not self._lvsKeyDown then
		self._lvsKeyDown = {}
	end

	self._lvsKeyDown[ name ] = value
end

function meta:lvsSetAITeam( nTeam )
	nTeam = nTeam or LVS.PlayerDefaultTeam:GetInt()

	local TeamText = {
		[0] = "FRIENDLY TO EVERYONE",
		[1] = "Team 1",
		[2] = "Team 2",
		[3] = "HOSTILE TO EVERYONE",
	}

	if self:lvsGetAITeam() ~= nTeam then
		self:PrintMessage( HUD_PRINTTALK, "[LVS] Your AI-Team has been updated to: "..TeamText[ nTeam ] )
	end

	self:SetNWInt( "lvsAITeam", nTeam )
end

hook.Add( "PlayerButtonUp", "!!!lvsButtonUp", function( ply, button )
	for _, KeyBind in pairs( ply:lvsGetControls() ) do
		local KeyTBL = KeyBind[ button ]

		if not KeyTBL then continue end

		for _, KeyName in pairs( KeyTBL ) do
			ply:lvsSetInput( KeyName, false )
		end
	end
end )

hook.Add( "PlayerButtonDown", "!!!lvsButtonDown", function( ply, button )
	if not ply:lvsGetInputEnabled() then return end

	local vehicle = ply:lvsGetVehicle()
	local vehValid = IsValid( vehicle )

	for _, KeyBind in pairs( ply:lvsGetControls() ) do
		local KeyTBL = KeyBind[ button ]

		if not KeyTBL then continue end

		for _, KeyName in pairs( KeyTBL ) do
			ply:lvsSetInput( KeyName, true )

			if not vehValid then continue end

			if string.StartWith( KeyName, "~SELECT~" ) then
				local exp_string = string.Explode( "#", KeyName )
				local base = ply:lvsGetWeaponHandler()

				if exp_string[2] and IsValid( base ) then
					base:SelectWeapon( tonumber( exp_string[2] ) )
				end
			end

			if KeyName == "EXIT" then
				ply:ExitVehicle()
			end
		end
	end
end )

hook.Add("CanExitVehicle","!!!lvsCanExitVehicle",function(vehicle,ply)
	if IsValid( ply:lvsGetVehicle() ) then return false end
end)
