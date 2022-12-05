local meta = FindMetaTable( "Player" )

function meta:lvsGetVehicle()
	if not self:InVehicle() then return NULL end

	local Pod = self:GetVehicle()

	if not IsValid( Pod ) then return NULL end

	if Pod.LVSchecked then

		return Pod.LVSBaseEnt

	else
		local Parent = Pod:GetParent()
		
		if not IsValid( Parent ) then return NULL end

		if not Parent.LVS then return NULL end

		Pod.LVSchecked = true
		Pod.LVSBaseEnt = Parent

		return Parent
	end
end

function meta:lvsGetControls()
	if not istable( self.LVS_BINDS ) then
		self:lvsBuildControls()
	end
	
	return self.LVS_BINDS
end

function meta:lvsBuildControls()
	if istable( self.LVS_BINDS ) then
		table.Empty( self.LVS_BINDS )
	end

	if SERVER then
		self.LVS_BINDS = table.Copy( LVS.KEYS_CATEGORIES )

		for _,v in pairs( LVS.KEYS_REGISTERED ) do
			self.LVS_BINDS[v.category][ self:GetInfoNum( v.cmd, 0 ) ] = v.id
		end
	else
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
			local KeyCode =  GetConVar( v.cmd ):GetInt()

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
	local Pressed = GetInput( self, name )
	local NewPressed = hook.Run( "LVS.PlayerKeyDown", self, name, Pressed )

	if isbool( NewPressed ) then
		return NewPressed
	else
		return Pressed
	end
end

if CLIENT then return end

function meta:lvsSetInput( name, value )
	if not self._lvsKeyDown then
		self._lvsKeyDown = {}
	end

	self._lvsKeyDown[ name ] = value
end

hook.Add( "PlayerButtonUp", "!!!lvsButtonUp", function( ply, button )
	for _, KeyBind in pairs( ply:lvsGetControls() ) do
		if KeyBind[ button ] then
			ply:lvsSetInput( KeyBind[ button ], false )
		end
	end
end )

hook.Add( "PlayerButtonDown", "!!!lvsButtonDown", function( ply, button )
	local vehicle = ply:lvsGetVehicle()

	for _, KeyBind in pairs( ply:lvsGetControls() ) do
		if KeyBind[ button ] then
			ply:lvsSetInput( KeyBind[ button ], true )
			
			if IsValid( vehicle ) then
				if KeyBind[ button ] == "EXIT" then
					ply:ExitVehicle()
				end
			end
		end
	end
end )

hook.Add("CanExitVehicle","!!!lvsCanExitVehicle",function(vehicle,ply)
	if IsValid( ply:lvsGetVehicle() ) then return false end
end)
