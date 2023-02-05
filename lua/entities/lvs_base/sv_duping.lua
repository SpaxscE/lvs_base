
-- attempt at fixing dupe support

function ENT:PostEntityPaste(Player,Ent,CreatedEntities)
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
