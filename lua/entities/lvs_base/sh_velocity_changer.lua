
if CLIENT then
	hook.Add( "InitPostEntity", "!!!lvsUpdateMaxVelocity", function()
		net.Start( "lvs_maxvelocity_updater" )
		net.SendToServer()

		hook.Remove( "InitPostEntity", "!!!lvsUpdateMaxVelocity" )
	end )

	net.Receive( "lvs_maxvelocity_updater", function( len, ply )
		for _, data in pairs( net.ReadTable() ) do
			local entity = data.ent

			if not IsValid( entity ) or not entity.LVS or not entity.MaxVelocity then continue end

			entity.MaxVelocity = data.vel
		end
	end )

	return
end

util.AddNetworkString( "lvs_maxvelocity_updater" )

local UpdatedVehicles = {}

net.Receive( "lvs_maxvelocity_updater", function( len, ply )
	if ply._lvsAlreadyAskedForVelocityUpdate then return end

	ply._lvsAlreadyAskedForVelocityUpdate = true

	local TableSend = {}

	for id, data in pairs( UpdatedVehicles ) do
		local entity = data.ent

		if IsValid( entity ) and entity.LVS and isfunction( entity.ChangeVelocity ) then
			table.insert( TableSend, data )

			continue
		end

		UpdatedVehicles[ id ] = nil
	end

	net.Start( "lvs_maxvelocity_updater" )
		net.WriteTable( TableSend )
	net.Send( ply )
end )

function ENT:ChangeVelocity( new )
	self.MaxVelocity = math.min( new, physenv.GetPerformanceSettings().MaxVelocity )

	timer.Simple(0, function()
		if not IsValid( self ) then return end

		local data = { ent = self, vel = new }

		table.insert( UpdatedVehicles, data )

		net.Start( "lvs_maxvelocity_updater" )
			net.WriteTable( {data} )
		net.Broadcast()
	end)
end