
ENT._pdsParts = {}

ENT.PDSDamageVelocity = 100
ENT.PDSDamageMultiplier = 0.05

function ENT:ClearPDS()
	if not istable( self._pdsParts ) then return end

	table.Empty( self._pdsParts )
end

function ENT:PDSHealthValueChanged( name, old, new)
	if new == old then return end
	
	if not self:IsInitialized() or not istable( self._pdsParts ) or new ~= self:GetMaxHP() then return end

	self._pdsPartsAutoProgress = nil

	for _, part in pairs( self._pdsParts ) do
		part:SetStage( 0 )

		if not part._group or not part._subgroup then continue end

		self:SetBodygroup( part._group, part._subgroup )

		part._group = nil
		part._subgroup = nil
	end
end

local function DamagePart( ent, part, speed )
	if ent._pdsPartsAutoProgress and ent._pdsPartsAutoProgress.part == part then
		ent._pdsPartsAutoProgress = nil
	end

	if not speed then
		speed = 0
	end

	local stage = part:GetStage() + 1

	part:SetStage( stage )

	local data = part:GetStageData()

	if isfunction( data.Callback ) then
		data:Callback( ent, part, speed )
	end

	if istable( data.bodygroup ) then
		for group, subgroup in pairs( data.bodygroup ) do
			if not part._group or not part._subgroup then
				part._group = group
				part._subgroup = ent:GetBodygroup( group )
			end

			ent:SetBodygroup( group, subgroup )
		end
	end

	if isstring( data.sound ) then
		ent:EmitSound( data.sound, 75, 100, math.min(0.1 + speed / 700,1) )
	end

	if isnumber( data.maxvelocity ) then
		ent._pdsPartsAutoProgress = {
			part = part,
			velocity = data.maxvelocity,
		}
	end

	if isstring( data.effect ) then
		local effectdata = EffectData()
		effectdata:SetOrigin( ent:LocalToWorld( part.pos ) )
		util.Effect( data.effect, effectdata, true, true )
	end

	if not istable( data.gib ) or not data.gib.mdl then return end

	timer.Simple(0, function()
		if not IsValid( ent ) then return end

		local InvAttach = isstring( data.gib.target )

		local pos
		local ang

		if InvAttach then
			pos = vector_origin
			ang = angle_zero
		else
			if isvector( data.gib.pos ) and isangle( data.gib.ang ) then
				pos = ent:LocalToWorld( data.gib.pos )
				ang = ent:LocalToWorldAngles( data.gib.ang )
			end
		end

		local gib = ents.Create( "prop_physics" )
		gib:SetModel( data.gib.mdl )
		gib:SetPos( pos )
		gib:SetAngles( ang )
		gib:Spawn()
		gib:Activate()
		gib:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
		gib:SetSkin( ent:GetSkin() )

		if InvAttach then
			local att = gib:GetAttachment( gib:LookupAttachment( data.gib.target ) )

			if att then
				local newpos = ent:LocalToWorld( -att.Pos )
				local newang = ent:LocalToWorldAngles( -att.Ang )

				gib:SetPos( newpos )
				gib:SetAngles( newang )
			end
		end

		gib:SetOwner( ent )
		gib:SetColor( ent:GetColor() )
		gib:SetRenderMode( RENDERMODE_TRANSALPHA )

		ent:DeleteOnRemove( gib )
		ent:TransferCPPI( gib )

		timer.Simple( 59.5, function()
			if not IsValid( gib ) then return end
			gib:SetRenderFX( kRenderFxFadeFast  ) 
		end)

		timer.Simple( 60, function()
			if not IsValid( gib ) then return end
			gib:Remove()
		end)

		local PhysObj = gib:GetPhysicsObject()

		if not IsValid( PhysObj ) then return end

		PhysObj:SetVelocityInstantaneous( ent:GetVelocity() + Vector(0,0,250) )
		PhysObj:AddAngleVelocity( VectorRand() * 500 ) 
	end)
end

function ENT:AddPDS( data )
	if not data then return end

	if self._pdsPartsID then
		self._pdsPartsID = self._pdsPartsID + 1
	else
		self._pdsPartsID = 1
	end

	data.pos = data.pos or Vector(0,0,0)
	data.ang = data.ang or Angle(0,0,0)
	data.mins = data.mins or Vector(-1,-1,-1)
	data.maxs = data.maxs or Vector(1,1,1)
	data.stages = data.stages or {}
	data.GetStage = function( self )
		if not self._curstage then
			self._curstage = 0
		end

		return self._curstage
	end
	data.SetStage =  function( self, stage )
		self._curstage = stage
	end

	data.GetStageData =  function( self, stage )
		return self.stages[ self:GetStage() ] or {}
	end

	debugoverlay.BoxAngles( self:LocalToWorld( data.pos ), data.mins, data.maxs, self:LocalToWorldAngles( data.ang ), 8, Color( 50, 50, 0, 150 ) )

	self._pdsParts[ self._pdsPartsID ] = data

	if data.allow_damage then
		local id = self._pdsPartsID

		self:AddDS( {
			pos = data.pos,
			ang = data.ang,
			mins = data.mins,
			maxs = data.maxs,
			Callback = function( tbl, ent, dmginfo )
				if not IsValid( ent ) then return end

				local part = ent._pdsParts[ id ]

				if not part then return end

				DamagePart( ent, part, 1000 )
			end
		} )
	end
end

function ENT:FindPDS( PosToCheck, RadiusAdd )
	if not isnumber( RadiusAdd ) then
		RadiusAdd = 1
	end

	if InfMap then
		PosToCheck = InfMap.unlocalize_vector( PosToCheck, self.CHUNK_OFFSET )
	end

	local Parts = {}

	debugoverlay.Cross( PosToCheck, 50, 4, Color( 255, 255, 0 ) )

	for index, part in ipairs( self._pdsParts ) do
		local mins = part.mins
		local maxs = part.maxs
		local pos = self:LocalToWorld( part.pos )
		local ang = self:LocalToWorldAngles( part.ang )
		local dir = (pos - PosToCheck):GetNormalized()

		local HitPos, HitNormal, Fraction = util.IntersectRayWithOBB( PosToCheck, dir * RadiusAdd, pos, ang, mins, maxs )

		if HitPos then
			table.insert( Parts, part )
		end
	end

	for _, closestPart in ipairs( Parts ) do
		local mins = closestPart.mins
		local maxs = closestPart.maxs
		local pos = self:LocalToWorld( closestPart.pos )
		local ang = self:LocalToWorldAngles( closestPart.ang )
		debugoverlay.BoxAngles( pos, mins, maxs, ang, 1, Color( 255, 255, 0, 150 ) )
	end

	return Parts
end

function ENT:CalcPDS( physdata )
	local VelDif = (physdata.OurOldVelocity - physdata.OurNewVelocity):Length()

	if VelDif < self.PDSDamageVelocity then return end

	local parts = self:FindPDS( physdata.HitPos, (VelDif - self.PDSDamageVelocity) * self.PDSDamageMultiplier )

	if #parts == 0 then return end

	local HP = self:GetHP()
	local MaxHP = self:GetMaxHP()

	if HP == MaxHP then
		self:SetHP( math.max( MaxHP - 0.1, 1 ) )
	end

	for _, part in pairs( parts ) do
		DamagePart( self, part, VelDif )
	end
end

function ENT:PDSThink( data )
	local vel = self:GetVelocity():Length()

	if vel < data.velocity then return end

	DamagePart( self, data.part, vel )

	return true
end