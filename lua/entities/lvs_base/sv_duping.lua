
-- attempt at fixing dupe support

function ENT:PostEntityPaste(Player,Ent,CreatedEntities)
	if Ent.SetlvsReady then Ent:SetlvsReady( false ) end
	if Ent.GetActive then Ent:SetActive( false ) end
	if Ent.GetEngineActive then Ent:SetEngineActive( false ) end
	if Ent.GetAI then Ent:SetAI( false ) end

	-- allow rebuild of passenger seats
	Ent.pPodKeyIndex = nil
	Ent.pSeats = nil

	-- allow rebuild of crosshair trace filter
	Ent.CrosshairFilterEnts  = nil
end

--[[
function ENT:PreEntityCopy()
end
]]
