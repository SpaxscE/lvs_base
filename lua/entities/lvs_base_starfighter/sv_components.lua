
function ENT:AddEngine( pos, ang, mins, maxs, health )
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

	if not health then
		health = self.MaxHealth / 8
	end

	Engine:SetMaxHP( health )
	Engine:SetHP( health )
	self:DeleteOnRemove( Engine )
	self:TransferCPPI( Engine )

	self:AddDS( {
		pos = pos,
		ang = (ang or Angle(0,0,0)),
		mins = (mins or Vector(-40,-20,-30)),
		maxs =  (maxs or Vector(40,20,30)),
		Callback = function( tbl, ent, dmginfo )
			if dmginfo:GetDamage() <= 0 then return end

			Engine:TakeDamageInfo( dmginfo )
		end
	} )

	
	if not istable( self._lvsEngines ) then
		self._lvsEngines = {}
	end

	table.insert( self._lvsEngines, Engine )

	return Engine
end

function ENT:GetEngines()
	return self._lvsEngines or {}
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