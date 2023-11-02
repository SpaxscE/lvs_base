LVS.VehiclesStored = LVS.VehiclesStored or {}
LVS.NPCsStored = LVS.NPCsStored or {}

function LVS:GetNPCs()
	for index, ent in pairs( LVS.NPCsStored ) do
		if not IsValid( ent ) then
			LVS.NPCsStored[ index ] = nil
		end
	end

	return LVS.NPCsStored
end

function LVS:GetVehicles()
	for index, ent in pairs( LVS.VehiclesStored ) do
		if not IsValid( ent ) then
			LVS.VehiclesStored[ index ] = nil
		end
	end

	return LVS.VehiclesStored
end

hook.Add( "OnEntityCreated", "!!!!lvsEntitySorter", function( ent )
	timer.Simple( 2, function() 
		if not IsValid( ent ) then return end

		if isfunction( ent.IsNPC ) and ent:IsNPC() then
			table.insert( LVS.NPCsStored, ent )
		end

		if ent.LVS then 
			if CLIENT and ent.PrintName then
				language.Add( ent:GetClass(), ent.PrintName)
			end

			table.insert( LVS.VehiclesStored, ent )
		end

		if ent.LFS then 
			table.insert( LVS.VehiclesStored, ent )
		end

		if SERVER then
			LVS:FixVelocity()
		end
	end )
end )