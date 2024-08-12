
-- attempt at fixing dupe support

function ENT:PostEntityPaste(Player,Ent,CreatedEntities)
	self.MaxHealth = self:GetHP()

	if not self.SetAI then return end
	
	if IsValid( Player ) and Player:IsAdmin() then return end

	self:SetAI( false )
end

local Active
local EngineActive
local HP

function ENT:PreEntityCopy()
	Active = self:GetActive()
	EngineActive = self:GetEngineActive()
	HP = self:GetHP()

	self:SetlvsReady( false )
	self:SetActive( false )
	self:SetEngineActive( false )
	self:SetHP( self:GetMaxHP() )
end

function ENT:PostEntityCopy()
	timer.Simple(0, function()
		if not IsValid( self ) then return end

		self:SetlvsReady( true )
		self:SetActive( Active )
		self:SetEngineActive( EngineActive )
		self:SetHP( HP )

		Active = nil
		EngineActive = nil
		HP = nil
	end)
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

	for id, entry in pairs( data ) do
		if not isfunction( entry ) then continue end

		data[ id ] = nil
	end

	-- stuff below is things like constraints or DeleteOnRemove still referencing the old object. These need to go
	data.OnDieFunctions = nil
	data.Constraints = nil
	data._children = nil
end
