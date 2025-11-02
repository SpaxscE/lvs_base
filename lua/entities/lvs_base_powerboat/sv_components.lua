
function ENT:AddEngine( pos, ang, mins, maxs )
	if IsValid( self:GetEngine() ) then return end

	ang = ang or angle_zero
	mins = mins or Vector(-10,-10,-10)
	maxs = maxs or Vector(10,10,10)

	local Engine = ents.Create( "lvs_powerboat_engine" )

	if not IsValid( Engine ) then
		self:Remove()

		print("LVS: Failed to create engine entity. Vehicle terminated.")

		return
	end

	Engine:SetPos( self:LocalToWorld( pos ) )
	Engine:SetAngles( self:LocalToWorldAngles( ang ) )
	Engine:Spawn()
	Engine:Activate()
	Engine:SetParent( self )
	Engine:SetBase( self )
	Engine:SetMaxHP( self.MaxHealthEngine )
	Engine:SetHP( self.MaxHealthEngine )

	self:SetEngine( Engine )

	self:DeleteOnRemove( Engine )

	self:TransferCPPI( Engine )

	debugoverlay.BoxAngles( self:LocalToWorld( pos ), mins, maxs, self:LocalToWorldAngles( ang ), 15, Color( 0, 255, 255, 255 ) )

	self:AddDS( {
		pos = pos,
		ang = ang,
		mins = mins,
		maxs =  maxs,
		Callback = function( tbl, ent, dmginfo )
			local Engine = self:GetEngine()

			if not IsValid( Engine ) then return end

			Engine:TakeTransmittedDamage( dmginfo )

			if not Engine:GetDestroyed() then
				dmginfo:ScaleDamage( 0.25 )
			end
		end
	} )

	return Engine
end
