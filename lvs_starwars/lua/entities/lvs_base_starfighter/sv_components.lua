
function ENT:AddEngine( pos )
	local Engine = ents.Create( "lvs_starfighter_engine" )

	if not IsValid( Engine ) then
		self:Remove()

		print("LVS: Failed to create engine entity. Vehicle terminated.")

		return
	end

	Engine:SetPos( self:LocalToWorld( pos ) )
	Engine:SetAngles( self:GetAngles() )
	Engine:Spawn()
	Engine:Activate()
	Engine:SetParent( self )
	Engine:SetBase( self )

	self:DeleteOnRemove( Engine )

	self:TransferCPPI( Engine )

	self:AddDS( {
		pos = pos,
		ang = Angle(0,0,0),
		mins = Vector(-40,-20,-30),
		maxs =  Vector(40,20,30),
		Callback = function( tbl, ent, dmginfo )
			if dmginfo:GetDamage() <= 0 then return end

			dmginfo:ScaleDamage( 2 )

			Engine:TakeDamageInfo( dmginfo )
		end
	} )

	return Engine
end

function ENT:AddEngineSound( pos )
	local EngineSND = ents.Create( "lvs_starfighter_soundemitter" )

	if not IsValid( EngineSND ) then
		self:Remove()

		print("LVS: Failed to create engine sound entity. Vehicle terminated.")

		return
	end

	EngineSND:SetPos( self:LocalToWorld( pos ) )
	EngineSND:SetAngles( self:GetAngles() )
	EngineSND:Spawn()
	EngineSND:Activate()
	EngineSND:SetParent( self )
	EngineSND:SetBase( self )

	self:DeleteOnRemove( EngineSND )

	self:TransferCPPI( EngineSND )

	return EngineSND
end