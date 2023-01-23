
function ENT:AddEngineSound( pos )
	local Engine = ents.Create( "lvs_helicopter_engine" )

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

	return Engine
end

function ENT:AddRotor( pos, ang, radius, speed )
	if not pos or not ang or not radius or not speed then return end

	local Rotor = ents.Create( "lvs_helicopter_rotor" )

	if not IsValid( Rotor ) then
		self:Remove()

		print("LVS: Failed to create rotor entity. Vehicle terminated.")

		return
	end

	Rotor:SetPos( self:LocalToWorld( pos ) )
	Rotor:SetAngles( self:LocalToWorldAngles( ang ) )
	Rotor:Spawn()
	Rotor:Activate()
	Rotor:SetParent( self )
	Rotor:SetBase( self )
	Rotor:SetRadius( radius )
	Rotor:SetSpeed( speed )

	self:DeleteOnRemove( Rotor )

	self:TransferCPPI( Rotor )

	return Rotor
end
