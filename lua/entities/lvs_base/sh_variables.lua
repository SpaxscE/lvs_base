
function ENT:HasQuickVar( name )
	name =  "_smValue"..name

	return self[ name ] ~= nil
end

function ENT:GetQuickVar( name )
	name =  "_smValue"..name

	if not self[ name ] then return 0 end

	return self[ name ]
end

function ENT:UpdateVariable( categoryID, entryID, value )
	local EntTable = self:GetTable()

	if not istable( EntTable.lvsEditables ) then return end
	if not EntTable.lvsEditables[ categoryID ] then return end
	if not EntTable.lvsEditables[ categoryID ].Options then return end
	if not EntTable.lvsEditables[ categoryID ].Options[ entryID ] then return end

	local variable = EntTable.lvsEditables[ categoryID ].Options[ entryID ].name
	local valueMin = EntTable.lvsEditables[ categoryID ].Options[ entryID ].min
	local valueMax = EntTable.lvsEditables[ categoryID ].Options[ entryID ].max

	if not variable then return end

	if type( value ) ~= type( EntTable[ variable ] ) then return end

	if type( value ) == "number" and valueMin and valueMax then
		EntTable[ variable ] = math.Clamp( value, valueMin, valueMax )
	else
		EntTable[ variable ] = value
	end

	if CLIENT then return end

	net.Start( "lvs_variable_updater" )
		net.WriteEntity( self )
		net.WriteInt( categoryID, 8 )
		net.WriteInt( entryID, 8 )
		net.WriteString( tostring( value ) )
	net.Broadcast()
end

if CLIENT then
	function ENT:QuickLerp( name, target, rate )
		name =  "_smValue"..name

		local EntTable = self:GetTable()

		if not EntTable[ name ] then EntTable[ name ] = 0 end

		EntTable[ name ] = EntTable[ name ] + (target - EntTable[ name ]) * math.min( RealFrameTime() * (rate or 10), 1 )

		return EntTable[ name ]
	end

	net.Receive( "lvs_variable_updater", function( len, ply )
		local ent = net.ReadEntity()

		if not IsValid( ent ) or not isfunction( ent.UpdateVariable ) then return end

		local categoryID = net.ReadInt( 8 )
		local entryID = net.ReadInt( 8 )
		local value = net.ReadString()

		value = tonumber( value ) or tobool( value )

		if not value then return end

		ent:UpdateVariable( categoryID, entryID, value )
	end )

	return
end

util.AddNetworkString( "lvs_variable_updater" )

function ENT:QuickLerp( name, target, rate )
	name =  "_smValue"..name

	if not self[ name ] then self[ name ] = 0 end

	self[ name ] = self[ name ] + (target - self[ name ]) * math.min( FrameTime() * (rate or 10), 1 )

	return self[ name ]
end

function ENT:ChangeVelocity( new )
end