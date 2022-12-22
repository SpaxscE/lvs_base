
ENT._dmgParts = {}

function ENT:AddDS( data )
	if not data then return end

	data.pos = data.pos or Vector(0,0,0)
	data.ang = data.ang or Angle(0,0,0)
	data.mins = data.mins or Vector(-1,-1,-1)
	data.maxs = data.maxs or Vector(1,1,1)

	debugoverlay.BoxAngles( self:LocalToWorld( data.pos ), data.mins, data.maxs, self:LocalToWorldAngles( data.ang ), 5, Color( 50, 50, 50, 150 ) )

	table.insert( self._dmgParts, data )
end

function ENT:CalcDamage( dmginfo )
	local Damage = dmginfo:GetDamage()
	local CurHealth = self:GetHP()

	local Len = self:BoundingRadius()
	local dmgPos = dmginfo:GetDamagePosition()
	local dmgDir = dmginfo:GetDamageForce():GetNormalized()
	local dmgPenetration = dmgDir * 10

	debugoverlay.Line( dmgPos - dmgDir * 250, dmgPos + dmgPenetration, 4, Color( 0, 0, 255 ) )

	local closestPart
	local closestDist = Len * 2

	for index, part in pairs( self._dmgParts ) do
		local mins = part.mins
		local maxs = part.maxs
		local pos = self:LocalToWorld( part.pos )
		local ang = self:LocalToWorldAngles( part.ang )

		local HitPos, HitNormal, Fraction = util.IntersectRayWithOBB( dmgPos, dmgPenetration, pos, ang, mins, maxs )

		if HitPos then
			debugoverlay.Cross( HitPos, 50, 4, Color( 255, 0, 255 ) )

			local dist = (HitPos - pos):Length()

			if closestDist > dist then
				closestPart = part
				closestDist = dist
			end
		end
	end

	for index, part in pairs( self._dmgParts ) do
		local mins = part.mins
		local maxs = part.maxs
		local pos = self:LocalToWorld( part.pos )
		local ang = self:LocalToWorldAngles( part.ang )

		if part == closestPart then
			debugoverlay.BoxAngles( pos, mins, maxs, ang, 1, Color( 255, 0, 0, 150 ) )
		else
			debugoverlay.BoxAngles( pos, mins, maxs, ang, 1, Color( 100, 100, 100, 150 ) )
		end
	end

	local NewHealth = math.Clamp( CurHealth - Damage, -self:GetMaxHP(), self:GetMaxHP() )

	self:SetHP( NewHealth )

	PrintChat( self:GetHP() )

	local Attacker = dmginfo:GetAttacker() 

	if IsValid( Attacker ) and Attacker:IsPlayer() then
		net.Start( "lvs_hitmarker" )
		net.Send( Attacker )
	end
end
