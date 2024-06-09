
function ENT:AddArmor( pos, ang, mins, maxs, health, minforce )
	local Armor = ents.Create( "lvs_armor" )

	if not IsValid( Armor ) then return end

	Armor:SetPos( self:LocalToWorld( pos ) )
	Armor:SetAngles( self:LocalToWorldAngles( ang ) )
	Armor:Spawn()
	Armor:Activate()
	Armor:SetParent( self )
	Armor:SetBase( self )
	Armor:SetMaxHP( health )
	Armor:SetHP( health )
	Armor:SetMins( mins )
	Armor:SetMaxs( maxs )

	if isnumber( minforce ) then
		Armor:SetIgnoreForce( minforce + self.DSArmorIgnoreForce )
	else
		Armor:SetIgnoreForce( self.DSArmorIgnoreForce )
	end

	self:DeleteOnRemove( Armor )

	self:TransferCPPI( Armor )

	self:AddDSArmor( {
		pos = pos,
		ang = ang,
		mins = mins,
		maxs = maxs,
		Callback = function( tbl, ent, dmginfo )
			if not IsValid( Armor ) or not dmginfo:IsDamageType( DMG_AIRBOAT + DMG_SNIPER ) then return true end
	
			local MaxHealth = self:GetMaxHP()
			local MaxArmor = Armor:GetMaxHP()
			local Damage = dmginfo:GetDamage()

			local ArmoredHealth = MaxHealth + MaxArmor
			local NumShotsToKill = ArmoredHealth / Damage

			local ScaleDamage =  math.Clamp( MaxHealth / (NumShotsToKill * Damage),0,1)

			local DidDamage = Armor:TakeTransmittedDamage( dmginfo )

			if DidDamage then
				local Attacker = dmginfo:GetAttacker() 
	
				if IsValid( Attacker ) and Attacker:IsPlayer() then
					net.Start( "lvs_armormarker" )
						net.WriteBool( self:GetHP() > Damage * ScaleDamage )
					net.Send( Attacker )
				end

				dmginfo:ScaleDamage( ScaleDamage )
			else
				dmginfo:ScaleDamage( 0 )
			end

			return true
		end
	} )

	return Armor
end
