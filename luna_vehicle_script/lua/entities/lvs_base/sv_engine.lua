
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

function ENT:OnEngineActiveChanged( Active )
end

function ENT:StartEngine()
	if self:GetEngineActive() or not self:IsEngineStartAllowed() then return end

	self:SetEngineActive( true )
	self:OnEngineActiveChanged( true )
end

function ENT:StopEngine()
	if not self:GetEngineActive() then return end

	self:SetEngineActive( false )
	self:OnEngineActiveChanged( false )
end

function ENT:AddEngine( pos )
	local Engine = ents.Create( "lvs_engine" )

	if not IsValid( Engine ) then
		self:Remove()

		print("LVS: Failed to create engine point entity. Vehicle terminated.")

		return
	end

	Engine:SetPos( self:LocalToWorld( pos ) )
	Engine:SetAngles( self:GetAngles() )
	Engine:Spawn()
	Engine:Activate()
	Engine:SetParent( self )
	Engine:SetBase( self )

	self:DeleteOnRemove( Engine )

	self:TransferCPPI( Engine )

	return Engine
end