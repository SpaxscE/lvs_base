
function ENT:HandleStart()
	local Driver = self:GetDriver()

	if IsValid( Driver ) then
		local KeyReload = Driver:lvsKeyDown( "ENGINE" )

		if self.OldKeyReload ~= KeyReload then
			self.OldKeyReload = KeyReload

			if KeyReload then
				self:ToggleEngine()
			end
		end
	end
end

function ENT:ToggleEngine()
	if self:GetEngineActive() then
		self:StopEngine()
	else
		self:StartEngine()
	end
end

function ENT:IsEngineStartAllowed()
	if hook.Run( "LVS.IsEngineStartAllowed", self ) == false then return false end

	return true
end

function ENT:OnEngineStarted()
end

function ENT:OnEngineStopped()
end

function ENT:StartEngine()
	if self:GetEngineActive() or not self:IsEngineStartAllowed() then return end

	self:SetEngineActive( true )
	self:OnEngineStarted()
end

function ENT:StopEngine()
	if not self:GetEngineActive() then return end

	self:SetEngineActive( false )
	self:OnEngineStopped()
end