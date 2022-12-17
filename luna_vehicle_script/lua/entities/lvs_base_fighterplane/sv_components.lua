
function ENT:AddEngine( pos )
	local Engine = ents.Create( "lvs_fighterplane_engine" )

	if not IsValid( Engine ) then
		self:Remove()

		print("LVS: Failed to create engine entity. Vehicle terminated.")

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

	self:AddEntityDS( Engine )

	return Engine
end

function ENT:AddRotor( pos )
	local Rotor = ents.Create( "lvs_fighterplane_rotor" )

	if not IsValid( Rotor ) then
		self:Remove()

		print("LVS: Failed to create rotor entity. Vehicle terminated.")

		return
	end

	Rotor:SetPos( self:LocalToWorld( pos ) )
	Rotor:SetAngles( self:GetAngles() )
	Rotor:Spawn()
	Rotor:Activate()
	Rotor:SetParent( self )
	Rotor:SetBase( self )

	self:DeleteOnRemove( Rotor )

	self:TransferCPPI( Rotor )

	return Rotor
end