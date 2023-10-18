
-- attempt at fixing dupe support

function ENT:PostEntityPaste(Player,Ent,CreatedEntities)
	if not self.SetAI then return end
	
	if IsValid( Player ) and Player:IsAdmin() then return end

	self:SetAI( false )
end

local Active
local EngineActive
local CrosshairFilterEnts
local DoorHandlers
local pPodKeyIndex
local pSeats

function ENT:PreEntityCopy()
	Active = self:GetActive()
	EngineActive = self:GetEngineActive()

	self:SetlvsReady( false )
	self:SetActive( false )
	self:SetEngineActive( false )

	CrosshairFilterEnts = self.CrosshairFilterEnts
	DoorHandlers = self._DoorHandlers
	pSeats = self.pSeats
	pPodKeyIndex = self.pPodKeyIndex

	self.CrosshairFilterEnts = nil
	self._DoorHandlers = nil
	self.pPodKeyIndex = nil
	self.pSeats = nil
end

function ENT:PostEntityCopy()
	timer.Simple(0, function()
		if not IsValid( self ) then return end

		self:SetlvsReady( true )
		self:SetActive( Active )
		self:SetEngineActive( EngineActive )

		Active = nil
		EngineActive = nil
	end)

	self.CrosshairFilterEnts = CrosshairFilterEnts
	self._DoorHandlers = DoorHandlers
	self.pPodKeyIndex = pPodKeyIndex
	self.pSeats = pSeats

	CrosshairFilterEnts = nil
	DoorHandlers = nil
	pSeats = nil
	pPodKeyIndex = nil
end