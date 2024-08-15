
util.AddNetworkString( "lvs_buymenu" )

net.Receive( "lvs_buymenu", function( len, ply )
	local class = net.ReadString()

	if not GAMEMODE:VehicleClassAllowed( class ) then return end

	if not ply:IsAdmin() and GAMEMODE:VehicleClassAdminOnly( class ) then return end

	ply:lvsSetCurrentVehicle( class )
end )

local function fixupProp( ply, ent, hitpos, mins, maxs )
	local entPos = ent:GetPos()
	local endposD = ent:LocalToWorld( mins )
	local tr_down = util.TraceLine( {
		start = entPos,
		endpos = endposD,
		filter = { ent, ply }
	} )

	local endposU = ent:LocalToWorld( maxs )
	local tr_up = util.TraceLine( {
		start = entPos,
		endpos = endposU,
		filter = { ent, ply }
	} )

	-- Both traces hit meaning we are probably inside a wall on both sides, do nothing
	if ( tr_up.Hit && tr_down.Hit ) then return end

	if ( tr_down.Hit ) then ent:SetPos( entPos + ( tr_down.HitPos - endposD ) ) end
	if ( tr_up.Hit ) then ent:SetPos( entPos + ( tr_up.HitPos - endposU ) ) end
end

local function TryFixPropPosition( ply, ent, hitpos )
	fixupProp( ply, ent, hitpos, Vector( ent:OBBMins().x, 0, 0 ), Vector( ent:OBBMaxs().x, 0, 0 ) )
	fixupProp( ply, ent, hitpos, Vector( 0, ent:OBBMins().y, 0 ), Vector( 0, ent:OBBMaxs().y, 0 ) )
	fixupProp( ply, ent, hitpos, Vector( 0, 0, ent:OBBMins().z ), Vector( 0, 0, ent:OBBMaxs().z ) )
end

function GM:SpawnVehicle( ply, EntityName, tr )

	if not IsValid( ply ) then return end

	if EntityName == nil then return end

	if not tr then

		local vStart = ply:EyePos()
		local vForward = ply:GetAimVector()

		tr = util.TraceLine( {
			start = vStart,
			endpos = vStart + ( vForward * 4096 ),
			filter = ply
		} )

	end

	local entity = nil
	local PrintName = nil
	local sent = scripted_ents.GetStored( EntityName )

	if sent then

		local sentTable = sent.t

		ClassName = EntityName

			local SpawnFunction = scripted_ents.GetMember( EntityName, "SpawnFunction" )

			if not SpawnFunction then return end

			entity = SpawnFunction( sentTable, ply, tr, EntityName )

			if IsValid( entity ) then
				entity:SetCreator( ply )
			end

		ClassName = nil

		PrintName = sentTable.PrintName

	else

		local SpawnableEntities = list.Get( "SpawnableEntities" )
		if not SpawnableEntities then return end

		local EntTable = SpawnableEntities[ EntityName ]
		if not EntTable then return end

		PrintName = EntTable.PrintName

		local SpawnPos = tr.HitPos + tr.HitNormal * 16

		if EntTable.NormalOffset then SpawnPos = SpawnPos + tr.HitNormal * EntTable.NormalOffset end

		local oobTr = util.TraceLine( {
			start = tr.HitPos,
			endpos = SpawnPos,
			mask = MASK_SOLID_BRUSHONLY
		} )

		if oobTr.Hit then
			SpawnPos = oobTr.HitPos + oobTr.HitNormal * ( tr.HitPos:Distance( oobTr.HitPos ) / 2 )
		end

		entity = ents.Create( EntTable.ClassName )
		entity:SetPos( SpawnPos )

		if EntTable.KeyValues then
			for k, v in pairs( EntTable.KeyValues ) do
				entity:SetKeyValue( k, v )
			end
		end

		if EntTable.Material then
			entity:SetMaterial( EntTable.Material )
		end

		entity:Spawn()
		entity:Activate()

		if EntTable.DropToFloor then
			entity:DropToFloor()
		end

	end

	if not IsValid( entity ) then return end

	ply:AddEntityList( entity )

	ply:SetNWEntity( "lvs_current_spawned_vehicle", entity )

	if entity.SetAITEAM then
		entity:SetAITEAM( ply:lvsGetAITeam() )
	end

	TryFixPropPosition( ply, entity, tr.HitPos )

	return entity
end
