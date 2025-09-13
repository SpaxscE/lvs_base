
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

	self:AddDS( {
		pos = pos,
		ang = Angle(0,0,0),
		mins = Vector(-40,-20,-30),
		maxs =  Vector(40,20,30),
		Callback = function( tbl, ent, dmginfo )
			dmginfo:ScaleDamage( 2.5 )
		end
	} )

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

	if self:BoundingRadius() >= 600 then
		Rotor:SetSound("lvs/vehicles/generic/bomber_propeller.wav")
		Rotor:SetSoundStrain("lvs/vehicles/generic/bomber_propeller_strain.wav")
	end

	self:DeleteOnRemove( Rotor )

	self:TransferCPPI( Rotor )

	return Rotor
end

function ENT:AddExhaust( pos, ang )
	if not istable( self.ExhaustPositions ) then self.ExhaustPositions = {} end

	local Exhaust = {
		pos = pos,
		ang = ang,
	}

	table.insert( self.ExhaustPositions, Exhaust )
end
