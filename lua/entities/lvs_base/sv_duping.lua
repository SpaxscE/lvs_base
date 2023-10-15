
-- attempt at fixing dupe support

function ENT:PostEntityPaste(Player,Ent,CreatedEntities)
	if Ent.SetlvsReady then Ent:SetlvsReady( false ) end

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
