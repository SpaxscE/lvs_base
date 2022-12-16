
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
	local dmgDir = dmginfo:GetDamageForce():GetNormalized() * self:BoundingRadius()
	local dmgPos = dmginfo:GetDamagePosition()
	local dmgEndPos = dmgDir

	debugoverlay.Line( dmgPos, dmgEndPos, 1, Color( 0, 0, 255 ), true )

	for index, part in pairs( self._dmgEnts ) do
		local mins, maxs = part:GetDamageBounds()
		local pos = part:GetPos()
		local ang = part:GetAngles()

		local HitPos, HitNormal, Fraction = util.IntersectRayWithOBB( dmgPos, dmgEndPos, pos, ang, mins, maxs )

		if HitPos then
			debugoverlay.BoxAngles( pos, mins, maxs, ang, 1, Color( 255, 0, 0 ) )
			debugoverlay.Cross( HitPos,50, 2, Color( 255, 0, 255 ), true )
		else
			debugoverlay.BoxAngles( pos, mins, maxs, ang, 1, Color( 255, 255, 255 ) )
		end
	end

	local Attacker = dmginfo:GetAttacker() 

	if IsValid( Attacker ) and Attacker:IsPlayer() then
		net.Start( "lvs_hitmarker" )
		net.Send( Attacker )
	end
end

-- Vector, Vector, number util.IntersectRayWithOBB( Vector rayStart, Vector rayDelta, Vector boxOrigin, Angle boxAngles, Vector boxMins, Vector boxMaxs )