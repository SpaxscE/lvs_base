
function ENT:OnCreateAI()
	self:StartEngine()
end

function ENT:OnRemoveAI()
	self:StopEngine()
end


function ENT:RunAI()

	local StartPos = self:LocalToWorld( self:OBBCenter() )

	local TraceFilter = self:GetCrosshairFilterEnts()

end
