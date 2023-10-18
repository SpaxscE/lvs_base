
-- attempt at fixing dupe support

function ENT:PostEntityPaste(Player,Ent,CreatedEntities)
	if self.SetAI then self:SetAI( false ) end
	if self.SetActive then self:SetActive( false ) end
	if self.SetEngineActive then self:SetEngineActive( false ) end
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

	self:SetActive( false )
	self:SetEngineActive( false )


	self:SetlvsReady( false )


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
	self:SetActive( Active )
	self:SetEngineActive( EngineActive )

	Active = nil
	EngineActive = nil


	self:SetlvsReady( true )


	self.CrosshairFilterEnts = CrosshairFilterEnts
	self._DoorHandlers = DoorHandlers
	self.pPodKeyIndex = pPodKeyIndex
	self.pSeats = pSeats

	CrosshairFilterEnts = nil
	DoorHandlers = nil
	pSeats = nil
	pPodKeyIndex = nil
end