
ENT._dmgEnts = {}

function ENT:AddEntityDS( entity )
	if not IsValid( entity ) then return end

	if not entity.GetDamageBounds then
		entity.GetDamageBounds = function( self )
			return self:OBBMins(), self:OBBMaxs()
		end
	end

	table.insert( self._dmgEnts, entity )
end

function ENT:CalcDamage( dmginfo )
	local Damage = dmginfo:GetDamage()
	local CurHealth = self:GetHP()

	local dmgPos = dmginfo:GetDamagePosition()
	local dmgDir = dmginfo:GetDamageForce():GetNormalized()
	local dmgPenetration = dmgDir * 200

	local CriticalHit = false

	for index, part in pairs( self._dmgEnts ) do
		if CriticalHit then break end

		local mins, maxs = part:GetDamageBounds()
		local pos = part:GetPos()
		local ang = part:GetAngles()

		local HitPos, HitNormal, Fraction = util.IntersectRayWithOBB( dmgPos, dmgPenetration, pos, ang, mins, maxs )

		if HitPos then
			CriticalHit = true
		end
	end

	if CriticalHit then
		Damage = Damage * 1.5
	end

	local NewHealth = math.Clamp( CurHealth - Damage, -self:GetMaxHP(), self:GetMaxHP() )

	self:SetHP( NewHealth )

	PrintChat( self:GetHP() )

	local Attacker = dmginfo:GetAttacker() 

	if IsValid( Attacker ) and Attacker:IsPlayer() then
		net.Start( "lvs_hitmarker" )
			net.WriteBool( CriticalHit )
		net.Send( Attacker )
	end
end
