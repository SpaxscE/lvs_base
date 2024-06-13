
ENT.TrailMaterial = Material( "trails/smoke" )
ENT.TrailRed = 255
ENT.TrailGreen = 255
ENT.TrailBlue = 255
ENT.TrailAlpha = 100

function ENT:OnTrail( active, id )
end

function ENT:HandleTrail()
	if not self.RegisteredTrailPositions then return end

	local FT = RealFrameTime()

	local pos = self:GetPos()
	local vel = self:GetVelocity()
	local vel_length = vel:Length()

	for id, data in pairs( self.RegisteredTrailPositions ) do
		local cur_pos = self:LocalToWorld( data.pos )
		local cur_vel = (cur_pos - data.oldpos) / FT

		local cur_velL = math.abs( self:WorldToLocal( pos + cur_vel ).z )

		if cur_velL > data.activation_speed and vel_length > data.min_flight_speed then
			if not data.id then
				data.id = self:StartTrail( data.pos, data.startsize, data.endsize, data.lifetime )
				self:OnTrail( true, data.id )
			end
		else
			if data.id then
				self:OnTrail( false, data.id )
				self:FinishTrail( data.id )
				data.id = nil
			end
		end

		data.oldpos = cur_pos
	end
end

function ENT:RegisterTrail( Pos, StartSize, EndSize, LifeTime, min_flight_speed, activation_speed )
	if not istable( self.RegisteredTrailPositions ) then
		self.RegisteredTrailPositions = {}
	end

	local data = {
		pos = Pos,
		oldpos = self:LocalToWorld( Pos ),
		startsize = StartSize,
		endsize = EndSize,
		lifetime = LifeTime,
		min_flight_speed = min_flight_speed,
		activation_speed = activation_speed,
	}

	table.insert( self.RegisteredTrailPositions, data )
end

function ENT:StartTrail( Pos, StartSize, EndSize, LifeTime )
	if not LVS.ShowTraileffects then return end

	if not istable( self.TrailActive ) then
		self.TrailActive = {}
	end

	local ID = 1
	for _,_ in ipairs( self.TrailActive ) do
		ID = ID + 1
	end

	self.TrailActive[ ID ] = {
		lifetime = LifeTime,
		start_size = StartSize,
		end_size = EndSize,
		pos = Pos,
		active = true,
		positions = {},
	}

	return ID
end

function ENT:FinishTrail( ID )
	self.TrailActive[ ID ].active = false
end

function ENT:DrawTrail()
	local EntTable = self:GetTable()

	if not EntTable.TrailActive then return end

	local Time = CurTime()

	EntTable._NextTrail = EntTable._NextTrail or 0

	local Set = EntTable._NextTrail < Time

	render.SetMaterial( EntTable.TrailMaterial )

	for ID, data in pairs( EntTable.TrailActive ) do

		for pos_id, pos_data in pairs( data.positions ) do
			if Time - pos_data.time > data.lifetime then
				data.positions[ pos_id ] = nil
			end
		end

		if Set then
			if data.active then
				local cur_pos = {
					time = Time,
					pos = self:LocalToWorld( data.pos ),
				}

				table.insert( data.positions, cur_pos )
				table.sort( data.positions, function( a, b ) return a.time > b.time end )
			end
		end

		local num = #data.positions

		if num == 0 then 
			if not data.active then
				EntTable.TrailActive[ ID ] = nil
			end

			continue
		end

		render.StartBeam( num )

		for _, pos_data in ipairs( data.positions ) do
			local Scale = (pos_data.time + data.lifetime - Time) / data.lifetime
			local InvScale = 1 - Scale

			render.AddBeam( pos_data.pos, data.start_size * Scale + data.end_size * InvScale, pos_data.time * 50, Color( EntTable.TrailRed, EntTable.TrailGreen, EntTable.TrailBlue, EntTable.TrailAlpha * Scale ^ 2 ) )
		end

		render.EndBeam()
	end

	if Set then
		EntTable._NextTrail = Time + 0.025
	end
end
