include("shared.lua")

function ENT:Think()
end

function ENT:OnRemove()
end

function ENT:Draw()
end

function ENT:DrawTranslucent()
end

function ENT:GetAimVector()
	if self:GetAI() then
		return self:GetNWAimVector()
	end

	local Driver = self:GetDriver()

	if IsValid( Driver ) then
		return Driver:GetAimVector()
	else
		return self.VectorNull
	end
end