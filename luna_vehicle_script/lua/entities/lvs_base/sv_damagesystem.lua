
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
	local dmgPos = dmginfo:GetDamagePosition()
	local dmgDir = dmginfo:GetDamageForce():GetNormalized()
	local dmgPenetration = dmgDir * 25

	debugoverlay.Line( dmgPos - dmgDir * 250, dmgPos + dmgPenetration, 4, Color( 0, 0, 255 ) )

	for index, part in pairs( self._dmgEnts ) do
		local mins, maxs = part:GetDamageBounds()
		local pos = part:GetPos()
		local ang = part:GetAngles()

		local HitPos, HitNormal, Fraction = util.IntersectRayWithOBB( dmgPos, dmgPenetration, pos, ang, mins, maxs )

		if HitPos then
			debugoverlay.BoxAngles( pos, mins, maxs, ang, 1, Color( 255, 0, 0, 150 ) )
			debugoverlay.Cross( HitPos,50, 4, Color( 255, 0, 255 ) )
		else
			debugoverlay.BoxAngles( pos, mins, maxs, ang, 1, Color( 100, 100, 100, 150 ) )
		end
	end

	local Attacker = dmginfo:GetAttacker() 

	if IsValid( Attacker ) and Attacker:IsPlayer() then
		net.Start( "lvs_hitmarker" )
		net.Send( Attacker )
	end
end
