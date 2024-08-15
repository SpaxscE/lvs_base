
local meta = FindMetaTable( "Player" )

function meta:ReapplyLoadout()
	local Weapon = self:GetActiveWeapon()

	local Class

	if IsValid( Weapon ) then Class = Weapon:GetClass() end

	self:StripWeapons()
	self:RemoveAllAmmo()

	timer.Simple( 0.5, function()
		if not IsValid( self ) or not self:Alive() then return end

		hook.Call( "PlayerLoadout", GAMEMODE, self )

		if not Class then return end

		self:SelectWeapon( Class )
	end )
end

function meta:CreateGibs( dmginfo )
	local ent = ents.Create( "lvs_player_explosion" )

	if not IsValid( ent ) then return end

	ent:SetPos( self:GetPos() )
	ent:SetAngles( self:GetAngles() )
	ent:SetHull( self:GetHull() )
	ent:SetOwner( self )

	if dmginfo then
		ent:SetForce( dmginfo:GetDamageForce() * 0.001 + self:GetVelocity() )
		ent:SetDissolve( dmginfo:IsDamageType( DMG_DISSOLVE ) )
	end

	ent:Spawn()
	ent:Activate()
end

function meta:ClearEntityList( keep_spawnpoints )
	local List = self:GetEntityList()

	for id, ent in pairs( List ) do

		if ent._lvsPlayerSpawnPoint then

			if keep_spawnpoints then continue end

			GAMEMODE:GameSpawnPointRemoved( self, ent )
		end

		ent:Remove()

		List[ id ]= nil
	end
end

function meta:AddEntityList( ent )
	if not istable( self._EntList ) then
		self._EntList = {}
	end

	table.insert( self._EntList, ent )
end

function meta:GetEntityList()
	if not istable( self._EntList ) then return {} end

	for id, ent in pairs( self._EntList ) do
		if IsValid( ent ) then continue end

		self._EntList[ id ] = nil
	end

	return self._EntList
end
