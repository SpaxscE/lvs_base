
function ENT:HasQuickVar( name )
	name =  "_smValue"..name

	return self[ name ] ~= nil
end

function ENT:GetQuickVar( name )
	name =  "_smValue"..name

	if not self[ name ] then return 0 end

	return self[ name ]
end

if CLIENT then
	function ENT:QuickLerp( name, target, rate )
		name =  "_smValue"..name

		local EntTable = self:GetTable()

		if not EntTable[ name ] then EntTable[ name ] = 0 end

		EntTable[ name ] = EntTable[ name ] + (target - EntTable[ name ]) * math.min( RealFrameTime() * (rate or 10), 1 )

		return EntTable[ name ]
	end

	return
end

function ENT:QuickLerp( name, target, rate )
	name =  "_smValue"..name

	if not self[ name ] then self[ name ] = 0 end

	self[ name ] = self[ name ] + (target - self[ name ]) * math.min( FrameTime() * (rate or 10), 1 )

	return self[ name ]
end

function ENT:UpdateVariable( categoryID, entryID, value )
	local EntTable = self:GetTable()

	if not istable( EntTable.lvsEditables ) then return end

	print( EntTable.lvsEditables[ categoryID ].Options[ entryID ].name )
end

function ENT:ChangeVelocity( new )
	print("dsfgdsf")
end