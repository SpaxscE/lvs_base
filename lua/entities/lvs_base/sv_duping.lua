
-- attempt at fixing dupe support

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )

	if isnumber( self._DuplicatorRestoreMaxHealthTo ) then
		self.MaxHealth = self._DuplicatorRestoreMaxHealthTo
	end

	if self.SetlvsReady then
		self:SetlvsReady( false )
	end

	if self.SetActive then
		self:SetActive( false )
	end

	if self.SetEngineActive then
		self:SetEngineActive( false )
	end

	if not self.SetAI then return end
	
	if IsValid( Player ) and Player:IsAdmin() then return end

	self:SetAI( false )
end

function ENT:OnEntityCopyTableFinish( data )
	data.CrosshairFilterEnts = nil
	data._DoorHandlers = nil
	data.pPodKeyIndex = nil
	data.pSeats = nil
	data.WEAPONS = nil
	data._armorParts = nil
	data._dmgParts = nil
	data._DoorHandlers = nil
	data._pdsParts = nil

	data._DuplicatorRestoreMaxHealthTo = self:GetMaxHP()

	for id, entry in pairs( data ) do
		if not isfunction( entry ) then continue end

		data[ id ] = nil
	end

	-- stuff below is things like constraints or DeleteOnRemove still referencing the old object. These need to go
	data.OnDieFunctions = nil
	data.Constraints = nil
	data._children = nil
end
